generate 'scaffold place user:references:index name:string:uniq description:text'

file 'config/locales/place.yml', <<-CODE
en:
  place:
    choose:
      from: From city...
      to: To city...
    search: Search...

zh-CN:
  place:
    where_to_go: 目的地...
    choose:
      from: 来源城市...
      to: 返回城市...
    search: 搜索...
CODE

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :places
  CODE

  inject_into_class 'place.rb', 'Place', <<-CODE
  validates :user, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :q, ->(query_string) { query_string.nil? ? nil : where("name LIKE ?", "%\#{query_string}%") }

  acts_as_followable

  has_many :comments, as: :commentable
  CODE

end

inside 'app/controllers/' do
  inject_into_class 'places_controller.rb', PlacesController, <<-CODE
  before_action :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def index\n[^\n]*?Place\.)all\n/m, <<-CODE
\\1q(params[:q])
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @place.user = current_user
\\3
  CODE

end

inside 'app/views/places/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'

  gsub_file '_form.html.haml', /@place/, 'place'

  gsub_file '_form.html.haml', /(= f.text_field :)(user)$/, '= f.hidden_field :\2_id, value: current_user.id'
  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+name\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary.mr-2<>= t('place.name')
\\2    = f.text_field :name,
\\2                  class: 'form-control',
\\2                  placeholder: t('place.add_name'),
\\2                  'aria-describedby': 'place-name-help',
\\2                  rows: 3
\\2  %small#place-name-help.form-text.text-muted<>= t('place.add_name')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+description\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary.mr-2<>= t('place.description')
\\2    = f.text_area :description,
\\2                  class: 'form-control',
\\2                  placeholder: t('place.add_description'),
\\2                  'aria-describedby': 'place-description-help',
\\2                  rows: 3
\\2  %small#place-description-help.form-text.text-muted<>= t('place.add_description')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('place.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  gsub_file 'new.html.haml', /= render 'form'$/, '\0, place: @place'

  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, place: @place'
end

inside 'spec/factories/' do
  gsub_file 'places.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'places.rb', /(^\s*?)(name|description) .*?$/, %q^\1sequence(:\2) {|n| 'place_\2_%d' % n }^

  insert_into_file 'places.rb', before: /^(\s\s)end$/ do
    <<-CODE
\\1  factory :invalid_place do
\\1    user nil
\\1    name nil
\\1  end
\\1  factory :bare_place do
\\1    user nil
\\1    name nil
\\1    description nil
\\1  end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'place_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\2  it "should increment the count" do
\\2    expect{ create(:place) }.to change{Place.count}.by(1)
\\2  end

\\2it "should fail with invalid" do
\\2  expect( build(:invalid_place) ).to be_invalid
\\2end

\\2  it "should fail without :name" do
\\2    expect( build(:place, name: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:place, user: nil) ).to be_invalid
\\2  end
\\2end

\\2describe "#name duplicated" do
\\2  it "should fail with UniqueViolation" do
\\2    expect { 2.times {create(:place, name: 'duplicate_name')} }.to raise_error(ActiveRecord::RecordInvalid)
\\2  end
\\2end

\\2describe "followable" do
\\2  it "can be followed by user" do
\\2    follower = create(:user)
\\2    followable = create(:place)
\\2    expect{ follower.follow(followable) }.to change{Follow.count}.by(1)
\\2    expect( follower.follow?(followable) ).to be true
\\2  end
\\2end
  CODE

end

inside 'spec/controllers' do
  gsub_file 'places_controller_spec.rb', /(\n\s*?let\(:valid_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:place).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'places_controller_spec.rb', /(\n\s*?let\(:invalid_attributes\) \{\n\s*?)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:invalid_place).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'places_controller_spec.rb', /(\n\s*?let\(:new_attributes\) \{\n\s*)skip.*?\n(\s*\})\n/m, <<-CODE
\\1build(:place).attributes.except("id", "created_at", "updated_at")
\\2
  CODE

  gsub_file 'places_controller_spec.rb', /(updates the requested place.*?)skip\(.*?\)\n/m, <<-CODE
\\1expect(place.attributes.fetch_values(*new_attributes.keys)).to be == new_attributes.values
  CODE

end

inside 'spec/views/places/' do
  gsub_file 'index.html.haml_spec.rb', /(\s*?)assign\(:places,.*?\]\)(\n)/m, <<-CODE
\\1@places = assign(:places, create_list(:place, 2))
  CODE

  gsub_file 'index.html.haml_spec.rb', /(renders a list of places.*?)\n\s+render(\s*assert_select.*?\n)+/m, <<-CODE
\\1
    expect(@places.size).to be(2)
    render
    @places.each do |place|
      assert_select "tr>td", :text => place.name.to_s, :count => 1
      assert_select "tr>td", :text => place.description.to_s, :count => 1
    end
  CODE

  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*?))(.*?)Place.new\(.*?\)\)\n/m, <<-CODE
\\1\\3build(:place))
  CODE
  insert_into_file 'new.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Place.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:place))
  CODE
  insert_into_file 'edit.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Place.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:place))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(it.*renders attributes in .*\n(\s*?)?)(expect.*?\n)+?(\s+end)\n/m, <<-CODE
\\1expect(rendered).to match(/\#{@place.name}/)
\\2expect(rendered).to match(/\#{@place.description}/)
\\4
  CODE
end

gsub_file 'spec/helpers/places_helper_spec.rb', /^\s.pending .*\n/, ''
