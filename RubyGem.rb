
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

	# just return a
	def self.all_collection
		name_vers=[]
		fetcher = Gem::SpecFetcher.fetcher
		name_vers_tuple = fetcher.detect(:released) {true}
		name_vers_tuple.each do |x|
			name_vers << [x[0].name,x[0].version.to_s()]
		end
		name_vers
	end

	# this will return the latest unique gems name list without version
	def self.collection
		name_list=[]
		name_vers = all_collection
		name_vers.each do |x,y|
			name_list << x
		end
		name_list.uniq
	end

	def self.check_difference

	end

end
