
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

	def self.all_collection
		name_vers=[]
		fetcher = Gem::SpecFetcher.fetcher
		name_vers_tuple = fetcher.detect(:released) {true}
		name_vers_tuple.each do |x|
			name_vers<<x[0]
		end
		name_vers
	end		
	
	def self.collection
		name_list=[]
		name_vers = all_collection
		name_vers.each do |x|
			name_list << x.name
		end
		name_list.uniq
	end
end
