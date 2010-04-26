#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),"/app")))
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),"/lib")))
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),"/slib")))

# only in debug environment
require 'rubygems'
require 'ruby-debug'
require 'pp'

# base requires
require 'json'
require 'yaml'
require 'logger'

# rack stuff
require 'rack/request'
require 'rack/response'
require 'slib/handler/base'
require 'slib/handler/error'
require 'slib/lib/rack'

# active_record
require 'active_record'
config = YAML::load(File.open(File.expand_path(File.join(File.dirname(__FILE__),"/config/database.yml"))))["development"]
ActiveRecord::Base.establish_connection(config)
ActiveRecord::Base.logger = Logger.new(STDOUT)
pp config

# image service specific
USE_SSL = true
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

# run queued jobs
require 'lib/delayed_job'
require 'app/image_job'
Delayed::Worker.new.start
