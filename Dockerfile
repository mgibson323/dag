FROM alpine:latest
RUN apk update && \
apk add --update bash git curl nmap whois bind-tools perl && \
git clone https://github.com/savagemike/dag /dag
WORKDIR /dag
ENTRYPOINT ["bash","/dag/dag.sh"]
CMD [""]
