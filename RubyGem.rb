
# class RubyGem
# 	def self.collection
# 		cli = "gem list -r"
#         list = `#{cli}`
#         y=list.split("\n")
#         y.each do |x|
#         	puts x.split(" ")[0]
#         end
# 	end
# end
require 'rubygems/spec_fetcher'

class RubyGem

	# this will return the latest unique gems name list without version
	def self.collection
		name_list=[]
		name_vers = all_collection
		name_vers.each do |x,y|
			name_list << x
		end
		name_list.uniq
	end

	# load older array and save it to old_array
	def self.load_from_file(file_name)
		old_array = []
		f = File.readlines(file_name)
		f.each do |x|
			old_array << x.strip().split()
		end
		old_array
	end

	# just return latest array
	def self.all_collection
		name_vers=[]
		fetcher = Gem::SpecFetcher.fetcher
		name_vers_tuple = fetcher.detect(:released) {true}
		name_vers_tuple.each do |x|
			name_vers << [x[0].name,x[0].version.to_s()]
		end
		name_vers
	end

	# comparing the difference of old and new
	def self.check_difference(old_array, new_array)
		difference = new_array-old_array
		difference
	end

	# save new result to file and leave it for later usage.
	def self.write_to_file(new_array)
		f = File.open("old_array.txt", "w")
		new_array.each do |name,ver|
			f.puts name+"\t"+ver
		end
		# f.puts all_collection
		f.close
	end

	# work_flow to chain together
	def self.work_flow
		old_array = load_from_file("old_array.txt")
		new_array = all_collection
		write_to_file(new_array)
		difference = check_difference(old_array,new_array)
		difference
	end

end
