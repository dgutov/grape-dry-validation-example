require './grape_contract'

module Apples
  ColorString = Dry::Types['string'].constrained(included_in: %w(green red yellow))

  BasketSchema = Dry::Schema.Params do
    required(:color).filled(ColorString)
    required(:count).filled(:integer)
  end

  OrderSchema = Dry::Schema.Params do
    required(:baskets).array(BasketSchema)
  end

  class Order
    class << self
      attr_accessor :orders
    end

    def self.create!(params)
      self.orders ||= []
      self.orders << params

      params
    end
  end

  class API < Grape::API
    format :json
    prefix :api

    resource :orders do
      desc 'Create new'
      contract do
        params do
          required(:order).filled(OrderSchema)
        end

        rule(:order) do
          next if value[:baskets].count < 10

          key.failure('contains too many baskets')
        end
      end
      post do
        order = Order.create!(contract_params)
        body order
      end
    end
  end
end
