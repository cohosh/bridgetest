# Probetest

This is a collection of scripts for performing automatic reachability tests of Snowflake and obfs4. 

### Setup


#### Docker

We have a docker image for performing these tests.

#### Manual

1. Install dependencies
```
# python and required packages
apt-get install python3 tcpdump wget
pip3 install stem
Golang 1.13+

# tor and obfs4proxy
apt install obfs4proxy tor torsocks
```

2. Build the stun test
#build scripts
cd stun-test
go build

3. Configure tcpdump

### Running tests

Usage: `./probetests.sh [TYPE] [SITENAME]`

[SITENAME] is an arbitrary identifier for the probe site
that you have to choose.

[TYPE] is the type of probe test to be performed. Right now
there are two types: "obfs4"|"snowflake"

The bridge_lines.txt file should contain a list of bridges to test. Each line corresponds to a bridge and should be of the form:
        <nickname>,<bridge_line>
where <bridge_line> is the line to go in the torrc file and is structured as follows:
        obfs4 <IP:Port> <FINGERPRINT> cert=<CERT> iat-mode=0

Add to crontab to run tests 4x a day:
	0 */6 * * * cd ~/bridgetest && ./probetest.sh [TYPE] [SITENAME]

Analyze Tor bootstrap progress from logs:
	1. Make the CSV: find log -name '*.log' | sort | ./makecsv > bootstrap.csv
	2. Plot the results: Rscript plot-bootstrap.R bootstrap.csv

Analyze obfs4 throughput from pcap files:
    1. Adapt the variables CLIENT_TUPLE and SERVER_TUPLE in infer-throughput.py.
    2. Run the script: python obfs4-throughput.py download.pcap > download.csv
    3. Plot the results: Rscript obfs4-throughput.R download.csv    

Analyze snowflake throughput from pcap files:
    1. Plot the results: Rscript snowflake-throughput.R snowflake-throughput.csv

Analyze snowflake reachability from log files:
    1. Run the script find log -name '*.log' | sort | ./snowflake-stage.py > stage.csv
    2. Plot the results Rscript snowflake-stage.R stage.csv

### Clean up ###
To remove generate pcap files, run
find log/ -name "*.pcap* --delete
