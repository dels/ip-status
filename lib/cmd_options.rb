# Copyright 2020 Dominik Elsbroek. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
# 
#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above copyright notice, this list
#       of conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY Dominik Elsbroek ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Dominik Elsbroek OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of Dominik Elsbroek

require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class Optparser
  Version = '0.0.1'
  attr_reader :parser, :options


  def parse(args)
    @options = ScriptOptions.new
    @args = OptionParser.new do |parser|
      @options.define_options(parser)
      parser.parse!(args)
    end
    @options
  end
  
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

      parser.separator ""
      parser.separator "Common options:"
      
      parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end
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

end


