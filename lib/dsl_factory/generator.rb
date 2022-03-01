class DslFactory::Generator
  attr_reader :definition

  def initialize
    @definition = Module.new do
      def get_dsl_value(name)
        @dsl_values ||= {}
        @dsl_values[name]
      end

      def set_dsl_value(name, value, &block)
        @dsl_values ||= {}
        @dsl_values[name] = value
      end
    end
  end

  # for more information & examples, please see README.md
  #
  # if a `callback` is given it will be called when the extended class uses this attribute (after setting the value).
  # the callback block will be called with the value as first parameter (if you need multiple parameter pass a list).
  # for examples, please see `README.md``.
  #
  # if a validation is given the block will be called with the value as first parameter.
  # if the block returns false a `DslFactory::ValidationError` will be raised.
  def any(name, callback: nil, validation: nil)
    @definition.define_method(name) do |value = :not_given, &block|
      return get_dsl_value(name) if value == :not_given
      raise DslFactory::ValidationError, "#{name} is not valid" if validation && !validation.call(value)
      set_dsl_value(name, value)
      self.instance_exec(value, &callback) if callback
    end
  end

  # for more information & examples, please see README.md
  def string(name, **kwargs)
    any(name, validation: ->(value) { value.is_a?(String) }, **kwargs)
  end

  # for more information & examples, please see README.md
  def symbol(name, **kwargs)
    any(name, validation: ->(value) { value.is_a?(Symbol) }, **kwargs)
  end

  # for more information & examples, please see README.md
  def numeric(name, **kwargs)
    any(name, validation: ->(value) { value.is_a?(Numeric) }, **kwargs)
  end

  # for more information & examples, please see README.md
  def boolean(name, **kwargs)
    any(name, validation: ->(value) { value.is_a?(TrueClass) || value.is_a?(FalseClass) }, **kwargs)
  end

  # for more information & examples, please see README.md
  def callable(name, **kwargs)
    any(name, validation: ->(value) { value.respond_to?(:call) }, **kwargs)
  end

  # for more information & examples, please see README.md
  def array(plural_name, item_class=nil, callback: nil, &definition_block)
    singular_name = build_singular_name!(plural_name)
    raise DslFactory::DefinitionError, "#{plural_name} item_class can not given at the same time as a block" if item_class && definition_block

    any(plural_name, callback: callback, validation: ->(value) { value.is_a?(Array) && (item_class.nil? || value.all? { |item| item.is_a?(item_class) }) })

    @definition.define_method(singular_name) do |value = :not_given, &block|
      old_value = get_dsl_value(plural_name)
      return old_value if value == :not_given && !block

      if block # we deal with a sub-DSL
        value_object = Class.new
        value_object.extend(DslFactory.define_dsl(&definition_block))
        value_object.instance_eval(&block)
        value = value_object
      end
      raise DslFactory::ValidationError, "#{singular_name} is not valid" if item_class && !value.is_a?(item_class)
      new_value = old_value || []
      new_value << value
      set_dsl_value(plural_name, new_value)
      self.instance_exec([value], &callback) if callback # wrap the item in a list
    end
  end

  # for more information & examples, please see README.md
  def hash(plural_name, key_class=nil, value_class=nil, callback: nil, &definition_block)
    singular_name = build_singular_name!(plural_name)
    raise DslFactory::DefinitionError, "#{plural_name} value_class can not given at the same time as a block" if value_class && definition_block

    @definition.define_method(plural_name) do |value = nil|
      raise DslFactory::DefinitionError, "hashes do not support setting values with the plural form, please use #{singular_name} to define items" if value
      get_dsl_value(plural_name)
    end

    @definition.define_method(singular_name) do |key, value = nil, &block|
      raise DslFactory::ValidationError, "value can not be given at the same time as a block for a hash" if value && block

      if block # we deal with a sub-DSL
        value_object = Class.new
        value_object.extend(DslFactory.define_dsl(&definition_block))
        value_object.instance_eval(&block)
        value = value_object
      end
      raise DslFactory::ValidationError, "#{singular_name}'s key is not a #{key_class}" if key_class && !key.is_a?(key_class)
      raise DslFactory::ValidationError, "#{singular_name}'s value is not a #{value_class}" if value_class && !value.is_a?(value_class)
      new_value = get_dsl_value(plural_name) || {}
      new_value[key] = value
      set_dsl_value(plural_name, new_value)
      self.instance_exec(key, value, &callback) if callback
    end
  end

  protected

  def build_singular_name!(plural_name)
    singular_name = ActiveSupport::Inflector.singularize(plural_name).to_sym
    raise DslFactory::DefinitionError, "can not singularize #{plural_name}, please make sure to provide the plural form and that ActiveSupport::Inflector can singularize" if singular_name == plural_name
    singular_name
  end
end
