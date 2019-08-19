#!/usr/bin/env ruby

results = ["min", "avg", "max", "95th percentile", "sum"]

labels = { 
  "kyber"       => "\\textsc{Kyber}",
  "bfq"         => "\\textsc{BFQ}",
  "none"        => "\\textsc{None}",
  "mq-deadline" => "\\textsc{MQ-Dl.}",
  "k2"          => "\\textsc{K2}"
}

longlabels = labels.dup
longlabels["mq-deadline"] = "\\textsc{MQ-Deadline}"

Dir.glob("k2-results/mysql*/").each do |dir|
  bm = File.basename(dir)
  set = {}
  Dir.glob(File.join(dir, "*.res")). each do |file|
    sched = File.basename(file, ".res")
    values = {}
    results.each { |v|
      num = `ack "#{v}:" #{file}`.split(':')[-1].to_f
      values[v] = num
      #p "#{sched} #{file} #{v} #{num}"
    }
    set[sched] = values

  end
  
  outfile = File.join("generated", "data", "#{bm}.dat")
  File.open(outfile, "w") do |file|
    file.write("sched min avg max p95 sum name longname\n")
    ["k2", "mq-deadline", "bfq", "none", "kyber"].each { |s|
      v = set[s]
      file.write("#{s} #{v["min"]} #{v["avg"]} #{v["max"]} #{v["95th percentile"]} #{'%.1f' % (v["sum"]/1000)} #{labels[s]} #{longlabels[s]}\n");
    }
  end
end

