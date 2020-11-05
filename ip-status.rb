require 'net/http'
require 'json'
require 'time'
require_relative 'numeric'

class IpStatus
  DEBUG = false
  VERBOSE = false
  DB = "statistics_db.json"

  def initialize
    raise "verbose must be true if debug" if DEBUG && false == VERBOSE
    puts "DEBUG: working in DEBUG mode" if DEBUG
    puts "working in VERBOSE mode" if VERBOSE
    init_db unless @db
  end
  
  def set_ip4(val)
    init_db unless @db
    return if val == @db["ip4"]["cur_ip"]
    if @db["ip4"]["cur_ip"]
      puts "DEBUG: we have an update on ipv4" if DEBUG
      puts "ip4 addr changed from #{@db["ip4"]["cur_ip"]} to #{val}" if VERBOSE
      puts "ip4 was last updated #{(Time.now - Time.parse(@db["ip4"]["last_update"])).duration} ago" if VERBOSE
      @db["ip4"]["last_ip"] = @db["ip4"]["cur_ip"]
    else
      puts "DEBUG: we have a brand new ip4 addr" if DEBUG
    end
    @db["ip4"]["cur_ip"] = val
    @db["ip4"]["last_update"] = Time.now.to_s
  end
  
  def set_ip6(val)
    init_db unless @db
    return if val == @db["ip6"]["cur_ip"]
    if @db["ip6"]["cur_ip"]
      puts "DEBUG: we have an update on ipv6" if DEBUG
      puts "ip6 addr changed from #{@db["ip6"]["cur_ip"]} to #{val}" if VERBOSE
      puts "ip6 was last updated #{(Time.now - Time.parse(@db["ip6"]["last_update"])).duration} ago" if VERBOSE
      @db["ip6"]["last_ip"] = @db["ip6"]["cur_ip"]      
    else
      puts "DEBUG: we have a brand new ip6 addr" if DEBUG
    end
    @db["ip6"]["cur_ip"] = val
    @db["ip6"]["last_update"] = Time.now.to_s
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
    puts "DEBUG: writing db" if DEBUG
    ip4_json = @db["ip4"].to_json
    ip4_json = @db["ip6"].to_json
    #  json = 
    File.open(DB,"w") do |f|
      f.write("#{@db.to_json}")
    end  
  end
  
  def init_db
    return if @db
    puts "DEBUG: initing db" if DEBUG
    if File.exists?(DB)
      puts "DEBUG: found json file" if DEBUG    
      File.open(DB, "r") do |f|
        @db = JSON.load f
      end
      pp @db if DEBUG
      return
    else
      puts "DEBUG: initing hash json file no found" if DEBUG
      @db = {}
      ["ip4", "ip6"].each do |ipv|
        puts "DEBUG: initing db for #{ipv}" if DEBUG
        @db[ipv] = {}
      end
    end
  end
  
  def recv_ip4addr
    tmp_val = get_ip('https://4.fst.st/ip')
    puts "DEBUG: fetched ip4 addr #{tmp_val}" if DEBUG
    set_ip4(tmp_val)
  end
  
  def recv_ip6addr
    tmp_val = get_ip('https://6.fst.st/ip')
    puts "DEBUG: fetched ip6 addr #{tmp_val}" if DEBUG
    set_ip6(tmp_val)  
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
  
  def update_status print
    recv_ip4addr
    recv_ip6addr  
    return unless print
    msg = "\n"
    if -1 == ip4
      msg << "ERROR: could not update ipv4 addr"
    else
      msg << "ipv4: \n\t#{@db["ip4"]["cur_ip"]} (updated: #{(Time.now - Time.parse(@db["ip4"]["last_update"])).duration} ago)\n"
      if @db["ip4"]["last_ip"] && false == @db["ip4"]["last_ip"].empty?
        msg << "\twas before #{@db['ip4']['last_ip']}\n"
      end
    end
    if -1 == ip6
      msg << "ERROR: could not update ipv6 addr"
    else
      msg << "ipv6: \n\t#{@db["ip6"]["cur_ip"]} (updated: #{(Time.now - Time.parse(@db["ip6"]["last_update"])).duration} ago)\n"
      if @db["ip6"]["last_ip"] && false == @db["ip6"]["last_ip"].empty?
        msg << "\twas before #{@db['ip6']['last_ip']}\n"
      end      
    end
    msg << "\n"
    puts msg
    save_db_to_file
  end
end

IpStatus.new.update_status(true)


