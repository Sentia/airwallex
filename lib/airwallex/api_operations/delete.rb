# frozen_string_literal: true

module Airwallex
  module APIOperations
    module Delete
      def delete(id, opts = {})
        response = Airwallex.client.post(
          "#{resource_path}/#{id}/delete",
          {},
          opts[:headers] || {}
        )
        response == true
      end
    end
  end
end
