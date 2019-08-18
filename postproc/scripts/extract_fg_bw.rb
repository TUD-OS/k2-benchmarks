#!/usr/bin/env ruby

require 'pathname'

avg = Regexp.new(/avg=(\d+.\d+)/)

Dir.glob("k2-results/**/").each do |dir|
  # meh. I want increasing BW :/
  data = []
  Dir.glob(File.join(dir, "*.out")). each do |file|
    p file
    # Wind rushing through your hair, skating by the edge … fuck error checking
    bw = /K(\d+)\.out/.match(file)[1].to_i
    h = { "bw" =>  bw, "r" => 0, "w" => 0}
    ["realtime", "realtime2"].each do |rt|
      read = `tail -n +6 #{file} | grep -A 17 #{rt}: | grep read: -A 7 | grep avg`
      write = `tail -n +6 #{file} | grep -A 17 #{rt}: | grep write: -A 7 | grep avg`
      match_read = avg.match(read)
      match_write = avg.match(write)

    #p match_read, match_write
      if match_read
        h["r"] += match_read[1].to_f / 1024.0
      end
      if match_write
        h["w"] += match_write[1].to_f / 1024.0
      end
    end

    if h["r"] == 0 and h["w"] == 0
      raise "#{file} has both r and w 0"
    end

    data << h
  end

  if not data.empty?
    outfile = File.join(dir, "fg_bw.dat")
    File.open(outfile, "w") do |file|
      file.write("bw fg_total fg_r fg_w\n")
      data.sort_by {|e| e["bw"]}.each do |line|
        file.write("#{line["bw"]} #{line["r"] + line["w"]} #{line["r"]} #{line["w"]}\n")
      end
    end
  end
end

