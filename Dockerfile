FROM golang:1.17-bullseye as builder

COPY . /bridgetest/

ENV CGO_ENABLED=0

#install snowflake
RUN git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git \
    && cd snowflake/client && go get -d && go build && mv client /usr/bin/snowflake

RUN cd /bridgetest/stun-test && go get -d && go build -o stun-test

FROM debian:bullseye-slim

#install python
RUN apt-get update && apt-get install -y wget tcpdump \
    python3 python3-stem tor obfs4proxy python2&& apt-get clean

COPY --from=builder /usr/bin/snowflake /usr/bin/snowflake

COPY --from=builder /bridgetest/ /bridgetest/

RUN crontab /bridgetest/docker/probe-crontab

COPY ./docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

RUN ln /usr/bin/tcpdump /usr/sbin/tcpdump

ENTRYPOINT ["/entrypoint.sh"]
