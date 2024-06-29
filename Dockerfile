ARG SYNAPSE_VERSION=1.110.0rc2
ARG PYTHON_VERSION=3.12
ARG HARDENED_MALLOC_VERSION=2024061200
ARG UID=991
ARG GID=991


### Build Hardened Malloc
FROM alpine:latest as hmalloc-builder

ARG HARDENED_MALLOC_VERSION
ARG CONFIG_NATIVE=false
ARG VARIANT=default

RUN apk -U upgrade \
    && apk --no-cache add build-base git gnupg openssh-keygen
    
RUN cd /tmp \
    && git clone --depth 1 --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
    && cd hardened_malloc \
    && wget -q https://grapheneos.org/allowed_signers -O grapheneos_allowed_signers \
    && git config gpg.ssh.allowedSignersFile grapheneos_allowed_signers \
    && git verify-tag $(git describe --tags) \
    && make CONFIG_NATIVE=${CONFIG_NATIVE} VARIANT=${VARIANT}


### Build Synapse
FROM python:${PYTHON_VERSION}-alpine as synapse-builder

ARG SYNAPSE_VERSION

RUN apk -U upgrade \
    && apk --no-cache add -t build-deps build-base libffi-dev libjpeg-turbo-dev libxslt-dev linux-headers openssl-dev postgresql-dev rustup zlib-dev
    
RUN rustup-init -y && source $HOME/.cargo/env \
    && pip install --upgrade pip \
    && pip install --prefix="/install" --no-warn-script-location \
    matrix-synapse[all]==${SYNAPSE_VERSION}


### Get RootFS Files
FROM alpine:latest as rootfs

ARG SYNAPSE_VERSION

RUN apk -U upgrade \
    && apk --no-cache add git

RUN cd /tmp \
    && git clone --depth 1 --branch v${SYNAPSE_VERSION} https://github.com/element-hq/synapse


### Build Production

FROM python:${PYTHON_VERSION}-alpine

LABEL maintainer="Thien Tran contact@tommytran.io"

ARG UID
ARG GID

RUN apk -U upgrade \
    && apk --no-cache add -t run-deps libffi libgcc libjpeg-turbo libstdc++ libxslt libpq openssl zlib tzdata xmlsec git curl icu-libs \
    && rm -rf /var/cache/apk/*

RUN adduser -g ${GID} -u ${UID} --disabled-password --gecos "" synapse

RUN pip install --upgrade pip \
    && pip install -e "git+https://github.com/matrix-org/mjolnir.git#egg=mjolnir&subdirectory=synapse_antispam"

COPY --from=hmalloc-builder /tmp/hardened_malloc/out/libhardened_malloc.so /usr/local/lib/
COPY --from=synapse-builder /install /usr/local
COPY --from=rootfs --chown=synapse:synapse /tmp/synapse/docker/start.py /start.py
COPY --from=rootfs --chown=synapse:synapse /tmp/synapse/docker/conf /conf

ENV LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"

USER synapse

VOLUME /data

EXPOSE 8008/tcp 8009/tcp 8448/tcp

ENTRYPOINT ["python3", "start.py"]

HEALTHCHECK --start-period=5s --interval=15s --timeout=5s \
    CMD curl -fSs http://localhost:8008/health || exit 1
