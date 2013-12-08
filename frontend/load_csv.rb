require 'csv'
require './models'

CSV.foreach("cuilla_data.csv") do |row|
# label,time,from,subject,body	
	Email.create(
		#:label => row[0],
		:sent_time => row[1].to_f,
		:from => row[2],
		:subject => row[3],
		:body => row[4]
		)
end