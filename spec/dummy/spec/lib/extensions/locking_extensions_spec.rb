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

require "spec_helper"

RSpec.describe ActiveRecord::LockingExtensions do
  let(:pg_error) do
    ActiveRecord::StatementInvalid.new('PG::Error: ERROR:  deadlock detected')
  end

  let(:mysql_error) do
    ActiveRecord::StatementInvalid.new('Mysql::Error: Deadlock found when trying to get lock')
  end

  let(:sqlite_error) do
    ActiveRecord::StatementInvalid.new('SQLite3::BusyException: database is locked: UPDATE...')
  end

  describe '#restartable_transaction' do
    it "keeps running the lock until a ActiveRecord::RestartTransaction isn't raised" do
      expect(User).to receive(:create!).ordered.and_raise(ActiveRecord::RestartTransaction)
      expect(User).to receive(:create!).ordered.and_raise(ActiveRecord::RestartTransaction)
      expect(User).to receive(:create!).ordered.and_return(true)

      expect { User.restartable_transaction { User.create! } }.not_to raise_error
    end
  end

  describe '#with_restart_on_deadlock' do
    shared_examples 'abstract adapter' do
      it 'raises a ActiveRecord::RestartTransaction error if a deadlock occurs' do
        expect { User.with_restart_on_deadlock { fail exception } }.to raise_error(
          ActiveRecord::RestartTransaction
        )
      end

      it 'publishes a notification' do
        expect(ActiveSupport::Notifications).to receive(:publish).with(
          'deadlock_restart.ledgerizer', hash_including(exception: exception)
        )
        expect { User.with_restart_on_deadlock { fail exception } }.to raise_error(
          ActiveRecord::RestartTransaction
        )
      end
    end

    context 'with mysql adapter' do
      let(:exception) { mysql_error }

      it_behaves_like 'abstract adapter'
    end

    context 'with postgres adapter' do
      let(:exception) { pg_error }

      it_behaves_like 'abstract adapter'
    end

    context 'with sqlite adapter' do
      let(:exception) { sqlite_error }

      it_behaves_like 'abstract adapter'
    end
  end

  describe '#create_ignoring_duplicates' do
    it 'does not raise an error if a duplicate index error is raised in the database' do
      create(:user, id: 1, name: 'Lean')

      expect { create(:user, id: 1, name: 'Lean') }.to raise_error(ActiveRecord::RecordNotUnique)
      expect { User.create_ignoring_duplicates! id: 1, name: 'Lean' }.not_to raise_error
    end

    it 'publishes a notification when a duplicate is encountered' do
      create(:user, id: 1, name: 'Lean')

      expect(ActiveSupport::Notifications).to receive(:publish).with(
        'duplicate_ignore.ledgerizer',
        hash_including(exception: kind_of(ActiveRecord::RecordNotUnique))
      )
      expect { User.create_ignoring_duplicates! id: 1, name: 'Lean' }.not_to raise_error
    end

    shared_examples 'abstract adapter' do
      it 'retries the creation if a deadlock error is raised from the database' do
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect { User.create_ignoring_duplicates! }.not_to raise_error
      end

      it 'publishes a notification on each retry' do
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect(ActiveSupport::Notifications).to receive(:publish).with(
          'deadlock_retry.ledgerizer', hash_including(exception: exception)
        ).twice

        expect { User.create_ignoring_duplicates! }.not_to raise_error
      end
    end

    context 'with mysql adapter' do
      let(:exception) { mysql_error }

      it_behaves_like 'abstract adapter'
    end

    context 'with postgres adapter' do
      let(:exception) { pg_error }

      it_behaves_like 'abstract adapter'
    end

    context 'with sqlite adapter' do
      let(:exception) { sqlite_error }

      it_behaves_like 'abstract adapter'
    end
  end
end
