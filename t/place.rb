generate 'model place user:references:index name:string:uniq description:text'

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :places
  CODE

  inject_into_class 'place.rb', 'Place', <<-CODE
  validates :user, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :random, ->(limit=1) { order("RANDOM()").limit(limit) }

  has_many :comments, as: :commentable
  CODE

end

inside 'spec/' do
  gsub_file 'factories/places.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'factories/places.rb', /(^\s*?)(name|description) .*?$/, %q^\1sequence(:\2) {|n| 'place_\2_%d' % n }^

  gsub_file 'models/place_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\2  it "should increment the count" do
\\2    expect{ create(:place) }.to change{Place.count}.by(1)
\\2  end

\\2  it "should fail without :name" do
\\2    expect( build(:place, name: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:place, user: nil) ).to be_invalid
\\2  end
\\2end

\\2describe "#name duplicated" do
\\2  it "should fail with UniqueViolation" do
\\2    expect { 2.times {create(:place, name: 'duplicate_name')} }.to raise_error(ActiveRecord::RecordInvalid)
\\2  end
\\2end
  CODE

end
