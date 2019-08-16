#!/usr/bin/env ruby

require 'pathname'

def multicolumn(cells, text)
  "\\multicolumn{" + cells + "}{c}{" + text + "}"
end

def cmidrule(start, step, num)
 (start..start+num).to_a.each_with_index.map{|x, i| x + i * step}.map{|x| "\\cmidrule(l{2pt}r{2pt}){" + '%d' % x + "-"  + '%d' % (x + step) + "}"}
end

def write_header(file, title)
  groups = ["Read", "Write", "Read/Write", "Read", "Write"]
  groups.map!(&method(:multicolumn).to_proc.curry.call("4"))
  file.write("\\newcolumntype{C}{>{\\centering\\arraybackslash}X}\n")
  file.write("\\newcolumntype{n}{S[table-format=2.2]}\n")
  file.write("\\begin{tabularx}{\\textwidth}{r" + " C@{\\,(}n@{) }" * 10 + "}\n")
  file.write("& \\multicolumn{20}{c}{" + title + ")} \\\\\n")
  file.write(" " * 11 + "\\cmidrule(l{2pt}r{2pt}){2-21}\n")
  file.write(" " *  9 + "& " + '%-81s' % '\\multicolumn{12}{c}{Random}' + "& " + '%-81s' %  '\\multicolumn{8}{c}{Sequential}' + "\\\\\n")
  file.write(" " * 11 + '%-82s' % '\\cmidrule(l{2pt}r{2pt}){2-13}' + " \\cmidrule(l{2pt}r{2pt}){14-21}\n")
  file.write(" " *  9 + "& " + groups.join(" & ") + " " * 24 + "\\\\\n")
  file.write(" " * 11 + cmidrule(2, 3, 4).join(" ") + "\n")
  file.write(" " *  9 + "& " + ([4, 64] * 5).map{|bs| "\\SI{" + bs.to_s + "}{\\kibi\\byte}" }.map(&method(:multicolumn).to_proc.curry.call("2")).join(" & ") + "\\\\\n")
end

def write_footer(file)
  file.write("\\end{tabularx}\n")
end

def write_tex(input, output, title)
  schedulers = ["None", "BFQ", "Kyber", "MQ-Dl.", "K2-8", "K2-16", "K2-32"].map{|name| "%-15s" % ("\\textsc{" + name + "}")}
  input = File.readlines(input).drop(1)
  input = input.zip(schedulers).map! { |line, sched|
    # replace the scheduler name with TeX-formatted name
    line = line.split(" & ").drop(1).unshift(sched)
    # drop the last 2 columns, which do not fit in the table
    # we also do not report on them in the paper (space!)
    line = line.take(10 * 2 + 1)
    # add TeX newline to new last row
    line[-1] += "\\\\\n"
    line.join(" & ")
  }
  File.open(output, "w") do |file|
    write_header(file, title)
    file.write(input.join(""))
    write_footer(file)
  end
end


write_tex(File.join("generated", "data", "mb"), File.join("generated", "tex", "maxbw.tex"), "Maximum Throughput [MiB/s] (at 99.9th percentile Latency [ms]")
write_tex(File.join("generated", "data", "ml"), File.join("generated", "tex", "maxlat.tex"), "Throughput [MiB/s] (at Maximum 99.9th percentile Latency [ms]")
