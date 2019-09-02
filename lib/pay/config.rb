require 'dry-validation'

module Pay
  class Config
    Schema = Dry::Validation.Schema do
      required(:user_class).filled(:str?)
      required(:charge_class).filled(:str?)
      required(:subscription_class).filled(:str?)
      required(:subscription_plan_class).filled(:str?)
      optional(:setup_class) { filled? > str? }
    end

    class Error < StandardError; end

    def initialize(config = {})
      schema = Schema.call(config)
      raise Error.new("Config not valid: #{schema.errors}") if schema.errors.present?
      @config = OpenStruct.new(schema.output)
    end

    delegate_missing_to :@config
  end
end
