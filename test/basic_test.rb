require "test_helper"

class BasicTest < Minitest::Test
  SomeDefinition = DslFactory.define_dsl do
    any :some_any
    string :some_string
    symbol :some_symbol
    numeric :some_numeric
    boolean :some_boolean
    callable :some_callable
  end

  def test_access_to_simple_value_from_class
    using_class = Class.new do
      extend SomeDefinition
      some_string 'thevalue'
      some_numeric 123
    end
    assert_equal('thevalue', using_class.some_string)
    assert_equal(123, using_class.some_numeric)
  end

  def test_validation
    assert_raises(DslFactory::ValidationError) do
      Class.new do
        extend SomeDefinition
        some_string 123
      end
    end
  end

  def test_callbacks
    definition = DslFactory.define_dsl do
      any :with_callback, callback: ->(args) { op1, op2 = args; save_sum(op1, op2) }
    end
    using_class = Class.new do
      extend definition

      def self.save_sum(op1, op2)
        @sum = op1 + op2
      end

      def self.sum
        @sum
      end

      with_callback [1, 2] # CAUTION: we must make sure to define methods that are used in the callback first!
    end
    assert_equal(3, using_class.sum)
  end

  ListDefinition = DslFactory.define_dsl(inspectable: true) do
    array :items do
      string :label
    end
  end

  def test_inspection
    using_class = Class.new do
      extend ListDefinition
      item { label 'eins' }
      item { label 'zwei' }
    end

    assert_includes(using_class.inspect, 'items')
    assert_includes(using_class.inspect, 'eins')
    assert_includes(using_class.items.inspect, 'eins')
    assert_includes(using_class.items.inspect, 'zwei')
    assert_includes(using_class.items.first.inspect, 'eins')
  end
end
