# frozen_string_literal: true

module Airwallex
  class ListObject
    include Enumerable

    attr_reader :data, :has_more, :next_cursor

    def initialize(data:, has_more:, resource_class:, next_cursor: nil, params: {})
      @data = data.map { |item| resource_class.new(item) }
      @has_more = has_more
      @next_cursor = next_cursor
      @resource_class = resource_class
      @params = params
    end

    def each(&)
      @data.each(&)
    end

    def [](index)
      @data[index]
    end

    def size
      @data.size
    end

    alias length size
    alias count size

    def empty?
      @data.empty?
    end

    def first
      @data.first
    end

    def last
      @data.last
    end

    # Fetch the next page of results
    def next_page
      return nil unless @has_more

      next_params = @params.dup

      if @next_cursor
        # Cursor-based pagination
        next_params[:next_cursor] = @next_cursor
      else
        # Offset-based pagination
        page_size = @params[:page_size] || @params[:limit] || 20
        current_offset = @params[:offset] || 0
        next_params[:offset] = current_offset + page_size
      end

      @resource_class.list(next_params)
    end

    # Automatically iterate through all pages
    def auto_paging_each(&block)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      loop do
        page.each(&block)
        break unless page.has_more

        page = page.next_page
        break if page.nil? || page.empty?
      end
    end

    def to_a
      @data
    end

    def inspect
      "#<#{self.class}[#{@data.size}] has_more=#{@has_more}>"
    end
  end
end
