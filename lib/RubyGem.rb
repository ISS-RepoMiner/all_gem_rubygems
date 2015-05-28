require 'rubygems/spec_fetcher'
require 'json'
require 'httparty'
require 'concurrent'
require 'gems'
require 'benchmark'
require_relative '../model/gem_spec_download'
require_relative 'no_sql_store'

# this class is used to get the name list of gem in specific form
class RubyGem

  # not sample testing
  def self.workflow_get_all_gem_info
    pool = Concurrent::FixedThreadPool.new(100)
    lock = Mutex.new

    db = NoSqlStore.new
    collection = JSON.load(collection_json)
    collection.each do |x|
      pool.post do
        results = get_gem_info(x)
        if results.class == Array
          results.each do |result|
          # puts "result is #{result}"
            gem_info = GemMiner::GemSpecDownload.new(result["name"],result["version"],result["build_date"],result["authors"],result["github"],result["dependencies"],result["platform"])
            # db.save(gem_info)
            db.save_eventually(gem_info)
          end
        end
      end
    end
    pool.shutdown
    pool.wait_for_termination
  end

  def self.workflow_get_sample_gem_info
    pool = Concurrent::FixedThreadPool.new(100)
    lock = Mutex.new

    db = NoSqlStore.new
    collection = JSON.load(collection_json).sample(1000)
    collection.each do |x|
      pool.post do
        results = get_gem_info(x)
        if results.class == Array
          results.each do |result|
          # puts "result is #{result}"
            gem_info = GemMiner::GemSpecDownload.new(result["name"],result["version"],result["build_date"],result["authors"],result["github"],result["dependencies"],result["platform"])
            # db.save(gem_info)
            db.save_eventually(gem_info)
          end
        end
      end
    end
    pool.shutdown
    pool.wait_for_termination
  end

  # get the information of one gem (all) to be saved to dynamodb later
  def self.get_gem_info(gem_name)
    gem_info = Gems.info gem_name
    signal = RubyGem.check_github(gem_info)
    if signal != "no source"
      github_uri = gem_info[signal]
      gem_versions = Gems.versions gem_name
      dependencies = Gems.dependencies gem_name
      if gem_versions.length == dependencies.length
        sorted_gem_versions = gem_versions.sort_by{ |k| k["number"]}
        sorted_depen = dependencies.sort_by{ |k| k[:number]}
        data = sorted_gem_versions.each_with_index.map{|x,i| {"name"=>gem_name,"version"=>x["number"],"build_date"=>x["built_at"],"authors"=>x["authors"],"github"=>github_uri,"dependencies"=>sorted_depen[i][:dependencies].to_json,"platform"=>x["platform"]}}
      else
        puts "the gem #{gem_name} is updated right now, please try later"
      end
    else
      puts "the gem #{gem_name} does not have a github uri"
    end
    data
  end

  # this will return the latest unique gems name list without version
  def self.collection
    name_list = []
    name_vers = all_collection
    name_vers.each do |x, _y|
      name_list << x
    end
    name_list.uniq
  end

  # just return latest array
  def self.all_collection
    name_vers = []
    fetcher = Gem::SpecFetcher.fetcher
    name_vers_tuple = fetcher.detect(:released) { true }
    name_vers_tuple.each do |x|
      name_vers << [x[0].name, x[0].version.to_s]
    end
    name_vers
  end

  # comparing the difference of old and new
  def self.check_difference(old_array, new_array)
    difference = new_array - old_array
    difference
  end

  # save new result to file and leave it for later usage.
  def self.write_to_file(new_array)
    f = File.open('old_array.txt', 'w')
    new_array.each do |name, ver|
      f.puts name + "\t" + ver
    end
    # f.puts all_collection
    f.close
  end

  # work_flow to chain all the changes together
  def self.work_flow
    old_array = load_from_file('old_array.txt')
    new_array = all_collection
    write_to_file(new_array)
    difference = check_difference(old_array, new_array)
    difference
  end

  # get date of the day before yesterday
  def self.yesterday_date
    today = Time.new
    right_day = today - 3600 * 24 * 2
    right_day.strftime('%Y-%m-%d')
  end

  # get yesterday data in hash format.
  def self.yesterday_json
    yesterday = yesterday_date
    gem_list = collection
    gem_array = []
    gem_list.each do |x|
      gem_unit = {}
      gem_unit['name'] = x
      gem_unit['start_date'], gem_unit['end_date'] = yesterday, yesterday
      gem_array << gem_unit
    end
    gem_array
  end

  # read gem name from github.txt
  def self.open_github
    File.open("github.txt","r") do |f|
      gem_list = []
      f.each_line do |line|
        gem_name = line.split()[0]
        gem_list << gem_name
      end
      gem_list
    end
  end


  # get all the latest unique name of gems in json format
  def self.collection_json
    clt = collection
    clt.to_json
  end



  # start from here in github url getter work


  def self.updating_github_gemlist
    source_uri_set = updating_github_collection
    write_to_github_file(source_uri_set)
    source_uri_set.keys
  end

  # get all the latest name with version of gems in json format
  def self.all_collection_json
    aclt = all_collection
    aclt_hash = Hash.new { |h, k| h[k] = [] }
    aclt.each do |x, y|
      aclt_hash[x] << y
    end
    aclt_hash.to_json
  end

  # get all the latest unique name of gems and the specification from RubyGems.org
  def self.parse_from_remote(gem_name)
    url = 'https://rubygems.org/api/v1/gems/'+gem_name+'.json'
    response = HTTParty.get(url)
    content = response.body
    hash_content = JSON.parse(content)
    hash_content
  end

  # check if the gem is repositoried in github
  def self.check_github(hash_content)
    # puts hash_content["name"]
    if hash_content.has_key?("source_code_uri") and hash_content["source_code_uri"]!=nil
      if hash_content["source_code_uri"].include?("github")
        return "source_code_uri"
      end
    end
    if hash_content.has_key?("homepage_uri") and hash_content["homepage_uri"]!=nil
      if hash_content["homepage_uri"].include?("github")
        return "homepage_uri"
      end
    end
    return "no source"
  end

  # check from the signal and parse the name and source code place in github
  def self.get_source_uri(hash_content, signal)
    if signal=="source_code_uri"
      return {hash_content["name"]=>hash_content["source_code_uri"]}
    elsif signal=="homepage_uri"
      return {hash_content["name"]=>hash_content["homepage_uri"]}
    else
      return "not_found"
    end
  end

  # add all the element to a txt file and send the sequence, I should not have too much http request!!!,use a variable when use it in time.
  def self.add_checked_results(source_uri,source_uri_set)
    if source_uri=="not_found"
      return source_uri_set
    else
      source_uri_set.merge!source_uri
      return source_uri_set
    end
  end

  # set the github_gem with date information
  def self.github_yesterday_json
    gem_list = updating_github_gemlist
    yesterday = yesterday_date
    gem_array = []
    gem_list.each do |x|
      gem_unit = {}
      gem_unit['name'] = x
      gem_unit['start_date'], gem_unit['end_date'] = yesterday, yesterday
      gem_array << gem_unit
    end
    gem_array
  end

  # this part will write get the gem list with github url.
  def self.updating_github_collection
    pool = Concurrent::FixedThreadPool.new(100)
    lock = Mutex.new
    # pool = Concurrent::FixedThreadPool.new(100)
    collections = collection_json
    collections = JSON.load(collections).sample(1000)
    source_uri_set = {}
    collections.each do |x|
      pool.post do
        begin
          hash_content = parse_from_remote(x)
          signal = check_github(hash_content)
          source_uri = get_source_uri(hash_content,signal)
          lock.synchronize { add_checked_results(source_uri, source_uri_set) }
        rescue Exception => msg
          puts msg
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination

    source_uri_set
  end





  def self.write_to_github_file(source_uri_set)
    File.open("github_info.txt","w"){|file| source_uri_set.each do |k,v| file.write(k+"\t"+v+"\n") end}
  end

  # write one by one json format data with a comman in the end of each line
  def self.write_json_all(all_info)
    File.open("jsonfor.json","a") do |f| f.puts all_info.to_json+"," end
  end

  # load the json format I need
  def self.load_json(file)
    f = File.read(file)
    data_hash = JSON.parse(f)
    data_hash
  end





  # first time write
  def self.first_write_all
    pool = Concurrent::FixedThreadPool.new(100)
    lock = Mutex.new

    puts "Getting Full Collection"
    collections = collection_json
    collections = JSON.load(collections)[31000..-1]

    puts "Analyzing each gem source"
    File.open("jsonfor3.json","a") do |f|
      collections.each_with_index do |x, i|
        pool.post do
          begin
            # puts i if i % 10 == 0
            hash_content = parse_from_remote(x)
            out_s = hash_content.to_json+","
            puts "[#{i}] #{out_s[0..40]}"
            lock.synchronize { f.puts out_s }
          rescue Exception => msg
            puts x
            puts msg
          end
        end
      end

      pool.shutdown
      pool.wait_for_termination
    end
  end

  # load older array and save it to old_array
  def self.load_from_file(file_name)
    old_array = []
    f = File.readlines(file_name)
    f.each do |x|
      old_array << x.strip.split
    end
    old_array
  end


end
