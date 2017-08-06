generate 'scaffold activity user:references:index title:string content:text uuid:string:uniq --parent=post'

file 'config/locales/activity.yml', <<-CODE
en:
  activity:
    create: New Activity
    posted: Post at
    from: From
    back: Back
    from_/_back: From/Back
    date_range: dates

    post_new_activity: Publish new activity

    save: Save
    title: Title
    content: Content
    add_title: Add title
    add_content: Write more about your journey...

    list_activities: Activities
    new_activity: New Activity
    edit_activity: Update Activity

zh-CN:
  activity:
    create: '发布新行程'
    posted: '提交于'
    from: 来自
    back: 返回
    from_/_back: 来自／返回
    date_range: 往返时间

    post_new_activity: 发布行程

    save: 保存
    title: 标题
    content: 详情
    add_title: 写个标题吧
    add_content: 关于旅行的更多细节……

    list_activities: 行程列表
    new_activity: 发布新行程
    edit_activity: 更新行程
CODE

inside 'app/models/' do

  gsub_file 'activity.rb', /^\s+belongs_to :user\n/, ''

  inject_into_class 'activity.rb', 'Activity', <<-CODE
  default_scope { recent }
  validates :title, presence: true
  validates :content, presence: true
  validates :uuid, uniqueness: { case_sensitive: false }, allow_nil: true
  CODE

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :activities
  CODE

end

inside 'app/controllers/' do
  inject_into_class 'activities_controller.rb', ActivitiesController, <<-CODE
  before_action :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]
  CODE

  gsub_file 'activities_controller.rb', /(\n(\s*?)def index\n[^\n]*?Activity\.)all\n/m, <<-CODE
\\1sample(params[:s]).limit(params[:c])
  CODE

  gsub_file 'activities_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @activity.user = current_user
\\3
  CODE

end

inside 'app/views/activities/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'
  gsub_file 'index.html.haml', /^(%h1) .*$/, %q^\1= t('activity.list_activities')^
  gsub_file 'index.html.haml', /(link_to )'New Activity'(, new_activity_path)/, %q^\1t('activity.new_activity')\2, data: {"no-turbolink": true}^

  insert_into_file 'index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @activities
    CODE
  end

  gsub_file 'index.html.haml', /(\n)%table.*?\n([^\s].*)\n/m, <<-CODE
\\1= render 'items', items: @activities
\\2
  CODE

  file 'index.js.coffee', <<-CODE
$("main #activities").replaceWith "<%= escape_javascript(render 'items', items: @activities) %>"
$("main #activities.list-group").trigger("activities:load")
  CODE

  file '_items.html.haml', <<-CODE
#activities.list-group{'data-url': activities_path}
  - items.each do |activity|
    .list-group-item.flex-column.align-items-start
      .d-flex.w-100.justify-content-between<>
        .lead= activity.places.pluck(:title).to_sentence
        %small.card.text-muted.p-1
          .card-block.text-nowrap.p-0<>
            .font-weight-bold= t('activity.date_range')
          .card-block.text-nowrap.p-0<>
            = timeago_tag activity.start_date
            %span.m-1<>
              |
            = timeago_tag activity.end_date
      %h5.activity-title.mt-1<>= activity.title.html_safe
      .activity-content.mt-1<>= activity.content.html_safe
      .d-flex.w-100.justify-content-between<>
        %small
          = precede t("activity.posted") do
            = timeago_tag activity.created_at, class: 'ml-1'
        - if activity.respond_to? :comments
          %small
            = link_to t('comment.comments', count: activity.comments.count),
                      polymorphic_url([activity, :comments], only_path: true)
  CODE

  file '_items_list.html.haml', <<-CODE
#activities.list-group{'data-url': activities_path}
  - items.each do |activity|
    .list-group-item.list-group-item-action.justify-content-between
      = activity.title.html_safe
      = activity.places.pluck(:title).to_sentence
      .badge.badge-default.badge-pill<>
        = timeago_tag activity.start_date
        %span.m-1<>
          |
        = timeago_tag activity.end_date
  CODE

  gsub_file '_form.html.haml', /@activity/, 'activity'

  gsub_file '_form.html.haml', /(= f.label :)(user)$/, '= f.label :user, current_user.email'
  gsub_file '_form.html.haml', /(= f.text_field :)(user)$/, '= f.hidden_field :user_id, value: current_user.id'
  gsub_file '_form.html.haml', /(= f.text_field :)(uuid)$/, '= f.hidden_field :uuid if activity.uuid'
  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+title\n)+/m, <<-CODE
