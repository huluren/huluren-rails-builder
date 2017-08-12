
#========== Devise ==========#
unless File.exists? 'config/initializers/devise.rb'
  generate 'devise:install'
  generate 'devise:i18n:locale', :'zh-CN'
  generate :devise, :user

  route 'resources :users, only: []'

  inside 'app/views/users/' do
    file '_items.html.haml', <<-CODE
#users.list-group
  - items.each do |user|
    .list-group-item.flex-column.align-items-start
      .d-flex.w-100.justify-content-between<>
        .lead.user-name
          = precede user.model_name.human do
            %b.ml-1<>= user.id
        %small.card.text-muted.p-1
      %p.user-description.mt-1<>
      .d-flex.w-100.justify-content-between<>
        - if user.respond_to? :comments
          %small
            = link_to t('comment.comments', count: user.comments.count),
                      polymorphic_url([user, :comments], only_path: true)
    CODE
  end

  inside 'config/' do
    gsub_file 'initializers/devise.rb', /^(\s*# config.secret_key = ).*$/, %q^\1ENV['DEVISE_SECRET_KEY']^
    gsub_file 'initializers/devise.rb', /^(\s*# config.pepper = ).*$/, %q^\1ENV['DEVISE_PEPPER']^
  end

  inside 'spec' do

    file 'support/devise.rb', <<-CODE
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
end
    CODE

    insert_into_file 'factories/users.rb', after: %/factory :user do\n/ do
      <<-CODE
    sequence(:email) { |n| "\#{n}@email.com" }
    password Devise.friendly_token[0, 6]

    factory :user_invalid_password do
      password Devise.friendly_token[0, 5]
    end

    factory :user_no_email do
      email nil
    end

    factory :user_no_password do
      password nil
    end
      CODE
    end

    gsub_file 'models/user_spec.rb', /^(\s*?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\1  it "should increment the count" do
\\1    expect{ create(:user) }.to change{User.count}.by(1)
\\1  end

\\1  it "should fail without ::email or :password" do
\\1    expect( build(:user_no_email) ).to be_invalid
\\1    expect( build(:user_no_password) ).to be_invalid
\\1  end
\\1end

\\1describe "#email duplicated" do
\\1  it "should fail with UniqueViolation" do
\\1    expect { 2.times {create(:user, email: 'duplicate@email.com')} }.to raise_error(ActiveRecord::RecordInvalid)
\\1  end
\\1end
    CODE
  end

end
