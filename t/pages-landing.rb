#========== Landing ==========#
generate :controller, :pages, :landing, '--no-helper-specs'
route %q{root to: 'pages#landing'}

inside('app/views/pages/') do
  remove_file 'landing.html.haml'

  file 'landing.html.haml', <<-CODE
.row<>
  .activities-col.col-md.col-md-8.card.border-0
    .nav.nav-tabs.justify-content-between
      %h5.nav-item.nav-link= t('menu.activities')
      .nav-item.nav-link= link_to t('action.more'), activities_path, class: 'btn btn-link'
    .activities.list-group{data: {remote: 'true', url: activities_path, params: 'c=6&s=true', trigger: 'activities:load', method: :get, type: :script}}
  .places-col.col.card.border-0
    .nav.nav-tabs.justify-content-between
      %h5.nav-item.nav-link= t('menu.places')
      .nav-item.nav-link= link_to t('action.more'), places_path, class: 'btn btn-link'
    .places.list-group{data: {remote: 'true', url: places_path, params: 'c=6&s=true', trigger: 'places:load', method: :get, type: :script}}
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

inside 'app/assets/javascripts/' do

  append_to_file 'pages.coffee', <<-CODE
$(document).on "turbolinks:load", ->

  $("main.c-pages.a-landing").find(".activities, .places").each (idx) ->

    $.ajax
      method: $(this).data("method")
      url: $(this).data("url")
      data: $(this).data("params")
      dataType: $(this).data("type")
      context: $(this)
      success: ->
        $(this).trigger $(this).data("trigger")

  true
  CODE

end

inside('spec/views/pages/') do
  gsub_file 'landing.html.haml_spec.rb', /^\s.pending .*\n/, <<-CODE
  it 'renders landing' do
    render
    assert_select '.activities'
    assert_select '.places'
  end
  CODE
end
