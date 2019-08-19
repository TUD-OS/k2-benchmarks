# K2 I/O Scheduler benchmark data post-processing

The postprocessing infrastructure will consume benchmark data and filter and
postprocess it to be suitable for presentation and inclusion in figures in a
paper.

Postprocessing will output all generated files into the directory "generated"
in the repository root. Postprocessing output includes data tables,
intermediary data, and LaTeX files.

The ```postproc```-directory contains itself two directories:

```scripts```, which contains all the scripts described in this README, and  
```tex``` which contains the necessary TeX-files to generate tables and figures.

However, using those scripts is not strictly necessary, since we report simple
quantiles (minimum, median, 95th, 99th, 99.9th, and maximum) which can be
extracted using different tooling as well.

## Step 1 - Extracting Data Rates for Foreground and Background loads

The script ```extract_fg_bw.rb``` is a Ruby script, that extracts for each
benchmark configuration the target background data rate, achieved data rate
(total, read, and write), total data rate of background workloads, and
foreground workloads (total, read, and write).

The data is used for the x-axis labels and achieved data rate is represented as
colour in the plots.

The data is written to a file ```fg_bw.dat```, for each benchmark
configuration, in its corresponding sub-directory in the
```generated/data```-directory.

## Step 2 - Filtering and extracting data

The ```postproc_k2.R``` file contains an R script doing all the heavy lifting.
It consumes all results from all benchmark configuration and extracts the
following latency quantiles: min, median, 95th, 99th, 99.9th and maximum.

The script consumes the file ```fg_bw.dat``` for each configuration, which was
created in the preceding step. Additionally, it consumes the following raw data
files:

```data.csv```  
```data_schedtime.csv```   
```data_rt2.csv``` (optional)  
```data_schedtime_rt2.csv``` (optional)  

For each benchmark configration it creates an output file in the
```generated/data``` directory of the form:

```$trim-$scheduler-$workload-$blocksize.dat```, for example:
```half-k2_16-randread-4.dat```

The script also generates intermediary data files for the maximum throughput
and maximum latency tables. Output files are:

```generated/data/mb```  
```generated/data/ml```

The script ```extract_mysql.rb``` is used to extract benchmark results of the
Sysbench ```*.res``` result files. The benchmark is executed twice: once with
read-only background load (rob) and once with read-write background (rwb) load.

The script places its output files in the ```generated/data``` directory.
Accordingly, the generated files are:

```generated/data/mysql_ro_rob.dat``` and  
```generated/data/mysql_ro_rwb.dat```

## Step 3 - Generating TeX files

The script ```table_data_to_tex.rb``` consumes the following files:

```generated/data/mb```  
```generated/data/ml```

and generates the LaTeX files

```generated/tex/maxbw.tex```  
```generated/tex/maxlat.tex```

which can be used to re-create the tables containing maximum thoughput and
latency values from the paper. In fact, the LaTeX for the paper is compiled by
including those generated TeX-files.

## Step 4 - Generating a PDF

Compile the file ```postproc/tex/everything.tex``` to generate a PDF with
graphs for all experiments along width overview tables. The file
```postproc/tex/paper.tex``` will generate a PDF with those graphs and tables
contained in the Paper.
