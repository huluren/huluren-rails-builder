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
  .douban-groups
    &hellip;
  .douban-topics
    .from-douban
      &hellip;
  / .douban-topic
  = render 'douban_topic'
  CODE

  file 'douban_groups.html.haml', <<-CODE
= render 'douban_groups', groups: @douban_user_groups
  CODE

  file 'douban_groups.js.coffee', <<-CODE
$("main #douban .douban-groups").replaceWith "<%= escape_javascript(render 'douban_groups', groups: @douban_user_groups) %>"
$("main #douban .douban-groups").trigger 'douban:groups:loaded'
  CODE

  file '_douban_groups.html.haml', <<-CODE
= form_tag :douban_topics, method: 'GET', class: 'douban-groups' do
  .groups-sel.btn-group-wrap.btn-group-sm.mx-auto{role: "group", "data-toggle": "buttons"}
    - groups.each do |group|
      %label.btn.btn-outline-info
        = radio_button_tag :url, group[0]
        = group[1]
  = submit_tag
  CODE

  file 'douban_topics.html.haml', <<-CODE
= render 'douban_topics', content: @table
  CODE

  file '_douban_topics.html.haml', <<-CODE
.from-douban
  = content.html_safe
  CODE

  file 'douban_topics.js.coffee', <<-CODE
$("main #douban .douban-topics :nth-child(1)").replaceWith "<%= escape_javascript(render 'douban_topics', content: @table) %>"
$("main #douban .douban-topics").trigger 'douban:topics:loaded'
  CODE

  file 'douban_topic.html.haml', <<-CODE
= render 'activities/form', activity: @activity
  CODE

  file 'douban_topic.js.coffee', <<-CODE
$("main #douban .douban-topic-form :nth-child(1)").replaceWith "<%= escape_javascript(render 'activities/form', activity: @activity) %>"
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
        = form_tag :present, method: 'POST', class: 'douban-topic-set', role: "group", "data-toggle": "buttons" do
          = hidden_field_tag :key
          .btn-group-d
            - [:inbox, :deny, :accept].each do |set|
              %label.btn.btn-outline-info
                = radio_button_tag :set, set, class: "set set-\#{set}"
                = set
        .douban-topic-form
          .replace
            &hellip;
  CODE

end

inside 'app/assets/javascripts/' do
  append_to_file 'import.coffee', <<-CODE
$(document).on "turbolinks:load", ->

  # Fetch Groups
  $('main #douban').on 'douban:groups:load', '.douban-groups', ->
    # trigger load action
    $.ajax
      url: $('main #douban').data('groups-url')
      method: 'GET'
      dataType: 'script'

  # Fetch Groups finished
  $('main #douban').on 'douban:groups:loaded', '.douban-groups', ->

    # setup once
    $('main #douban .douban-groups').on "change", 'label input[name=url]', ->
      $(this).parents("form").submit()

    $('main #douban form.douban-groups').submit (e) ->
      e.preventDefault()

      $.ajax
        url: $(this).attr("action")
        method: $(this).attr("method")
        data: $(this).serialize()
        dataType: "script"
        complete: (jqXHR, textStatus) ->
          $.rails.enableFormElements($("main #douban .douban-groups"))
          $("#douban .douban-topics .title + td a, #douban .douban-topics .title a").trigger("check:present")

  # Check present
  $("#douban .douban-topics").on "check:present", "td.title + td a, td.title a", ->

    $.ajax
      url: $('#import').data('present-url')
      method: $('#import').data('present-method')
      data:
        key: $(this).attr("href")
      dataType: "json"
      success: (data, textStatus, jqXHR) =>
        $(this).attr 'class', 'set set-' + data["set"]

  # disable click event
  $("#douban .douban-topics").on 'click', "td.title + td a", (e) ->
    e.preventDefault()

  # trigger click
  $("#douban").on 'click', "td.title a", (e) ->
    e.preventDefault()

    $("#douban .douban-topic").data "url", $(this).attr("href")
    $("#douban .douban-topic").trigger "check:present"
    $("#douban .douban-topic").trigger "douban:topic:load"

  # modal btn-group fetch check:present status
  $("#douban .douban-topic").on "check:present", ->

    $.ajax
      url: $('#import').data('present-url')
      method: $('#import').data('present-method')
      data:
        key: $(this).data("url")
      dataType: "json"
      success: (data, textStatus, jqXHR) =>
        $(this).find("label:has(input[name=set])").removeClass "active"
        $(this).find("label:has(input[name=set][value=" + data["set"] + "])").addClass "active"

  # modal btn-group topic set changed
  $("#douban .douban-topic").on "douban:topic:set:changed", "form.douban-topic-set", ->

    $(this).submit (e) ->
      e.preventDefault()

      $(this).find('input[name=key]').val $("#douban .douban-topic").data("url")

      $.ajax
        url: $(this).attr("action")
        method: $(this).attr("method")
        data: $(this).serialize()
        dataType: "json"
        success: (data, textStatus, jqXHR) ->
          $("a[href='" + data["key"] + "']").trigger "check:present"

    $(this).submit()

  # topic set changed
  $("#douban .douban-topic").on "change", 'label input[name=set]', ->
    $(this).parents("form").trigger "douban:topic:set:changed"

  # Fetch topic form
  $("#douban .douban-topic").on "douban:topic:load", ->

    $.ajax
      method: "GET"
      url: $("#douban").data("topic-url")
      data:
        url: $(this).data("url")
      dataType: "script"
      complete: (jqXHR, textStatus) =>
        $(this).trigger "douban:topic:loaded"

  # Fetch topic form finished
  $('main #douban').on 'douban:topic:loaded', '.douban-topic.modal', ->
    $(this).modal()

    $(this).find('.ckeditor').ckeditor()

    $(this).find('.douban-topic-form > form').submit (e) ->
      e.preventDefault()

      $.ajax
        method: 'POST'
        url: $(this).attr("action")
        data: $(this).serialize()
        dataType: "json"
        success: (data, textStatus, jqXHR) ->
          $("label:has(input[name=set][value=accept])").click()
          $(".douban-topic.modal").modal("toggle")
        error: (jqXHR, textStatus, errorThrown) =>
          $(this).trigger("reset")
          return ! confirm "Error, cannot save " + jqXHR.responseText
        complete: (jqXHR, textStatus) =>
          $.rails.enableFormElements($(this))
          $(this).off( "submit" )

  # trigger No. 1
  $("main #douban .douban-groups").trigger 'douban:groups:load'

  true
  CODE
end
