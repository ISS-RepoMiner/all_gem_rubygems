require 'sinatra'
require './RubyGem'

class ListingService < Sinatra::Base
  # configure :development, :test do
  #   ConfigEnv.path_to_config("")
  helpers do
    get '/' do
      "Hello World!"
    end

    get '/get_yesterday' do
      RubyGem.get_yesterday_json
    end


  end
end
