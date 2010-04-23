module Processor
  # Handles thumbnailing images
  class Thumbnail < FileProcessor

    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options, :source_file_options

    # Creates a Thumbnail object set to work on the +file+ given. It
    # will attempt to transform the image into one defined by +target_geometry+
    # which is a "WxH"-style string. +format+ will be inferred from the +file+
    # unless specified. Thumbnail creation will raise no errors unless
    # +whiny+ is true (which it is, by default. If +convert_options+ is
    # set, the options will be appended to the convert command upon image conversion 
    def initialize file, options = {}
      super

      @file                = file
      @file_id             = options[:file_id].to_s
      @geometry            = options[:geometry]
      @crop                = @geometry[-1,1] == '#'
      @target_style        = options[:style].to_s
      @target_geometry     = Geometry.parse @geometry
      @current_geometry    = Geometry.from_file @file
      @source_file_options = options[:source_file_options]
      @convert_options     = options[:convert_options]
      @whiny               = options[:whiny].nil? ? true : options[:whiny]
      @format              = options[:format]

      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
      
    end

    # Returns true if the +target_geometry+ is meant to crop.
    def crop?
      @crop
    end
    
    # Returns true if the image is meant to make use of additional convert options.
    def convert_options?
      !@convert_options.nil? && !@convert_options.empty?
    end

    # Performs the conversion of the +file+ into a thumbnail.
    def make
      dst_path=[Processor.options[:dst_path],@file_id,@target_style].join('/')
      FileUtils.makedirs(dst_path)
      dst_file=[dst_path,File.basename(@file.path)].join('/')
      dst=File.open(dst_file,'w+') # write out to this file
      dst.binmode

      command = <<-end_command
        #{ source_file_options }
        "#{ File.expand_path(@file.path) }[0]"
        #{ transformation_command }
        "#{ File.expand_path(dst_file) }"
      end_command

      begin
        success = Processor.run("convert", command.gsub(/\s+/, " "))
      rescue ProcessorCommandLineError
        raise ProcessorError, "There was an error processing the thumbnail for #{@basename}" if @whiny
      end

      dst # return the processed file
    end

    # Returns the command ImageMagick's +convert+ needs to transform the image
    # into the thumbnail.
    def transformation_command
      scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)
      trans = ""
      trans << " -resize \"#{scale}\"" unless scale.nil? || scale.empty?
      trans << " -crop \"#{crop}\" +repage" if crop
      trans << " #{convert_options}" if convert_options?
      trans
    end
  end
end
