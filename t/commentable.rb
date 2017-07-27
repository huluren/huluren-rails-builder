#========== Comment ==========#
generate 'scaffold comment user:references content:text commentable:references{polymorphic}:index --no-resource-route'

route <<-CODE
concern :commentable do
    resources :comments, shallow: true
  end
CODE

gsub_file 'config/routes.rb', /resources :(users|places|activities)/, '\0, concerns: :commentable'

file 'config/locales/comment.yml', <<-CODE
en:
  comment:
    comment: Comment
    list_comments: Comments
    write_comment: Write your comment...
    leave_comment_here: Leave comment here.
    save: Post
    comments:
      zero: "No comments"
      one: "%{count} comment"
      few: "%{count} comments"
      many: "%{count} comments"
      other: "%{count} comments"
zh-CN:
  comment:
    comment: 评论
    list_comments: 评论列表
    write_comment: 发表评论……
    leave_comment_here: 留下你的评论。
    save: 发布
    comments:
      zero: "无评论"
      one: "%{count} 条评论"
      few: "%{count} 条评论"
      many: "%{count} 条评论"
      other: "%{count} 条评论"
    new_comment: 添加评论
CODE

inside 'app/models/' do
  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :user_comments, class_name: 'Comment'
  CODE

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :comments, as: :commentable
  CODE

  inject_into_class 'place.rb', 'Place', <<-CODE
  has_many :comments, as: :commentable
  CODE

  inject_into_class 'activity.rb', 'Activity', <<-CODE
  has_many :comments, as: :commentable
  CODE

  inject_into_class 'comment.rb', 'Comment', <<-CODE
  validates :user, presence: true
  validates :content, presence: true
  validates :commentable, presence: true
  CODE
end

inside 'app/controllers/' do
  gsub_file 'comments_controller.rb', /(\n(\s*))(before_action :set_comment)(, only.*?)\n/, <<-CODE
\\1before_action :set_commentable, only: [:index, :create, :new]
\\2\\3_commentable\\4
  CODE

  gsub_file 'comments_controller.rb', /(\n(\s*))def set_comment\n.*?end\n/m, <<-CODE
\\1def set_comment_commentable
\\2  @comment = Comment.find(params[:id])
\\2  @commentable = @comment.commentable
\\2end

\\2# :index, :create, :new
\\2def set_commentable
\\2  @commentable = -> {
\\2    params.each do |name, value|
\\2      if name =~ /(.+)_id$/
\\2        return $1.classify.constantize.find(value)
\\2      end
\\2    end
\\2    return nil
\\2  }.call
\\2end
  CODE

  gsub_file 'comments_controller.rb', /(def index\n.*?)Comment.all\n/m, <<-CODE
\\1@commentable.comments
  CODE

  gsub_file 'comments_controller.rb', /(def (new|create)\n.*?)Comment.new(.*?)\n/m, <<-CODE
\\1@commentable.comments.new\\3
  CODE

  gsub_file 'comments_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @comment.user = current_user
\\3
  CODE

  gsub_file 'comments_controller.rb', /(redirect_to )comments_url(, )/, '\1polymorphic_url([@commentable, Comment])\2'
end

inside 'app/views/comments/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'
  gsub_file 'index.html.haml', /^(%h1) .*$/, %q^\1= t('comment.list_comments')^
  gsub_file 'index.html.haml', /new_comment_path/, 'new_polymorphic_url([@commentable, Comment])'

  insert_into_file 'index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @comments
    CODE
  end

  gsub_file 'index.html.haml', /(\n)%table.*?\n([^\s].*)\n/m, <<-CODE
\\1= render 'comments', commentable: @commentable, items: @comments
\\2
  CODE

  file '_comments.html.haml', <<-CODE
/ commentable, items
#comments.list-group{'data-url': polymorphic_url([commentable, :comments], only_path: true)}
  - items.each do |comment|
    .list-group-item.flex-column.align-items-start
      .d-flex.w-100.justify-content-between<>
      %p.comment-content.mt-1<>= comment.content.html_safe
      %small<>
  CODE

  gsub_file '_form.html.haml', /@comment/, 'comment'

  gsub_file '_form.html.haml', /(= f.text_field :)(user|commentable)$/, '= f.hidden_field :\2_id'
  gsub_file '_form.html.haml', /(= f.hidden_field :)(user_id)$/, '\1\2, value: current_user.id'
  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(= form_for ([@]*comment))( do .*)\n/, <<-CODE
- form_path = \\2.id ? comment_path(\\2) : polymorphic_url([\\2.commentable, :comments], only_path: true)
\\1, url: form_path\\3
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+content\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary.mr-2<>= t('comment.content')
\\2    = f.text_area :content,
\\2                  class: 'form-control',
\\2                  placeholder: t('comment.write_comment'),
\\2                  'aria-describedby': 'comment-content-help',
\\2                  rows: 3
\\2  %small#comment-content-help.form-text.text-muted<>= t('comment.write_comment')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('comment.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  gsub_file 'new.html.haml', /comments_path/, '[@commentable, Comment]'
  gsub_file 'new.html.haml', /= render 'form'$/, '\0, comment: @comment'

  gsub_file 'show.html.haml', /comments_path/, '[@commentable, Comment]'

  gsub_file 'edit.html.haml', /comments_path/, '[@commentable, Comment]'
  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, comment: @comment'
