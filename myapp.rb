#myapp.rb
require 'sinatra'				# that's my web server
require 'httparty'			# this probably does some HTTP stuff
require 'haml'					# this one is quite good for markup
require 'rack/ssl'			# without this we probably can't run
require 'json'					# this is how we talk

class McGolf < Sinatra::Application

  get '/' do
  	haml :index
  end
  
  get '/newcourse' do
  	# determine the next ID
  	
  	@id = 1
  
  	haml :newcourse
  end
end
