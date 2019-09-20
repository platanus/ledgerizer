shared_examples 'definition dsl movement' do |type|
  describe "##{type}" do
    it "raises error with no tenant" do
      expect_error_in_class_definition("'#{type}' needs to run inside 'entry' block") do
        include Ledgerizer::Definition::Dsl

        send(type, account: nil, accountable: nil)
      end
    end

    it "raises error with no entry" do
      expect_error_in_class_definition("'#{type}' needs to run inside 'entry' block") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(type, account: nil, accountable: nil)
        end
      end
    end

    it "raises error with no defined account" do
      expect_error_in_class_definition("the cash account does not exist in tenant") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'portfolio') do
            send(type, account: :cash, accountable: nil)
          end
        end
      end
    end

    it "raises error with invalid accountable" do
      expect_error_in_class_definition("accountable must be an ActiveRecord model name") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          asset(:cash)

          entry(:deposit, document: 'portfolio') do
            send(type, account: :cash, accountable: 'invalid')
          end
        end
      end
    end

    context "with valid #{type}" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          asset(:cash)

          entry(:deposit, document: :portfolio) do
            send(type, account: :cash, accountable: :user)
          end
        end
      end

      let(:expected) do
        {
          movement_type: type,
          account: :cash,
          accountable: :user
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :deposit, expected) }
    end

    context "with multiple movements" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          asset(:cash)
          asset(:bank)

          entry(:deposit, document: :portfolio) do
            send(type, account: :cash, accountable: :user)
            send(type, account: :bank, accountable: :user)
          end
        end
      end

      let(:exp_cash) do
        {
          movement_type: type,
          account: :cash,
          accountable: :user
        }
      end

      let(:exp_bank) do
        {
          movement_type: type,
          account: :bank,
          accountable: :user
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :deposit, exp_cash) }
      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :deposit, exp_bank) }
    end

    context "with movements in multiple entries" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          asset(:cash)
          asset(:bank)

          entry(:deposit, document: :portfolio) do
            send(type, account: :cash, accountable: :user)
            send(type, account: :bank, accountable: :user)
          end

          entry(:distribute, document: :portfolio) do
            send(type, account: :cash, accountable: :user)
          end
        end
      end

      let(:exp_cash) do
        {
          movement_type: type,
          account: :cash,
          accountable: :user
        }
      end

      let(:exp_bank) do
        {
          movement_type: type,
          account: :bank,
          accountable: :user
        }
      end

      let(:exp_cash1) do
        {
          movement_type: type,
          account: :cash,
          accountable: :user
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :deposit, exp_cash) }
      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :deposit, exp_bank) }
      it { expect(LedgerizerTest).to have_tenant_account_entry(:portfolio, :distribute, exp_cash1) }
    end
  end
end
