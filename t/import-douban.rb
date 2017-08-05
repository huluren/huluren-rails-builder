file 'config/locales/import-douban.yml', <<-CODE
en:
  import:
    douban:
      group: Group

zh-CN:
  import:
    douban:
      group: 小组
CODE

inside 'app/controllers/' do
  inject_into_class 'import_controller.rb', 'ImportController', <<-CODE
  def douban
    Nokogiri::HTML(open params[:url]).tap do |page|
      @table = page.css("#group-topics table.olt").to_html
    end
  end

  def douban_post
    Nokogiri::HTML(open params[:url]).tap do |page|
      @activity = Activity.new
      @activity.uuid = params[:url]
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
$("#douban #import-douban-group-topics").trigger 'douban:import:topics:loaded'
  CODE

  file 'douban_post.html.haml', <<-CODE
= render 'activities/form', activity: @activity
  CODE

  file 'douban_post.js.coffee', <<-CODE
$("main #douban #douban-topic-form :nth-child(1)").replaceWith "<%= escape_javascript(render 'activities/form', activity: @activity) %>"
  CODE

  append_to_file 'index.html.haml', <<-CODE
#import{'data-present-url': present_path, 'data-present-method': 'POST'}
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
          #douban-topic-set{}
            .btn-group
              - [:inbox, :deny, :accept].each do |set|
                %a.btn.btn-secondary{'data-set': set}= set
            %label
          #douban-topic-form{}
            .replace
  CODE
end

inside 'app/assets/javascripts/' do
  append_to_file 'import.coffee', <<-CODE
$(document).on "turbolinks:load", ->

  $("#douban").on 'click', ".title + td a", (e) ->
    e.preventDefault()

  $("#douban").on 'import:present', ".title + td a, td.title a", (e) ->

    $.ajax
      method: $('#import').data('present-method')
      url: $('#import').data('present-url')
      data:
        key: $(this).attr("href")
      dataType: "json"
      success: (response) =>
        $(this).attr 'class', 'set set-' + response["set"]

  $("#douban").on 'click', "td.title a", (e) ->
    e.preventDefault()

    # 1. query imported? or denied?
    # 2. trigger import:form
    $(this).trigger "douban:import:post"

  $('#douban-import-modal #douban-topic-set a[data-set]').on "click", (e) ->
    e.preventDefault()

    $.ajax
      method: $('#import').data('present-method')
      url: $('#import').data('present-url')
      data:
        key: $("#douban-topic-set").data("url")
        set: $(this).data("set")
      dataType: "json"
      success: (response) =>
        $(this).siblings().removeClass("active")
        $(this).addClass 'active set set-' + response["set"]
        $(this).parent().next("label").text response["set"]
        $(this).parent().next("label").attr 'class', 'set set-' + response["set"]
        $("a[href='" + $("#douban-topic-set").data("url") + "']").trigger "import:present"

  $("#douban").on 'douban:import:post', "td.title a", (e) ->
    e.preventDefault()

    $("#douban-topic-set").data "url", $(this).attr("href")

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

      $('#douban-import-modal #douban-topic-set a[data-set=accept]').trigger "click"

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

  $("#import-douban-group-topics").on 'douban:import:topics:loaded', ->
    $.rails.enableFormElements($("#import-douban-group-topics"))
    $("#douban .title + td a, #douban td.title a").trigger("import:present")

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
