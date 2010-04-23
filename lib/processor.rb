require 'processor/file_processor'
require 'processor/iostream'
require 'processor/geometry'
require 'processor/thumbnail'

module Processor

  class << self
    def options
      @options ||= {
        :whiny             => true,
        :command_path      => nil,
        :src_path          => nil,
        :dst_path          => nil,
        :log               => true,
        :log_command       => false,
        :swallow_stderr    => true
      }
    end

    def path_for_command command #:nodoc:
      path = options[:command_path],command
      File.join(*path)
    end

    # The run method takes a command to execute and a string of parameters
    # that get passed to it. The command is prefixed with the :command_path
    # option from Processor.options. If you have many commands to run and
    # they are in different paths, the suggested course of action is to
    # symlink them so they are all in the same directory.
    #
    # If the command returns with a result code that is not one of the
    # expected_outcodes, a ProcessorCommandLineError will be raised. Generally
    # a code of 0 is expected, but a list of codes may be passed if necessary.
    #
    # This method can log the command being run when 
    # Processor.options[:log_command] is set to true (defaults to false). This
    # will only log if logging in general is set to true as well.
    def run cmd, params = "", expected_outcodes = 0
      command = %Q[#{path_for_command(cmd)} #{params}].gsub(/\s+/, " ")
      command = "#{command} 2>#{bit_bucket}" if Processor.options[:swallow_stderr]
      Processor.log(command) if Processor.options[:log_command]
      output = `#{command}`
      unless [expected_outcodes].flatten.include?($?.exitstatus)
        raise ProcessorCommandLineError, "Error while running #{cmd}"
      end
      output
    end

    def bit_bucket #:nodoc:
      File.exists?("/dev/null") ? "/dev/null" : "NUL"
    end

    def included base #:nodoc:
      base.extend ClassMethods
      unless base.respond_to?(:define_callbacks)
        base.send(:include, Processor::CallbackCompatability)
      end
    end

    def processor name #:nodoc:
      name = name.to_s.camelize
      processor = Processor.const_get(name)
      unless processor.ancestors.include?(Processor::FileProcessor)
        raise ProcessorError.new("Processor #{name} was not found") 
      end
      processor
    end

    # Log a processor-specific line. Uses ActiveRecord::Base.logger
    # by default. Set Processor.options[:log] to false to turn off.
    def log message
      logger.info("[processor] #{message}") if logging?
    end

    def logger #:nodoc:
      ActiveRecord::Base.logger
    end

    def logging? #:nodoc:
      options[:log]
    end
  end

  class ProcessorError < StandardError #:nodoc:
  end

  class ProcessorCommandLineError < StandardError #:nodoc:
  end

  class NotIdentifiedByImageMagickError < ProcessorError #:nodoc:
  end
  
  class InfiniteInterpolationError < ProcessorError #:nodoc:
  end

  module ClassMethods
    def has_attached_file name, options = {}
      include InstanceMethods
    end
  end

  module InstanceMethods #:nodoc:
  end

end
