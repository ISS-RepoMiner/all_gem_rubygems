class RubyGem
	def self.collection
		cli = "gem list -r"
        list = `#{cli}`
        y=list.split("\n")
        y.each do |x| 
        	puts x.split(" ")[0]        
        end
	end

end

