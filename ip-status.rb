# coding: utf-8
require 'net/http'
require 'json'
require 'time'
require_relative 'numeric'
require_relative 'cmd_options'

class IpStatus
  @DEBUG = false
  @VERBOSE = false
  DB = "statistics_db.json"

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
    if -1 == @opts.sleep
      updated = (update_ip4addr || update_ip6addr)      
      puts to_s if updated || false == @QUIET
      return
    end
    puts "will updated status every #{@opts.sleep} seconds."
    sleeper
  end

  def sleeper
    iter = 0
    while true
      updated = false
      iter = iter + 1
      begin
        puts "DEBUG: starting iteration #{iter}" if @DEBUG
        show_wait_spinner {
          updated = (update_ip4addr || update_ip6addr)
        }
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
  
  def update_ip4addr
    init_db unless @db
    cur_ip = get_ip('https://4.fst.st/ip')
    return false if cur_ip == @db["ip4"]["cur_ip"]
    return false if -1 == cur_ip
    if @db["ip4"]["cur_ip"]
      puts "DEBUG: we have an update on ipv4" if @DEBUG
      puts "\nip4 addr changed from #{@db["ip4"]["cur_ip"]} to #{cur_ip} (last updated #{(Time.now - Time.parse(@db["ip4"]["last_update"])).duration} ago)\n"
      @db["ip4"]["last_ip"] = @db["ip4"]["cur_ip"]
    else
      puts "DEBUG: we have a brand new ip4 addr" if @DEBUG
    end
    @db["ip4"]["cur_ip"] = cur_ip
    @db["ip4"]["last_update"] = Time.now.to_s
    save_db_to_file
    true
  end
  
  def update_ip6addr
    init_db unless @db
    cur_ip = get_ip('https://6.fst.st/ip')
    return false if cur_ip == @db["ip6"]["cur_ip"]
    return false if -1 == cur_ip    
    if @db["ip6"]["cur_ip"]
      puts "DEBUG: we have an update on ipv6" if @DEBUG
      puts "\nip6 addr changed from #{@db["ip6"]["cur_ip"]} to #{cur_ip} (last updated #{(Time.now - Time.parse(@db["ip6"]["last_update"])).duration} ago)\n"
      @db["ip6"]["last_ip"] = @db["ip6"]["cur_ip"]      
    else
      puts "DEBUG: we have a brand new ip6 addr" if @DEBUG
    end
    @db["ip6"]["cur_ip"] = cur_ip
    @db["ip6"]["last_update"] = Time.now.to_s
    save_db_to_file    
    true
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
    ip4_json = @db["ip4"].to_json
    ip4_json = @db["ip6"].to_json
    #  json = 
    File.open(DB,"w") do |f|
      f.write("#{@db.to_json}")
    end  
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
      return
    else
      puts "DEBUG: initing hash json file no found" if @DEBUG
      @db = {}
      ["ip4", "ip6"].each do |ipv|
        puts "DEBUG: initing db for #{ipv}" if @DEBUG
        @db[ipv] = {}
      end
    end
  end
  
  def get_ip from
    uri = URI(from)
    begin
      Net::HTTP.start(uri.host, uri.port,
                      :use_ssl => uri.scheme == 'https') do |http|
        req = Net::HTTP::Get.new uri
        res = http.request(req)
        res.body
      end
    rescue => e
      -1
    end
  end


  def to_s
    msg = "\n"
    if -1 == ip4
      msg << "ERROR: could not update ipv4 addr"
    else
      msg << "ipv4: \n\t#{@db["ip4"]["cur_ip"]}"
      begin
        if 10 < (Time.now - Time.parse(@db["ip4"]["last_update"])).to_i
          msg << " (updated: #{(Time.now - Time.parse(@db["ip4"]["last_update"])).duration} ago)"
        end
        msg << "\n"
        if @db["ip4"]["last_ip"] && false == @db["ip4"]["last_ip"].empty?
          msg << "\tprev addr: #{@db['ip4']['last_ip']}\n"
        end
      rescue
      end
    end
    if -1 == ip6
      msg << "ERROR: could not update ipv6 addr"
    else
      msg << "ipv6: \n\t#{@db["ip6"]["cur_ip"]}"
      begin
        if 10 < (Time.now - Time.parse(@db["ip6"]["last_update"])).to_i
          msg << " (updated: #{(Time.now - Time.parse(@db["ip6"]["last_update"])).duration} ago)"
        end
        msg << "\n"
        if @db["ip6"]["last_ip"] && false == @db["ip6"]["last_ip"].empty?
          msg << "\tprev addr:  #{@db['ip6']['last_ip']}\n"
        end
      rescue
      end
    end
    msg << "\n"
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
    yield.tap{
      iter = false
      spinner.join
      if @VERBOSE
        print "."
      else
        print " \b"
      end
    }
  end
  
end

opts = OptparseExample.new.parse(ARGV)
pp opts if opts.debug

ips = IpStatus.new(opts)

