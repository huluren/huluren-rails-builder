generate 'model authentication', 'user:references provider uid token secret email nickname image'
generate 'devise:controllers authentication', '-c=omniauth_callbacks'

inside 'app/models/' do
  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :authentications

  def self.from_omniauth(auth, current_user)
    # if logged in
    #   link auth -> user_id
    # else (not logged in)
    #   find link auth -> user_id
    #   create link auth email -> user email, only for verified email
    if current_user.blank?
      authentication = Authentication.where( provider: auth.provider, uid: auth.uid.to_s ).first_or_initialize do |authentication|
        authentication.token = auth.credentials.token
        authentication.email = auth.info.email
        authentication.user ||= User.where( email: auth.info.email ).first_or_initialize if self.email_verified?(auth)
      end
    else
      authentication = current_user.authentications.where( provider: auth.provider, uid: auth.uid.to_s ).first_or_initialize do |authentication|
        authentication.token = auth.credentials.token
      end
    end

    authentication.user
  end

  def self.email_verified?(auth)
    auth.extra.all_emails.keep_if {|e| e.email == auth.info.email and e.verified == true }.size > 0
  end
  CODE
  
  insert_into_file 'user.rb', after: ':validatable' do
    %q^, :omniauthable^
  end
end

inside 'app/controllers/authentication/' do

  inject_into_class 'omniauth_callbacks_controller.rb', 'Authentication::OmniauthCallbacksController', <<-CODE
  def github
    @user = User.from_omniauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = t('devise.omniauth_callbacks.success', :kind => 'GitHub')
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

insert_into_file 'config/routes.rb', after: 'devise_for :users' do
  %q^, controllers: { omniauth_callbacks: 'authentication/omniauth_callbacks' }^
end

insert_into_file 'config/initializers/devise.rb', after: /# config.omniauth [^\n]+?\n/ do
  <<-CODE
  config.omniauth :github, ENV['GITHUB_APP_ID'], ENV['GITHUB_APP_SECRET'], scope: 'user:email'
  CODE
end

inside 'spec/factories/' do
  gsub_file 'authentications.rb', /(^\s*?)(user) nil$/, '\1\2'
end