end

inside('spec/factories/') do
  gsub_file 'comments.rb', /^\s*user nil$/, '    user'
  gsub_file 'comments.rb', /^\s*content .*$/, '    sequence(:content) {|n| %/Comment Content #{n}/ }'
  gsub_file 'comments.rb', /^\s*commentable nil$/, '    association :commentable, factory: :user'

  insert_into_file 'comments.rb', after: %/association :commentable, factory: :user\n/ do
    <<-CODE

    factory :invalid_comment do
      user nil
      content nil
      commentable nil
    end

    factory :bare_comment do
      user nil
      content nil
      commentable nil
    end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'comment_spec.rb', /^\s.pending .*\n/, <<-CODE
  it "should increment the count" do
    expect{ create(:comment) }.to change{Comment.count}.by(1)
  end

  it "should fail with bare comment" do
    expect( build(:bare_comment) ).to be_invalid
  end

  it "should fail with invalid" do
    expect( build(:invalid_comment) ).to be_invalid
  end

  it "should fail without :user" do
    expect( build(:comment, user: nil) ).to be_invalid
  end

  it "should fail without :content" do
    expect( build(:comment, content: nil) ).to be_invalid
  end

  it "should fail without :commentable" do
    expect( build(:comment, commentable: nil) ).to be_invalid
  end

  it "should have :commentable_id" do
    expect( create(:comment).commentable ).not_to be(nil)
  end
CODE
end

inside 'spec/controllers' do
  gsub_file 'comments_controller_spec.rb', /let\(:valid_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:valid_attributes) {
    build(:comment, commentable: create(:user)).attributes.except("id", "created_at", "updated_at")
  }
  CODE

  gsub_file 'comments_controller_spec.rb', /(get :(index|new), params: \{)(})/, '\1 user_id: create(:user) \3'
  gsub_file 'comments_controller_spec.rb', /(post :create, params: {comment: (valid_attributes|invalid_attributes))(})/, %q!\1, user_id: \2['commentable_id']\3!

  gsub_file 'comments_controller_spec.rb', /let\(:invalid_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:invalid_attributes) {
    build(:invalid_comment, commentable: create(:user)).attributes.except("id", "created_at", "updated_at")
  }
  CODE

  gsub_file 'comments_controller_spec.rb', /let\(:new_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:new_attributes) {
        build(:comment).attributes.except("id", "created_at", "updated_at")
      }
  CODE

  gsub_file 'comments_controller_spec.rb', /(updates the requested comment.*?)skip\(.*?\)\n/m, <<-CODE
\\1expect(comment.attributes.fetch_values(*new_attributes.keys)).to be == new_attributes.values
  CODE

  gsub_file 'comments_controller_spec.rb', /(DELETE #destroy.*?redirects to the comments list.*?)\n(\s*)(delete :destroy.*?)comments_url(.*)\n/m, <<-CODE
\\1
\\2commentable = comment.commentable
\\2\\3[commentable, Comment]\\4
  CODE

end

inside 'spec/views/comments/' do
  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*))assign\(:comment, Comment.new\(.*?\)\)\n/m, <<-CODE
\\1@commentable = create :user
\\2assign(:comment, build(:comment, commentable: @commentable))
  CODE

  gsub_file 'new.html.haml_spec.rb', /(, )(comments_path)(, )/, '\1user_\2(@commentable)\3'

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*))(.*?)Comment.create!\(.*?\)\)\n/m, <<-CODE
\\1@commentable = build(:user)
\\2@comment = assign(:comment, create(:comment, commentable: @commentable))
  CODE

  gsub_file 'index.html.haml_spec.rb', /assign\(:comments,.*?\]\)(\n)/m, <<-CODE
@commentable = create :user
    @comments = assign(:comments, create_list(:comment, 2, commentable: @commentable))
  CODE

  gsub_file 'index.html.haml_spec.rb', /(renders a list of comments.*?)\n\s+render(\s*assert_select.*?\n)+/m, <<-CODE
\\1
    expect(@comments.size).to be(2)

    render

    @comments.each do |comment|
      assert_select "#comments .comment-content", :text => comment.content.to_s, :count => 1
    end
  CODE

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*))(.*?)Comment.create!\(.*?\)\)\n/m, <<-CODE
\\1@commentable = create :user
\\2\\3create(:comment, commentable: @commentable))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(renders attributes in .*?)expect.*?(\s+end)\n/m, <<-CODE
\\1expect(rendered).to match(/\#{@comment.content}/)\\2
  CODE

end

gsub_file 'spec/routing/comments_routing_spec.rb', /(\s*it .*?#(index|new|create).*?\n\s*?expect.*?)(\/comments.*?route_to\(.comments#\2.)(\))\n/m, <<-CODE
\\1/users/1\\3, user_id: '1'\\4
CODE

gsub_file 'spec/helpers/comments_helper_spec.rb', /^\s.pending .*\n/, ''

gsub_file 'spec/requests/comments_spec.rb', /comments_path$/, 'user_\0(create :user)'
