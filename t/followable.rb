# Follow
generate 'acts_as_followable'
generate 'rspec:model follow follower:references{polymorphic}:index followable:references{polymorphic}:index blocked:boolean --no-migration'

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  acts_as_followable
  acts_as_follower
  CODE

end
