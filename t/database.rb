#========== Database Config ==========#
inside 'config/' do
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
