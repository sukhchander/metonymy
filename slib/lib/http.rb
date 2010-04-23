class HttpHeader
	attr :version, true
	attr :status_code, true
	attr :status_message, true
	attr :headers, true

	def initialize(header_str)
		@headers = {}
		_parse_header(header_str)
	end

	def _parse_header(header_str)
		headers = header_str.split("\r\n")
		_parse_status_line(headers.shift)
		headers.each { |header|
			values = header.split(":")
			name = values.shift
			value = values.join(":")
			@headers[name] = value
		}
	end

	def _parse_status_line(status_line)
		statuses = status_line.split
		http_version = statuses.shift
		@version = http_version.split('/')[1]
		@status_code = statuses.shift.to_i
		@status_message = statuses.join(" ")
	end
end

class HttpException < Exception
	attr :status_code
	def initialize(status_code)
		@status_code = status_code
	end
end

module HttpLib
	def HttpLib.raise_not_success(status_code)
		if status_code < 200 or status_code > 299
			raise HttpException.new(status_code)
		end
	end
end
