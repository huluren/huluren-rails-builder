#========== Landing ==========#
generate :controller, :pages, :landing, '--no-helper-specs'
route %q{root to: 'pages#landing'}

inside('app/views/pages/') do
  remove_file 'landing.html.haml'

  file 'landing.html.haml', <<-CODE
.row.d-flex.justify-content-center<>
  .activities.col-md.card.border-0
    .nav.nav-tabs.justify-content-between
      %h5.nav-item.nav-link= t('menu.activities')
      .nav-item.nav-link= link_to t('action.more'), activities_path, class: 'btn btn-link'
    #activities{'data-url': activities_path}
  .places.col-md.col-lg-4.card.border-0
    .nav.nav-tabs.justify-content-between
      %h5.nav-item.nav-link= t('menu.places')
      .nav-item.nav-link= link_to t('action.more'), places_path, class: 'btn btn-link'
    #places{'data-url': places_path}
/
  .row.d-flex.justify-content-center<>
    .articles.col-md.card.border-0
      .nav.nav-tabs.justify-content-between
        %h5.nav-item.nav-link= t('articles')
        .nav-item.nav-link= link_to '-', nil
    .app.col-md-2.card.border-0
      .nav.nav-tabs.justify-content-between
        %h5.nav-item.nav-link= t('app')
        .nav-item.nav-link= link_to '-', nil
  CODE
end

inside('app/views/activities/') do
  file 'index.js.coffee', <<-CODE
$("#activities").replaceWith "<%= escape_javascript(render 'activities', items: @activities) %>"
  CODE
end

inside('app/views/places/') do
  file 'index.js.coffee', <<-CODE
$("#places").replaceWith "<%= escape_javascript(render 'places_list', items: @places) %>"
  CODE
end

inside 'app/assets/javascripts/' do

  append_to_file 'pages.coffee', <<-CODE
$(document).on "turbolinks:load", ->
  $("main.pages.landing #activities").html("Loading activities...")
  $("main.pages.landing #places").html("Loading places...")

  $.ajax
    method: "GET"
    url: $("main.pages.landing #activities").data("url")
    data:
      c: 6
      s: true
    dataType: "script"

  $.ajax
    method: "GET"
    url: $("main.pages.landing #places").data("url")
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
