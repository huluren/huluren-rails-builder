generate 'scaffold place user:references:index title:string content:text --parent=post'

file 'config/locales/place.yml', <<-CODE
en:
  place:
    choose:
      from: From city...
      to: To city...
    search: Search...

    save: Save
    title: Name
    content: Description
    add_title: Add Name of the Place
    add_content: Add some content of the place...

    list_places: Places
    new_place: New Place
    edit_place: Update Place

zh-CN:
  place:
    where_to_go: 目的地...
    choose:
      from: 来源城市...
      to: 返回城市...
    search: 搜索...

    save: 保存
    title: 名称
    content: 详情
    add_title: 填写地点名称
    add_content: 添加地点描述与介绍

    list_places: 地点列表
    new_place: 创建新地点
    edit_place: 编辑地点
CODE

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :places
  CODE

  gsub_file 'place.rb', /^\s+belongs_to :user\n/, ''

  inject_into_class 'place.rb', 'Place', <<-CODE
  validates :title, presence: true, uniqueness: { case_sensitive: false }

  scope :q, ->(query_string) { query_string.nil? ? nil : where("title LIKE ?", "%\#{query_string}%") }
  CODE

end

inside 'app/controllers/' do
  inject_into_class 'places_controller.rb', PlacesController, <<-CODE
  before_action :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def index\n[^\n]*?Place\.)all\n/m, <<-CODE
\\1sample(params[:s]).q(params[:q]).limit(params[:c])
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @place.user = current_user
\\3
  CODE

end

inside 'app/views/places/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'
  gsub_file 'index.html.haml', /^(%h1) .*$/, %q^\1= t('place.list_places')^
  gsub_file 'index.html.haml', /link_to 'New Place'/, %q{link_to t('place.new_place')}

  insert_into_file 'index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @places
    CODE
  end

  gsub_file 'index.html.haml', /(\n)%table.*?\n([^\s].*)\n/m, <<-CODE
\\1= render 'places', places: @places
\\2
  CODE

  file 'index.js.coffee', <<-CODE
$("main #places").replaceWith "<%= escape_javascript(render 'items_list', items: @places) %>"
  CODE

  file '_places.html.haml', <<-CODE
#places.list-group{'data-url': places_path}
  - places.each do |place|
    = render place
  CODE

  file '_place.html.haml', <<-CODE
.list-group-item.flex-column.align-items-start
  .d-flex.w-100.justify-content-between<>
    .lead.place-title= place.title
    %small.card.text-muted.p-1
  %p.place-content.mt-1<>= place.content.html_safe
  .d-flex.w-100.justify-content-between<>
    %small
      = precede t("place.posted") do
        = timeago_tag place.created_at, class: 'ml-1'
    - if place.respond_to? :comments
      %small
        = link_to t('comment.comments', count: place.comments.count),
                  polymorphic_url([place, :comments], only_path: true)
  CODE

  file '_items_list.html.haml', <<-CODE
#places.list-group{'data-url': places_path}
  - items.each do |place|
    .list-group-item.list-group-item-action.justify-content-between
      = place.title
      .badge.badge-default.badge-pill= place.activities.count
  CODE

  gsub_file '_form.html.haml', /@place/, 'place'

  gsub_file '_form.html.haml', /(= f.text_field :)(user)$/, '= f.hidden_field :\2_id, value: current_user.id'
  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+title\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary<>= t('place.title')
\\2    = f.text_field :title,
\\2                  class: 'form-control',
\\2                  placeholder: t('place.add_title'),
\\2                  'aria-describedby': 'place-title-help',
\\2                  rows: 3
\\2  %small#place-title-help.form-text.text-muted<>= t('place.add_title')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+content\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary<>= t('place.content')
\\2    = f.text_area :content,
\\2                  class: 'form-control',
\\2                  placeholder: t('place.add_content'),
\\2                  'aria-describedby': 'place-content-help',
\\2                  rows: 3
\\2  %small#place-content-help.form-text.text-muted<>= t('place.add_content')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('place.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  gsub_file 'new.html.haml', /= render 'form'$/, '\0, place: @place'
  gsub_file 'new.html.haml', /^(%h1) .*$/, %q^\1= t('place.new_place')^

  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, place: @place'
  gsub_file 'edit.html.haml', /^(%h1) .*$/, %q^\1= t('place.edit_place')^

  gsub_file 'new.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
  gsub_file 'edit.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
end

inside 'spec/factories/' do
  gsub_file 'places.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'places.rb', /(^\s*?)(title|content) .*?$/, %q^\1sequence(:\2) {|n| 'place_\2_%d' % n }^

  insert_into_file 'places.rb', before: /^(\s\s)end$/ do
    <<-CODE
\\1  factory :invalid_place do
\\1    user nil
\\1    title nil
\\1    content nil
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

\\2  it "should fail with invalid" do
\\2    expect( build(:invalid_place) ).to be_invalid
\\2  end

\\2  it "should fail without :title" do
\\2    expect( build(:place, title: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:place, user: nil) ).to be_invalid
\\2  end
\\2end

\\2describe "#title duplicated" do
\\2  it "should fail with UniqueViolation" do
\\2    expect { 2.times {create(:place, title: 'duplicate_title')} }.to raise_error(ActiveRecord::RecordInvalid)
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
  insert_into_file 'places_controller_spec.rb', after: /^(\n+?(\s+?))describe "(GET|POST|PUT|DELETE) #(new|edit|create|update|destroy)" do\n/ do
    <<-CODE
\\2  before do
\\2    sign_in create(:user)
\\2  end

    CODE
  end

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
      assert_select "#places .place-title", :text => place.title.to_s, :count => 1
      assert_select "#places .place-content", :text => place.content.to_s, :count => 1
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

  gsub_file 'show.html.haml_spec.rb', /([ ]+)(it.*renders attributes in .*?)expect.*?\n(\1end)\n/m, <<-CODE
\\1\\2expect(rendered).to match(/\#{@place.title}/)
\\1  expect(rendered).to match(/\#{@place.content}/)
\\3
  CODE
end

gsub_file 'spec/helpers/places_helper_spec.rb', /^\s.pending .*\n/, ''
