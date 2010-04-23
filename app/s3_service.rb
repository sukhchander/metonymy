require 'lib/s3'

class S3Service
    include Handler::Base
    include Handler::Error

    def initialize(access_key_id, secret_access_key, use_ssl, image_bucket, image_cache_dir)
        AWS::S3::Base.establish_connection!(
            :access_key_id => access_key_id,
            :secret_access_key => secret_access_key,
            :use_ssl => use_ssl,
            :persistent => true
        )
        @image_cache_dir = normalize_dir_name(image_cache_dir)
        @image_bucket = image_bucket
    end

    def validate_required_args(req, args)
        return true
        return if req.authorization.eql?SHARED_SECRET

        cookie = req.cookies['_20x200_session']
        unless cookie.nil?
            session = cookie.strip
            if session.nil?
                raise Handler::Error::RestForbidden.new("Request not authorized")
            end
        else
            raise Handler::Error::RestForbidden.new("Request not authorized")
        end
    end

    def parse_path(req)
        path = req.path_info 
        "" if path.eql?"/"
        path[1..(path.length - 1)]
    end

    def cache_file(key,file)
        begin
            object = AWS::S3::S3Object.find(key, @image_bucket)
            FileUtils.makedirs(File.dirname(file))

            File.open(file, "w", 0644) { |data|
                AWS::S3::S3Object.stream(key, @image_bucket) do |chunk|
                    data.write chunk
                end
            }
        rescue AWS::S3::NoSuchKey
            raise Handler::Error::RestNotFound.new("File " + key + " not found.")
        end
    end

    def get_mime(file)
        mimes = MIME::Types.type_for(file)
        if mimes.length > 0
            mimes[0].content_type
        else
            logger.warn("unrecognized file type for file: #{file}")
            "application/octet-stream"
        end
    end

    def finish_get(req, resp)
        if resp.status == 200 and req.env.has_key?"IMAGE_FILENAME"
            resp.finish {
                File.open(req.env["IMAGE_FILENAME"], "r") { |file|
                    file.each { |line|
                        resp.write(line)
                    }
                }
            }
        else
            resp.finish
        end
    end

    def set_content_length(resp, file)
        resp["Content-Length"] = File.stat(file).size.to_s
    end

    def set_content_type(resp, mime)
        resp["Content-Type"] = mime
    end

    def normalize_dir_name(dir)
        dir + "/" if dir.rindex("/") != (dir.size - 1)
    end

    def normalize_key(key)
        ret_key = key
        while (ret_key =~ /\%2C/)
            ret_key = ret_key.sub(/\%2C/, ",");
        end
        while (ret_key =~ /\%28/)
            ret_key = ret_key.sub(/\%28/, "(");
        end
        while (ret_key =~ /\%29/)
            ret_key = ret_key.sub(/\%29/, ")");
        end
        while (ret_key =~ /\%20/)
            ret_key = ret_key.sub(/\%20/, "_");
        end
        while not (ret_key =~ /^[a-zA-Z0-9_\-\.\/\(\)]*$/)
            ret_key = ret_key.sub(/[^a-zA-Z0-9_\-\.\/\(\)]/, "_");
        end
        ret_key
    end

end
