generate 'model schedule activity:references:index place:references:index start_date:date:index end_date:date:index description:text'

file 'config/locales/schedule.yml', <<-CODE
en:
  schedule:
    arrival_at: Arrival Date
    departure_at: Departure Date
    description: Description
    add_schedule: Add schedule
    remove: Remove

zh-CN:
  schedule:
    arrival_at: 到达日期
    departure_at: 离开日期
    description: 备注
    add_schedule: 添加地点
    remove: 移除
CODE

inside 'app/models/' do

  inject_into_class 'activity.rb', 'Activity', <<-CODE
  has_many :schedules, dependent: :destroy
  has_many :places, -> { distinct }, through: :schedules

  accepts_nested_attributes_for :schedules, allow_destroy: true, reject_if: ->(attributes) { attributes['place_id'].blank? }

  def start_date
    schedules.pluck(:start_date).compact.sort.first
  end

  def end_date
    schedules.pluck(:end_date).compact.sort.last
  end
  CODE

  inject_into_class 'place.rb', 'Place', <<-CODE
  has_many :schedules, dependent: :destroy
  has_many :activities, -> { distinct }, through: :schedules
  CODE

  inject_into_class 'schedule.rb', 'Schedule', <<-CODE
  validates :activity, presence: true
  validates :place, presence: true
  CODE

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :schedules, through: :activities
  has_many :destinations, -> { distinct }, through: :schedules, source: :place
  CODE

end

inside 'app/controllers/' do

  gsub_file 'activities_controller.rb', /(\n(\s*?)def new\n.*?\n)(\2end)\n/m, <<-CODE
\\1\\2  @activity.schedules.new
\\3
  CODE

  gsub_file 'activities_controller.rb', /(def activity_params\n(\s+?)params[^\n]+)(\))\n/m, <<-CODE
\\1, schedules_attributes: {}\\3
  CODE

end

