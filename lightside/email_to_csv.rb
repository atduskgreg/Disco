require 'mail'
require 'csv'

ROOT_PATH = "/Users/greg/Documents/mit/scifi/lawyer/enron_mail_20110402/maildir/cuilla-m"

# calculate these values using calculate_date_range.rb
min_time = 949907760.0
max_time = 1009910657.0

labels = {}
CSV.foreach("labels.csv") do |row|
	labels[row[1]] = row[0].to_i
end

addresses = open("addresses.csv").read.split("\n")

CSV.open("cuilla_data.csv", "wb") do |csv|
	csv << ["label", "time", "from", "subject", "body"]

	mails = Dir.glob(ROOT_PATH + "/**/*.")
	mails.each_with_index do |filename, i|
		puts "#{i+1}/#{mails.length}"
		mail = Mail.read(filename)

		label = labels[filename]
		body = mail.body.decoded
		subject = mail.subject
		# express time as 0.0-1.0
		raw_time = mail.date.to_time.to_i
		time = ((raw_time - min_time)/(max_time - min_time)).round(3)

		from = mail.from[0]

		csv << [label, time, from, subject, body]
	end
end