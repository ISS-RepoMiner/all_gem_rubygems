require 'sinatra'
require './RubyGem'
require './GemMapQueue'

# this is a web service for the gem list generate
class ListingService < Sinatra::Base
  # configure :development, :test do
  #   ConfigEnv.path_to_config("")
  helpers do
    get '/' do
      'Hello World!'
    end

    get '/collection/yesterday' do
      hash_data = RubyGem.yesterday_json
      queue = GemMiner::GemMapQueue.new('GemMap')
      queue.send_message_batch(hash_data.to_json)
      # hash_data.to_json
    end

    get '/collection' do
      RubyGem.collection_json
    end

    get '/all_collection' do
      RubyGem.all_collection_json
    end
  end
end
