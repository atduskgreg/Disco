require 'mail'

ROOT_PATH = "/Users/greg/Documents/mit/scifi/lawyer/enron_mail_20110402/maildir/cuilla-m"

minTime = 10000000000
maxTime = -10000

mails = Dir.glob(ROOT_PATH + "/**/*.")
mails.each_with_index do |filename, i|
	puts "#{i+1}/#{mails.length}"
	mail = Mail.read(filename)
	time = mail.date.to_time.to_i

	if time > maxTime
		maxTime = time
	end

	if time < minTime
		minTime = time
	end
end

puts "min: #{minTime} | max: #{maxTime}"