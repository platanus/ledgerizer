shared_examples "ledgerizer active record accountable" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:accounts) }
  it { expect(entity).to have_many(:lines) }
end

shared_examples "ledgerizer PORO accountable" do |entity_name|
  let(:entity) { create(entity_name) }

  let(:account1) { create(:ledgerizer_account, accountable: entity) }

  before do
    create_list(:ledgerizer_line, 3, account: account1)
    create_list(:ledgerizer_line, 2)
  end

  it { expect(Ledgerizer::Line.count).to eq(5) }
  it { expect(entity.lines.count).to eq(3) }
  it { expect(entity.accounts.count).to eq(1) }
end
