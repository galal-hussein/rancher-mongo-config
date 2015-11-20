FROM debian:wheezy
MAINTAINER Hussein Galal

RUN echo "deb http://http.debian.net/debian wheezy-backports main" | tee /etc/apt/sources.list.d/wheezy-backports.list
RUN echo "deb http://security.debian.org/ wheezy/updates main contrib non-free " | tee /etc/apt/sources.list.d/wheezy-security.list
RUN echo "deb-src http://security.debian.org/ wheezy/updates main contrib non-free" | tee /etc/apt/sources.list.d/wheezy-security.list
RUN apt-get update \
&& apt-get install -yqq dnsutils python build-essential python-dev python-pip python-setuptools jq\
&& pip install pymongo \
&& pip install netifaces \
&& pip install pydns

ENV MONGO_SERVICE_NAME mongo

ADD ./*.sh /opt/rancher/bin/
RUN cp /usr/bin/jq /opt/rancher/bin/jq 
RUN chmod u+x /opt/rancher/bin/*

VOLUME /opt/rancher/bin

ENTRYPOINT ["/opt/rancher/bin/entrypoint.sh"]
CMD ["mongod"]
