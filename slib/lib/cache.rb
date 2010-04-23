module Cacheing

	def self.cache_grab(*params)
		ret_obj = nil
		key = build_key(*params)
		unmarshaled = cache_get(key)
		unless unmarshaled.nil?
			ret_obj = Marshal.load(unmarshaled)
		else
			ret_obj = yield
			cache_set(key, ret_obj)
		end
		ret_obj
	end

private

	def self.cache_get(key)
		#Handler::Base.logger.debug("Fetching - " + key)
		CACHE.get(key)
	end

	def self.cache_set(key, data)
		#Handler::Base.logger.debug("Cacheing - " + key + ": " + data.to_s)
		obj = Marshal.dump(data)
		CACHE.set(key, obj) unless obj.nil?
	end

	def self.build_key(*params)
		type,obj=*params
		attrs=[type,obj]
		attrs.join('_').gsub(' ','_').downcase unless (type.nil? and obj.nil?)
	end

end
