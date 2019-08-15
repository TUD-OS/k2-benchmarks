# 
# python3 script for converting ctf traces into a csv file used for
# generating plots
#
# expected arguments:
#   argv[1] - base directory containing subdirectories with all traces
#   argv[2] - comma-separated list of background noise rates
#   argv[3] - comma-separated list of realtime processes
#
# the number of elements in argv[2] and argv[3] has to be the same
#
# Copyright (c) 2018, 2019 Till Miemietz
#

import babeltrace
import sys
import os

#
# get a list of all immediate subdirectories of wdir
#
def imm_subdirs(wdir):
    return [name for name in os.listdir(wdir)
                 if os.path.isdir(os.path.join(wdir, name))]

# do some primitive input checking
if (len(sys.argv) <= 3):
    print("Insufficient number of arguments.\n", file=sys.stderr)
    sys.exit(1)

# fixed path for testing
path  = sys.argv[1]
# list of target background load rates
rates = sys.argv[2].split(",")
# list of realtime process ids
pids  = sys.argv[3].split(",")

# list of rates and pids must have the same length
if len(rates) != len(pids):
    print(len(rates))
    print(rates)
    print(len(pids))
    print(pids)
    print("There must be the same number of rates and pids.\n", file=sys.stderr)
    sys.exit(2)

trace_dirs = imm_subdirs(path)

# list should be sorted by integer suffix that indicates the bandwidth of each
# background process
trace_dirs = sorted(trace_dirs, key = lambda k : int(k[3:]))

# list index for iterating over the lists
idx = 0

values = []                           # matrix for time values
# initialize value list with "head" (rate values)
for rate in rates:
    values.append([int(rate)])

# this loop fills the value matrix
for tdir in trace_dirs:
    cur_rate = rates[idx]
    cur_pid  = int(pids[idx])        # convert to int for comparison!

    outstanding = {}                 # dictionary with outstanding requests

    # set up tracer
    tc = babeltrace.TraceCollection()
    tc.add_traces_recursive(os.path.join(path, tdir), 'ctf')

    for evt in tc.events:
        if evt.name == "block_bio_queue2" and evt['reqtid'] == cur_pid:
            outstanding[evt['bptr']] = evt.timestamp           
        elif evt.name == "block_bio_complete2" and evt['bptr'] in outstanding:
            stime = outstanding[evt['bptr']]    # starting time
            ctime = evt.timestamp               # completion time

            dtime = ctime - stime
            values[idx].append(dtime)

            del outstanding[evt['bptr']]
        else:
            pass

    idx = idx + 1

maxlen = 0

# convert value matrix into a csv string that is written to the resulting file
# in one piece to minimize the number of writing instructions
csvstring = ""

# find sublist with maximum entries
for i in range(len(values)):
    if len(values[i]) > maxlen:
        maxlen = len(values[i])

# iterate ove the value matrix row by row
for i in range(maxlen):
    for j in range(len(values)):
        # the lists for single background noises do not have to have the same
        # length, thus check if we are accessing a correct element
        if i < len(values[j]):
            csvstring += str(values[j][i])

        if j == (len(values) - 1):
            # no newline on last line
            if i < (maxlen - 1):
                csvstring += "\n"
        else:
            csvstring += ","

# after creating the output string, write to the target file
csv = open(os.path.join(path, "data.csv"), "w+")
csv.write(csvstring)

# close the file again
csv.close()
