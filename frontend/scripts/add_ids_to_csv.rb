require 'csv'
require 'SecureRandom'

CSV.open("data/cuilla_data_ids.csv", "wb") do |csv|
	CSV.foreach("data/cuilla_data.csv") do |row|
		if row[0] == "label"
			csv << (["uuid"] << row).flatten
		else
			csv << ([SecureRandom.uuid] << row).flatten
		end
	end
end