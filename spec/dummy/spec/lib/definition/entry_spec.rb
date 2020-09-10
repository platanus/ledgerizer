require "spec_helper"

describe Ledgerizer::Definition::Entry do
  subject(:entry) { build(:entry_definition, code: code, document: document) }

  let(:code) { :deposit }
  let(:document) { :deposit }

  it { expect(entry.code).to eq(code) }
  it { expect(entry.document).to eq(document) }

  context "with string code" do
    let(:code) { "deposit" }

    it { expect(entry.code).to eq(code.to_sym) }
  end

  context "with invalid document" do
    let(:document) { :invalid }

    it { expect { entry }.to raise_error(/entry's document must be a snake_case representation/) }
  end

  describe "#find_movement" do
    let(:movement_type) { :debit }
    let(:account_name) { :cash }
    let(:account_currency) { :usd }
    let(:mirror_currency) { :clp }
    let(:accountable) { :user }

    let(:account) do
      build(
        :account_definition,
        name: account_name,
        type: :asset,
        currency: account_currency,
        mirror_currency: mirror_currency
      )
    end

    let(:search_params) do
      {
        movement_type: movement_type,
        account_name: account_name,
        account_currency: account_currency,
        mirror_currency: mirror_currency,
        accountable: accountable
      }
    end

    before do
      entry.add_movement(movement_type: movement_type, account: account, accountable: accountable)
    end

    def perform
      entry.find_movement(search_params)
    end

    it { expect(perform).to be_a(Ledgerizer::Definition::Movement) }

    context "with invalid account name" do
      before { search_params[:account_name] = :bank }

      it { expect(perform).to be_nil }
    end

    context "with invalid account name format" do
      before { search_params[:account_name] = 'cash' }

      it { expect(perform).to be_nil }
    end

    context "with invalid account currency" do
      before { search_params[:account_currency] = :clp }

      it { expect(perform).to be_nil }
    end

    context "with account currency having invalid format" do
      before { search_params[:account_currency] = "USD" }

      it { expect(perform).to be_nil }
    end

    context "with nil account currency" do
      before { search_params[:account_currency] = nil }

      it { expect(perform).to be_nil }
    end

    context "with invalid mirror currency" do
      before { search_params[:mirror_currency] = :usd }

      it { expect(perform).to be_nil }
    end

    context "with mirror currency having invalid format" do
      before { search_params[:mirror_currency] = "CLP" }

      it { expect(perform).to be_nil }
    end

    context "with nil mirror currency" do
      before { search_params[:mirror_currency] = nil }

      it { expect(perform).to be_nil }
    end

    context "with accountable having invalid format" do
      before { search_params[:accountable] = "user" }

      it { expect(perform).to be_nil }
    end

    context "with nil accountable" do
      before { search_params[:accountable] = nil }

      it { expect(perform).to be_nil }
    end
  end

  describe "#add_movement" do
    let(:accountable) { 'user' }
    let(:movement_type) { :debit }
    let(:mirror_currency) { :clp }
    let(:account_currency) { :usd }

    let(:account) do
      build(
        :account_definition,
        name: :cash,
        type: :asset,
        currency: account_currency,
        mirror_currency: mirror_currency
      )
    end

    def perform
      entry.add_movement(
        movement_type: movement_type, account: account, accountable: accountable
      )
    end

    it { expect { perform }.to change { entry.movements.count }.from(0).to(1) }
    it { expect(perform.account_name).to eq(:cash) }
    it { expect(perform.accountable).to eq(:user) }
    it { expect(perform.account_currency).to eq(:usd) }
    it { expect(perform.mirror_currency).to eq(:clp) }
    it { expect(perform.movement_type).to eq(movement_type) }

    context "with added movement" do
      before { perform }

      let(:expected_error) do
        <<~MSG.chomp
          movement with account cash, usd currency (clp mirror currency) and accountable user already exists in tenant
        MSG
      end

      it { expect { perform }.to raise_error(Ledgerizer::ConfigError, expected_error) }

      context "with nil mirror currency" do
        let(:mirror_currency) { nil }

        let(:expected_error) do
          <<~MSG.chomp
            movement with account cash, usd currency (NO mirror currency) and accountable user already exists in tenant
          MSG
        end

        it { expect { perform }.to raise_error(Ledgerizer::ConfigError, expected_error) }
      end

      context "with same account but different currency" do
        let(:another_account) do
          build(
            :account_definition,
            name: account.name,
            type: account.type,
            currency: :ars,
            mirror_currency: mirror_currency
          )
        end

        it do
          expect do
            entry.add_movement(
              movement_type: movement_type, account: another_account, accountable: accountable
            )
          end.to change { entry.movements.count }.from(1).to(2)
        end
      end

      context "with same account but nil mirror currency" do
        let(:another_account) do
          build(
            :account_definition,
            name: account.name,
            type: account.type,
            currency: account_currency,
            mirror_currency: nil
          )
        end

        it do
          expect do
            entry.add_movement(
              movement_type: movement_type, account: another_account, accountable: accountable
            )
          end.to change { entry.movements.count }.from(1).to(2)
        end
      end

      context "with same account but different mirror currency" do
        let(:another_account) do
          build(
            :account_definition,
            name: account.name,
            type: account.type,
            currency: account_currency,
            mirror_currency: :ars
          )
        end

        it do
          expect do
            entry.add_movement(
              movement_type: movement_type, account: another_account, accountable: accountable
            )
          end.to change { entry.movements.count }.from(1).to(2)
        end
      end
    end

    context "with invalid accountable" do
      let(:accountable) { :invalid }

      it { expect { perform }.to raise_error(/accountable must be a snake_case/) }
    end
  end
end
