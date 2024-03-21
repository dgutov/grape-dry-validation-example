require 'grape'
require 'dry-validation'

module GrapeContract
  class ValidationError < Grape::Exceptions::Base
    # @return [Dry::Validation::MessageSet]
    attr_reader :errors

    def initialize(errors:, headers: nil)
      @errors = errors

      message = errors.messages.map do |message|
        full_name = message.path.first.to_s

        full_name += "[#{message.path[1..].join('][')}]" if message.path.size > 1

        "#{full_name} #{message.text}"
      end.join(', ')

      super(status: 400, message: message, headers: headers)
    end
  end

  module EndpointDSL
    def contract(kontrakt = nil, &block)
      unless kontrakt
        kontrakt = Class.new(Dry::Validation::Contract, &block)
      end

      self.namespace_stackable(:contract, kontrakt)
    end
  end

  module InsideRouteHelper
    def contract_params
      kontrakt = namespace_stackable(:contract).last

      raise "No contract defined" unless kontrakt

      res = kontrakt.new.call(params)

      if res.success?
        res.to_h
      else
        raise ValidationError.new(errors: res.errors, headers: header)
      end
    end
  end

  ::Grape::API::Instance.extend(EndpointDSL)
  ::Grape::DSL::InsideRoute.include(InsideRouteHelper)
end
