# Probetest

This is a collection of scripts for performing automatic reachability tests of Snowflake and obfs4.

Datasets from multiple probe points are published by us at: https://people.torproject.org/~cohosh/bootstrap.csv

(You may want to run the bootstrap.csv file through the analysis/compare-with-control.pl script, to list only the lines where the bridges are known to be working in our control location.)

### Setup


#### Docker

We have a docker image for performing these tests. To run this image, first modify `.env` with your user id number (you can get this by checking `echo $UID`), and a unique name for the site (e.g., a country code).

You can either build the image from scratch, or if you don't, the compose file will pull our pre-built image from docker hub. I recommend this latter option in places where Tor is blocked. It also contains some built-in obfs4 bridge lines selected by us.

Then start the probe by running:
```
docker-compose up -d
```
The results will appear in the `log/` directory.

##### Docker Build

To build a multi-arch docker image and push it:
```
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -f Dockerfile -t ${TAG_NAME} --push
```

#### Manual

1. Install dependencies
- the following packages:
```
apt-get install python3 tcpdump wget tor
```
- Go 1.13+
- tcpdump

2. Build the stun test
```
cd stun-test
go get -d && go build
```

3. Configure tcpdump (Optional)

If you're running this as a non-root (or sudo) user, and you want to take packet captures, you'll have to set up tcpdump as follows:

```
groupadd tcpdump
usermod -a -G tcpdump user
chgrp tcpdump /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
```

### Running tests

Usage: `./probetests.sh [TYPE] [SITENAME]`

`[SITENAME]` is an arbitrary identifier for the probe site
that you have to choose.

`[TYPE]` is the type of probe test to be performed. Right now
there are two types: "obfs4"|"snowflake"

The `bridge_lines.txt` file should contain a list of bridges to test. Each line corresponds to a bridge and should be of the form:
```
<nickname>,<bridge_line>
```
where `<bridge_line>` is the line to go in the torrc file and is structured as follows:
```
obfs4 <IP:Port> <FINGERPRINT> cert=<CERT> iat-mode=0
```

Add to crontab to run tests 4x a day:
```
0 */6 * * * cd ~/bridgetest && ./probetest.sh [TYPE] [SITENAME]
```

### Analyzing tests results

#### Data format

All data from the tests are located in the created `log/` directory. The directory structure is as follows:
```
log/[TYPE]/[SITENAME]/[RUN]
```
where `[RUN]` is the timestamp of the test run in the format `YYYYMMDD-HHMM`.

Inside of each run's directory are a combination of capture files and logs, depending on the type of test.

##### Snowflake data output

The snowflake tests checks the reachability of the default STUN servers and then proceeds to make a connection to snowflake and download a file over the connection for a set number of times. This produces the following output:

- `stun-test.csv` is a CSV file with entries of the format:
    ```
    <url>,<reachability>,<error>
    ```

    where `url` is the URL of the STUN server, `reachability` is a boolean value of whether it was reachable or not, and `error` is an error message that was produced in case it was not reachable.

- `snowflake-probe-[n]-client.log` is a log file with output from the snowflake client binary.
- `snowflake-probe-[n]-eth0.pcap` is a packet capture of all snowflake network traffic
- `snowflake-probe-[n]-lo.pcap` is a packet capture of local traffic, useful for measuring the rate of the file download
- `snowflake-probe-[n]-tor.log` is the tor bootstrapping output
- `snowflake-probe-[n].tcpdump.err` is the tcpdump error output


#### Analysis scripts
We've written some scripts to analyze and extract data from the packet captures, but in some cases manually inspecting the capture files might prove useful.

Analyze Tor bootstrap progress from logs:
1. Make the CSV:
    ```
    find log/[TYPE] -name '*.log' | sort | ./makecsv > bootstrap.csv
    ```

2. Plot the results:
    ```
    Rscript plot-bootstrap.R bootstrap.csv
    ```

Analyze obfs4 throughput from pcap files:
1. Adapt the variables `CLIENT_TUPLE` and `SERVER_TUPLE` in `infer-throughput.py`.

2. Run the script:
    ```
    python obfs4-throughput.py download.pcap > download.csv
    ```

3. Plot the results:
    ```
    Rscript obfs4-throughput.R download.csv
    ```

Analyze snowflake throughput from pcap files:
1. Run the script:

2. Plot the results:
    ```
    Rscript snowflake-throughput.R snowflake-throughput.csv
    ```

Analyze snowflake reachability from log files:
1. Run the script:
    ```
    find log -name '*.log' | sort | ./snowflake-stage.py > stage.csv
    ```

2. Plot the results:
    ```
    Rscript snowflake-stage.R stage.csv
    ```
