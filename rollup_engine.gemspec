require_relative "lib/rollup_engine/version"

Gem::Specification.new do |spec|
  spec.name        = "rollup_engine"
  spec.version     = RollupEngine::VERSION
  spec.authors     = [ "tylercschneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/DYB-Development/rollup_engine"
  spec.summary     = "Source-agnostic aggregation engine: measures, rollups, sketches"
  spec.description = "Turn facts into numbers. RollupEngine declares measures, rolls them up by time grain and dimension, and recomputes idempotently. Source-agnostic — feed it any facts (dimensions + measures); it does not depend on any particular event source."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/DYB-Development/rollup_engine/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/DYB-Development/rollup_engine/issues"
  spec.metadata["documentation_uri"] = "https://github.com/DYB-Development/rollup_engine#readme"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,the_local}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  # json 3 dropped the second argument ActiveSupport::JSON.decode passes it, so
  # every read of a json column raises until Rails ships a release that calls
  # the new interface.
  spec.add_dependency "json", "< 3"

  spec.add_dependency "rails", ">= 8.1", "< 9"
end
