# DSL Factory

A small DSL to generate DSLs.  
Define DSLs quickly and avoid the [boilerplate to write getters and setters](https://gist.github.com/motine/28da503ba0075e9d64d3f3b1faab9014). Oh, and it does validation too.

## Example

```ruby
# add this to your Gemfile: gem 'dsl_factory'

# define the DSL
LakeDsl = DslFactory.define_dsl do
  string :lake_name
  numeric :max_depth
  array :fishes, String
end

# use it in any class
class LakeSuperior
  extend LakeDsl

  lake_name 'Lake Superior'
  max_depth 406
  fish 'trout'
  fish 'northern pike'
end

# and you can access the values
LakeSuperior.lake_name # => "Lake Superior"
LakeSuperior.fishes # => ["trout", "northern pike"]
```

This gem came about during my time at [Netskin GmbH](https://www.netskin.com). Check it out, we do great (Rails) work there.

# Usage

## Definition

**Basic Types**

```ruby
# the following data types are available
# if a value is given which does not fit the type a `DslFactory::ValidationError` is raised
LakeDsl = DslFactory.define_dsl do
  string :lake_name
  symbol :group
  numeric :max_depth
  boolean :protected_habitat
  callable :current_temperature_handler
  any :continent # does not validate the given contents later
end

# now we can use the definition
class LakeSuperior
  extend LakeDsl

  lake_name 'Lake Superior'
  group :great_lakes
  max_depth 406
  protected_habitat true
  current_temperature_handler ->() { self.temperature = FetchService.receive_temperature } # the proc is only saved, DslFactory will not call it
  continent Continent::NorthAmerica
end
```

**Arrays**

```ruby
BookDsl = DslFactory.define_dsl do
  array :authors            # we must use the plural!
  array :publishers, String # validates that the item is of the given (Ruby) class
  # see below for nested DSLs
end

class SuperBook
  extend BookDsl
  authors ['Manfred', 'Dieter'] # we can use the plural form to set the whole array
  author 'Heinz'                # or the singular form to add an item

  publisher 'abc'
end

SuperBook.authors # => ['Manfred', 'Dieter', 'Heinz']
SuperBook.publishers # => ['abc']
```

**Hashes**

```ruby
GeographyDsl = DslFactory.define_dsl do
  hash :capital_for_countries         # we must use the plural!
  hash :country_sizes, String, Numeric # validate key and value (key must be of String class, value of Symbol) 
  # see below for nested DSLs
end

class World
  extend GeographyDsl
  capital_for_country 'Berlin', 'Germany' # here we use the signular
  capital_for_country 'Copenhagen', 'Denmark'

  country_size 'Germany', 357_022
end

World.capital_for_countries # => { 'Berlin' => 'Germany', 'Copenhagen' => 'Denmark'}
World.country_sizes # => { 'Germany' => 357022 }
```

**Nested DSLs**
```ruby
PersonDsl = DslFactory.define_dsl do
  array :parents do
    string :name
    numeric :age
  end

  hash :citizenships, String do # validate key as String
    symbol :status
    any :expiry
  end
end

class Sabine
  extend PersonDsl
  # note that nested DSLs can only be used via the singular form

  parent do
    name 'Karla'
    age 88
  end

  citizenship 'Germany' do
    status :revoked
    expiry Time.new(2000)
  end
end

Sabine.parents.first.name # => 'Karla'
Sabine.citizenships['Germany'].status # => :revoked
```

**Callbacks**

Sometimes we might want to do something when the DSL method is called.
This can be achived via callbacks.

```ruby
ButtonDsl = DslFactory.define_dsl do
  # all types outlined above support callbacks
  any :trigger, callback: ->(value) { puts "#{value} was triggered" }
  any :snicker, callback: ->(value) { arg1, arg2 = value; puts "snicker: #{arg1} & #{arg2}" } # we can pass arguments via the value
  any :clicker, callback: ->(value) { self.do_the_click } # see method definition in using class
  numeric :width, callback: ->(value) { raise DslFactory::ValidationError, 'buttons must be small' if width > 100 }

  # for arrays the callback always receives an array (even if it was used in singular form)
  # for hashes the callback receives two arguments: key, value
end

class MonsterButton
  extend ButtonDsl
  # if we want to call a method of the class, we need to define it before the first usage of the DSL method
  def self.do_the_click
    puts 'Click!'
  end

  trigger 'abc'            # -> abc was triggered
  snicker ['haha', 'hihi'] # -> snicker: haha & hihi
  clicker nil              # make sure to alway pass a value; -> Click!
  width 2000               # -> DslFactory::ValidationError: buttons must be small
end

MonsterButton.trigger # values are still set; => 'abc'
```

**Inspection**

For debugging it is useful to introspect the DSL values.
When `inspectable` is set to `true` (`DslFactory.define_dsl(inspectable: true)`) the module will provide an `inspect` method.
All sub-DSL modules provide an such a method by default.

## Use of the definition

Usually we **extend a class** like so:

```ruby
class LakeSuperior
  extend LakeDsl
  lake_name 'Lake Superior'
end

LakeSuperior.lake_name # => 'Lake Superior'
```

However we can also use the **DSL in a variable**:

```ruby
@config = Module.new.extend(LakeDsl)
@config.lake_name 'Müritz'
@config.lake_name # => 'Müritz'

# or with the configuration pattern
@config = Module.new.extend(LakeDsl).tap do |c|
  c.lake_name 'Summter See'
end
@config.lake_name # => 'Summter See'

# or even without any prefix
@config = Module.new.extend(LakeDsl)
@config.instance_exec do
  lake_name 'Mühlenbecker See'
end
@config.lake_name # => 'Mühlenbecker See'

```

# Development

```bash
docker run --rm -ti -v (pwd):/app -w /app ruby:2.7 bash
bundle install
rake test # run the tests
pry # require_relative 'lib/dsl_factory.rb'

# to release a new version, update `CHANGELOG.md` and the version number in `version.rb`, then run
bundle exec rake release
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Alternatives

_Download counts are from 01.03.2022._

- [dslh](https://github.com/kumogata/dslh) (178.000 downloads)
  Allows to define a Hash as a DSL.
- [dsl_maker](https://rubygems.org/gems/dsl_maker) (80.700 downloads)
    allows defining DSLs with structs.
- [genki-dsl_accessor](https://rubygems.org/gems/genki-dsl_accessor) (5.600 downloads)
    allows defining hybrid accessors for class.
- [configuration_dsl](https://rubygems.org/gems/configuration_dsl) (4.100 downloads)
    nice way to define configuration DSLs. quite outdated.
- [blockenspiel](https://github.com/dazuma/blockenspiel) (2.869.000 downloads)
    allows to nicely define configuration blocks. does not facilitate assigning variables.
- [dsl_accessors](https://rubygems.org/gems/dsl_accessors) (3.700 downloads)
    provides helpers to facilitate variable setting via DSL. exactly what we need, but unfortunately quite outdated.
- [open_dsl](https://rubygems.org/gems/open_dsl) (17.000 downloads)
    dynamically defines OpenStructs to collect data for DSLs. really nice idea and quite close to what we need. unfortunately a little outdated.
- [alki-dsl](https://rubygems.org/gems/alki-dsl) (12.900 downloads)
    allows to define DSL methods nicely. does not assist in variable getting/setting.

**Honerable Mentions**

- [cleanroom](https://rubygems.org/gems/cleanroom) (5.560.000 downloads)
    allows to safely define DSLs. does not really facilitate the data assignments.
- [dsl_block](https://rubygems.org/gems/dsl_block) 4.900 downloads)
    allows you to use classes to define blocks with commands. does not really facilitate setting/getting variables.
- [declarative](https://rubygems.org/gems/declarative) (110.990.000 downloads)
    define declarative schemas.
- [dslkit](https://rubygems.org/gems/dslkit) (54.500 downloads)
    allows defining DSL to be read from files (maybe). documentation hard to find. outdated.
- [dsltasks](https://rubygems.org/gems/dsltasks) (4.100 downloads)
    allows to define hierarchical DSLs. does not facilitate variable assignments.
- [opendsl](https://rubygems.org/gems/opendsl) (8.800 downloads)
    allows to simply define DSLs. does not help assigning variables. outdated.

**Not Applicable**

- [dsl](https://rubygems.org/gems/dsl) defines delegators. i am not sure when this is useful.
- [dsl_eval](https://rubygems.org/gems/dsl_eval) only defines an alias for instance_eval.
- [instant_dsl](https://rubygems.org/gems/instant_dsl) could not find repo/docs. quite outdated.
- [dsl_companion](https://rubygems.org/gems/dsl_companion) no documentation.
- [def_dsl](https://rubygems.org/gems/def_dsl) no documentation.
- [dslr](https://rubygems.org/gems/dslr) no documentation.
