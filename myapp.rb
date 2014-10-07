#myapp.rb
require 'sinatra'   				# that's my web server
require 'httparty'    			# this probably does some HTTP stuff
require 'haml'    					# this one is quite good for markup
require 'rack/ssl'			    # without this we probably can't run
require 'json'					    # this is how we talk
require './models/golf'     # golf module

# TODO: initialise the key.json files

def is_number?(object)
  true if Float(object) rescue false
end



class McGolf < Sinatra::Application
  
  #######################################################################
  #                              STATIC STUFF                           #
  #######################################################################

  COURSE_DIR = File.join(Dir.pwd,'courses')
  COURSE_KEY = File.join(COURSE_DIR,'key.txt')

  RESULT_DIR = File.join(Dir.pwd, 'results')
  RESULT_KEY = File.join(RESULT_DIR, 'key.txt')

  PLAYER_DIR = File.join(Dir.pwd, 'players')

  TOUR_FILE  = File.join(Dir.pwd, 'tourname.txt')

  ERROR_FILE = File.join(Dir.pwd, 'errors.json')

  # Get the name of the tour 
  TOUR_NAME = File.read(TOUR_FILE)
  IS_INITIALISED = TOUR_NAME.empty? == false

  def initialise
    unless IS_INITIALISED
      redirect '/init', 302
    end
  end

  #######################################################################
  #                        ALL ABOUT THE PLAYERS                        #
  #######################################################################

  get '/' do
    initialise
    # the root page will show some info about the players
    @info = Golf::Player.get_all
  	haml :index
  end

  get '/playerz/:id' do
    # open the player file
    @info = Golf::Player.load(params["id"])
    haml :playerzinfo
  end
  
  #######################################################################
  #                      BULK UPDATE OF HANDICAPS                       #
  #######################################################################
 
  get '/update-hcps' do
    @info = Golf::Player.get_all
  	haml :updatehcps
  end
  
  post '/update-hcps' do
    # TODO: security....?
    # The payload is {id1 => hcp1, id2 => hcp2, id3 => hcp3, ad nauseum}

    params.each do |p|
      unless p[1].empty?
        player = Golf::Player.load(p[0])
        player.Handicap = p[1]
        player.save!
      end
    end
    redirect '/',302 
  end
  #######################################################################
  #                         BULK UPDATE OF POINTS                       #
  #######################################################################
 
  get '/update-points' do
    @info = Golf::Player.get_all
  	haml :updatepoints
  end
  
  post '/update-points' do
    # TODO: security....? 

    params.each do |p| 
      unless p[1].empty?
        player = Golf::Player.load(p[0])
        player.Points = p[1]
        player.save!
      end

    end
    redirect '/',302 
  end
      
  #######################################################################
  #                    ADDING NEW MEMBERS TO THE TOUR                   #
  #######################################################################
    
  get '/newplayer' do
  	haml :newplayer
  end
  
  post '/newplayer' do
    # TODO: security....?
    # add the player 
    new_player = Golf::Player.create!(params["PlayerName"],params)
    redirect "/playerz/#{params["PlayerName"]}",302
  end

  #######################################################################
  #                           ERROR HANDLING                            #
  #######################################################################
  
  # TODO: don't do it like this...
  get '/error' do
    errors = JSON.parse(File.read(ERROR_FILE))
    @errormsg = errors[params[:n]]
    haml :errormsg
  end

  #######################################################################
  #                                   ADMIN LINKS                       #
  #######################################################################
 
  get '/adminabc' do
    haml :adminabc
  end

  #######################################################################
  #                         INITIALISE THE SYSTEM                       #
  #######################################################################
 
  get '/init' do
    haml :init
  end

  post '/init' do
    TOUR_NAME = params[:comp] # This is not nice...
    File.open(TOUR_FILE,'w') do |f|
      File.write(f,TOUR_NAME.to_s)
    end
    File.open(COURSE_KEY, 'w') do |f|
      File.write(f,0)
    end
    File.open(RESULT_KEY, 'w') do |f|
      File.write(f,0)
    end
    IS_INITIALISED = true
    redirect '/',302
  end

  #######################################################################
  #              ADDING RESULTS - THIS IS THE NEXT BIT!                 #
  #######################################################################
 
  get '/newresult' do
    @players = [] # initialise the array

    Dir.glob(File.join(PLAYER_DIR,'*.player.json')).each do |f|
      @players.push(JSON.parse(File.read(f)))
    end   
    haml :newresult
  end

  post '/newresult' do
    # determine the next round ID
    id = (File.read(RESULT_KEY)).to_i + 1
    File.open(RESULT_KEY,'w') do |f|
      f.write(id)
    end 

    puts result_file = File.join(RESULT_DIR,"#{id}.result.json")   

    # get the data
    roundnum  = params[:id]
    rounddate = params[:date]
    positions = params[:position]
    # initialise some things
    points  = []
    players = []

    positions.each do |p|
      if p[1] == "Select a player" then
        # do nothing with this one
      else
        points.push(0) # add the player to the end of the points matrix
        players.push(p[1]) # index the players name
        points = points.map { |e| e + 1 }
      end
    end
    # add bonus for 1st and 2nd
    if points.count == 0 then
      redirect '/error?n=3',302
    elsif points.count == 1 then
      points = [2]
    elsif points.count == 2 then
      points = [3,1]
    else
      points[0] += 2
      points[1] += 1
    end
    puts points.inspect
    puts players.inspect

    File.open(result_file,'w') do |f|
      f.write(Hash[*players.zip(points).flatten].to_json)
    end
    redirect '/',302
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

  error do
    'Error: ' + env['sinatra.error'].message
  end



end
