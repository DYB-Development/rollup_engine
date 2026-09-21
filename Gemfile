source "https://rubygems.org"

# Specify your gem's dependencies in rollup_engine.gemspec.
gemspec

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "the_local", github: "tylercschneider/the_local"

group :development, :test do
  gem "puma"
  gem "sqlite3"
  gem "propshaft"
  gem "pry"
  gem "minitest", "~> 5.0"
end
