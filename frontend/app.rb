require 'sinatra'
require './models'
require 'rack'

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get "/" do
			puts params.inspect

	if params.keys.include? "q"
		puts "searching"
		@emails = Email.all(:subject.like => "%#{params["q"]}%")
	else 
		@emails = Email.all
	end
	
	erb :index
end