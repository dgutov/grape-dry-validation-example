require 'grape'
require 'dry-validation'

module Apples
  class ContractError < Grape::Exceptions::Base
    def initialize(errors:, headers: nil)
      message = errors_array(errors.to_h, false).join(', ')

      super(status: 400, message: message, headers: headers)
    end

    private

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

  module Contractable
    def contract(kontrakt = nil, &block)
      unless kontrakt
        kontrakt = Class.new(Dry::Validation::Contract, &block)
      end

      self.namespace_stackable(:contract, kontrakt)
    end
  end

  module ContractHelper
    def contract_params
      kontrakt = namespace_stackable(:contract).last

      raise "No contract defined" unless kontrakt

      res = kontrakt.new.call(params)

      if res.success?
        res.to_h
      else
        raise ContractError.new(errors: res.errors, headers: header)
      end
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

  ::Grape::API::Instance.extend(Contractable)

  class API < Grape::API
    format :json
    prefix :api

    helpers ContractHelper

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
