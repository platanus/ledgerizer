require 'rails_helper'

module Ledgerizer
  RSpec.describe Account, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_account)).to be_valid
    end

    describe "associations" do
      it { is_expected.to belong_to(:tenant) }
      it { is_expected.to belong_to(:accountable).optional }
      it { is_expected.to have_many(:lines).dependent(:destroy) }
    end

    describe "validations" do
      it { is_expected.to enumerize(:account_type).in(Ledgerizer::Definition::Account::TYPES) }
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:account_type) }
      it { is_expected.to validate_presence_of(:currency) }
      it { is_expected.to validate_presence_of(:balance_cents) }
      it { is_expected.to monetize(:balance) }

      it_behaves_like 'currency', :ledgerizer_account
    end

    it_behaves_like "ledgerizer lines related", :ledgerizer_account

    describe "#find_by_executable_account" do
      let(:executable_tenant_instance) { create(:portfolio) }
      let(:executable_account_type) { :asset }
      let(:executable_account_name) { :account1 }
      let(:executable_accountable) { create(:user) }
      let(:executable_currency) { "CLP" }

      let(:tenant_instance) { executable_tenant_instance }
      let(:account_type) { executable_account_type }
      let(:account_name) { executable_account_name }
      let(:accountable) { executable_accountable }
      let(:currency) { executable_currency }

      let(:lock) { false }

      let(:executable_account) do
        build(
          :executable_account,
          tenant: executable_tenant_instance,
          accountable: executable_accountable,
          account_type: executable_account_type,
          account_name: executable_account_name,
          currency: executable_currency
        )
      end

      let!(:account) do
        create(
          :ledgerizer_account,
          tenant: tenant_instance,
          accountable: accountable,
          account_type: account_type,
          name: account_name,
          currency: currency
        )
      end

      def perform
        described_class.find_by_executable_account(executable_account, lock: true)
      end

      it { expect(perform).to eq(account) }

      context "with executable currency not matching the account" do
        let(:currency) { "USD" }

        it { expect(perform).to be_nil }
      end

      context "with executable accountable not matching the account" do
        let(:accountable) { create(:user) }

        it { expect(perform).to be_nil }
      end

      context "with executable tenant not matching the account" do
        let(:tenant_instance) { create(:portfolio) }

        it { expect(perform).to be_nil }
      end

      context "with executable account_name not matching the account" do
        let(:account_name) { :account2 }

        it { expect(perform).to be_nil }
      end

      context "with executable account_type not matching the account" do
        let(:account_type) { :liability }

        it { expect(perform).to be_nil }
      end
    end

    describe "#balance_at" do
      let(:datetime) { nil }
      let(:account) { create(:ledgerizer_account) }

      def perform
        account.balance_at(datetime)
      end

      before do
        create(
          :ledgerizer_line,
          account: account,
          force_entry_time: "1984-06-04".to_datetime,
          balance: clp(10)
        )

        create(
          :ledgerizer_line,
          account: account,
          force_entry_time: "1984-06-05".to_datetime + 1.minute,
          balance: clp(15)
        )

        create(
          :ledgerizer_line,
          account: account,
          force_entry_time: "1984-06-05".to_datetime + 2.minutes,
          balance: clp(20)
        )

        create(
          :ledgerizer_line,
          account: account,
          force_entry_time: "1984-06-05".to_datetime + 3.minutes,
          balance: clp(25)
        )

        create(
          :ledgerizer_line,
          account: account,
          force_entry_time: "1984-06-06".to_datetime,
          balance: clp(30)
        )
      end

      it { expect(perform).to eq(clp(30)) }

      context "with specific datetime" do
        let(:datetime) { "1984-06-05".to_datetime + 3.minutes }

        it { expect(perform).to eq(clp(25)) }
      end

      context "with super old datetime" do
        let(:datetime) { "1974-06-05".to_datetime }

        it { expect(perform).to eq(clp(0)) }
      end

      context "with super new datetime" do
        let(:datetime) { "2084-06-05".to_datetime }

        it { expect(perform).to eq(clp(30)) }
      end
    end

    describe "check_integrity" do
      let(:account_balance) { nil }
      let(:account) { create(:ledgerizer_account, balance: account_balance) }

      def perform
        account.check_integrity
      end

      context "with no lines" do
        let(:account_balance) { clp(0) }

        it { expect(perform).to eq(true) }
      end

      context "with valid lines matching account balance" do
        let(:account_balance) { clp(20) }

        before do
          create(:ledgerizer_line, account: account, amount: clp(10), balance: clp(10))
          create(:ledgerizer_line, account: account, amount: clp(5), balance: clp(15))
          create(:ledgerizer_line, account: account, amount: clp(5), balance: clp(20))
        end

        it { expect(perform).to eq(true) }
      end

      context "with valid lines not matching account balance" do
        let(:account_balance) { clp(666) }

        before do
          create(:ledgerizer_line, account: account, amount: clp(10), balance: clp(10))
          create(:ledgerizer_line, account: account, amount: clp(5), balance: clp(15))
          create(:ledgerizer_line, account: account, amount: clp(5), balance: clp(20))
        end

        it { expect(perform).to eq(false) }
      end

      context "with invalid lines balances" do
        let(:account_balance) { clp(20) }

        before do
          create(:ledgerizer_line, account: account, amount: clp(10), balance: clp(10))
          create(:ledgerizer_line, account: account, amount: clp(666), balance: clp(15))
          create(:ledgerizer_line, account: account, amount: clp(5), balance: clp(20))
        end

        it { expect(perform).to eq(false) }
      end
    end
  end
end
