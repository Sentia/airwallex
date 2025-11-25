# frozen_string_literal: true

module Airwallex
  class APIResource
    attr_reader :id, :attributes

    def initialize(attributes = {})
      @attributes = Util.deep_symbolize_keys(attributes || {})
      @id = @attributes[:id]
      @previous_attributes = {}
    end

    # Convert class name to resource name
    # PaymentIntent -> payment_intent
    def self.resource_name
      name.split("::")[-1]
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
    end

    # Override in subclasses to specify custom path
    def self.resource_path
      raise NotImplementedError, "#{self} must implement .resource_path"
    end

    # Dynamic attribute accessors
    def method_missing(method_name, *args, &)
      method_str = method_name.to_s

      if method_str.end_with?("=")
        # Setter
        attr_name = method_str.chop.to_sym
        @previous_attributes[attr_name] = @attributes[attr_name] unless @previous_attributes.key?(attr_name)
        @attributes[attr_name] = args[0]
      elsif @attributes.key?(method_name)
        # Getter
        @attributes[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_str = method_name.to_s
      method_str.end_with?("=") || @attributes.key?(method_name) || super
    end

    # Refresh resource from API
    def refresh
      response = Airwallex.client.get("#{self.class.resource_path}/#{id}")
      refresh_from(response)
      self
    end

    # Update internal state from response
    def refresh_from(data)
      @attributes = Util.deep_symbolize_keys(data || {})
      @id = @attributes[:id]
      @previous_attributes = {}
      self
    end

    # Check if any attributes have changed
    def dirty?
      !@previous_attributes.empty?
    end

    # Get changed attributes
    def changed_attributes
      @previous_attributes.keys
    end

    # Convert to hash
    def to_hash
      @attributes.dup
    end

    alias to_h to_hash

    # Convert to JSON
    def to_json(*args)
      to_hash.to_json(*args)
    end

    # String representation
    def inspect
      id_str = id ? " id=#{id}" : ""
      "#<#{self.class}:0x#{object_id.to_s(16)}#{id_str}> JSON: #{to_json}"
    end

    def to_s
      to_json
    end
  end
end
