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

  gsub_file 'activities_controller.rb', /(def activity_params\n(\s+?)params[^\n]+)(\))\n/m, <<-CODE
\\1, schedules_attributes: {}\\3
  CODE

end

inside 'app/helpers/' do

  insert_into_file 'application_helper.rb', after: %/module ApplicationHelper\n/ do
    <<-CODE

  def text_input_to_add_fields(name, f, association, options={})
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.pluralize + "/fields", f: builder)
    end
    text_field_tag(name, nil, options.merge( name: nil, class: options.fetch(:class, []) << 'add_fields', 'data-id': id, 'data-fields': fields.gsub("
", "") ))
  end

    CODE
  end

end

inside 'app/views/activities/' do

  insert_into_file '_form.html.haml', before: /^(\s+?)[^\s]+?\.actions$/ do
    <<-CODE
\\1.form-group.row.field
\\1  .input-group
\\1    = f.fields_for :schedules do |builder|
\\1      = render 'schedules/fields', f: builder
\\1    = text_input_to_add_fields :activity_schedule_place, f, :schedules, class: ['form-control', 'activity-add-place'], placeholder: t('place.search')
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
        = form_for Place.new, remote: true do |f|
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
  = f.hidden_field :_destroy
  = link_to "&times;".html_safe, '#', title: t("schedule.remove"), class: ['remove_fields', 'activity-remove-place']
  CODE

end

inside('app/assets/stylesheets') do

end

inside 'app/assets/javascripts/' do

  file 'schedules.coffee', <<-CODE
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/widgets/autocomplete

# create place
@create_place = (title, callback) ->
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

$(document).on "turbolinks:load", ->

  $("main").on "hide.bs.modal", "#modalNewPlace", (e) ->
    $("#new_place").trigger("reset")
    $.rails.enableFormElements($("#new_place"))

  $('main').on 'click', '.activity-remove-place', (event) ->
    event.preventDefault()
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()

  $("main").on 'add:fields', '.activity-add-place', ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before $(this).data('fields').replace(regexp, time)
    $(this).prev('fieldset').find('label').text $(this).data("place_title")
    $(this).prev('fieldset').find('label').attr "title", $(this).data("place_id")
    $(this).prev('fieldset').find('input[name$=\[place_id\]]').val $(this).data("place_id")

  $("main").on "setup", "form.new_activity, form.edit_activity", ->
    $(this).find('.ckeditor').ckeditor()
    $(this).find(".activity-add-place").trigger("setup")

  $('main').on 'setup', '.activity-add-place', ->
    $(this).autocomplete
      minLength: 1
      select: ( event, ui ) ->
        if ui.item.id == 0
          $('#place_title').val(ui.item.title)
          $('#modalNewPlace').modal()

          create_place ui.item.title, (new_place) =>
            $(this).data "place_id", new_place.id
            $(this).data "place_title", new_place.title
            $(this).trigger "add:fields"
        else
          $(this).data "place_id", ui.item.id
          $(this).data "place_title", ui.item.title
          $(this).trigger "add:fields"
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
            data.unshift(label: 'Add ' + request.term + '...', title: request.term, id: 0) unless request.term in (item.title for item in res)
            response( data )
          error: (res) ->
            false

  $("main.activities").find("form.new_activity, form.edit_activity").trigger "setup"

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
