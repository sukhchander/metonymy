module Handler

	Handler::HTTP_CODES = {
		200 => "OK",
		201 => "Created",
		202 => "Accepted",
		203 => "Non-Authoritative Information",
		204 => "No Content",
		205 => "Reset Content",
		206 => "Partial Content",
		300 => "Multiple Choices",
		301 => "Moved Permanently",
		302 => "Found",
		303 => "See Other",
		304 => "Not Modified",
		305 => "Use Proxy",
		307 => "Temporary Redirect",
		400 => "Bad Request",
		401 => "Unauthorized",
		402 => "Payment Required",
		403 => "Forbidden",
		404 => "Not Found",
		405 => "Method Not Allowed",
		406 => "Not Acceptable",
		407 => "Proxy Authentication Required",
		408 => "Request Timeout",
		409 => "Conflict",
		410 => "Gone",
		411 => "Length Required",
		412 => "Precondition Failed",
		413 => "Request Entity Too Large",
		414 => "Request-URI Too Long",
		415 => "Unsupported Media Type",
		416 => "Requested Range Not Satisfiable",
		417 => "Expectation Failed",
		500 => "Server Error",
		501 => "Not Implemented",
		502 => "Bad Gateway",
		503 => "Service Unavailable",
		504 => "Gateway Timeout",
		505 => "HTTP Version Not Supported"
	}

	module Error

		class Http < Exception
			attr :error_code, true

			def error_message
				Handler::HTTP_CODES[error_code]
			end
		end

		class RestNotFound < Http
			@@error_code = 404
			def error_code
				@@error_code
			end
		end 

		class RestBadRequest < Http 
			@@error_code = 400
			def error_code
				@@error_code
			end
		end 

		class RestUnauthorized < Http 
			@@error_code = 401
			def error_code
				@@error_code
			end
		end 

		class RestForbidden < Http 
			@@error_code = 403
			def error_code
				@@error_code
			end
		end 

		class RestInternalServerError < Http 
			@@error_code = 500
			def error_code
				@@error_code
			end
		end 

		class RestMethodNotAllowed < Http 
			@@error_code = 405
			def error_code
				@@error_code
			end
		end 

		class RestNotAcceptable < Http 
			@@error_code = 406
			def error_code
				@@error_code
			end
		end 

		class RestConflict < Http 
			@@error_code = 409
			def error_code
				@@error_code
			end
		end 

	end

end
