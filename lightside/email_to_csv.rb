require 'mail'
require 'csv'

ROOT_PATH = "/Users/greg/Documents/mit/scifi/lawyer/code/disco/data/emails/cuilla-m/"

labels = {}
CSV.foreach("labels.csv") do |row|
	labels[row[1]] = row[0].to_i
end

puts labels.inspect

CSV.open("cuilla_data.csv", "wb") do |csv|
	csv << ["label", "body", "subject"]

	mails = Dir.entries(ROOT_PATH + "/sent").select{|f| f =~ /[^\.]/ && f != "entities"}
	mails.each_with_index do |filename, i|
		puts "#{i+1}/#{mails.length}"
		mail_path = ROOT_PATH + "sent/" + filename
		mail = Mail.read(mail_path)

		label = labels[mail_path]
		body = mail.body.decoded
		subject = mail.subject

		csv << [label, body, subject]

	end

end