\\1.form-group
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary.mr-2<>= t('activity.title')
\\2    = f.text_field :title,
\\2                  class: 'form-control',
\\2                  placeholder: t('activity.add_title'),
\\2                  'aria-describedby': 'activity-title-help'
\\2  %small#activity-title-help.form-text.text-muted<>= t('activity.add_title')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+content\n)+/m, <<-CODE
\\1.form-group
\\2  %span.input-group-addon.btn.btn-secondary.mr-2<>= t('activity.content')
\\2  = f.text_area :content,
\\2                class: 'form-control ckeditor',
\\2                placeholder: t('activity.add_content'),
\\2                'aria-describedby': 'activity-content-help',
\\2                rows: 5
\\2  %small#activity-content-help.form-text.text-muted<>= t('activity.add_content')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('activity.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  gsub_file 'new.html.haml', /= render 'form'$/, '\0, activity: @activity'
  gsub_file 'new.html.haml', /^(%h1) .*$/, %q^\1= t('activity.new_activity')^

  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, activity: @activity'
  gsub_file 'edit.html.haml', /^(%h1) .*$/, %q^\1= t('activity.edit_activity')^

  gsub_file 'new.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
  gsub_file 'edit.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
end

inside 'app/assets/javascripts/' do

  append_to_file 'activities.coffee', <<-CODE
delay = (ms, func) -> setTimeout func, ms

load_image_from_iframe = (img, callback) ->
  if img.attr("loading")
    return

  img.attr("loading", true)

  iframe = $('<iframe style="display: none;"></iframe>')
  $(iframe).attr "src", 'data:text/html;charset=utf-8,' + encodeURI('<img src="' + img.data("src") + '" />')

  iframe.on "load", ->
    img.attr "src", img.data("src")
    img.data "loading-complete", (new Date()).getTime()
    img.attr "loading-cost", (img.data("loading-complete") - img.data("loading-start"))
    img.attr "title", "success " + (img.data("loading-complete") - img.data("loading-start"))

  iframe.on "error", ->
    img.attr("loading", false)
    img.data "loading-complete", (new Date()).getTime()
    img.attr "loading-cost", (img.data("loading-complete") - img.data("loading-start"))
    img.attr "title", "error " + (img.data("loading-complete") - img.data("loading-start"))

  img.data "loading-start", (new Date()).getTime()
  img.before(iframe)

$(document).on "turbolinks:load", ->

  $("main").on "activities:load", "#activities.list-group", ->

    $(".list-group-item p > img", $(this)).each ->
      $(this).data "src", $(this).attr("src")
      $(this).removeAttr "src"
      load_image_from_iframe $(this)

  $("main #activities.list-group").trigger("activities:load")

  true
  CODE

end

inside 'spec/factories/' do
  gsub_file 'activities.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'activities.rb', /(^\s*?)(title|content|uuid) .*?$/, %q^\1sequence(:\2) {|n| 'activity_\2_%d' % n }^

  insert_into_file 'activities.rb', before: /^(\s\s)end$/ do
    <<-CODE
\\1  factory :invalid_activity do
\\1    user nil
\\1    title nil
\\1    content nil
\\1  end
\\1  factory :bare_activity do
\\1    user nil
\\1    title nil
\\1    content nil
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

\\2  it "should fail with invalid" do
\\2    expect( build(:invalid_activity) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:activity, user: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :title" do
\\2    expect( build(:activity, title: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :content" do
\\2    expect( build(:activity, content: nil) ).to be_invalid
\\2  end

\\2  it "should fail with duplicate :uuid" do
\\2    expect{ 2.times { create(:activity, uuid: 'duplicate_uuid') } }.to raise_error(ActiveRecord::RecordInvalid)
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
  insert_into_file 'activities_controller_spec.rb', after: /^(\n+?(\s+?))describe "(GET|POST|PUT|DELETE) #(new|edit|create|update|destroy)" do\n/ do
    <<-CODE
\\2  before do
\\2    sign_in create(:user)
\\2  end

    CODE
  end

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
      assert_select "#activities .activity-content", :text => activity.content.to_s, :count => 1
    end
  CODE

  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*?))(.*?)Activity.new\(.*?\)\)\n/m, <<-CODE
\\1\\3build(:activity))
  CODE
  insert_into_file 'new.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Activity.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:activity))
  CODE
  insert_into_file 'edit.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*?))(.*?)Activity.create!\(.*?\)\)\n/m, <<-CODE
\\1\\3create(:activity))
  CODE

  gsub_file 'show.html.haml_spec.rb', /([ ]+)(it.*renders attributes in .*?)expect.*?\n(\1end)\n/m, <<-CODE
\\1\\2expect(rendered).to match(/\#{@activity.content}/)
\\3
  CODE
end

gsub_file 'spec/helpers/activities_helper_spec.rb', /^\s.pending .*\n/, ''
