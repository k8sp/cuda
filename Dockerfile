FROM ubuntu:14.04
MAINTAINER Yi Wang <yi.wang.2005@gmail.com>

COPY build.sh /opt

CMD /opt/build.sh

