# frozen_string_literal: true

RSpec.describe RebillingSystem, type: :class do
  let(:subscription_id) { "sub_123" }
  let(:amount) { 100 }

  it "has a version number" do
    expect(RebillingSystem::VERSION).not_to be nil
  end

  context "successful payment" do
    it "pays the full amount" do
      stub_request(:post, "#{ENV["PAYMENT_API_URL"]}/paymentIntents/create")
        .to_return_json(body: { "status" => "success" })

      expect(described_class.new(subscription_id, amount).call).to eq(0)
    end
  end

  context "insufficient funds" do
    it "pays the full amount" do
      stub = stub_request(:post, "#{ENV["PAYMENT_API_URL"]}/paymentIntents/create")
             .to_return_json(body: { "status" => "insufficient_funds" })
      expect(described_class.new(subscription_id, amount).call).to eq(100)
      expect(stub)
        .to have_been_made.times(4)
    end
  end
end
