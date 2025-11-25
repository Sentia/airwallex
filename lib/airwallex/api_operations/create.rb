# frozen_string_literal: true

module Airwallex
  module APIOperations
    module Create
      def create(params = {}, opts = {})
        response = Airwallex.client.post(
          "#{resource_path}/create",
          params,
          opts[:headers] || {}
        )
        new(response)
      end
    end
  end
end
