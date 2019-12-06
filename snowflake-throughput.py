#!/usr/bin/env python2
"""
Turn pcap into csv file.

Problem:  A client is downloading a large file from a server and we want to
          figure out if the throughput of the download degrades over time.

Solution: We analyze the pcap file of the download and extract the ACK segments
          that the client sends to the server.  From the ACK segments we can
          infer how much data was transferred in a given time interval
          (CUM_TIME_THRESHOLD).  We can then plot the number of downloaded
          bytes per time interval and do a simple qualitative inspection.
"""

import sys
import time

import scapy.all as scapy

LOG_PATH="log/linux-na/20191127-1845"

# Change this to whatever client/server tuple you want to analyze.
ip_addr = "127.0.0.1"
server_port = 0

# Number of seconds of our time intervals.
CUM_TIME_THRESHOLD = 1

timestamp = None
prev_ack = None
prev_time = None
cum_time = 0
sent_bytes = 0
client_port = 0

test_id = 0

socks_re = re.compile('.*Socks listener listening on port (\d+)')

print "test,bytes,timestamp"

def ignore_packet(packet):

    # Make sure that we only inspect the given client and server IP
    # addresses.
    if not packet.haslayer(scapy.IP):
        return True
    if not packet[scapy.IP].src == ip_addr:
        return True
    if not packet[scapy.IP].dst == ip_addr:
        return True

    # Make sure that we only inspect the given client and server TCP ports.
    if not packet.haslayer(scapy.TCP):
        return True
    if not packet[scapy.TCP].dport == server_port:
        return True

    # Make sure that we're only inspecting ACK segments.
    if not (packet[scapy.TCP].flags.A):
        return True

    return False


def process_packet(packet):

    global prev_ack
    global prev_time
    global cum_time
    global sent_bytes
    global timestamp
    global client_port

    if ignore_packet(packet):
        return

    # Reset measurements for a new connection
    if not packet[scapy.TCP].sport == client_port:
        client_port = packet[scapy.TCP].sport
        timestamp = packet.time
        prev_time = None
        prev_ack = None
        sent_bytes = 0
        cum_time = 0

    # Remember timestamp and ACK number of the very first segment.
    if prev_time is None and prev_ack is None:
        prev_time = packet.time
        prev_ack = packet[scapy.TCP].ack
        return

    ack = packet[scapy.TCP].ack
    sent_bytes += (ack - prev_ack)
    cum_time += (packet.time - prev_time)

    prev_ack = ack
    prev_time = packet.time

    return


if __name__ == "__main__":

    for i in range(0,100):
        test_id = i
        pcap_file = ("%s/snowflake-probe-%d-lo.pcap" % (LOG_PATH, i) )
        log_file = ("%s/snowflake-probe-%d.log" % (LOG_PATH, i) )

        sys.stderr.write("Processing snowflake probe %d\n" % i)
        # Figure out the Socks port from the log file
        with open(log_file) as f:
            for line in f:
                m = socks_re.match(line)

                if m is not None:
                    server_port = int(m.group(1))
                    sys.stderr.write("Found Socks port %s\n" % server_port)
                    break


        scapy.sniff(offline=pcap_file, prn=process_packet, store=0)
        print "%d,%d,%.2f" % ( i, sent_bytes, cum_time)
        sent_bytes = 0
        cum_time = 0
        prev_time = None
        prev_ack = None
