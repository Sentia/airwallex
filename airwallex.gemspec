# frozen_string_literal: true

require_relative "lib/airwallex/version"

Gem::Specification.new do |spec|
  spec.name = "airwallex"
  spec.version = Airwallex::VERSION
  spec.authors = ["Chayut Orapinpatipat"]
  spec.email = ["chayut@sentia.com.au"]

  spec.summary = "Production-grade Ruby client for the Airwallex API"
  spec.description = "A comprehensive Ruby gem for integrating with Airwallex's global payment infrastructure, " \
                     "including payment acceptance, payouts, foreign exchange (FX rates, quotes, conversions), " \
                     "and multi-currency balance management. Features automatic authentication, idempotency " \
                     "guarantees, webhook verification, and unified pagination across all resources."
  spec.homepage = "https://www.sentia.com.au"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Sentia/airwallex"
  spec.metadata["changelog_uri"] = "https://github.com/Sentia/airwallex/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/airwallex"
  spec.metadata["bug_tracker_uri"] = "https://github.com/Sentia/airwallex/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml local_tests/ docs/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
end
