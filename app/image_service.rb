require 's3_service'
require 'image'
require 'image_job'

class ImageService < S3Service

	def get(req, resp)
        if req.path_info =~ /.*\/$/
            # implement: an entire file list if needed OR FOR NOW -->
			raise Handler::Error::RestBadRequest.new("Nice try. Can't list all files yet. That wouldn't be cool.")
        else # GET image
            key = normalize_key(parse_path(req))
            file = [IMAGE_CACHE_DIR,key].join('/')
            begin
                cache_file(key,file) unless FileTest.file?file
            rescue Handler::Error::RestNotFound
                cache_file(key,file) unless FileTest.file?file
            end
            mime = get_mime(file)
            set_content_length(resp,file)
            set_content_type(resp,mime)
            req.env["IMAGE_FILENAME"]=file
            resp.status = 200 # OK
            finish_get(req,resp)
        end
	end

	def post(req, resp)
        debugger
		if req.path_info =~ /.*\/$/
			raise Handler::Error::RestBadRequest.new("Can't create files with trailing slash.")
		else
			begin
                # see multipart upload ==> file structure
                # http://github.com/chneukirchen/rack/blob/master/lib/rack/utils.rb
                #key = normalize_key(parse_path(req)) # FOR curl
                # handle multiple image posts
                uploads={:ids => [], :keys => []}
                tempfile=nil
                upload = req.params["upload"]
                upload.each_key do |k|
                    tempfile = upload[k][:tempfile]
                    file_key = normalize_key upload[k][:filename]
                    file_path = [IMAGE_CACHE_DIR,file_key].join('/')

                    # process thumbnails as background tasks
                    file_id = process(file_key,file_path,tempfile)
                    uploads[:ids] << file_id
                    uploads[:keys] << file_key
                end
            rescue Handler::Error::RestBadRequest
                raise Handler::Error::RestBadRequest.new("Couldn't upload")
			ensure
				tempfile.close! unless tempfile.nil?
			end
		end
        resp.write({:upload => uploads}.to_json) 
        resp.status = 201 # created

        referer=req.referer
        ids=uploads[:ids].collect {|x| "#{x},"}
        args="?ids="+ids.to_s
        redirect_to=referer+args

        resp.redirect redirect_to
	end

private

    def process file_key,file_path,file_data
        next_image_id=CACHE.get("next_image_id")
        if next_image_id.nil?
            next_image_id=process_record(file_key,file_path,file_data)
            # upload to s3 and cache
            process_original(file_key,file_path,file_data,next_image_id)
            # process styles aka thumbnails
            process_styles(file_key,file_path,file_data,next_image_id)
        else
            # upload to s3 and cache
            process_original(file_key,file_path,file_data,next_image_id)
            # record image metadata
            process_record(file_key,file_path,file_data)
            # process styles aka thumbnails
            process_styles(file_key,file_path,file_data,next_image_id)
        end
        next_image_id
    end

    def process_original file_key,file_path,file_data,file_id=nil
        # store it in s3 and cache it locally
        key="#{file_id}/original/#{file_key}"
        object = AWS::S3::S3Object.store(key, file_data, @image_bucket)
        path=[File.dirname(file_path),key].join('/')
        cache_file(key,path)
    end

    def process_record file_key,file_path,file_data,file_id=nil
        image = Image.new({
                            :file_name => file_key,
                            :file_size => file_data.size,
                            :content_type => get_mime(file_path)
                         })
        image.save!
        CACHE.get("curr_image_id")
    end

    #@styles = @edition.styles ---> through inventory? / releases?
    #:original => "3888x2592" # 10.1MP <-> 3:2 NOTE: this will change
    @@styles = {
        :square => "75x75#",
        :thumb => "100x67>",
        :small => "240x160",
        :medium => "500x333",
        :large => "1024x683"
    }

    def process_styles file_key,file_path,file_data,file_id=nil
        curr_image_id=CACHE.get("curr_image_id")||file_id
        @@styles.each_pair do |style,dimensions|
            begin
                Delayed::Job.enqueue ImageJob.new(file_key,file_id,style,dimensions)
            rescue Exception => e
                puts "An error occurred while processing: #{e.inspect}"
            end
        end
    end

end
