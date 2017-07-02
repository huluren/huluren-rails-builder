generate 'scaffold schedule activity:references:index place:references:index start_date:date:index end_date:date description:text'

inside 'app/models/' do

  inject_into_class 'activity.rb', 'Activity', <<-CODE
  has_many :schedules
  has_many :places, through: :schedules

  accepts_nested_attributes_for :schedules, allow_destroy: true
  CODE

  inject_into_class 'schedule.rb', 'Schedule', <<-CODE
  validates :place, presence: true
  validates :activity, presence: true

  belongs_to :place
  belongs_to :activity
  CODE

end

inside 'app/controllers/' do
end

inside 'app/views/schedules/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'

  gsub_file '_form.html.haml', /(= f.text_field :)(activity|place)$/, '\1\2_id'
  gsub_file '_form.html.haml', /@schedule/, 'schedule'

  gsub_file 'new.html.haml', /= render 'form'$/, '\0, schedule: @schedule'

  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, schedule: @schedule'
end

inside 'spec/factories/' do

  gsub_file 'schedules.rb', /(^\s*?)(activity|place) nil$/, '\1\2'
  gsub_file 'schedules.rb', /(^\s*?)(description) .*?$/, %q^\1sequence(:\2) {|n| 'schedule_\2_%d' % n }^
  gsub_file 'schedules.rb', /(^\s*?)(start_date) nil$/, '\1sequence(:\2) {|n| n.days.from_now }'
  gsub_file 'schedules.rb', /(^\s*?)(end_date) nil$/, '\1sequence(:\2) {|n| 3.days.since n.days.from_now }'

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

  gsub_file 'schedules_controller_spec.rb', /(\n\s*?let\(:valid_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:schedule).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'schedules_controller_spec.rb', /(\n\s*?let\(:invalid_attributes\) \{\n\s*?)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:invalid_schedule).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'schedules_controller_spec.rb', /(\n\s*?let\(:new_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:schedule).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'schedules_controller_spec.rb', /(updates the requested schedule.*?)skip\(.*?\)\n/m, <<-CODE
\\1expect(schedule.attributes.fetch_values(*new_attributes.keys)).to be == new_attributes.values
  CODE

end

inside 'spec/views/schedules/' do

  gsub_file 'index.html.haml_spec.rb', /(\s*?)assign\(:schedules,.*?\]\)(\n)/m, <<-CODE
\\1@schedules = assign(:schedules, create_list(:schedule, 2))
  CODE

  gsub_file 'index.html.haml_spec.rb', /(renders a list of schedules.*?)\n\s+render(\s*assert_select.*?\n)+/m, <<-CODE
\\1
    expect(@schedules.size).to be(2)
    render
    @schedules.each do |schedule|
      assert_select "tr>td", :text => schedule.description.to_s, :count => 1
    end
  CODE

  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*?))(.*?)Schedule.new\(.*?\)\)\n/m, <<-CODE
\\1\\3build(:schedule))
  CODE

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Schedule.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:schedule))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Schedule.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:schedule))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(it.*renders attributes in .*\n(\s*?)?)(expect.*?\n)+?(\s+end)\n/m, <<-CODE
\\1expect(rendered).to match(/\#{@schedule.description}/)
\\4
  CODE

end

gsub_file 'spec/helpers/schedules_helper_spec.rb', /^\s.pending .*\n/, ''
