# frozen_string_literal: true

require_relative "lib/dsl_factory/version"

Gem::Specification.new do |spec|
  spec.name          = "dsl_factory"
  spec.version       = DslFactory::VERSION
  spec.authors       = ["Tom Rothe"]
  spec.email         = ["info@tomrothe.de"]

  spec.summary       = "A small DSL to generate DSLs"
  spec.description   = "Define DSLs quickly and avoid the boilerplate write getters and setters. Oh, and it does validation too."
  spec.homepage      = "https://github.com/motine/dsl_factory"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = 'https://github.com/motine/dsl_factory/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
