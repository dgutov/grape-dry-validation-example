require 'grape'
require 'dry-validation'

module GrapeContract
  class ValidationError < Grape::Exceptions::Base
    # @return [Dry::Validation::MessageSet]
    attr_reader :errors

    def initialize(errors:, headers: nil)
      @errors = errors
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
