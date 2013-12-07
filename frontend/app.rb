require 'sinatra'
require './models'
require 'rack'
require 'json'

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

	@relevant = Label.all(:relevant => 1).collect{|label| label.email}
	
	erb :emails
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

post "/emails/:email_id/labels" do
	# content_type :json

	relevant = params[:relevant] == "relevant" ? 1 : 0

	email = Email.get params[:email_id]
	email.assign_label relevant
	redirect back
	# {:email => {:id => email.id}, :label => {:id => email.label.id, :relevant => email.label.relevant}}.to_json
end

