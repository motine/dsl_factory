require_relative "dsl_factory/version"
require_relative "dsl_factory/generator"

require 'active_support/inflector'

module DslFactory
  class DefinitionError < StandardError; end
  class ValidationError < StandardError; end

  def define_dsl(&block)
    generator = DslFactory::Generator.new
    generator.instance_eval(&block)
    return generator.definition
  end

  module_function :define_dsl
end
