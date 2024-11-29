# frozen_string_literal: true

require "sidekiq"

class PaymentRetryJob
  include Sidekiq::Job

  def perform(subscription_id, amount)
    RebillingSystem.new(subscription_id, amount).call
  end
end
