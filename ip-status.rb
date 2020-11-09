# coding: utf-8
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

require 'net/http'
require 'json'
require 'time'
require 'securerandom'
require_relative 'lib/numeric'
require_relative 'lib/cmd_options'

raise "Ruby Version 2.0 or higher required." if RUBY_VERSION < '2'

class IpStatus
  @DEBUG = false
  @VERBOSE = false
  DB = "statistics_db.json"
  ip4_regex = Regexp.new(/^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})){3}$/).freeze
  ip6_regex = Regexp.new(/^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/i).freeze  

  def initialize opts=nil
    if opts
      @opts = opts
      if (@QUIET = opts.quiet)
        @DEBUG = false
        @VERBOSE = false
        else
        @DEBUG = opts.debug
        @VERBOSE = opts.verbose
        @VERBOSE = true if @DEBUG
      end
    end
    puts "DEBUG: working in @DEBUG mode" if @DEBUG 
    init_db unless @db
    updated = (update_ip4addr || update_ip6addr)      
    puts to_s if updated || false == @QUIET
    exit if -1 == @opts.sleep
    puts "will update status every #{@opts.sleep} seconds."
    sleeper
  end

  def sleeper
    iter = 0
    while true
      updated = false
      iter = iter + 1
      begin
        puts "DEBUG: starting iteration #{iter}" if @DEBUG
        show_wait_spinner do
          updated = (update_ip4addr || update_ip6addr)
        end
        puts "DEBUG: we had an update? #{updated}" if @DEBUG
        puts self.to_s if @DEBUG || updated
        sleep @opts.sleep
      rescue SystemExit, Interrupt
        puts "\n"
        puts "DEBUG: stopped after #{iter} iterations" if @DEBUG
        puts "saving status and quit...\n"
        save_db_to_file
        puts "done\n"        
        exit
#      rescue Exception => e
#        puts "other exception: #{e}"
#        exit
      end
    end
  end

  def update_ipaddr cur_ip, version
    return false if cur_ip == @db[version]["cur_ip"]
    return false if -1 == cur_ip
    if @db[version]["cur_ip"]
      puts "DEBUG: we have an update on #{version}" if @DEBUG
      puts "\n#{version} addr changed from #{@db[version]["cur_ip"]} to #{cur_ip} (last updated #{(Time.now - Time.parse(@db[version]["first_seen"])).duration} ago)\n"
    else
      puts "DEBUG: we have a brand new ip4 addr" if @DEBUG
    end
    if @db[version]["cur_ip"] && @db[version]["first_seen"]
      @db[version]["history"] << {"ip" => @db[version]["cur_ip"], "first_seen" => @db[version]["first_seen"]}
    end
    @db[version]["cur_ip"] = cur_ip
    @db[version]["first_seen"] = Time.now.to_s
    save_db_to_file
    true
  end
  
  def update_ip4addr
    init_db unless @db
    cur_ip = get_ip("https://4.fst.st/ip?client_id=#{@db["client_id"]}")
    return update_ipaddr(cur_ip, "ip4") unless cur_ip =~ @ip4_regex
    puts "WARN: IPv4 (#{cur_ip}) does not match RegEx" unless @QUIET
    return false
  end
  
  def update_ip6addr
    init_db unless @db
    cur_ip = get_ip("https://6.fst.st/ip?client_id=#{@db["client_id"]}")    
    return update_ipaddr(cur_ip, "ip6") unless cur_ip =~ @ip6_regex
    puts "WARN: IPv6 (#{cur_ip}) does not match RegEx" unless @QUIET
    return false    
  end

  def ip4
    init_db unless @db
    @db["ip4"]["cur_ip"]
  end
  
  def ip6
    init_db unless @db
    @db["ip6"]["cur_ip"]
  end
  
  def save_db_to_file
    puts "DEBUG: writing db" if @DEBUG
    File.open(DB,"w") do |f|
      @opts.pretty_database ? f.write(JSON.pretty_generate(@db)) : f.write(@db.to_json)
    end  
  end

  # method to safely upgrade database on version changes
  def db_upgrade
    nil # no action required
  end
  
  def init_db
    return if @db
    puts "DEBUG: initing db" if @DEBUG
    if File.exists?(DB)
      puts "loading history file '#{DB}'" unless @QUIET
      File.open(DB, "r") do |file|
        @db = JSON.load file
      end
      pp @db if @DEBUG
      db_upgrade()
      return
    else
      puts "DEBUG: initing hash json file no found" if @DEBUG
      @db = {}
      ["ip4", "ip6"].each do |version|
        puts "DEBUG: initing db for #{version}" if @DEBUG
        @db[version] = {}
        @db[version]["history"] = []
      end
      db_upgrade()
    end
  end
  
  def get_ip from
    uri = URI(from)
    res = nil
    begin
      Net::HTTP.start(uri.host, uri.port,
                      :use_ssl => uri.scheme == 'https') do |http|
        req = Net::HTTP::Get.new(uri)
        res = http.request(req)
        if 200 != res.code.to_i
          puts "\b  WARN: Could not update IP (HTTP Response Code #{res.code})\n" unless @QUIET
          return -1
        end
        res.body
      end
    rescue => e
      puts "\nWARN: Could not read IP Addr: #{e.to_s}\n" unless @QUIET
      -1
    end
  end

  def to_s
    init_db unless @db
    msg = "\n"
    if -1 == ip4
      msg << "\nERROR: could not update ipv4 addr\n"
    else
      msg << print_ip("ip4")
    end
    if -1 == ip6
      msg << "\nERROR: could not update ipv6 addr\nWARN"
    else
      msg << print_ip("ip6")
    end
    msg << "\n"
    msg
  end

  def print_ip version
    msg = ""
    msg << "#{version}: \n\t#{@db[version]["cur_ip"]}"
    begin
      if 10 < (Time.now - Time.parse(@db[version]["first_seen"])).to_i
        msg << " (updated: #{(Time.now - Time.parse(@db[version]["first_seen"])).duration} ago)"
      else
        msg << " (updated just now)"
      end
      puts "DEBUG: found #{@db[version]["history"].size} history elements for #{version}" if @DEBUG
      msg << "\n"
      ec = 0
      (@db[version]["history"].sort {|h1,h2| Time.parse(h2["first_seen"]) <=> Time.parse(h1["first_seen"]) }).each do |hist|
        msg << "\t#{hist['ip']} (first seen at #{hist['first_seen'] })"
        msg << "\n"
        ec = ec + 1
        break if ec >= @opts.max_history && 0 < @opts.max_history
      end
    rescue Exception => e
      puts "WARN: exception caught..." if @DEBUG
      raise e if @DEBUG
    end
    # pp @db if @DEBUG
    msg
  end

  def show_wait_spinner(fps=10)
    chars = %w[| / - \\]
    delay = 1.0/fps
    iter = 0
    spinner = Thread.new do
      while iter do  # Keep spinning until told otherwise
        print chars[(iter+=1) % chars.length]
        sleep delay
        print "\b"
      end
    end
    yield.tap do 
      iter = false
      spinner.join
      if @VERBOSE
        print "."
      else
        print " \b"
      end
    end
  end
  
end

opts = Optparser.new.parse(ARGV)
pp opts if opts.debug

ips = IpStatus.new(opts)

