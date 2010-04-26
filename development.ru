$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/app"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/slib"))


# only in debug environment
require 'ruby-debug'
require 'pp'


# base requires
require 'json'
require 'yaml'
require 'logger'
require 'rack/request'
require 'rack/response'
require 'handler/base'
require 'handler/error'
require 'lib/rack'


# rack setup
use Rack::ContentLength
use Rack::Chunked
use Rack::Deflater
use Rack::Static

use Rack::ShowExceptions
use Rack::CommonLogger, STDOUT
Handler::Base.logger = Logger.new(STDERR)


# memcache
require 'memcache'
memcache_options = {
	:compression => false,
	:debug => false,
	:namespace => "upORdown",
	:readonly => false,
	:urlencode => false
}
memcache_uri = ['127.0.0.1:11211']
pp CACHE = MemCache.new(memcache_uri,memcache_options)
CACHE["foo"]="bar"
pp CACHE['booyah!']
pp CACHE['foo']


# active_record
require 'active_record'
config = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + "/config/database.yml")))["development"]
ActiveRecord::Base.establish_connection(config)
ActiveRecord::Base.logger = Logger.new(STDOUT)
pp config


# image_service
require 'image_service'
USE_SSL = true
SHARED_SECRET = "secret"
ACCESS_KEY_ID = "AKIAI5MCGXS3DHLJUIAQ"
SECRET_ACCESS_KEY = "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"
IMAGE_BUCKET = ACCESS_KEY_ID+".image"
IMAGE_CACHE_DIR = "/var/www/image/cache"
IMAGE_PROCESSED_DIR = "/var/www/image/processed"

# image service thumbnail processor
require 'lib/processor'
Processor.options[:command_path]="/opt/local/bin"
Processor.options[:src_path]=IMAGE_CACHE_DIR
Processor.options[:dst_path]=IMAGE_PROCESSED_DIR

# delayed_job
require 'lib/delayed_job'


#
# everything is setup now run it!
#
image_service = ImageService.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY, USE_SSL, IMAGE_BUCKET, IMAGE_CACHE_DIR)

# proxy
map '/api/images' do
	run image_service
end
