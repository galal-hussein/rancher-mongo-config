FROM mongo:latest
MAINTAINER Hussein Galal

RUN apt-get update \
&& apt-get install -yqq python build-essential python-dev python-pip python-setuptools \
&& pip install pymongo \
&& pip install netifaces \
&& pip install dnspython

RUN mkdir -p /mongo
WORKDIR /mongo

ENV MONGO_SERVICE_NAME mongo

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["mongod"]
