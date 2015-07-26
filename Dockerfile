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
ADD mongo_run.sh mongo_run.sh
RUN chmod u+x mongo_run.sh

ENTRYPOINT /bin/bash mongo_run.sh
CMD []
