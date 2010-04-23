require 'net/http'

module Net
	class HTTP
		alias_method :orig_request, :request
		def request(req, body = nil, &block)
			puts "12345678900987654321"
			orig_request(req, body, &block)
		end
	end
end
