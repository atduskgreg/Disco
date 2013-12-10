require "#{File.expand_path(File.dirname(__FILE__))}/../models.rb"

s = open("#{File.expand_path(File.dirname(__FILE__))}/../data/cuilla_data_ids_labeled.csv").read
s.force_encoding("UTF-8")
s.split(/\n/).collect{|line| line.split(",")}.each do |row|
	label_prediction = row[2].to_i
	uuid = row[4]

	email = Email.first :uuid => uuid

	Prediction.create :email => email, :relevant => label_prediction
end