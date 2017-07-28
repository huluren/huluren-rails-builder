generate 'model authentication', 'user:references provider uid token secret email name nickname image'
generate 'devise:controllers authentication', '-c=omniauth_callbacks'

inside 'app/models/' do
  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :authentications

  def self.from_omniauth(auth, current_user)
    # 1. find link auth -> user_id
    # 2. if logged in, link auth -> user_id
    # 3. if verified email, create link auth email -> user email
    authentication = Authentication.where( provider: auth.provider, uid: auth.uid.to_s ).first_or_initialize do |authentication|
      authentication.token = auth.credentials.token

      authentication.email = auth.info.email
      authentication.name = auth.info.name
      authentication.nickname = auth.info.nickname
      authentication.image = auth.info.image

      authentication.user = current_user || authentication.user || (User.where( email: auth.info.email ).first_or_initialize if email_verified?(auth))
      authentication.user.authentications << authentication

      authentication.save
    end

    authentication.user
  end

  def self.email_verified?(auth)
    auth.extra.all_emails.select {|e| e.email == auth.info.email and e.verified == true }.size > 0
  end
  CODE
  
  insert_into_file 'user.rb', ', :omniauthable', after: ':validatable'
end

inside 'app/controllers/authentication/' do

  inject_into_class 'omniauth_callbacks_controller.rb', 'Authentication::OmniauthCallbacksController', <<-CODE
  def github
    @user = User.from_omniauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = t('devise.omniauth_callbacks.success', kind: request.env["omniauth.auth"].provider)
      sign_in_and_redirect @user
    else
      if @user.save(:validate => false)
        flash[:notice] = "Account created and signed in successfully."
        sign_in_and_redirect(@user)
      else
        session['devise.user_attributes'] = @user.attributes
        redirect_to new_user_registration_url
      end
    end
  end
  CODE

end

insert_into_file 'config/routes.rb', %q^, controllers: { omniauth_callbacks: 'authentication/omniauth_callbacks' }^, after: 'devise_for :users'

insert_into_file 'config/initializers/devise.rb', after: /# config.omniauth [^\n]+?\n/ do
  <<-CODE
  config.omniauth :github, ENV['GITHUB_APP_ID'], ENV['GITHUB_APP_SECRET'], scope: 'user:email'
  CODE
end

inside 'spec/factories/' do
  gsub_file 'authentications.rb', /(^\s*?)(user) nil$/, '\1\2'
end
