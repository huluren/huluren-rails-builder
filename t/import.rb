generate 'controller import --skip-routes --no-stylesheets --no-helper'

inside 'app/views/import/' do
  file 'index.html.haml', <<-CODE
%h3 Import
  CODE
end

inside 'app/assets/javascripts/' do
end

inside 'spec/controllers/' do
  insert_into_file 'import_controller_spec.rb', after: /RSpec.describe ImportController, type: :controller do\n/ do
    <<-CODE
  before do
    sign_in create(:user)
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
    CODE
  end

end
