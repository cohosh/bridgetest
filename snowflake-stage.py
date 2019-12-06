#!/usr/bin/env python2

import csv
import datetime
import locale
import os.path
import re
import sys

# For strptime.
locale.setlocale(locale.LC_ALL, "C")

# Dec 01 20:57:53.000
stage_re = re.compile(r'^stage:(.*)')
date_re = re.compile(r'^(\w+ \d+ \d\d:\d\d:\d\d\.\d\d\d)')
ip_re = re.compile(r'^Successfully connected to snowflake (.*)')

csvW = csv.DictWriter(sys.stdout, fieldnames=("timestamp", "site", "runid", "ip", "percent"))
csvW.writeheader()

stages = {'Gathering': 20, 'Signaling': 40, 'Connecting': 60, 'Data': 80, 'Done':100}

rows = []


def process_log(f, site, runid, nickname):
    timestamp = datetime.datetime.strptime(runid, "%Y%m%d-%H%M")
    ip = None
    for line in f:
        
        m = ip_re.match(line)
        if m is not None:
            ip = m.group(1)

        m = stage_re.match(line)
        if m is not None:

            stage = m.group(1)
            percent = stages[stage]

            row = {
                "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S.%f"),
                "site": site,
                "runid": runid,
                "ip": "",
                "percent": percent,
            }
            rows.append(row)
        
    for row in rows:
        row['ip'] = ip
        csvW.writerow(row)

for filename in sys.stdin:
    filename = filename.strip()

    nickname, ext = os.path.splitext(os.path.basename(filename))

    if ext != ".log":
        continue
    if nickname == "main":
        continue

    parent = os.path.dirname(filename)
    runid = os.path.basename(parent)
    parent = os.path.dirname(parent)
    site = os.path.basename(parent)

    with open(filename) as f:
        process_log(f, site, runid, nickname)
