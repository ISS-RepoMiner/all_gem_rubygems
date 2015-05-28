require 'sinatra'
require_relative 'lib/RubyGem'
require_relative 'lib/GemMapQueue'

# this is a web service for the gem list generate
class ListingService < Sinatra::Base
  # configure :development, :test do
  #   ConfigEnv.path_to_config("")
  helpers do
    get '/' do
      'Hello World!'
    end

    # this function will send all the gem from rubygems.org yesterday
    get '/collection/yesterday' do
      hash_data = RubyGem.yesterday_json
      queue = GemMiner::GemMapQueue.new('GemMap')
      queue.send_message_batch(hash_data)
      "success"
      # hash_data.to_json
    end

    # this function send all the gem which has a github url
    get '/github/collection/yesterday' do
      hash_data = RubyGem.github_yesterday_json
      queue = GemMiner::GemMapQueue.new('GemMap')
      queue.send_message_batch(hash_data)
      "success"
    end

    get '/workflow_get_all_gem_info' do
      RubyGem.workflow_get_all_gem_info
      "success"
    end

    get '/workflow_get_sample_gem_info' do
      RubyGem.workflow_get_sample_gem_info
      "success"
    end

    get '/collection' do
      RubyGem.collection_json
    end

    get '/all_collection' do
      RubyGem.all_collection_json
    end

  end
end
