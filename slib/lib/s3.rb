require 'aws/s3'

module AWS
	module S3
		class S3Object
			#There is no reason to hit the server over and over for data you already have.
			def attributes
				@attributes
			end
		end
	end
end
