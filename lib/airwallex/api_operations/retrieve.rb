# frozen_string_literal: true

module Airwallex
  module APIOperations
    module Retrieve
      def retrieve(id, opts = {})
        response = Airwallex.client.get(
          "#{resource_path}/#{id}",
          {},
          opts[:headers] || {}
        )
        new(response)
      end
    end
  end
end
