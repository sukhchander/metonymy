module Processor
  class FileProcessor
    attr_accessor :file, :options

    def initialize file, options = {}
      @file = file
      @options = options
    end

    def make
    end

    def self.make file, options = {}
      new(file, options).make
    end
  end
  
  # Due to how ImageMagick handles its image format conversion and how Tempfile
  # handles its naming scheme, it is necessary to override how Tempfile makes
  # its names so as to allow for file extensions. Idea taken from the comments
  # on this blog post:
  # http://marsorange.com/archives/of-mogrify-ruby-tempfile-dynamic-class-definitions
  class Tempfile < ::Tempfile
    # Replaces Tempfile's +make_tmpname+ with one that honors file extensions.
    def make_tmpname(basename, n)
      extension = File.extname(basename)
      sprintf("%s,%d,%d%s",File.basename(basename, extension), $$, n, extension)
    end
  end
end
