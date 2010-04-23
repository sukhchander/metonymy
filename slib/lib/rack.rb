module Rack
	class Request
		def accept
			@env['HTTP_ACCEPT']
		end

		def authorization
			@env['HTTP_AUTHORIZATION']
		end
	end
end
