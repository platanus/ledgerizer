require "spec_helper"

RSpec.describe Ledgerizer::Validators do
  describe '#validate_active_record_model_name!' do
    let(:model_name) { :portfolio }
    let(:error_prefix) { 'name' }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_active_record_model_name!(model_name, error_prefix)
    end

    def raise_invalid_model_error
      expect { perform }.to raise_error(/must be an ActiveRecord model name/)
    end

    it { expect(perform).to eq(true) }

    context "when string model name" do
      let(:model_name) { "portfolio" }

      it { raise_invalid_model_error }
    end

    context "with camel model name" do
      let(:model_name) { "Portfolio" }

      it { raise_invalid_model_error }
    end

    context "when model name is the class" do
      let(:model_name) { Portfolio }

      it { raise_invalid_model_error }
    end

    context "when name does not match AR model" do
      let(:model_name) { "invalid" }

      it { raise_invalid_model_error }
    end
  end

  describe '#validate_currency!' do
    let(:currency) { :clp }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_currency!(currency)
    end

    it { expect(perform).to eq(true) }

    context "when different currency" do
      let(:currency) { :usd }

      it { expect(perform).to eq(true) }
    end

    context "with string currency" do
      let(:currency) { "clp" }

      it { expect(perform).to eq(true) }
    end

    context "with upcase currency" do
      let(:currency) { "CLP" }

      it { expect(perform).to eq(true) }
    end

    context "with invalid currency" do
      let(:currency) { :petro }

      it { expect { perform }.to raise_error("invalid currency 'petro' given") }
    end
  end

  describe '#validate_date!' do
    let(:date) { "1984-06-04" }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_date!(date)
    end

    it { expect(perform).to eq(true) }

    context "when invalid date" do
      let(:date) { "invalid" }

      it { expect { perform }.to raise_error("invalid date given") }
    end
  end

  describe "#validate_tenant_instance!" do
    let(:error_prefix) { 'value' }

    define_test_class do
      include Ledgerizer::Definition::Dsl
      include Ledgerizer::Validators

      tenant(:portfolio)
    end

    def perform
      test_class.new.validate_tenant_instance!(instance, error_prefix)
    end

    context "with valid tenant" do
      let(:instance) { create(:portfolio) }

      it { expect(perform).to eq(true) }
    end

    context "with valid model that is not a tenant" do
      let(:instance) { create(:user) }

      it { expect { perform }.to raise_error("can't find tenant for given User model") }
    end

    context "with non ActiveRecord instance" do
      let(:instance) { LedgerizerTest.new }

      it { expect { perform }.to raise_error("value must be an ActiveRecord model") }
    end
  end

  describe "#validate_tenant_entry!" do
    let(:tenant) { create(:portfolio) }
    let(:entry_code) { :deposit }
    let(:document) { create(:user) }

    define_test_class do
      include Ledgerizer::Definition::Dsl
      include Ledgerizer::Validators

      tenant(:portfolio) do
        entry(:deposit, document: :user)
      end
    end

    def perform
      test_class.new.validate_tenant_entry!(tenant, entry_code, document)
    end

    it { expect(perform).to eq(true) }

    context "with invalid entry" do
      let(:entry_code) { :register }

      it { expect { perform }.to raise_error("invalid entry code register for given tenant") }
    end

    context "with invalid document" do
      let(:document) { create(:portfolio) }

      it { expect { perform }.to raise_error("invalid document Portfolio for given deposit entry") }
    end
  end

  describe "#validate_entry_account!" do
    let(:tenant) { create(:portfolio) }
    let(:entry_code) { :deposit }
    let(:accountable) { create(:user) }
    let(:account_type) { :credit }
    let(:account_name) { :cash }

    define_test_class do
      include Ledgerizer::Definition::Dsl
      include Ledgerizer::Validators

      tenant(:portfolio) do
        asset(:cash)

        entry(:deposit, document: :user) do
          credit(account: :cash, accountable: :user)
        end
      end
    end

    def perform
      test_class.new.validate_entry_account!(
        tenant, entry_code, account_type, account_name, accountable
      )
    end

    it { expect(perform).to eq(true) }

    context "with invalid account name" do
      let(:account_name) { :bank }

      it { expect { perform }.to raise_error(/bank with accountable User for given deposit entry/) }
    end

    context "with valid account name but invalid accountable" do
      let(:accountable) { create(:portfolio) }

      it { expect { perform }.to raise_error(/with accountable Portfolio for given deposit entry/) }
    end

    context "with invalid account type" do
      let(:account_type) { :debit }

      it { expect { perform }.to raise_error(/User for given deposit entry in debits/) }
    end
  end

  describe "#validate_money!" do
    let(:value) { clp(1000) }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_money!(value)
    end

    it { expect(perform).to eq(true) }

    context "with nil value" do
      let(:value) { nil }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with not money value" do
      let(:value) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end
  end

  describe "#validate_positive_money!" do
    let(:value) { clp(1000) }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_positive_money!(value)
    end

    it { expect(perform).to eq(true) }

    context "with not money value" do
      let(:value) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with 0 value" do
      let(:value) { clp(0) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with negative value" do
      let(:value) { clp(-1) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end
  end

  describe "#validate_tenant_currency!" do
    let(:tenant) { create(:portfolio) }
    let(:currency) { :clp }

    define_test_class do
      include Ledgerizer::Validators
      include Ledgerizer::Definition::Dsl

      tenant(:portfolio, currency: :clp)
    end

    def perform
      test_class.new.validate_tenant_currency!(tenant, currency)
    end

    it { expect(perform).to eq(true) }

    context "with currency not matching tenant currency" do
      let(:currency) { :usd }

      it { expect { perform }.to raise_error("usd is not the tenant's currency") }
    end
  end
end