inside 'app/helpers/' do

  insert_into_file 'application_helper.rb', after: %/module ApplicationHelper\n/ do
    <<-CODE

  def link_to_add_fields(name, f, association, options={})
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.pluralize + "/fields", f: builder)
    end
    link_to(name, '#', class: options.fetch(:class, []) << "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
  end

    CODE
  end

end

inside 'app/views/activities/' do

  insert_into_file '_form.html.haml', before: /^(\s+?)[^\s]+?\.actions$/ do
    <<-CODE
\\1.form-group.row.field
\\1  = f.fields_for :schedules do |builder|
\\1    = render 'schedules/fields', f: builder
\\1  = link_to_add_fields t("activity.schedule.add_schedule"), f, :schedules, class: [:btn, "btn-link", "btn-block"]
    CODE
  end

  append_to_file '_form.html.haml', <<-CODE

.modal.fade.place-modal#modalNewPlace{"aria-labelledby": "newPlace", role: "dialog", tabindex: "-1"}
  .modal-dialog.modal-sm{role: "document"}
    .modal-content
      .modal-header
        %button.close{"aria-label": "Close", "data-dismiss": "modal", type: "button"}
          %span{"aria-hidden": "true"} ×
        %h4#newPlace.modal-title= t("place.add_place")
      .modal-body
        = form_for Place.new do |f|
          = f.hidden_field :user_id, value: current_user.id
          .form-group
            = f.label :title
            = f.text_field :title, class: "form-control"
          .form-group
            = f.label :content
            = f.text_area :content, class: "form-control"
          .form-group
            = f.submit class: "btn btn-primary"
  CODE

end

inside 'app/views/schedules/' do

  file '_fields.html.haml', <<-CODE
%fieldset.activity_schedule.card
  = f.label :place_id, f.object.place.try(:title), class: ["btn", "btn-secondary"]
  = f.hidden_field :place_id
  = f.fields_for :place do |fp|
    = fp.text_field :title, {name: nil, class: 'place_title', placeholder: t('place.search')}
  = f.label :start_date, t('schedule.arrival_at')
  = f.date_field :start_date
  = f.label :end_date, t('schedule.departure_at')
  = f.date_field :end_date
  = f.text_field :description, placeholder: t('schedule.description')
  = f.hidden_field :_destroy
  = link_to t("schedule.remove"), '#', class: 'remove_fields'
  CODE

end

inside('app/assets/stylesheets') do

end

inside 'app/assets/javascripts/' do

  file 'schedules.coffee', <<-CODE
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/widgets/autocomplete

setup_datepicker = (start_date, end_date) ->
  start_date.datepicker
    dateFormat: 'yy-mm-dd'
    defaultDate: "+1w"
    changeMonth: true
    numberOfMonths: 1
    onSelect: (selectedDate) ->
      end_date.datepicker "option", "minDate", selectedDate
  end_date.datepicker
    dateFormat: 'yy-mm-dd'
    defaultDate: "+1w"
    changeMonth: false
    numberOfMonths: 1
    onSelect: (selectedDate) ->
      start_date.datepicker "option", "maxDate", selectedDate
  true

setup_place_field = (place, place_id, place_label) ->
  selected_place = (src) ->
    place_id.val(src.id)
    place_label.text(src.title)
    place_label.attr("title", src.id)

  place.autocomplete
    minLength: 1
    select: ( event, ui ) ->
      if ui.item.id == 0
        create_place place.val(), (new_place) ->
          selected_place new_place
      selected_place ui.item
    close: ( event, ui ) ->
      $(this).val(null)
    source: (request, response) ->
      $.ajax
        method: "GET"
        url: '/places'
        data: {q: request.term}
        dataType: "json"
        success: (res) ->
          data = ({label: item.title, title: item.title, id: item.id} for item in res)
          data.unshift(label: 'Add ' + request.term + '...', id: 0) unless request.term in (item.title for item in res)
          response( data )
        error: (res) ->
          false

create_place = (title, callback) ->
  $('#place_title').val(title)
  $('#modalNewPlace').modal()

  $('#new_place').submit (e) ->
    e.preventDefault()
    $.ajax
      method: 'POST'
      url: $(this).attr("action")
      data: $(this).serialize()
      dataType: "json"
      success: (response) ->
        $('#new_place').off( "submit" )
        $('#modalNewPlace').modal('toggle')
        callback(response)
      error: (response) ->
        $('#new_place').off( "submit" )
        $("#new_place").trigger("reset")
  true

setup_schedules = () ->
  fields = $(".activity_schedule")
  fields.each (idx) ->
    setup_schedule $(this)

setup_schedule = (schedule_fs) ->
  setup_place_field(schedule_fs.children("input[id$=_place_title]"), schedule_fs.children('input[id$=_place_id]'), schedule_fs.children('label[for$=_place_id]'))
  setup_datepicker(schedule_fs.children("input[id$=_start_date]"), schedule_fs.children("input[id$=_end_date]"))

$(document).on "turbolinks:load", ->
  setup_schedules()

  $("#modalNewPlace").on "hide.bs.modal", (e) ->
    $("#new_place").trigger("reset")
    $.rails.enableFormElements($("#new_place"))

  $('form').on 'click', '.remove_fields', (event) ->
    event.preventDefault()
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()
    true

  $('form').on 'click', '.add_fields', (event) ->
    event.preventDefault()
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    setup_schedule($(this).prev('fieldset'))
    true

  true
  CODE

end

inside 'spec/factories/' do

  gsub_file 'schedules.rb', /(^\s*?)(activity|place) nil$/, '\1\2'
  gsub_file 'schedules.rb', /(^\s*?)(description) .*?$/, %q^\1sequence(:\2) {|n| 'schedule_\2_%d' % n }^
  gsub_file 'schedules.rb', /(^\s*?)(start_date) .+$/, '\1sequence(:\2) {|n| n.days.from_now }'
  gsub_file 'schedules.rb', /(^\s*?)(end_date) .+$/, '\1sequence(:\2) {|n| 3.days.since n.days.from_now }'

  insert_into_file 'schedules.rb', before: /^(\s\s)end$/ do
    <<-CODE

\\1  factory :invalid_schedule do
\\1    activity nil
\\1    place nil
\\1    start_date nil
\\1    end_date nil
\\1    description nil
\\1  end

\\1  factory :bare_schedule do
\\1    activity nil
\\1    place nil
\\1    start_date nil
\\1    end_date nil
\\1    description nil
\\1  end

    CODE
  end

  insert_into_file 'activities.rb', before: /^(\s+?)factory :invalid_activity do$/ do
    <<-CODE
\\1factory :activity_with_schedules do
\\1  transient do
\\1    schedules_count 3
\\1  end

\\1  after(:create) do |activity, evaluator|
\\1    create_list(:schedule, evaluator.schedules_count, activity: activity)
\\1  end
\\1end
    CODE
  end

end

inside 'spec/models/' do

  gsub_file 'schedule_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do

\\2  it "should increment the count" do
\\2    expect{ create(:schedule) }.to change{Schedule.count}.by(1)
\\2  end

\\2  it "should fail with invalid" do
\\2    expect( build(:invalid_schedule) ).to be_invalid
\\2  end

\\2  it "should fail without :activity" do
\\2    expect( build(:schedule, activity: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :place" do
\\2    expect( build(:schedule, place: nil) ).to be_invalid
\\2  end

\\2end

\\2describe "#destroy" do

\\2  it "should decrease the count" do
\\2    schedule = create(:schedule)
\\2    expect{ schedule.destroy }.to change{Schedule.count}.by(-1)
\\2  end

\\2  it "should decrease the count when destroy activity" do
\\2    activity = create(:activity_with_schedules, schedules_count: 5)
\\2    expect{ activity.destroy }.to change{Schedule.count}.by(-5)
\\2  end

\\2end
  CODE

  insert_into_file 'activity_spec.rb', before: /^(\n+?(\s+?))it .should fail with invalid. do$/ do
    <<-CODE
\\1it "should increment the count with schedules" do
\\2  expect{ create(:activity_with_schedules) }.to change{Activity.count}.by(1)
\\2  expect{ create(:activity_with_schedules, schedules_count: 5) }.to change{Schedule.count}.by(5)
\\2end
    CODE
  end

end

inside 'spec/controllers' do

end

inside 'spec/views/activities/' do

end
