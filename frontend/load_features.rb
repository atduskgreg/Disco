require 'csv'
require './models'

s = open("positive_feature_table.csv").read
s.force_encoding("UTF-8")

s.split(/\n/).collect{|line| line.split(",")}.each do |row|
# CSV.foreach(s) do |row|
	#Feature,Feature Weight
	feature = Feature.new
	feature.weight = row[1].to_f
	feature.feature_type = "string"
	feature.feature = row[0]
	if row[0] =~ /__column/
		feature.feature_type = "column"
		feature.feature = row[0].split("__")[0]
	end
	if row[0] =~ /_subject$/
		feature.feature_type = "subject"
		feature.feature = row[0].split("_subject")[0]
	end
	if row[0] =~ /_body$/
		feature.feature_type = "body"
		feature.feature = row[0].split("_body")[0]
	end
	if row[0] =~ /__rx/
		feature.feature_type = "regex"
		feature.feature = row[0].split("__")[0]
	end

	feature.save

end