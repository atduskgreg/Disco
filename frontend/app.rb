require 'sinatra'
require './models'
require 'rack'
require 'json'
require 'sinatra/partial'

configure do
	set :partial_template_engine, :erb
	use Rack::MethodOverride
end

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

	all_labels = Label.all
	@relevant = all_labels.select{|label| label.relevant == 1}.collect{|label| label.email}
	@irrelevant = all_labels.select{|label| label.relevant == 0}.collect{|label| label.email}
	
	erb :emails
end

get "/features" do
	if params["sort"] == "asc"
		puts "asc"
		@features = Feature.all(:order => [:weight.asc], :limit => 100)
	else 
		@features = Feature.all(:order => [:weight.desc], :limit => 100)
	end
	
	all_labels = Label.all
	@relevant = all_labels.select{|label| label.relevant == 1}.collect{|label| label.email}
	@irrelevant = all_labels.select{|label| label.relevant == 0}.collect{|label| label.email}

	erb :features
end

post "/emails/:email_id/labels" do
	puts params.inspect

	relevant = params[:relevant] == "relevant" ? 1 : 0
	puts relevant
	email = Email.get params[:email_id]
	email.assign_label relevant
	redirect back
end

delete "/emails/:email_id/label" do
	label = Label.first :email_id => params[:email_id]
	label.destroy
	redirect back
end
