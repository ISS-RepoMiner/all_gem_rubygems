require 'sinatra'
require './RubyGem'

class ListingService < Sinatra::Base
  # configure :development, :test do
  #   ConfigEnv.path_to_config("")
  helpers do
    get '/hi' do
      "Hello World!"
    end

    get '/get_yesterday' do
      RubyGem.get_yesterday_json
    end

    get '/collection' do
      RubyGem.get_collection_json
    end

    get '/all_collection' do
      RubyGem.get_all_collection_json
    end

  end
end
