require "spec_helper"

RSpec.describe ActiveRecord::Base do
  describe "#model_names" do
    it { expect(described_class.model_names).to be_a(Array) }
    it { expect(described_class.model_names).to include(:portfolio, :user) }
  end
end
