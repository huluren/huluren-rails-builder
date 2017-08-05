route <<-CODE
scope :import do
    get  '/'       => 'import#index',       as: :import
    post 'present' => 'import#present',     as: :present
    post 'douban'  => 'import#douban',      as: :import_douban_list
    get  'douban'  => 'import#douban_post', as: :import_douban_post
  end
CODE

inside 'app/models/' do
  file 'present.rb', <<-CODE
class Present
  def initialize(url = ENV['REDIS_URL'])
    @client = Redis.new(url: url).tap {|c| c.ping }
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
