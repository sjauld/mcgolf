#myapp.rb
require 'sinatra'				# that's my web server
require 'httparty'			# this probably does some HTTP stuff
require 'haml'					# this one is quite good for markup
require 'rack/ssl'			# without this we probably can't run
require 'json'					# this is how we talk

# TODO: add .gitignore stuff, initialise the key.json files

class McGolf < Sinatra::Application
  
  #######################################################################
  #                              STATIC STUFF                           #
  #######################################################################

  COURSE_DIR = File.join(Dir.pwd,'courses')
  COURSE_KEY = File.join(COURSE_DIR,'key.json')

  PLAYER_DIR = File.join(Dir.pwd,'players')
  PLAYER_KEY = File.join(PLAYER_DIR,'key.json')
  
  #######################################################################
  #                        ALL ABOUT THE PLAYERS                        #
  #######################################################################

  get '/' do
    # the root page will show some info about the players
    @info = []
    
    # Read the files from the players directory
    Dir.glob(File.join(PLAYER_DIR,'*.player.json')).each do |f|
      @info.push(JSON.parse(File.read(f)))
    end
  	haml :index
  end
  
  get '/playerz/:id' do
    # open the player file
    @info = JSON.parse(File.read(File.join(PLAYER_DIR,"#{params['id']}.player.json")))
    haml :playerzinfo
  end
  
  #######################################################################
  #                      BULK UPDATE OF HANDICAPS                       #
  #######################################################################
 
  get '/updato' do
    @info=[]
    # Read the files from the players directory
    Dir.glob(File.join(PLAYER_DIR,'*.player.json')).each do |f|
      @info.push(JSON.parse(File.read(f)))
    end
  	haml :updato
  end
  
  post '/updato' do
    # TODO: security....?
    
    # The payload is {id1 => hcp1, id2 => hcp2, id3 => hcp3, ad nauseum}
    
    params.each do |p|
      filename = File.join(PLAYER_DIR,"#{p[0]}.player.json")
      data = JSON.parse(File.read(filename))
      data["Handicap"] = p[1]
      File.open(filename,'w') do |f|
        f.write(data.to_json)
      end
    end
    redirect '/',302 
  end
  #######################################################################
  #                         BULK UPDATE OF POINTS                       #
  #######################################################################
 
  get '/updatop' do
    @info=[]
    # Read the files from the players directory
    Dir.glob(File.join(PLAYER_DIR,'*.player.json')).each do |f|
      @info.push(JSON.parse(File.read(f)))
    end
  	haml :updatop
  end
  
  post '/updatop' do
    # TODO: security....?
    
    # The payload is {id1 => hcp1, id2 => hcp2, id3 => hcp3, ad nauseum}
    
    params.each do |p|
      filename = File.join(PLAYER_DIR,"#{p[0]}.player.json")
      data = JSON.parse(File.read(filename))
      data["points201415"] = p[1]
      File.open(filename,'w') do |f|
        f.write(data.to_json)
      end
    end
    redirect '/',302 
  end
      
  #######################################################################
  #                    ADDING NEW MEMBERS TO THE TOUR                   #
  #######################################################################
    
  get '/newplayer' do
    # determine the next ID
    data = JSON.parse(File.read(PLAYER_KEY))
    @id = data["key"] + 1
    data["key"] = @id
    File.open(PLAYER_KEY,'w') do |f|
      f.write(data.to_json)
    end
  	haml :newplayer
  end
  
  post '/newplayer' do
    # TODO: security....?
    # add the player 
    filename = File.join(PLAYER_DIR,params["id"]+'.player.json')
    unless params["Handicap"].to_i.to_s == params["Handicap"]
      # do something about incorrect handicap entry
      puts "Handicap Error!!!!"
    end
    if File.exists?(filename) # check that we're not overwriting anyone
      # some kind of error
      puts "We're overwriting someone!!!"
    else
      File.open(filename,'w') do |f|
        f.write(params.to_json)
      end
    end
    redirect '/',302
  end

  #######################################################################
  #              ADDING RESULTS - THIS IS THE NEXT BIT!                 #
  #######################################################################
 
  get '/result' do
    haml :result
  end
  
  #######################################################################
  # COURSES - THIS IS FOR WHEN HANDICAPPING CALCS ARE MANAGED BY MCGOLF #
  #######################################################################
  
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
    # TODO: security....?
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
