# frozen_string_literal: true

module Airwallex
  class Beneficiary < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    extend APIOperations::Delete

    def self.resource_path
      "/api/v1/beneficiaries"
    end
  end
end
