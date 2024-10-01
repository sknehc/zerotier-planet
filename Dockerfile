FROM node:14-alpine as builder_ztncui

ENV TZ=Asia/Shanghai

WORKDIR /app

RUN set -x \
    && apk update\
    && apk add --no-cache python3 git g++ make
RUN set -x \
    && mkdir /app -p \
    && cd /app \
    && git clone --progress https://github.com/key-networks/ztncui.git \
    && cd /app/ztncui/src \
    && npm install


FROM alpine:3.14 as builder_zt

ENV TZ=Asia/Shanghai
ARG TAG=main

WORKDIR /app
ADD ./patch/mkworld_custom.cpp /app/patch/mkworld_custom.cpp
ADD ./patch/disable-sso.patch /app/patch/disable-sso.patch

RUN set -x \
    && apk update\
    && apk add --no-cache git python3 npm make g++ linux-headers curl pkgconfig openssl-dev jq build-base gcc alpine-sdk nodejs \
    && echo "env prepare success!"
RUN set -x \
    && git clone --quiet https://github.com/zerotier/ZeroTierOne.git \
    && cd ZeroTierOne \
    && git checkout ${TAG} \
    && git apply /app/patch/*.patch \
    && make -f make-linux.mk \
    && make install \
    && echo "make success!" \
    && zerotier-one -d ; sleep 5s && ps -ef |grep zerotier-one |grep -v grep |awk '{print $1}' |xargs kill -9 \
    && echo "zerotier-one init success!"\
    && cd ./attic/world \
    && cp /app/patch/mkworld_custom.cpp .\
    && mv mkworld.cpp mkworld.cpp.bak \
    && mv mkworld_custom.cpp mkworld.cpp \
    && sh build.sh \
    && mv mkworld /var/lib/zerotier-one\
    && echo "mkworld build success!"


FROM alpine:3.14

ENV TZ=Asia/Shanghai

WORKDIR /app

ENV IP_ADDR4=''
ENV IP_ADDR6=''
ENV FILE_KEY=''
ENV ZT_PORT=9994
ENV API_PORT=3443
ENV FILE_SERVER_PORT=3000

RUN set -x \
    && apk update \
    && apk add --no-cache npm curl jq openssl \
    && mkdir -p /app/config

COPY --from=builder_zt /app/ZeroTierOne/zerotier-one /usr/sbin/zerotier-one
COPY --from=builder_zt /var/lib/zerotier-one /bak/zerotier-one
COPY --from=builder_ztncui /app/ztncui /bak/ztncui

ADD ./patch/entrypoint.sh /app/entrypoint.sh
ADD ./patch/http_server.js /app/http_server.js

VOLUME [ "/app/dist","/app/ztncui","/var/lib/zerotier-one","/app/config"]

CMD ["/bin/sh","/app/entrypoint.sh"]
