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
gem 'kaminari'
gem 'ckeditor_rails'
gem 'omniauth-github'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

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
  gem 'brakeman', require: false
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

#========== README ==========#
prepend_to_file 'README.md', <<-CODE
# huluren-rails [![Build Status](https://travis-ci.org/huluren/huluren-rails.svg?branch=master)](https://travis-ci.org/huluren/huluren-rails)
Huluren Community

# Development

See https://github.com/huluren/huluren-rails-builder

CODE

#========== Git ==========#
append_to_file '.gitignore', <<-CODE

*.rbc
capybara-*.html
.rspec
/db/*.sqlite3
/db/*.sqlite3-journal
/public/system
/coverage/
/spec/tmp
*.orig
rerun.txt
pickle-email-*.html

# TODO Comment out this rule if you are OK with secrets being uploaded to the repo
config/initializers/secret_token.rb

# Only include if you have production secrets in this file, which is no longer a Rails default
# config/secrets.yml

# dotenv
# TODO Comment out this rule if environment variables can be committed
#.env
.env.local

## Environment normalization:
/vendor/bundle

# these should all be checked in to normalize the environment:
# Gemfile.lock, .ruby-version, .ruby-gemset

# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:
.rvmrc

# if using bower-rails ignore default bower_components path bower.json files
/vendor/assets/bower_components
*.bowerrc
bower.json

# Ignore pow environment settings
.powenv

/db/*.sqlite
/db/*.sqlite-journal
CODE

inside 'config/' do
  gsub_file 'secrets.yml', /^(\s*secret_key_base: ).*$/, %q^\1<%= ENV['SECRET_KEY_BASE'] %>^
end

inside 'config/initializers/' do

  file '12factor.rb', <<-CODE
Rails.application.configure do
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end
end
  CODE

  file 'better_errors.rb', <<-CODE
BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']
  CODE

  file 'field_with_error.rb', <<-CODE
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  class_attr_index = html_tag.index('class="')
  first_tag_end_index = html_tag.index('>')

  if class_attr_index.nil? || class_attr_index > first_tag_end_index
    html_tag.insert(first_tag_end_index, ' class="error"')
  else
    html_tag.insert(class_attr_index + 7, 'error ')
  end
end
  CODE

  file 'i18n.rb', <<-CODE
Rails.application.configure do
  config.time_zone = 'Asia/Shanghai'

  #I18n.available_locales = [:en, :'zh-CN']
  config.i18n.available_locales = [:en, :'zh-CN']
  config.i18n.default_locale = :'zh-CN'

  config.i18n.fallbacks = [:en, :'zh-CN']
  Globalize.fallbacks = {:en => [:en, :'zh-CN'], :'zh-CN' => [:'zh-CN', :en]}
end
  CODE

  file 'timeago.rb', <<-CODE
Rails::Timeago.default_options limit: -> { 5.days.ago }, date_only: false, format: :short, nojs: false
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
  #   devise-user -> place
  #   devise-user -> omniauth
  #   post -> activity
  #   devise-user, place -> activity
  #   devise-user, place, activity -> followable
  #   devise-user, place, activity -> commentable
  #   place, activity -> schedule
  #   place, activity, commentable -> kaminari
  #   activity -> ckeditor
  #   activity, place, schedule -> import
  #   devise-user(login), place, activity, pages-landing(root) -> layout
  modules = %w{
    heroku travis puma
    database env

    models
    i18n devise-user omniauth
    post
    place activity ckeditor
    schedule
    import
    followable
    commentable
    kaminari
    pages-landing layout
    theme title

    db-seeds
  }

  modules.each do |fn|
    say '%s %s' % ['=' * 10, fn], :cyan

    sfp = '%s/t/%s.rb' % [__dir__, fn]
    fp = 'tmp/t/%s.rb' % fn

    get sfp, fp

    rails_command 'app:template LOCATION=%s' % fp
  end
end

after_bundle do
  rails_command 'db:migrate'
  rails_command :spec, env: 'test'
end
