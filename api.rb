require 'grape'
require 'dry-validation'

module Apples
  ColorString = Dry::Types['string'].constrained(included_in: %w(green red yellow))

  module GrapeCoercible
    def parse(value)
      res = call(value)

      if res.success?
        return res.to_h
      else
        message = errors_array(res.errors.to_h).join(', ')
        Grape::Types::InvalidValue.new(message)
      end
    end

    def parsed?(value)
      call(value).success?
    end

    def errors_array(hsh)
      res = []

      hsh.each do |key, value|
        key = "[#{key}]"

        case value
        when String
          res << [key, value]
        when Array
          value.each do |s|
            res << [key, s]
          end
        else # Should be Hash.
          errors_array(value).each do |subkey, s|
            res << [key + subkey.to_s, s]
          end
        end
      end

      res.map! { |arr| arr.compact.join(' ') }
    end
  end

  def self.build_schema(&block)
    klass = Dry::Schema.Params(&block)
    klass.extend(GrapeCoercible)
  end

  BasketSchema = Dry::Schema.Params do
    required(:color).filled(ColorString)
    required(:count).filled(:integer)
  end

  OrderSchema = build_schema do
    required(:baskets).array(BasketSchema)
  end

  class Order
    class << self
      attr_accessor :orders
    end

    def self.create!(params)
      self.orders ||= []

      raise "Unexpected!" unless OrderSchema.call(params).success?

      self.orders << params

      params
    end
  end

  class API < Grape::API
    format :json
    prefix :api

    resource :orders do
      desc 'Create new'
      params do
        requires :order, type: OrderSchema
      end
      post do
        order = Order.create!(declared(params)[:order])
        body order
      end
    end
  end
end
