route <<-CODE
scope :import do
    get  '/'      => 'import#index',       as: :import
    post 'douban' => 'import#douban',      as: :import_douban_list
    get  'douban' => 'import#douban_post', as: :import_douban_post
  end
CODE

inside 'app/controllers/' do
  inject_into_class 'import_controller.rb', 'ImportController', <<-CODE
  before_action :authenticate_user!

  def index
  end
  CODE
end
