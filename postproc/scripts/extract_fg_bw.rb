#!/usr/bin/env ruby

require 'pathname'

avg = Regexp.new(/avg=(\d+.\d+)/)

raw_data_dir = Pathname.new("k2-results")
output_dir = Pathname.new("generated").join("data")

Dir.glob("#{raw_data_dir}/**/").each do |dir|
  # meh. I want increasing BW :/
  data = []
  Dir.glob(File.join(dir, "*.out")). each do |file|
    print "Proccesing #{file}\n"
    # Extract target bandwidth from filename
    bw = /K(\d+)\.out/.match(file)[1].to_i

    # TODO: this is awfully slow, because it file is read multiple times and
    # several new processes are spawned.

    # extract total read and write data rates
    # is automatically 0.0 if no READ or WRITE line is found in "file".
    read = `awk \' /READ:/ { sub("MiB/s", "", $2); print substr($2, 4); }\' #{file}`.to_f
    write = `awk \' /WRITE:/ { sub("MiB/s", "", $2); print substr($2, 4); }\' #{file}`.to_f

    h = {
      "bw" => bw,              # target data rate
      "total" => read + write, # total accumulated data rate
      "r" => read,             # accumulated read data rate
      "w" => write,            # accumulated write data rate
      "rt_r" => 0,             # accumulated read data rate of RT procs
      "rt_w" => 0              # accumulated write data rate of RT procs
    }

    # for up to two realtime processes
    ["realtime", "realtime2"].each do |rt|
      # find read and write bandwidth
      rt_read = `tail -n +6 #{file} | grep -A 17 #{rt}: | grep read: -A 7 | grep avg`
      rt_write = `tail -n +6 #{file} | grep -A 17 #{rt}: | grep write: -A 7 | grep avg`
      match_read = avg.match(rt_read)
      match_write = avg.match(rt_write)

      # convert to MiB/s
      if match_read
        h["rt_r"] += match_read[1].to_f / 1024.0
      end
      if match_write
        h["rt_w"] += match_write[1].to_f / 1024.0
      end
    end

    # we should have either written or read something.
    if h["r"] == 0 and h["w"] == 0 or h["rt_r"] == 0 and h["rt_w"] == 0
      raise "#{file} has both r and w 0"
    end

    # collect extracted data
    data << h
  end

  # if we have extracted any data (empty file?)
  if not data.empty?
    # write to "generated" directory, but keep the rest of the hierarchy
    outfile = output_dir + Pathname.new(dir).relative_path_from(raw_data_dir) + "fg_bw.dat"
    # create dir, if not exists
    outfile.dirname.mkpath unless outfile.dirname.exist?
    # create + write the file.
    File.open(outfile, "w") do |file|
      # write total bandwidth, foreground + background bandwidth,
      # foreground read and foreground write bandwidth out to file
      file.write("bw total r w bg_total fg_total fg_r fg_w\n")
      data.sort_by {|e| e["bw"]}.each do |line|
        file.write("#{line["bw"]} #{line["total"]} #{line["r"]} #{line["w"]} ")
        file.write("#{line["total"] - line["rt_r"] - line["rt_w"]} ")
        file.write("#{line["r"] + line["w"]} #{line["r"]} #{line["w"]}\n")
      end
    end
  end
end

