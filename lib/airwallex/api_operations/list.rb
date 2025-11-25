# frozen_string_literal: true

module Airwallex
  module APIOperations
    module List
      def list(params = {}, opts = {})
        response = Airwallex.client.get(
          resource_path,
          params,
          opts[:headers] || {}
        )

        ListObject.new(
          data: response[:items] || response["items"] || [],
          has_more: response[:has_more] || response["has_more"] || false,
          next_cursor: response[:next_cursor] || response["next_cursor"],
          resource_class: self,
          params: params
        )
      end
    end
  end
end
