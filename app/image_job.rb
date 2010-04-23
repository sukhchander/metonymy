require 's3_service'
require 'lib/processor'
require 'handler/error'

class ImageJob < Struct.new(:file_key,:file_id,:style,:dimensions)

    # respond_to perfomable action for delayed job
    def perform
        file_path = [IMAGE_CACHE_DIR,file_id,"original",file_key].join('/')
        pp "file_path #{file_path}"
        file_data = File.open(file_path)
        pp "file_data #{file_data}"
        file_processed = Processor::Thumbnail.make(file_data,{:file_id => file_id, :style => style, :geometry => dimensions})
        file_processed_key = "#{file_id}/#{style}/#{file_key}"
        pp "file_processed_key #{file_processed_key}"
        re=/\/var\/www\/image\/processed/
        file_processed_path = file_processed.path.gsub(re,IMAGE_CACHE_DIR)
        pp "file_processed_path #{file_processed_path}"
        connect
        AWS::S3::S3Object.store(file_processed_key,file_processed,IMAGE_BUCKET)
        File.delete(file_processed_path) if FileTest.exist?(file_processed_path)
        cache_file(file_processed_key,file_processed_path)
    end

private

    def connect
        AWS::S3::Base.establish_connection!(
            :access_key_id => ACCESS_KEY_ID,
            :secret_access_key => SECRET_ACCESS_KEY,
            :use_ssl => USE_SSL,
            :persistent => true
        )
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

end
