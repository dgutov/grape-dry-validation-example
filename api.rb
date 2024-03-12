require 'grape'
require 'dry-validation'

module Apples
  ContractError = Class.new(StandardError)

  class ApiContract < Dry::Validation::Contract
    def validate!(value)
      res = call(value)

      if res.success?
        yield res.to_h
      else
        message = errors_array(res.errors.to_h, false).join(', ')
        raise ContractError.new(message)
      end
    end

    def errors_array(hsh, decorate = true)
      res = []

      hsh.each do |key, value|
        key = if decorate
                "[#{key}]"
              else
                key.to_s
              end

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

  ColorString = Dry::Types['string'].constrained(included_in: %w(green red yellow))

  BasketSchema = Dry::Schema.Params do
    required(:color).filled(ColorString)
    required(:count).filled(:integer)
  end

  OrderSchema = Dry::Schema.Params do
    required(:baskets).array(BasketSchema)
  end

  class CreateOrderContract < ApiContract
    params do
      required(:order).filled(OrderSchema)
    end
  end

  class Order
    class << self
      attr_accessor :orders
    end

    def self.create!(params)
      self.orders ||= []

      raise "Unexpected!" unless CreateOrderContract.new.call(params).success?

      self.orders << params

      params
    end
  end

  class API < Grape::API
    format :json
    prefix :api

    rescue_from ContractError do |e|
      error!({error: e.message}, 400)
    end

    resource :orders do
      desc 'Create new'
      post do
        CreateOrderContract.new.validate!(params) do |attrs|
          order = Order.create!(attrs)
          body order
        end
      end
    end
  end
end
