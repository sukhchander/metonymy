module Handler
  
	module Base
	  
		def Base.logger
			@@logger
		end

		def Base.logger=(logger)
			@@logger = logger
		end

		def logger
			@@logger
		end

		def call(env)
			req = Rack::Request.new(env)
			resp = Rack::Response.new
			begin
				if req.head?
					validate_required_head_args(req)
					head(req, resp)
				elsif req.get?
					validate_required_get_args(req)
					get(req, resp)
				elsif req.post?
					validate_required_post_args(req)
					post(req, resp)
				elsif req.put?
					validate_required_put_args(req)
					put(req, resp)
				elsif req.delete?
					validate_required_delete_args(req)
					delete(req, resp)
				end
			rescue Handler::Error::Http => httpe
				resp.status = httpe.error_code

				accept_header = req.accept().strip.split(',')[0]
				pp httpe
				if accept_header.eql?("application/json")
					resp.body = { :type => "Exception", :message => httpe.message }.to_json + "\n"
				elsif accept_header.eql?("text/html")
					resp.body = "<h1>#{httpe.error_message}</h1>\n" +
						httpe.message + "\n"
				else
					resp.body = "#{httpe.message}\n"
				end
			end
			finish(req, resp)
		end

		def head(req, resp)
			raise Handler::Error::RestMethodNotAllowed.new("HEAD not implemented")
		end

		def get(req, resp)
			raise Handler::Error::RestMethodNotAllowed.new("GET not implemented")
		end

		def post(req, resp)
			raise Handler::Error::RestMethodNotAllowed.new("POST not implemented")
		end

		def put(req, resp)
			raise Handler::Error::RestMethodNotAllowed.new("PUT not implemented")
		end

		def delete(req, resp)
			raise Handler::Error::RestMethodNotAllowed.new("DELETE not implemented")
		end

		def finish(req, resp)
			if req.head?
				finish_head(req, resp)
			elsif req.get?
				finish_get(req, resp)
			elsif req.post?
				finish_post(req, resp)
			elsif req.put?
				finish_put(req, resp)
			elsif req.delete?
				finish_delete(req, resp)
			end
		end

		def finish_head(req, resp)
			resp.finish
		end

		def finish_get(req, resp)
			resp.finish
		end

		def finish_post(req, resp)
			resp.finish
		end

		def finish_put(req, resp)
			resp.finish
		end

		def finish_delete(req, resp)
			resp.finish
		end

		def required_head_args
			[]
		end

		def required_get_args
			[]
		end

		def required_post_args
			[]
		end

		def required_put_args
			[]
		end

		def required_delete_args
			[]
		end

		def validate_required_head_args(req)
			validate_required_args(req, required_head_args)
		end

		def validate_required_get_args(req)
			validate_required_args(req, required_get_args)
		end

		def validate_required_post_args(req)
			validate_required_args(req, required_post_args)
		end

		def validate_required_put_args(req)
			validate_required_args(req, required_put_args)
		end

		def validate_required_delete_args(req)
			validate_required_args(req, required_delete_args)
		end

		def validate_required_args(req, args)
			errorstr = ""
			error = false
			args.each { |arg|
				if errorstr != ""
					errorstr = errorstr + ", "
				end
				errorstr = errorstr + arg
				unless req.params.has_key?(arg)
					error = true
					errorstr = errorstr + " (*)"
				end
			}
			raise Handler::Error::RestBadRequest.new("Required parameters missing: " + errorstr) if error
		end

		def path?(req, path)
            path=false
			path=true if req.path_info == path or req.path_info == path + "/"
            path
		end

		def split_path(req)
			path, ext = get_ext(req)
			path.split("/").select { |chunk| chunk unless chunk == "" }
		end

		def get_extension(req)
			ext = nil
			chunks = req.path_info.split(".")
			ext = chunks.pop if chunks.size > 1
			[chunks.join("."), ext]
		end
	
	end
	
end
