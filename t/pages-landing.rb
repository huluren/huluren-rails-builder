#========== Landing ==========#
generate :controller, :pages, :landing, '--no-helper-specs'
route %q{root to: 'pages#landing'}

inside('app/views/pages/') do
  remove_file 'landing.html.haml'

  file 'landing.html.haml', <<-CODE
.row.d-flex.justify-content-center<>
  .articles.col-lg-3
    %h5= t('articles')
  .col-lg-9.row.d-flex.flex-row-reverse
    .app.col-md-2
      %h5= t('app')
    .activities.col-md
      %h5= t('menu.activities')
      #activities
    .places.col-md
      %h5= t('menu.places')
      #places
  CODE
end

inside('app/views/activities/') do
  file 'index.js.coffee', <<-CODE
$("#activities").replaceWith "<%= escape_javascript(render 'activities', items: @activities) %>"
  CODE

  file '_activities.html.haml', <<-CODE
#activities.list-group
  - items.each do |activity|
    .list-group-item.list-group-item-action= activity.places.pluck(:name).to_sentence
  CODE
end

inside('app/views/places/') do
  file 'index.js.coffee', <<-CODE
$("#places").replaceWith "<%= escape_javascript(render 'places', items: @places) %>"
  CODE

  file '_places.html.haml', <<-CODE
#places.list-group
  - items.each do |place|
    .list-group-item.list-group-item-action= place.name
  CODE
end

inside 'app/assets/javascripts/' do

  append_to_file 'pages.coffee', <<-CODE
$(document).on "turbolinks:load", ->
  $("#activities").html("Loading activities...")
  $("#places").html("Loading places...")

  $.ajax
    method: "GET"
    url: '/places'
    data:
      c: 6
      s: true
    dataType: "script"

  $.ajax
    method: "GET"
    url: '/activities'
    data:
      c: 6
      s: true
    dataType: "script"

  true
  CODE

end

inside('spec/views/pages/') do
  gsub_file 'landing.html.haml_spec.rb', /^\s.pending .*\n/, <<-CODE
  it 'renders landing' do
    render
    assert_select '#activities'
    assert_select '#places'
  end
  CODE
end
