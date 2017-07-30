generate 'controller import --skip-routes --no-stylesheets --no-helper'

file 'config/locales/import.yml', <<-CODE
en:
  import:
    douban:
      group: Group

zh-CN:
  import:
    douban:
      group: 小组
CODE

route <<-CODE
scope :import do
    get  '/'      => 'import#index',       as: :import
    post 'douban' => 'import#douban',      as: :import_douban_list
    get  'douban' => 'import#douban_post', as: :import_douban_post
  end
CODE

inside 'app/controllers/' do
  inject_into_class 'import_controller.rb', 'ImportController', <<-CODE
  before_action :authenticate_user!

  def index
  end

  def douban
    Nokogiri::HTML(open params[:url]).tap do |page|
      @table = page.css("#group-topics table.olt").to_html
    end
  end

  def douban_post
    Nokogiri::HTML(open params[:url]).tap do |page|
      @activity = Activity.new
      @activity.title = page.at_css("#content>h1").text.strip
      @activity.content = page.css("#content .article .topic-content .topic-doc .from a, #content .article .topic-content .topic-doc h3 span.color-green, #content .article .topic-content .topic-doc .topic-content").to_html
    end
  end
  CODE
end

inside 'app/views/import/' do
  file '_douban_topics_list.html.haml', <<-CODE
.from-douban
  = content.html_safe
  CODE

  file 'douban.html.haml', <<-CODE
= render 'douban_topics_list', content: @table
  CODE

  file 'douban.js.coffee', <<-CODE
$("main #douban #douban-topics :nth-child(1)").replaceWith "<%= escape_javascript(render 'douban_topics_list', content: @table) %>"
$("#douban #import-douban-group-topics").trigger 'douban:import:topics:load'
  CODE

  file 'douban_post.html.haml', <<-CODE
= render 'activities/form', activity: @activity
  CODE

  file 'douban_post.js.coffee', <<-CODE
$("main #douban #douban-topic-form :nth-child(1)").replaceWith "<%= escape_javascript(render 'activities/form', activity: @activity) %>"
  CODE

  file 'index.html.haml', <<-CODE
#douban
  = form_tag :import_douban_list, method: :post, id: 'import-douban-group-topics' do
    = text_field_tag :url, 'https://www.douban.com/group/welikethailand/', activityholder: t('import.douban.group')
    = submit_tag

  #douban-topics
    .replace

  .modal.fade.activity-modal#douban-import-modal{'data-url': import_douban_post_path, "aria-labelledby": "newActivity", role: "dialog", tabindex: "-1"}
    .modal-dialog.modal-lg{role: "document"}
      .modal-content
        .modal-header
          %button.close{"aria-label": "Close", "data-dismiss": "modal", type: "button"}
            %span{"aria-hidden": "true"} ×
          %h4#newActivity.modal-title= t('activity.new_activity')
        .modal-body
          #douban-topic-form{}
            .replace
  CODE
end

inside 'app/assets/javascripts/' do
  append_to_file 'import.coffee', <<-CODE
$(document).on "turbolinks:load", ->

  $("#douban").on 'click', ".title + td a", (e) ->
    e.preventDefault()

  $("#douban").on 'click', "td.title a", (e) ->
    e.preventDefault()

    # 1. query imported? or denied?
    # 2. trigger import:form
    $(this).trigger "douban:import:post"

  $("#douban").on 'douban:import:post', "td.title a", (e) ->
    e.preventDefault()

    $.ajax
      method: "GET"
      url: $("#douban-import-modal").data("url")
      data:
        url: $(this).attr("href")
      dataType: "script"
      complete: ->
        $('main #douban #douban-import-modal').modal()
        $('main #douban #douban-import-modal').trigger "douban:import:post:form"

  $("#douban").on 'douban:import:post:form', "#douban-import-modal", (e) ->
    $('#douban-import-modal #new_activity .ckeditor').ckeditor()

    $('#douban-import-modal #new_activity').submit (e) ->
      e.preventDefault()

      $.ajax
        method: 'POST'
        url: $(this).attr("action")
        data: $(this).serialize()
        dataType: "json"
        success: (response) ->
          $('#douban-import-modal').modal('toggle')
        error: (response) ->
          $(this).trigger("reset")
        complete: ->
          $(this).off( "submit" )

  $("#import-douban-group-topics").on 'douban:import:topics:load', ->
    $.rails.enableFormElements($("#import-douban-group-topics"))

  $("#import-douban-group-topics").submit (e) ->
    e.preventDefault()

    $.ajax
      method: 'POST'
      url: $(this).attr("action")
      data: $(this).serialize()
      dataType: "script"

  true
  CODE
end

inside 'spec/controllers/' do
  insert_into_file 'import_controller_spec.rb', after: /RSpec.describe ImportController, type: :controller do\n/ do
    <<-CODE
  before do
    sign_in create(:user)
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
    CODE
  end

end
