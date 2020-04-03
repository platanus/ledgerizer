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

module ActiveRecord
  # These methods are available as class methods on ActiveRecord::Base.
  module LockingExtensions
    # Execute the given block within a database transaction, and retry the
    # transaction from the beginning if a RestartTransaction exception is raised.
    def restartable_transaction(&block)
      transaction(&block)
    rescue ActiveRecord::RestartTransaction
      retry
    end

    # Execute the given block, and retry the current restartable transaction if a
    # MySQL deadlock occurs.
    def with_restart_on_deadlock
      yield
    rescue ActiveRecord::StatementInvalid => e
      if e.message =~ /deadlock/i || e.message =~ /database is locked/i
        ActiveSupport::Notifications.publish('deadlock_restart.double_entry', exception: e)

        raise ActiveRecord::RestartTransaction
      else
        raise
      end
    end

    # Create the record, but ignore the exception if there's a duplicate.
    # if there is a deadlock, retry
    def create_ignoring_duplicates!(*args)
      retry_deadlocks do
        ignoring_duplicates do
          create!(*args)
        end
      end
    end

    private

    def ignoring_duplicates
      yield
    rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique => e
      if  e.message =~ /duplicate/i || e.message =~ /ConstraintException/
        ActiveSupport::Notifications.publish('duplicate_ignore.double_entry', exception: e)

        # Just ignore it...someone else has already created the record.
      else
        raise
      end
    end

    def retry_deadlocks
      # Error examples:
      #   PG::Error: ERROR:  deadlock detected
      #   Mysql::Error: Deadlock found when trying to get lock
      yield
    rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique => e
      if e.message =~ /deadlock/i || e.message =~ /database is locked/i
        # Somebody else is in the midst of creating the record. We'd better
        # retry, so we ensure they're done before we move on.
        ActiveSupport::Notifications.publish('deadlock_retry.double_entry', exception: e)

        retry
      else
        raise
      end
    end
  end

  # Raise this inside a restartable_transaction to retry the transaction from the beginning.
  class RestartTransaction < RuntimeError
  end
end

ActiveRecord::Base.extend(ActiveRecord::LockingExtensions)
