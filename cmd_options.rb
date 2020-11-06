require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptparseExample
  Version = '0.0.1'

  class ScriptOptions
    attr_accessor :verbose, :debug, :quiet, :sleep, :max_history, :pretty_database

    def initialize
      self.debug = false
      self.verbose = true
      self.quiet = false
      self.sleep = -1
      self.max_history = 3
      self.pretty_database = false      
    end

    def define_options(parser)
      parser.banner = "Usage: ip-status.rb [options]"
      parser.separator ""
      parser.separator "Specific options:"
      sleep_between_execution_option(parser)
      max_history_items_option(parser)
      pretty_database_option(parser)      
      debug_option(parser)
      verbose_option(parser)
      quiet_option(parser)
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

    def max_history_items_option(parser)
      parser.on("-hi", "--history-items N", Integer, "show N history items - use -1 for no limit") do |n|
        self.max_history = n
      end
    end

    def sleep_between_execution_option(parser)
      parser.on("-s", "--sleep N", Integer, "Sleep N seconds before next check") do |n|
        self.sleep = n
      end
    end

    def pretty_database_option(parser)
      parser.on("-pd", "--pretty-database", "Save database with pretty print, so JSON is human readable") do |q|
        self.pretty_database = q
      end
      
    end
    
    def quiet_option(parser)
      parser.on("-q", "--quiet", "Run quietely - only show changes") do |q|
        self.quiet = q
      end
    end
    
    def verbose_option(parser)
      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        self.verbose = v
      end
    end

    def debug_option(parser)
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


