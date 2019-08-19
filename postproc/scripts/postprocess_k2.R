#!/usr/bin/env RScript

require(utils)
require(reshape2)
library(data.table)
library(dplyr)

raw_data_prefix = "k2-results/"
gen_data_prefix = "generated/data/"

# generate filenames from a benchmark configuration to find the file with raw and post-processed data
paths <- function(config, type = "micro", form = "sc") {
	raw_path <- paste(c(raw_data_prefix, "res_", type, "_", form, "_", config["trim"], "/", config["sched"], "/", config["work"], "_bs", config["bs"], "K/"), collapse="")
	gen_path <- paste(c(gen_data_prefix, "res_", type, "_", form, "_", config["trim"], "/", config["sched"], "/", config["work"], "_bs", config["bs"], "K/"), collapse="")
	c(
		paste(c(raw_path, "data.csv"), collapse = ""), 
		paste(c(gen_path, "fg_bw.dat"), collapse = ""),
		paste(c(raw_path, "data_schedtime.csv"), collapse = ""),
		paste(c(raw_path, "data_rt2.csv"), collapse = ""),
		paste(c(raw_path, "data_schedtime_rt2.csv"), collapse = "")
	)
}

output_filename <- function(config, prefix = gen_data_prefix,  suffix = "") {
	file <- paste(c(prefix, paste(c(config["trim"], config["sched"], config["work"], config["bs"]), collapse = "-"), suffix, ".dat"), collapse = "")
	#print(file)
	file
}

# load data and calculate quantiles from a set of filenames
load <- function(files, quantiles) {
	# raw measurement data
	# drop first row of data b/c it contains junk
	data <- read.csv(file = files[1], header = FALSE)[-1, ] 
	# foreground and background bandwidth (post-processed from raw (total) bandwidth)
	fgbw <- read.table(file = files[2], header = TRUE)
	# scheduler latency
	sched <- read.csv(file = files[3], header = TRUE)

	data <- data / 1000 / 1000; #ns to ms
	sched <- sched / 1000; #ns to us

	# reduce raw data to quantiles
	percentiles <- apply(data, 2, quantile, prob = quantiles, na.rm = TRUE)
	sched_perc <- apply(sched, 2, quantile, prob = quantiles, na.rm = TRUE)
	rownames(percentiles) <- quantiles * 100;
	rownames(sched_perc) <- paste("sched", sep = "-", quantiles * 100);

	# combine everything
	df <- data.frame(fgbw, t(percentiles), t(sched_perc))
}

# extract max 99.0th percentile latency (and achieved bandwidth) or bandwidth (and achieved latency) – "what" parameter
find_max <- function(data, what, output) {
	# extract maximum "what" from data set
	df.agg <- aggregate(what, data, max);
	# merge with the original data set, to get all columns for that configuration
	# we only have either latency or bandwidth; we want both!
	df.max <- merge(df.agg, data)
	# we have all; but we just want the config (trim, work, sched, bs) and bw + latency)
	df.max.subset <- select(df.max, trim, work, sched, bs, bg_total, X99.9)
	# and now rename the columns to reflect the meaning of the selected data:
	# max achieved background bandwidth and corresponding latency and vice-versa.
	df.max.subset <- rename(df.max.subset, max_bg_bw = bg_total, max_X99.9 = X99.9)

	# data filtering complete!

	# prepare table output; we want rounded numbers in the table for typographic reasons.
	# we choose no decimal places for bandwidth and 2 decimal places for latency.
	df.max.subset$max_bg_bw = round(df.max.subset$max_bg_bw, 0)
	df.max.subset$max_X99.9 = round(df.max.subset$max_X99.9, 2)

	# of course, this wouldn't be R, if we could just write our data to a file.
	# we need to convert our data from wide to long format.
	long <- melt(select(subset(df.max.subset, trim == "half"), -trim), id.vars=c("sched", "work", "bs"), measure.vars=c("max_bg_bw", "max_X99.9"))
	long$work = as.factor(long$work)
	long$bs = as.factor(long$bs)
	long$variable = as.factor(long$variable)
	mb <- dcast(unique(long), sched ~ work + bs + variable, value.var = "value")
	write.table(mb, output, row.names = FALSE, sep = " & ", quote=FALSE, eol="\\\\\n")
}

# our configuration space is 4-dimensional:
# - trim setting of the disk (fully-trimmed, half-trimmed, not trimmed)
# - I/O scheduler (none, bfq, kyber, mq-deadline, and K2-variants)
# - workload (random read, random write, random read+write, (sequential) read, (sequential) write, random read (foreground)+random read/write (background))
# - blocksize (4 and 64 kiB)
trim <- c("full", "half", "trim");
sched <- c("none", "bfq", "kyber", "mq-deadline", "k2_8", "k2_16", "k2_32");
work <- c("randread", "randwrite", "randrw", "read");
bs <- c("4", "64");


# build a list of all combinations
combinations1 <- expand.grid(sched, c("half"), bs, c("write"));
combinations2 <- expand.grid(sched, c("half"), c("4"), c("randrrandrw"));
combinations <- expand.grid(sched, trim, bs, work, stringsAsFactors = FALSE);

combinations <- rbind(combinations, combinations1, combinations2);
colnames(combinations) <- c("sched", "trim", "bs", "work");

# load the raw data for all experiments
rawdata <- apply(combinations, 1, function(config) {
	# construct the filename with measurements from the config options
	file <- paths(config)
	#print(file);
	quantiles = c(0, 0.5, 0.95, 0.99, 0.999, 1);

	# load the data
	data <- load(file, quantiles)
	
	# generate plottable data sets from raw data
	#max_ <- apply(data, 2, max);
	#tmp <- cbind.data.frame(t(config), t(max_));
	write.table(data, output_filename(config), row.names=FALSE, quote = FALSE)
	#inverted <- extract_bw(data, c("X50", "X95", "X99", "X99.9", "X100"), c(0.1, 0.2, 0.5, 1, 2, 5))
	#write.table(inverted, output_filename("plots/data/", config, "-lat"), row.names=FALSE, quote = FALSE, na = "nan")

	# name columns
	cbind.data.frame(t(config), data);
})

data <-rbindlist(rawdata, fill=TRUE)

find_max(data, bg_total ~ trim + work + sched + bs, "generated/data/mb")
find_max(data, X99.9 ~ trim + work + sched + bs, "generated/data/ml")
