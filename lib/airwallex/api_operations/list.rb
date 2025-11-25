# frozen_string_literal: true

module Airwallex
  module APIOperations
    module List
      def list(params = {}, opts = {})
        response = Airwallex.client.get(resource_path, params, opts[:headers] || {})
        build_list_object(response, params)
      end

      private

      def build_list_object(response, params)
        ListObject.new(
          data: extract_data(response),
          has_more: extract_has_more(response),
          next_cursor: extract_next_cursor(response),
          resource_class: self,
          params: params
        )
      end

      def extract_data(response)
        return response if response.is_a?(Array)

        response[:items] || response["items"] || response[:data] || response["data"] || []
      end

      def extract_has_more(response)
        return false unless response.is_a?(Hash)

        response[:has_more] || response["has_more"] || false
      end

      def extract_next_cursor(response)
        return nil unless response.is_a?(Hash)

        response[:next_cursor] || response["next_cursor"]
      end
    end
  end
end
