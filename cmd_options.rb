require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptparseExample
  Version = '0.0.1'

  class ScriptOptions
    attr_accessor :verbose, :debug, :quiet, :sleep

    def initialize
      self.debug = false
      self.verbose = true
      self.quiet = false
      self.sleep = -1
    end

    def define_options(parser)
      parser.banner = "Usage: ip-status.rb [options]"
      parser.separator ""
      parser.separator "Specific options:"
      sleep_between_execution_option(parser)
      boolean_debug_option(parser)
      boolean_verbose_option(parser)
      boolean_quiet_option(parser)
      # add additional options

      parser.separator ""
      parser.separator "Common options:"
      
      parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end
      # Another typical switch to print the version.
      parser.on_tail("--version", "Show version") do
        puts "version: #{Version}"
        exit
      end
    end

    def sleep_between_execution_option(parser)
      # Cast 'sleep' argument to a Float.
      parser.on("--sleep N", Integer, "Sleep N seconds before next check") do |n|
        self.sleep = n
      end
    end

    def boolean_quiet_option(parser)
      # Boolean switch.
      parser.on("-q", "--quiet", "Run quietely - only show changes") do |q|
        self.quiet = q
      end
    end
    
    def boolean_verbose_option(parser)
      # Boolean switch.
      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        self.verbose = v
      end
    end

    def boolean_debug_option(parser)
      # Boolean switch.
      parser.on("-d", "--debug", "Show debug messages") do |d|
        self.debug = d
      end
    end
  end

  #
  # Return a structure describing the options.
  #
  def parse(args)
    # The options specified on the command line will be collected in
    # *options*.

    @options = ScriptOptions.new
    @args = OptionParser.new do |parser|
      @options.define_options(parser)
      parser.parse!(args)
    end
    @options
  end

  attr_reader :parser, :options
end  # class OptparseExample


