require "test_helper"

class ArrayTest < Minitest::Test
  def test_raises_for_singular_array_names
    assert_raises(DslFactory::DefinitionError) do
      DslFactory.define_dsl do
        array :item
      end
    end
  end

  def test_simple_array
    definition = DslFactory.define_dsl do
      array :items
    end
    using_class = Class.new do
      extend definition
      items [1, 2]
      item 3
    end

    assert_equal([1, 2, 3], using_class.items.sort)
  end

  def test_typed_array
    definition = DslFactory.define_dsl do
      array :items, String
    end
    using_class = Class.new do
      extend definition
      items ['a', 'b']
      item 'c'
    end
    assert_equal(['a', 'b', 'c'], using_class.items.sort)
  end

  def test_typed_array_validation
    definition = DslFactory.define_dsl do
      array :items, Numeric
    end

    assert_raises(DslFactory::ValidationError) do # using the plural form
      Class.new do
        extend definition
        items [1, 2, 'bad']
      end
    end
    assert_raises(DslFactory::ValidationError) do # using the singular form
      Class.new do
        extend definition
        item 'c'
      end
    end
  end

  # note that items with child DSLs can only be added via the singular form (see example below)
  def test_nested_array
    definition = DslFactory.define_dsl do
      array :items do
        any :child
      end
    end
    using_class = Class.new do
      extend definition
      item do
        child 'tom'
      end
    end
    assert_equal('tom', using_class.items.first.child)
  end

  def test_array_callbacks
    definition = DslFactory.define_dsl do
      array :items, callback: ->(arg) { add(arg.sum) } # the argument will always be passed as an array (also for singular form)
    end
    using_class = Class.new do
      extend definition

      def self.add(num)
        @sum ||= 0
        @sum += num
      end

      def self.sum
        @sum
      end

      items [500] # CAUTION: we must make sure to define methods that are used in the callback first!
      item 77
    end
    assert_equal(577, using_class.sum)
  end
end
