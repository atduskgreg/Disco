require 'csv'
require "#{File.expand_path(File.dirname(__FILE__))}/../models.rb"

CSV.foreach("#{File.expand_path(File.dirname(__FILE__))}/../data/cuilla_data_ids.csv") do |row|
# uuid,label,time,from,subject,body	
	Email.create(
		:uuid => row[0],
		:sent_time => row[2].to_f,
		:from => row[3],
		:subject => row[4],
		:body => row[5]
		)
end