require 'rubygems/spec_fetcher'
require 'json'

# this class is used to get the name list of gem in specific form
class RubyGem
  # this will return the latest unique gems name list without version
  def self.collection
    name_list = []
    name_vers = all_collection
    name_vers.each do |x, _y|
      name_list << x
    end
    name_list.uniq
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

  # set the github_gem with date information
  def self.github_yesterday_json
    gem_list = open_github
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


  # get all the latest unique name of gems in json format
  def self.collection_json
    clt = collection
    clt.to_json
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
end
