generate 'model schedule activity:references:index place:references:index start_date:date:index end_date:date description:text'

file 'config/locales/schedule.yml', <<-CODE
en:

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
  has_many :schedules
  has_many :places, through: :schedules

  accepts_nested_attributes_for :schedules, allow_destroy: true, reject_if: ->(attributes) { attributes['place_id'].blank? }
  CODE

  inject_into_class 'schedule.rb', 'Schedule', <<-CODE
  validates :place, presence: true
  validates :activity, presence: true

  belongs_to :place
  belongs_to :activity
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
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: options.fetch(:class, []) << "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
  end

    CODE
  end

end

inside 'app/views/activities/' do

  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+description\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary.mr-2<>= t('activity.description')
\\2    = f.text_area :description,
\\2                  class: 'form-control',
\\2                  placeholder: t('activity.add_description'),
\\2                  'aria-describedby': 'activity-description-help',
\\2                  rows: 3
\\2  %small#activity-description-help.form-text.text-muted<>= t('activity.add_description')
  CODE

  insert_into_file '_form.html.haml', before: /^(\s+?)\.actions$/ do
    <<-CODE
\\1.form-group.row.field
\\1  = f.fields_for :schedules do |builder|
\\1    = render 'schedule_fields', f: builder
\\1  = link_to_add_fields t("activity.schedule.add_schedule"), f, :schedules, class: [:btn, "btn-link", "btn-block"]
    CODE
  end

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('activity.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  file '_schedule_fields.html.haml', <<-CODE
%fieldset.activity_schedule.card
  = f.select :place_id, Place.all.pluck(:name, :id), {include_blank: false, prompt: t('activity.place.where_to_go')}, {class: 'selectize'}
  = f.date_field :start_date, placeholder: t('activity.schedule.arrival_at')
  = f.date_field :end_date, placeholder: t('activity.schedule.departure_at')
  = f.text_field :description, placeholder: t('activity.schedule.description')
  = f.hidden_field :_destroy
  = link_to t("activity.schedule.remove"), '#', class: 'remove_fields'
  CODE

end

inside('app/assets/stylesheets') do

  insert_into_file 'application.css', %^ *= require selectize\n^, after: /^\s\*= require_tree \.\n/
  insert_into_file 'application.css', %^ *= require selectize.default\n^, after: /^\s\*= require selectize\n/

end

inside 'app/assets/javascripts/' do

  insert_into_file 'application.js', after: /\/\/= require rails-ujs\n/ do
    <<-CODE
//= require selectize
    CODE
  end

  append_to_file 'activities.coffee', <<-CODE
//= require jquery-ui/widgets/datepicker

setup_datepicker = (start_date, end_date) ->
  start_date.datepicker({
      dateFormat: 'yy-mm-dd'
      defaultDate: "+1w"
      changeMonth: true
      numberOfMonths: 1
      onSelect: ( selectedDate ) ->
        end_date.datepicker( "option", "minDate", selectedDate );
    })

  end_date.datepicker({
      dateFormat: 'yy-mm-dd'
      defaultDate: "+1w"
      changeMonth: false
      numberOfMonths: 1
      onSelect: ( selectedDate ) ->
        start_date.datepicker( "option", "maxDate", selectedDate );
    })

  true

setup_selectize = (selectize) ->
  selectize.selectize({
      hideSelected: true,
      create: true,
      maxOptions: 100,
      maxItems: 1,
      loadThrottle: 3000
    })

  true

setup_schedules = () ->
  field = $(".activity_schedule")
  place = field.children("select[id$=_place_id]")
  start_date = field.children("input[id$=_start_date]")
  end_date = field.children("input[id$=_end_date]")

  setup_selectize(place)
  setup_datepicker(start_date, end_date)

  true

$(document).on "turbolinks:load", ->

  setup_schedules()

  $('form').on 'click', '.remove_fields', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()

    event.preventDefault()

  $('form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    setup_schedules()
    event.preventDefault()

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

end

inside 'spec/models/' do

  gsub_file 'schedule_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\2  it "should increment the count" do
\\2    expect{ create(:schedule) }.to change{Schedule.count}.by(1)
\\2  end

\\2it "should fail with invalid" do
\\2  expect( build(:invalid_schedule) ).to be_invalid
\\2end

\\2  it "should fail without :activity" do
\\2    expect( build(:schedule, activity: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :place" do
\\2    expect( build(:schedule, place: nil) ).to be_invalid
\\2  end
\\2end
  CODE

end

inside 'spec/controllers' do

end

inside 'spec/views/activities/' do

end
