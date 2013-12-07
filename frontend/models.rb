require 'dm-core'
require  'dm-migrations'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost:5432/disco')

class Email
  include DataMapper::Resource
  
  property :id, Serial
  property :subject, Text
  property :body, Text
  property :from, Text
  property :sent_time, Float

  has 1, :label
end

class Feature
  include DataMapper::Resource

  property :id, Serial
  property :feature, Text
  property :feature_type, String
  property :weight, Float

end

class Label
    include DataMapper::Resource

    property :id, Serial
    property :relevant, Integer

    belongs_to :email
end

DataMapper.finalize