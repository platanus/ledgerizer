require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe ActiveRecord::Base do
  describe "#model_names" do
    it { expect(described_class.model_names).to be_a(Array) }
    it { expect(described_class.model_names).to include(:portfolio, :user) }
  end
end
# rubocop:enable RSpec/FilePath
