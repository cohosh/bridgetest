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

# Change this to whatever client/server tuple you want to analyze.
CLIENT_TUPLE = ("1.2.3.4", 1234)
SERVER_TUPLE = ("4.3.2.1", 4321)

# Number of seconds of our time intervals.
CUM_TIME_THRESHOLD = 1

timestamp = None
prev_ack = None
prev_time = None
cum_time = 0
sent_bytes = 0
client_port = 0

print "test,bytes,timestamp"

def ignore_packet(packet):

    # Make sure that we only inspect the given client and server IP
    # addresses.
    if not packet.haslayer(scapy.IP):
        return True
    if not packet[scapy.IP].src == CLIENT_TUPLE[0]:
        return True
    if not packet[scapy.IP].dst == SERVER_TUPLE[0]:
        return True

    # Make sure that we only inspect the given client and server TCP ports.
    if not packet.haslayer(scapy.TCP):
        return True
    if not packet[scapy.TCP].dport == SERVER_TUPLE[1]:
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

    if cum_time > CUM_TIME_THRESHOLD:
        print "%s,%d,%.2f" % (time.strftime("%b %d %H:%M:%S", time.gmtime(timestamp)), sent_bytes, int(packet.time)- int(timestamp))
        sent_bytes = 0
        cum_time = 0

    prev_ack = ack
    prev_time = packet.time

    return


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print >> sys.stderr, "\nUsage: %s PCAP_FILE\n" % sys.argv[0]
        sys.exit(1)
    pcap_file = sys.argv[1]

    sys.exit(scapy.sniff(offline=pcap_file, prn=process_packet, store=0))
