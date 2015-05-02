require 'sinatra'
require './RubyGem'

# this is a web service for the gem list generate
class ListingService < Sinatra::Base
  # configure :development, :test do
  #   ConfigEnv.path_to_config("")
  helpers do
    get '/' do
      'Hello World!'
    end

    get '/collection/yesterday' do
      RubyGem.yesterday_json
    end

    get '/collection' do
      RubyGem.collection_json
    end

    get '/all_collection' do
      RubyGem.all_collection_json
    end
  end
end
