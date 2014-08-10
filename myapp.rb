#myapp.rb
require 'sinatra'				# that's my web server
require 'httparty'			# this probably does some HTTP stuff
require 'haml'					# this one is quite good for markup
require 'rack/ssl'			# without this we probably can't run
require 'json'					# this is how we talk

class McGolf < Sinatra::Application

  # Static stuff
  COURSE_DIR = File.join(Dir.pwd,'courses')
  COURSE_KEY = File.join(COURSE_DIR,'key.json')

  get '/' do
  	haml :index
  end
  
  get '/sonia' do
  	haml :sonia
  end
  
  get '/newcourse' do
  	# determine the next ID
    #info = []
    data = JSON.parse(File.read(COURSE_KEY))
    @id = data["key"] + 1
    data["key"] = @id
    File.open(COURSE_KEY,'w') do |f|
      f.write(data.to_json)
    end
  	haml :newcourse
  end

  post '/newcourse' do
    # store the course
    filename = File.join(COURSE_DIR,params["id"]+'.course.json')
    File.open(filename,'w') do |f|
      f.write(params.to_json)
    end
  redirect "/courses",302
  end

  get '/courses' do
    @courses = [] # an array with all of our courses
    # get the list of courses
    Dir.glob(File.join(COURSE_DIR,"*.course.json")).each do |f|
      contents = JSON.parse(File.read(f))
      @courses.push(contents)
    end
    haml :courses
  end

  get '/courses/:number' do
    filename = File.join(COURSE_DIR,params[:number] +'.course.json')
    @info = JSON.parse(File.read(filename))
    haml :coursedeets
  end




end
