require "test_helper"

class HashTest < Minitest::Test
  def test_raises_for_singular_hash_names
    assert_raises(DslFactory::DefinitionError) do
      DslFactory.define_dsl do
        hash :assignment
      end
    end
  end

  def test_simple_hash
    definition = DslFactory.define_dsl do
      hash :assignments
    end
    using_class = Class.new do
      extend definition
      assignment :one, 1
      assignment :two, 2
    end

    assert_equal({ one: 1, two: 2 }, using_class.assignments)
  end

  # hashes only support the singular form in the DSL
  def test_hash_raises_for_value_for_plural
    definition = DslFactory.define_dsl do
      hash :assignments
    end

    assert_raises(DslFactory::DefinitionError) do
      Class.new do
        extend definition
        assignments({})
      end
    end
  end

  def test_typed_hash
    definition = DslFactory.define_dsl do
      hash :assignments, String, Numeric
    end
    Class.new do
      extend definition
      assignment 'asd', 123
    end
  end

  def test_typed_hash_validation
    definition = DslFactory.define_dsl do
      hash :assignments, String, Numeric
    end

    assert_raises(DslFactory::ValidationError) do # key error
      Class.new do
        extend definition
        assignment 123, 123
      end
    end
    assert_raises(DslFactory::ValidationError) do # value error
      Class.new do
        extend definition
        assignment 'asd', 'fgh'
      end
    end
  end

  def test_nested_hash
    definition = DslFactory.define_dsl do
      hash :assignments, Symbol do
        any :child
      end
    end
    using_class = Class.new do
      extend definition
      assignment :tom do
        child 'is here'
      end
    end
    assert_equal('is here', using_class.assignments[:tom].child)
  end

  def test_hash_callbacks
    definition = DslFactory.define_dsl do
      hash :assignments, callback: ->(key, value) { add(key + value) }
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

      assignment 500, 33 # CAUTION: we must make sure to define methods that are used in the callback first!
    end
    assert_equal(533, using_class.sum)
  end
end
