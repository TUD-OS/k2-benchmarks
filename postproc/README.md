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

## Step 1 - Filtering and extracting data

The ```postproc_k2.R``` file contains an R script doing all the heavy lifting.
It consumes all results from all benchmark configuration and extracts the
following latency quantiles: min, median, 95th, 99th, 99.9th and maximum.

The script also generates intermediary data files for the maximum throughput
and maximum latency tables. Output files are:

```generated/data/mb```
```generated/data/ml```

## Step 2 - Generating TeX files

The script ```table_data_to_tex.rb``` consumes the following files:

```generated/data/mb```
```generated/data/ml```

and generates the LaTeX files

```generated/tex/maxbw.tex```
```generated/tex/maxlat.tex```

which can be used to re-create the tables containing maximum thoughput and
latency values from the paper. In fact, the LaTeX for the paper is compiled by
including those generated TeX-files.


