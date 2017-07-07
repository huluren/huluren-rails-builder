#========== Theme Setup ==========#
default_theme = :materia

#bs_theme = ask('Bootstrap theme name? (Go to https://bootswatch.com/4-alpha/ for available themes.) [default: %s]: ' % default_theme, :cyan)
bs_theme = default_theme # if bs_theme.blank?

inside('app/assets/stylesheets/%s/' % bs_theme) do
  get 'http://bootswatch.com/4-alpha/%s/_variables.scss' % bs_theme, '_variables.scss'
  get 'http://bootswatch.com/4-alpha/%s/_bootswatch.scss' % bs_theme, '_bootswatch.scss'
end

inside('app/assets/stylesheets') do
  run 'mv application.css application.scss'

  insert_into_file 'application.scss', %^ *= require normalize-rails\n^, before: /^\s\*= require_tree \.\n/
  insert_into_file 'application.scss', %^ *= require jquery-ui\n^, before: /^\s\*= require_tree \.\n/

  gsub_file 'application.scss', /^\s*\*= require_tree \.\n/, ''
  gsub_file 'application.scss', /^\s*\*= require_self\n/, ''

  append_to_file 'application.scss', <<-CODE
@import '#{bs_theme}/variables';
@import 'bootstrap';
@import '#{bs_theme}/bootswatch';

body {
  margin: 85px auto 0 auto;
}
CODE
end

inside('app/assets/javascripts') do
  insert_into_file 'application.js', before: '//= require rails-ujs' do
    <<-CODE
//= require jquery
//= require jquery_ujs
//= require tether
//= require bootstrap-sprockets
//= require rails-timeago
//= require locales/jquery.timeago.zh-CN.js
    CODE
  end

  file 'navbar_hide.coffee', <<-CODE
$(document).ready ->
  $(window).scroll ->
    if $(this).scrollTop() > 100
      $('#navbar').fadeOut 500
    else
      $('#navbar').fadeIn 500
  CODE
end
