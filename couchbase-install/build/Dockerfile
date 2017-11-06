	FROM debian:jessie

COPY generate.sh /
RUN chmod +x /generate.sh

COPY bootstrap.sh /
RUN chmod +x /bootstrap.sh

COPY jq /
RUN chmod +x /jq

ENTRYPOINT ["/generate.sh"]