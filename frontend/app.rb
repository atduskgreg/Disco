require 'sinatra'
require './models'
require 'rack'

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get "/" do
	if params.keys.include? "q"
		puts "searching"
		if params.keys.include? "field"
			if params["field"] == "subject"
				@emails = Email.all(:subject.like => "%#{params["q"]}%")

			elsif params["field"] == "body"
				@emails = Email.all(:body.like => "%#{params["q"]}%")
			end
		else 
			@emails = Email.all(:subject.like => "%#{params["q"]}%") + Email.all(:body.like => "%#{params["q"]}%")
		end
	else 
		@emails = Email.all
	end
	
	erb :index
end

get "/features" do
	if params["sort"] == "asc"
		puts "asc"
		@features = Feature.all(:order => [:weight.asc], :limit => 100)
	else 
		@features = Feature.all(:order => [:weight.desc], :limit => 100)
	end
	erb :features
end