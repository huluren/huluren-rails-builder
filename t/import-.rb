route <<-CODE
scope :import do
    get  '/'             => 'import#index',         as: :import
    post 'present'       => 'import#present',       as: :present
    get  'douban/groups' => 'import#douban_groups', as: :douban_groups
    get  'douban/topics' => 'import#douban_topics', as: :douban_topics
    get  'douban/topic'  => 'import#douban_topic',  as: :douban_topic
  end
CODE

file 'config/initializers/present.rb', <<-CODE
Rails.application.configure do
  config.present_enable = true
  config.present_redis_client = ConnectionPool::Wrapper.new(size: 1, timeout: 5) {
                                  Redis.new url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379')
                                }
end
CODE

inside 'app/models/' do
  file 'present.rb', <<-CODE
class Present
  def initialize
    @client = Rails.configuration.present_redis_client
    @sets = [:accept, :deny, :inbox]

    self
  end

  def present?(key, set=nil)
    set = set.to_sym if set
    @client.sadd set, key if set

    @sets.each do |s|
      @client.srem s, key if set and s != set
      return s if @client.sismember s, key
    end

    return @sets.last if @client.sadd @sets.last, key
  end

end
  CODE
end

inside 'app/controllers/' do
  inject_into_class 'import_controller.rb', 'ImportController', <<-CODE
  before_action :authenticate_user!

  def index
  end

  def present
    key = params[:key]
    set = params[:set]

    render json: { key: key, set: Present.new.present?(key, set) }
  end

  CODE
end
