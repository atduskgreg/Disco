require 'dm-core'
require  'dm-migrations'

# DataMapper.setup(:default, ENV['DATABASE_URL'] || {:adapter => 'yaml', :path => "db"})
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost:5432/disco')

class Email
  include DataMapper::Resource
  
  property :id, Serial
  property :subject, Text
  property :body, Text
  property :from, Text
  property :sent_time, Float
end

DataMapper.finalize