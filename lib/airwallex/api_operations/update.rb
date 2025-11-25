# frozen_string_literal: true

module Airwallex
  module APIOperations
    module Update
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def update(id, params = {}, opts = {})
          response = Airwallex.client.put(
            "#{resource_path}/#{id}",
            params,
            opts[:headers] || {}
          )
          new(response)
        end
      end

      # Instance methods
      def update(params = {})
        response = Airwallex.client.put(
          "#{self.class.resource_path}/#{id}",
          params
        )
        refresh_from(response)
        self
      end

      def save
        return self unless dirty?

        # Only send changed attributes
        params = {}
        changed_attributes.each do |attr|
          params[attr] = @attributes[attr]
        end

        update(params)
      end
    end
  end
end
