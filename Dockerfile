FROM ailispaw/barge

COPY swarmkit/bin/swarmd /usr/bin/

ENTRYPOINT [ "swarmd" ]
