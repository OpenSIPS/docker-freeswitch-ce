FROM debian:bullseye AS base
LABEL maintainer darius.stefan@opensips.org

RUN mkdir -p /var/run/freeswitch && mkdir -p /var/lib/freeswitch && mkdir -p /var/log/freeswitch &&\
    groupadd -r freeswitch --gid=999 && useradd -r -g freeswitch --uid=999 freeswitch

FROM base AS git

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

FROM git AS sounds
RUN git clone https://github.com/freeswitch/freeswitch-sounds.git /usr/src/freeswitch-sounds

FROM git AS libs

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config \
# general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
# core
    libpcre3-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
# core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
# mod_enum
    libldns-dev \
# mod_python3
    python3-dev \
# mod_av
    libavformat-dev libswscale-dev libavresample-dev \
# mod_lua
    liblua5.2-dev \
# mod_opus
    libopus-dev \
# mod_pgsql
    libpq-dev \
# mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
# mod_shout
    libshout3-dev libmpg123-dev libmp3lame-dev

FROM libs AS libks
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks &&\
    cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install

FROM libs AS sofia-sip
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip &&\
    cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install

FROM libs AS spandsp
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp &&\
    cd /usr/src/libs/spandsp && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install

FROM libs AS freeswitch
COPY --from=sofia-sip /usr/bin/ /usr/bin/
COPY --from=sofia-sip /usr/lib/ /usr/lib/
COPY --from=sofia-sip /usr/include/ /usr/include/
COPY --from=sofia-sip /usr/share/sofia-sip/ /usr/share/sofia-sip/
COPY --from=spandsp /usr/include/ /usr/include/
COPY --from=spandsp /usr/lib/ /usr/lib/
COPY --from=spandsp /usr/bin/ /usr/bin/
COPY --from=libks /usr/include/ /usr/include/
COPY --from=libks /usr/lib/ /usr/lib/

RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch &&\
# enable modules
    sed -i \
    -e 's|applications/mod_signalwire|#applications/mod_signalwire|'\
    -e 's|applications/mod_spandsp|#applications/mod_spandsp|'\
    -e 's|#formats/mod_shout|formats/mod_shout|'\
    /usr/src/freeswitch/build/modules.conf.in &&\
# install
    cd /usr/src/freeswitch &&\
    ./bootstrap.sh -j &&\
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && make -j`nproc` &&\
    make install config-vanilla

# configure
RUN sed -i -e "s/internal_auth_calls=true/internal_auth_calls=false/" \
    -e "s/domain=\$\${local_ip_v4}/domain=internal/" /etc/freeswitch/vars.xml &&\
    mv /etc/freeswitch/sip_profiles/internal.xml /etc/freeswitch/internal.xml &&\
    rm -rf /etc/freeswitch/sip_profiles/* &&\
    mv /etc/freeswitch/internal.xml /etc/freeswitch/sip_profiles/internal.xml &&\
    sed -i \
    -e 's|<!-- <param name="accept-blind-reg" value="true"/> -->|<param name="accept-blind-reg" value="true"/>|'\
    -e 's|<!-- <param name="accept-blind-auth" value="true"/> -->|<param name="accept-blind-auth" value="true"/>|'\
    /etc/freeswitch/sip_profiles/internal.xml &&\
    sed -i 's|<list name="domains" default="deny">|<list name="domains" default="allow">|' /etc/freeswitch/autoload_configs/acl.conf.xml &&\ 
    sed -i 's|<param name="listen-ip" value="::"/>|<param name="listen-ip" value="127.0.0.1"/>|' /etc/freeswitch/autoload_configs/event_socket.conf.xml &&\
    sed -i 's|<!--<param name="startup-script" value="startup_script_1.lua"/>-->|<param name="xml-handler-script" value="xml_handler.lua"/>|' /etc/freeswitch/autoload_configs/lua.conf.xml &&\
    sed -i 's|<!--<param name="startup-script" value="startup_script_2.lua"/>-->|<param name="xml-handler-bindings" value="directory"/>|' /etc/freeswitch/autoload_configs/lua.conf.xml

FROM base AS final
COPY --from=sounds /usr/src/freeswitch-sounds/en/ /usr/share/freeswitch/sounds/en/
COPY --from=freeswitch /usr/bin/ /usr/bin/
COPY --from=freeswitch /usr/lib/ /usr/lib/
COPY --from=freeswitch /usr/share/ /usr/share/
COPY --from=freeswitch /usr/include/ /usr/include/
COPY --from=freeswitch /etc/freeswitch/ /etc/freeswitch/
COPY --from=freeswitch /var/lib/freeswitch/ /var/lib/freeswitch/
COPY --from=freeswitch /var/run/freeswitch/ /var/run/freeswitch/
COPY --from=freeswitch /var/log/freeswitch/ /var/log/freeswitch/

RUN rm -rf /etc/freeswitch/dialplan/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY xml_handler.lua /usr/share/freeswitch/scripts/xml_handler.lua

HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]
