FROM alpine:latest

MAINTAINER jmoore@zedstar.org

RUN apk update && apk upgrade \
 && apk add sudo \
 && adduser -S databox \
 && echo 'databox ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/databox \
 && chmod 440 /etc/sudoers.d/databox \
 && chown root:root /etc/sudoers.d/databox \
 && sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers

USER databox
WORKDIR /home/databox

# add the code
ADD src src
RUN sudo chown -R databox:nogroup src
# add the build script
ADD build.sh .

# setup ocaml
RUN sudo apk add --no-cache --virtual .build-deps alpine-sdk bash ncurses-dev m4 perl gmp-dev zlib-dev libsodium-dev opam zeromq-dev \
&& opam init \ 
&& opam pin add -n sodium https://github.com/me-box/ocaml-sodium.git#with_auth_hmac256 \
&& opam install -y reason lwt tls sodium macaroons ezirmin bitstring ppx_bitstring uuidm lwt-zmq \
&& sudo chmod +x build.sh && sync \
&& ./build.sh \
&& rm -rf /home/databox/.opam \
&& sudo apk del .build-deps \
&& sudo apk add libsodium gmp zlib libzmq

USER root
VOLUME /database

EXPOSE 5555
EXPOSE 5556

