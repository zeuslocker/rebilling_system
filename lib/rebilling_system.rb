# frozen_string_literal: true

require "dotenv/load"
require_relative "rebilling_system/version"
require "date"
require "faraday"

class RebillingSystem
  def initialize(subscription_id, amount)
    @subscription_id = subscription_id
    @amount = amount
  end

  def call
    puts "Starting rebill process for subscription: #{@subscription_id}, amount: #{@amount}"

    remaining_balance = @amount
    attempts = 0
    percentages = [1.0, 0.75, 0.50, 0.25]

    percentages.each do |percentage|
      attempts += 1
      partial_amount = (@amount * percentage).round(2)
      result = attempt_payment(partial_amount)

      case result["status"]
      when "success"
        remaining_balance -= partial_amount
        break if remaining_balance <= 0 # Fully paid
      when "insufficient_funds"
        next
      when "failed"
        puts "Payment failed for #{partial_amount}. Aborting rebill process."
        break
      end

      break if attempts >= 4
    end

    schedule_partial_payment(@subscription_id, remaining_balance) if remaining_balance.positive?
    remaining_balance
  end

  private

  def attempt_payment(amount)
    puts "Attempting to charge #{amount} for subscription #{@subscription_id}"
    response = Faraday.post("#{ENV["PAYMENT_API_URL"]}/paymentIntents/create")

    JSON.parse(response.body)
  end

  # Schedule a partial payment for the remaining balance a week later
  def schedule_partial_payment(subscription_id, amount)
    puts "Scheduling remaining balance of #{amount} for subscription #{subscription_id} in one week."
  end
end
