FROM debian:buster-slim

LABEL maintainer="Cecylia Bocovich <cohosh@torproject.org>"

#install python
RUN apt-get update && apt-get install -y git wget tcpdump \
    python3 python3-stem tor obfs4proxy && apt-get clean

#install Go
RUN wget https://golang.org/dl/go1.15.14.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.15.14.linux-amd64.tar.gz && \
    rm go1.15.14.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

#install snowflake
RUN git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git \
    && cd snowflake/client && go get -d && go build && mv client /usr/bin/snowflake \
    && cd - && rm -rf snowflake

RUN git clone https://github.com/cohosh/bridgetest.git && \
    cd bridgetest/stun-test && go get -d && go build

COPY bridge_lines.txt /bridgetest/
RUN crontab /bridgetest/docker/probe-crontab


COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
