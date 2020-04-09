# Copyright © 2014 Envato Pty Ltd
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Ledgerizer
  # Lock financial accounts to ensure consistency.
  #
  # In order to ensure financial transactions always keep track of balances
  # consistently, database-level locking is needed. This module takes care of
  # it.
  #
  # Locking is done on Ledgerizer::Account records. If an Account
  # record for an account doesn't exist when you try to lock it, the locking
  # code will create one.
  module Locking
    # Run the passed in block in a transaction with the given accounts locked for update.
    #
    # The transaction must be the outermost transaction to ensure data integrity. A
    # LockMustBeOutermostTransaction will be raised if it isn't.
    def self.lock_accounts(*accounts, &block)
      lock = Lock.new(accounts)

      if lock.in_a_locked_transaction?
        lock.ensure_locked!
        block.call
      else
        lock.perform_lock(&block)
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message =~ /lock wait timeout/i
        raise LockWaitTimeout
      else
        raise
      end
    end

    # Return the account balance record for the given account name if there's a
    # lock on it, or raise a LockNotHeld if there isn't.
    def self.balance_for_locked_account(account)
      Lock.new([account]).balance_for(account)
    end

    class Lock
      @@locks = {}

      def initialize(accounts)
        # Make sure we always lock in the same order, to avoid deadlocks.
        @accounts = accounts.flatten.sort
      end

      # Lock the given accounts, creating account balance records for them if needed.
      def perform_lock(&block)
        ensure_outermost_transaction!

        unless lock_and_call(&block)
          create_missing_account_balances
          fail LockDisaster unless lock_and_call(&block)
        end
      end

      # Return true if we're inside a lock_accounts block.
      def in_a_locked_transaction?
        !locks.nil?
      end

      def ensure_locked!
        @accounts.each do |account|
          unless lock?(account)
            msg = "No lock held for account: #{account.identifier}"
            fail LockNotHeld, msg
          end
        end
      end

      def balance_for(account)
        ensure_locked!

        locks[account]
      end

      private

      def locks
        @@locks[Thread.current.object_id]
      end

      def locks=(locks)
        @@locks[Thread.current.object_id] = locks
      end

      def remove_locks
        @@locks.delete(Thread.current.object_id)
      end

      # Return true if there's a lock on the given account.
      def lock?(account)
        in_a_locked_transaction? && locks.key?(account)
      end

      # Raise an exception unless we're outside any transactions.
      def ensure_outermost_transaction!
        min_transaction_level = Ledgerizer.definition.running_inside_transactional_fixtures ? 1 : 0
        unless Ledgerizer::Account.connection.open_transactions <= min_transaction_level
          fail LockMustBeOutermostTransaction
        end
      end

      # Start a transaction, grab locks on the given accounts, then call the block
      # from within the transaction.
      #
      # If any account can't be locked (because there isn't a corresponding account
      # balance record), don't call the block, and return false.
      def lock_and_call
        locks_succeeded = nil
        Ledgerizer::Account.restartable_transaction do
          locks_succeeded = Ledgerizer::Account.with_restart_on_deadlock { grab_locks }
          if locks_succeeded
            begin
              yield
            ensure
              remove_locks
            end
          end
        end
        locks_succeeded
      end

      # Grab a lock on the account balance record for each account.
      #
      # If all the account balance records exist, set locks to a hash mapping
      # accounts to account balances, and return true.
      #
      # If one or more account balance records don't exist, set
      # accounts_with_balances to the corresponding accounts, and return false.
      def grab_locks
        account_balances = @accounts.map do |account|
          Ledgerizer::Account.find_by_executable_account(account, lock: true)
        end

        if account_balances.any?(&:nil?)
          accts = @accounts.zip(account_balances)
                           .select { |_account, account_balance| account_balance.nil? }
                           .collect { |account, _account_balance| account }
          @accounts_without_balances = accts
          false
        else
          self.locks = Hash[*@accounts.zip(account_balances).flatten]
          true
        end
      end

      # Create the account_balances for the given accounts.
      def create_missing_account_balances
        @accounts_without_balances.each do |account|
          # Try to create the balance record,
          # but ignore it if someone else has done it in the meantime.
          Ledgerizer::Account.create_ignoring_duplicates!(
            account.to_hash.merge(balance: account.balance)
          )
        end
      end
    end

    # Raised when lock_accounts is called inside an existing transaction.
    class LockMustBeOutermostTransaction < RuntimeError
    end

    # Raised when attempting a transfer on an account that's not locked.
    class LockNotHeld < RuntimeError
    end

    # Raised if things go horribly, horribly wrong. This should never happen.
    class LockDisaster < RuntimeError
    end

    # Raised if waiting for locks times out.
    class LockWaitTimeout < RuntimeError
    end
  end
end
