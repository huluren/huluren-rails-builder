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
  def douban_groups
    douban_user_url = 'https://www.douban.com/group/people/164902948/joins'
    Nokogiri::HTML(open douban_user_url).tap do |page|
      @douban_user_groups = page.css(".group-list .title a").remove_class.remove_attr("title").map {|nn| [nn["href"], nn.text.strip]}
    end
  end

  def douban_topics
    Nokogiri::HTML(open params[:url]).tap do |page|
      @table = page.css("#group-topics table.olt").to_html
    end
  end

  def douban_topic
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

  append_to_file 'index.html.haml', <<-CODE
= render 'douban'
  CODE

  file '_douban.html.haml', <<-CODE
#douban{'data-groups-url': douban_groups_path, 'data-topics-url': douban_topics_path, 'data-topic-url': douban_topic_path}
  .douban-groups.btn-group-sm.mx-auto{role: "group", "data-toggle": "buttons"}
    &hellip;
  .douban-topics
    &hellip;
  / .douban-topic
  = render 'douban_topic'
  CODE

  file 'douban_groups.html.haml', <<-CODE
= render 'douban_groups', groups: @douban_user_groups
  CODE

  file 'douban_groups.js.coffee', <<-CODE
$("main #douban .douban-groups").html "<%= escape_javascript(render 'douban_groups', groups: @douban_user_groups) %>"
  CODE

  file '_douban_groups.html.haml', <<-CODE
- groups.each do |group|
  = link_to :douban_topics, remote: true, data: {method: :get, type: :script, params: "url=\#{group[0]}", "disable-with": "Loading ..."}, class: 'btn btn-outline-info' do
    = group[1]
    = radio_button_tag :url, group[0]
  CODE

  file 'douban_topics.html.haml', <<-CODE
= render 'douban_topics', content: @table
  CODE

  file '_douban_topics.html.haml', <<-CODE
= content.html_safe
  CODE

  file 'douban_topics.js.coffee', <<-CODE
$("main #douban .douban-topics").html "<%= escape_javascript(render 'douban_topics', content: @table) %>"
  CODE

  file 'douban_topic.html.haml', <<-CODE
= render 'activities/form', activity: @activity
  CODE

  file 'douban_topic.js.coffee', <<-CODE
$("main #douban .douban-topic-form").html "<%= escape_javascript(render 'activities/form', activity: @activity) %>"
  CODE

  file '_douban_topic.html.haml', <<-CODE
.modal.fade.activity-modal.douban-topic{"aria-labelledby": "newActivity", role: "dialog", tabindex: "-1"}
  .modal-dialog.modal-lg{role: "document"}
    .modal-content
      .modal-header
        %button.close{"aria-label": "Close", "data-dismiss": "modal", type: "button"}
          %span{"aria-hidden": "true"} ×
        %h4#newActivity.modal-title= t('activity.new_activity')
      .modal-body
        .douban-topic-set.btn-group.btn-group-sm.mx-auto{role: "group", "data-toggle": "buttons"}
          - [:inbox, :deny, :accept].each do |set|
            = link_to :present, remote: true, data: {method: :post, type: :json, params: "set=\#{set}&key=", "disable-with": "Loading ..."}, class: "btn btn-outline-info set set-\#{set}" do
              = set
              = radio_button_tag :set, set
        .douban-topic-form
          &hellip;
  CODE

end

inside 'app/assets/javascripts/' do
  append_to_file 'import.coffee', <<-CODE
@update_topic_link = (e, callback) ->

  e.addClass "btn"
  e.attr "data-url", e.attr("href")
  e.attr "href", $("#douban").data("topic-url")

  e.attr "data-remote", "true"
  e.attr "data-method", "GET"
  e.attr "data-type", "script"
  e.attr "data-params", "url=" + e.data("url")

  if callback != undefined
    callback()

@check_present = (e, callback) ->

  $.ajax
    url: $('#import').data('present-url')
    method: $('#import').data('present-method')
    data:
      key: e.data("url")
    dataType: "json"
    success: (data, textStatus, jqXHR) ->
      e.attr "class", 'set set-' + data["set"]

      if callback != undefined
        callback(data, textStatus, jqXHR)

$(document).on "turbolinks:load", ->

  # Fetch Groups
  $('main #douban').on 'douban:groups:load', '.douban-groups', ->
    # trigger load action
    $.ajax
      url: $('main #douban').data('groups-url')
      method: 'GET'
      dataType: 'script'

  # group button clicked and topics returned.
  $("main #douban").on "ajax:success", ".douban-groups[role=group] a[data-remote]", (event) ->
    [response, status, xhr] = event.detail
    $("#douban .douban-topics td.title a:not([data-remote])").each ->
      update_topic_link $(this), =>
        check_present $(this), (data, textStatus, jqXHR) =>
          true

  # douban topic author: disable click event
  $("main #douban").on 'click', ".douban-topics td.title + td a:not([data-remote])", (e) ->
    e.preventDefault()

  # load topic into modal form
  $("main #douban").on "ajax:success", ".douban-topics td.title a[data-remote]", (event) ->
    # $("#douban .douban-topic").find(".ckeditor:not(:has(+ .cke))").ckeditor()
    # $("#douban .douban-topic").find(".activity-add-place").trigger("setup").autocomplete("option", "appendTo", ".douban-topic.modal")
    $("#douban .douban-topic").data "url", $(this).data("url")
    $("#douban .douban-topic.modal").modal()

  $("main #douban .douban-topic.modal").on "ajax:success", "form.new_activity, form.edit_activity", (event) ->
    $(".douban-topic.modal").modal("toggle")
    $(".douban-topic-set a.set-accept[data-remote]").click()
  $("main #douban .douban-topic.modal").on "ajax:error", "form.new_activity, form.edit_activity", (event) ->
    [response, status, xhr] = event.detail
    $(this).trigger("reset")
    return ! confirm "Error, cannot save: " + status
  $("main #douban .douban-topic.modal").on "ajax:complete", "form.new_activity, form.edit_activity", (event) ->
    $.rails.enableFormElements($(this))
    $(this).off( "submit" )

  $("main #douban .douban-topic-set").on "ajax:beforeSend", "a.set[data-remote]", (event) ->
    [xhr, options] = event.detail
    options.data += $("#douban .douban-topic").data("url")
    true

  $("main #douban .douban-topic-set").on "ajax:success", "a.set[data-remote]", (event) ->
    [response, status, xhr] = event.detail
    check_present $(".douban-topics td.title a[data-remote][data-url='" + response.key + "']")

  # trigger No. 1
  $("main #douban .douban-groups").trigger 'douban:groups:load'

  true
  CODE
end
