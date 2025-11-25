# frozen_string_literal: true

module Airwallex
  module APIOperations
    module Delete
      def delete(id, opts = {})
        Airwallex.client.delete(
          "#{resource_path}/#{id}",
          {},
          opts[:headers] || {}
        )
        true
      end
    end
  end
end
