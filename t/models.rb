inject_into_class 'app/models/application_record.rb', 'ApplicationRecord', <<-CODE
  scope :recent, -> { order(id: :desc) }
  scope :sample, ->(s=true) { s ? order("RANDOM()") : nil }
CODE
