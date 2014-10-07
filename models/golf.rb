# Dependencies
require 'json'
require 'csv'

# Golf module!

module Golf
  # Generic blob class to contain file writing stuff

  # Course class
  class Course
  end
  # Player class
  class Player
    FILE_IDENTIFIER = ".player.json"
    PLAYER_DIR = File.join(Dir.pwd, 'players')

    # Accessors
    attr_accessor :PlayerName, :Handicap, :Points

    def to_json
      {:PlayerName => @PlayerName, :Handicap => @Handicap, :Points => @Points}.to_json
    end

    def self.create!(name,options={})
      # Make a new player (as long as they have a unique name)
      begin
        my_file = File.join(PLAYER_DIR,"#{name}#{FILE_IDENTIFIER}")
        if File.exists?(my_file)
          raise "#{my_file} already exists"
        else
          my_player = Golf::Player.new(name,options)
          my_player.save!
          my_player
        end
      rescue
        raise "An unspecified error occured when creating the new player"
      end
    end

    def save!
      # Write the file
      puts "Saving!"
      begin
        my_file = File.join(PLAYER_DIR,"#{self.PlayerName}#{FILE_IDENTIFIER}")
        File.open(my_file,'w') do |f|
          f.write(self.to_json)
        end
      rescue
        raise "Failed to write file #{my_file}"
      end
    end


    def self.load(name)
      # Load data from JSON file
      begin
        my_file = File.join(PLAYER_DIR,"#{name}#{FILE_IDENTIFIER}")
        Golf::Player.new(name,JSON.parse(File.read(my_file)))
      rescue
        raise "There was a problem loading the file #{my_file}"
      end
    end

    def initialize(name,options={})
      options.each { |k,v| instance_variable_set("@#{k}", v) }
      self
    end

    def self.get_all
      players = []
      Dir.glob(File.join(PLAYER_DIR,"*#{FILE_IDENTIFIER}")).each do |p|
        players << Golf::Player.load(p.split('/').last.split('.').first)
      end
      players
    end


  end
end