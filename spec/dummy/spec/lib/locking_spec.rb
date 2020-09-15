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

describe Ledgerizer::Locking do
  let(:tenant_instance) { create(:portfolio) }
  let(:account_type1) { :asset }
  let(:account_name1) { :account1 }
  let(:accountable1) { create(:user) }
  let(:currency1) { "CLP" }

  let(:executable_account1) do
    build(
      :executable_account,
      tenant: tenant_instance,
      accountable: accountable1,
      account_type: account_type1,
      account_name: account_name1,
      currency: currency1
    )
  end

  let(:account_type2) { :liability }
  let(:account_name2) { :account2 }
  let(:accountable2) { create(:user) }

  let(:executable_account2) do
    build(
      :executable_account,
      tenant: tenant_instance,
      accountable: accountable2,
      account_type: account_type2,
      account_name: account_name2,
      currency: "CLP"
    )
  end

  it "creates missing account balance records" do
    expect do
      Ledgerizer::Locking.lock_accounts(executable_account1) {}
    end.to change(Ledgerizer::Account, :count).by(1)

    account_instance = Ledgerizer::Account.find_by_executable_account(executable_account1)
    expect(account_instance).not_to be_nil
    expect(account_instance.balance).to eq(clp(0))
  end

  context "with account lines" do
    before do
      create(
        :ledgerizer_line,
        force_tenant: tenant_instance,
        force_accountable: accountable1,
        force_account_type: account_type1,
        force_account_name: account_name1,
        amount: clp(3),
        balance: clp(3)
      )

      create(
        :ledgerizer_line,
        force_tenant: tenant_instance,
        force_accountable: accountable1,
        force_account_type: account_type1,
        force_account_name: account_name1,
        amount: clp(7),
        balance: clp(10)
      )
    end

    it "takes the balance for new account from the lines table" do
      expect do
        Ledgerizer::Locking.lock_accounts(executable_account1) {}
      end.to change(Ledgerizer::Account, :count).by(1)

      account_balance = Ledgerizer::Account.find_by_executable_account(executable_account1)
      expect(account_balance).not_to be_nil
      expect(account_balance.balance).to eq(clp(10))
    end
  end

  context "with ActiveRecord::StatementInvalid errors" do
    context "with non lock wait timeout errors" do
      let(:error) { ActiveRecord::StatementInvalid.new("some other error") }

      before do
        allow(Ledgerizer::Account).to receive(:with_restart_on_deadlock).and_raise(error)
      end

      it "re-raises the ActiveRecord::StatementInvalid error" do
        expect do
          Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) {}
        end.to raise_error(error)
      end
    end

    context "with lock wait timeout errors" do
      before do
        allow(Ledgerizer::Account).to receive(
          :with_restart_on_deadlock
        ).and_raise(ActiveRecord::StatementInvalid, "lock wait timeout")
      end

      it "raises a LockWaitTimeout error" do
        expect do
          Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) {}
        end.to raise_error(Ledgerizer::Locking::LockWaitTimeout)
      end
    end
  end

  it "prohibits locking inside a regular transaction" do
    expect do
      Ledgerizer::Account.transaction do
        Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) {}
      end
    end.to raise_error(Ledgerizer::Locking::LockMustBeOutermostTransaction)
  end

  it "allows nested locks if the outer lock locks all the accounts" do
    expect do
      Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) do
        Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) {}
      end
    end.not_to raise_error
  end

  it "prohibits nested locks if the out lock doesn't lock all the accounts" do
    expect do
      Ledgerizer::Locking.lock_accounts(executable_account1) do
        Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) {}
      end
    end.to raise_error(Ledgerizer::Locking::LockNotHeld, /No lock held for account/)
  end

  context "with entry executor" do
    let(:tenant_instance) { create(:portfolio) }
    let(:document_instance) { create(:deposit) }
    let(:entry_code) { :entry1 }
    let(:entry_time) { "1984-06-04" }
    let(:ledgerizer_config) { LedgerizerTestDefinition.definition }
    let(:conversion_amount) { nil }

    let(:executor) do
      Ledgerizer::EntryExecutor.new(
        config: ledgerizer_config,
        tenant: tenant_instance,
        document: document_instance,
        entry_code: entry_code,
        entry_time: entry_time,
        conversion_amount: conversion_amount
      )
    end

    let_definition_class do
      tenant('portfolio', currency: :clp) do
        asset(:account1)
        liability(:account2)

        entry(:entry1, document: :deposit) do
          debit(account: :account1, accountable: :user)
          credit(account: :account2, accountable: :user)
        end
      end
    end

    before do
      executor.add_new_movement(
        movement_type: :debit,
        account_name: account_name1,
        accountable: accountable1,
        amount: clp(10)
      )

      executor.add_new_movement(
        movement_type: :credit,
        account_name: account_name2,
        accountable: accountable2,
        amount: clp(10)
      )
    end

    it 'prohibits execution inside a regular transaction' do
      expect do
        Ledgerizer::Account.transaction do
          executor.execute
        end
      end.to raise_error(Ledgerizer::Locking::LockMustBeOutermostTransaction)
    end

    it "allows a transfer inside a lock if we've locked the transaction accounts" do
      expect do
        Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) do
          executor.execute
        end
      end.not_to raise_error
    end

    it "does not allow a transfer inside a lock if the right locks aren't held" do
      expect do
        Ledgerizer::Locking.lock_accounts(executable_account1) do
          executor.execute
        end
      end.to raise_error(Ledgerizer::Locking::LockNotHeld, /No lock held for account/)
    end

    it 'rolls back a locking transaction' do
      Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) do
        executor.execute
        fail ActiveRecord::Rollback
      end

      expect(executable_account1.balance).to eq(clp(0))
      expect(executable_account2.balance).to eq(clp(0))
    end

    it "rolls back a locking transaction if there's an exception" do
      expect do
        Ledgerizer::Locking.lock_accounts(executable_account1, executable_account2) do
          executor.execute
          fail 'Yeah, right'
        end
      end.to raise_error('Yeah, right')

      expect(executable_account1.balance).to eq(clp(0))
      expect(executable_account2.balance).to eq(clp(0))
    end
  end
end
