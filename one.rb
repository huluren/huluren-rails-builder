#========== Rails Gems ==========#
gem 'rails'

gem 'sprockets-rails'
gem 'bootstrap', '~> 4.0.0.alpha6'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'normalize-rails'
gem 'haml-rails'
gem 'pg'
gem 'puma'
gem 'rails-timeago'
gem 'devise'
gem 'acts_as_followable', github: 'huluren/acts_as_followable'

# i18n
gem 'rails-i18n'
gem 'devise-i18n'
gem 'globalize', github: 'globalize/globalize'
gem 'activemodel-serializers-xml'
gem 'title'

add_source 'https://rails-assets.org' do
  gem 'rails-assets-tether'
end

gem_group :development do
  gem 'listen'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'web-console'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails_best_practices'
end

gem_group :test do
  gem 'rails-controller-testing'

  gem 'database_cleaner'
  gem 'launchy'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'

  #gem 'headless'
  #gem 'capybara-webkit'
  #gem 'formulaic'
end

gem_group :development, :test do
  gem 'sqlite3'

  gem 'awesome_print'
  gem 'bullet'
  gem 'bundler-audit', '>= 0.5.0', require: false
  gem 'dotenv-rails'
  gem 'factory_girl_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails'
end

gem_group :development, :staging do
  gem 'rack-mini-profiler', require: false
end

#========== Git ==========#
append_to_file '.gitignore', '/db/*.sqlite'

#========== Foreman ==========#
file 'Procfile', 'web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}'

file '.env-template', <<-CODE
RACK_ENV=development
PORT=4000
# SECRET_KEY_BASE=$(rails secret)
CODE

#========== Database Config ==========#
inside 'config' do
  run 'mv database.yml database.yml.orig'

  file 'database.yml', <<-CODE
default: &default
  adapter: postgresql
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: duang
  password:
  host: localhost

development:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL") { "sqlite3:%s/%s.sqlite" % [ENV.fetch("DATABASE_DIR", "./db"), Rails.env] } %>

test:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL") { "sqlite3:%s/%s.sqlite" % [ENV.fetch("DATABASE_DIR", "./db"), Rails.env] } %>

production:
  <<: *default
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  url: <%= ENV['DATABASE_URL'] %>
  CODE

end

#========== Spec Setup ==========#
after_bundle do
  generate 'rspec:install'
end

file 'spec/__include_spec.rb', <<-CODE
require 'rails_helper'
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
CODE

file 'spec/support/factory_girl.rb', <<-CODE
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
CODE

# modules setup
after_bundle do
  # Depencencies:
  #   i18n ~> devise-user
  #   devise-user -> commentable
  #   devise-user -> followable
  #   devise-user, commentable, followable -> place
  #   devise-user, commentable, followable, place -> activity
  #   devise-user(login), place, activity, pages-landing(root) -> layout
  modules = %w{
    i18n devise-user commentable
    followable place activity
    pages-landing layout

    theme title
  }

  modules.each do |fn|
    sfp = '%s/t/%s.rb' % [__dir__, fn]
    fp = 'tmp/t/%s.rb' % fn

    get sfp, fp

    rails_command 'app:template LOCATION=%s' % fp
  end
end

after_bundle do
  rails_command 'db:migrate'
  rails_command :spec
end
