FROM mongo:latest
MAINTAINER Hussein Galal

RUN echo "deb http://http.debian.net/debian wheezy-backports main" | tee /etc/apt/sources.list.d/wheezy-backports.list
RUN apt-get update \
&& apt-get install -yqq python build-essential python-dev python-pip python-setuptools jq\
&& pip install pymongo \
&& pip install netifaces \
&& pip install pydns

RUN mkdir -p /mongo
WORKDIR /mongo

ENV MONGO_SERVICE_NAME mongo

ADD ./*.sh /
RUN chmod u+x /*.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["mongod"]
