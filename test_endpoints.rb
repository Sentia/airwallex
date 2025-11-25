#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/airwallex"

# Load .env.development if it exists
if File.exist?(".env.development")
  File.readlines(".env.development").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    key, value = line.split("=", 2)
    ENV[key] = value if key && value
  end
end

# Configure the client
Airwallex.configure do |config|
  config.client_id = ENV.fetch("DEV_CLIENT_ID", nil)
  config.api_key = ENV.fetch("DEV_API_KEY", nil)
  config.environment = :sandbox
end

puts "=" * 80
puts "Airwallex Ruby Gem - Endpoint Testing"
puts "=" * 80
puts

client = Airwallex.client

# Test 1: Authentication
puts "Test 1: Authentication"
puts "-" * 80
begin
  token = client.authenticate!
  puts "✓ Authentication successful"
  puts "  Token: #{token[0..20]}..."
  puts "  Expires at: #{client.token_expires_at}"
rescue Airwallex::Error => e
  puts "✗ Authentication failed: #{e.message}"
  puts "  Error class: #{e.class}"
  puts "  HTTP status: #{e.http_status}" if e.http_status
  puts "  Details: #{e.inspect}"
  exit 1
rescue StandardError => e
  puts "✗ Unexpected error: #{e.message}"
  puts "  Error class: #{e.class}"
  puts "  Backtrace: #{e.backtrace[0..5].join("\n  ")}"
  exit 1
end
puts

# Test 2: Token Auto-Refresh
puts "Test 2: Token Expiry Check"
puts "-" * 80
puts "  Token expired?: #{client.token_expired?}"
puts "  Token expires in: #{((client.token_expires_at - Time.now) / 60).round(2)} minutes"
puts

# Test 3: GET Request (List Payment Intents - will return empty or data)
puts "Test 3: GET Request - List Payment Intents"
puts "-" * 80
begin
  response = client.get("/api/v1/pa/payment_intents", { page_size: 5 })
  puts "✓ GET request successful"
  puts "  Response keys: #{response.keys.join(", ")}" if response.is_a?(Hash)
  puts "  Found #{response["items"].size} payment intent(s)" if response.is_a?(Hash) && response["items"]
rescue Airwallex::Error => e
  puts "✗ GET request failed: #{e.message}"
  puts "  Status: #{e.http_status}" if e.http_status
end
puts

# Test 4: POST Request with Idempotency (Create Payment Intent - will fail without full params)
puts "Test 4: POST Request with Idempotency - Create Payment Intent"
puts "-" * 80
begin
  # This will likely fail due to validation, but tests the request flow
  response = client.post("/api/v1/pa/payment_intents/create", {
                           amount: 100.00,
                           currency: "USD"
                         })
  puts "✓ POST request successful"
  puts "  Payment Intent ID: #{response["id"]}" if response.is_a?(Hash) && response["id"]
rescue Airwallex::BadRequestError => e
  puts "⚠ POST request validation failed (expected - missing required fields)"
  puts "  Message: #{e.message}"
  puts "  This is OK - it proves the request reached the API"
rescue Airwallex::Error => e
  puts "✗ POST request failed: #{e.message}"
  puts "  Status: #{e.http_status}" if e.http_status
end
puts

# Test 5: Error Handling
puts "Test 5: Error Handling - Invalid Endpoint"
puts "-" * 80
begin
  client.get("/api/v1/invalid/endpoint")
  puts "✗ Should have raised an error"
rescue Airwallex::NotFoundError => e
  puts "✓ Correctly raised NotFoundError"
  puts "  Message: #{e.message}"
rescue Airwallex::Error => e
  puts "✓ Correctly raised #{e.class.name}"
  puts "  Message: #{e.message}"
end
puts

# Test 6: Configuration
puts "Test 6: Configuration"
puts "-" * 80
puts "  Environment: #{Airwallex.configuration.environment}"
puts "  API URL: #{Airwallex.configuration.api_url}"
puts "  API Version: #{Airwallex.configuration.api_version}"
puts "  Client ID: #{Airwallex.configuration.client_id[0..10]}..."
puts "  Configured?: #{Airwallex.configuration.configured?}"
puts

puts "=" * 80
puts "All endpoint tests completed!"
puts "=" * 80
