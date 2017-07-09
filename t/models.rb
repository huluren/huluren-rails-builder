inject_into_class 'app/models/application_record.rb', 'ApplicationRecord', <<-CODE
  scope :sample, ->(limit=1) { order("RANDOM()").limit(limit) }
CODE
