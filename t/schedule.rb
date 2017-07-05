generate 'model schedule activity:references:index place:references:index start_date:date:index end_date:date description:text'

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

  def link_to_add_fields(name, f, association)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
  end

    CODE
  end

end

inside 'app/views/activities/' do

  insert_into_file '_form.html.haml', before: /^(\s+?)\.actions$/ do
    <<-CODE
\\1.field
\\1  = f.fields_for :schedules do |builder|
\\1    = render 'schedule_fields', f: builder
\\1  = link_to_add_fields :add_schedule, f, :schedules
    CODE
  end

  file '_schedule_fields.html.haml', <<-CODE
%fieldset
  = f.label :place
  = f.select :place_id, Place.all.pluck(:name, :id), {include_blank: false, prompt: 'Select City'}, {class: 'selectize'}
  = f.label :start_date
  = f.date_field :start_date
  = f.label :end_date
  = f.date_field :end_date
  = f.label :description
  = f.text_field :description
  CODE

end

inside('app/assets/stylesheets') do

  insert_into_file 'application.scss', %^ *= require selectize\n^, after: /^\s\*= require jquery-ui\n/
  insert_into_file 'application.scss', %^ *= require selectize.default\n^, after: /^\s\*= require selectize\n/

end

inside 'app/assets/javascripts/' do

  insert_into_file 'application.js', before: '//= require rails-ujs' do
    <<-CODE
//= require selectize
    CODE
  end

  append_to_file 'activities.coffee', <<-CODE
$(document).on "turbolinks:load", ->
  $(".selectize").selectize()

  $('form').on 'click', '.remove_fields', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()
    event.preventDefault()

  $('form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
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
