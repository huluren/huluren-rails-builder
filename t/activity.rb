generate 'scaffold activity user:references:index description:text'

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :activities
  CODE

  inject_into_class 'activity.rb', 'Activity', <<-CODE
  validates :user, presence: true
  validates :description, presence: true

  scope :random, ->(limit=1) { order("RANDOM()").limit(limit) }

  acts_as_followable

  has_many :comments, as: :commentable
  CODE

end

inside 'app/controllers/' do

  gsub_file 'activities_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @activity.user = current_user
\\3
  CODE

end

inside 'app/views/activities/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'

  gsub_file '_form.html.haml', /(= f.text_field :)(user)$/, '\1\2_id'
  gsub_file '_form.html.haml', /@activity/, 'activity'

  gsub_file 'new.html.haml', /= render 'form'$/, '\0, activity: @activity'

  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, activity: @activity'
end

inside 'spec/factories/' do
  gsub_file 'activities.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'activities.rb', /(^\s*?)(description) .*?$/, %q^\1sequence(:\2) {|n| 'activity_\2_%d' % n }^

  insert_into_file 'activities.rb', before: /^(\s\s)end$/ do
    <<-CODE
\\1  factory :invalid_activity do
\\1    user nil
\\1    description nil
\\1  end
\\1  factory :bare_activity do
\\1    user nil
\\1    description nil
\\1  end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'activity_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\2  it "should increment the count" do
\\2    expect{ create(:activity) }.to change{Activity.count}.by(1)
\\2  end

\\2it "should fail with invalid" do
\\2  expect( build(:invalid_activity) ).to be_invalid
\\2end

\\2  it "should fail without :description" do
\\2    expect( build(:activity, description: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:activity, user: nil) ).to be_invalid
\\2  end
\\2end

\\2describe "followable" do
\\2  it "can be followed by user" do
\\2    follower = create(:user)
\\2    followable = create(:activity)
\\2    expect{ follower.follow(followable) }.to change{Follow.count}.by(1)
\\2    expect( follower.follow?(followable) ).to be true
\\2  end
\\2end
  CODE

end

inside 'spec/controllers' do
  gsub_file 'activities_controller_spec.rb', /(\n\s*?let\(:valid_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:activity).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'activities_controller_spec.rb', /(\n\s*?let\(:invalid_attributes\) \{\n\s*?)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:invalid_activity).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'activities_controller_spec.rb', /(\n\s*?let\(:new_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:activity).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'activities_controller_spec.rb', /(updates the requested activity.*?)skip\(.*?\)\n/m, <<-CODE
\\1expect(activity.attributes.fetch_values(*new_attributes.keys)).to be == new_attributes.values
  CODE

end

inside 'spec/views/activities/' do
  gsub_file 'index.html.haml_spec.rb', /(\s*?)assign\(:activities,.*?\]\)(\n)/m, <<-CODE
\\1@activities = assign(:activities, create_list(:activity, 2))
  CODE

  gsub_file 'index.html.haml_spec.rb', /(renders a list of activities.*?)\n\s+render(\s*assert_select.*?\n)+/m, <<-CODE
\\1
    expect(@activities.size).to be(2)
    render
    @activities.each do |activity|
      assert_select "tr>td", :text => activity.description.to_s, :count => 1
    end
  CODE

  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*?))(.*?)Activity.new\(.*?\)\)\n/m, <<-CODE
\\1\\3build(:activity))
  CODE

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Activity.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:activity))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Activity.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:activity))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(it.*renders attributes in .*\n(\s*?)?)(expect.*?\n)+?(\s+end)\n/m, <<-CODE
\\1expect(rendered).to match(/\#{@activity.description}/)
\\4
  CODE
end

gsub_file 'spec/helpers/activities_helper_spec.rb', /^\s.pending .*\n/, ''
