FROM alpine:latest
LABEL org.label-schema.name="PegaProx"
LABEL org.label-schema.description="PegaProx - A powerful datacenter management for Proxmox VE clusters."
LABEL org.label-schema.vendor="PegaProx"
LABEL org.label-schema.url="https://pegaprox.com"
LABEL org.label-schema.vcs-url="https://github.com/PegaProx/project-pegaprox"
LABEL maintainer="support@pegaprox.com"

ENV PEGAPROX_CONFIG_DIR=/app/pegaprox/config

# Install runtime dependencies and build dependencies for python-ldap
RUN apk add --no-cache python3 py3-pip openldap libsasl \
  && addgroup -S pegaprox \
  && adduser -S -G pegaprox -h /home/pegaprox pegaprox \
  && mkdir -p /app/conf /opt/venv \
  && chown -R pegaprox:pegaprox /app /home/pegaprox /opt/venv

WORKDIR /app
COPY --chown=pegaprox:pegaprox requirements.txt /app/requirements.txt

# Install build dependencies, build python packages, then remove build deps
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev \
    openldap-dev \
    cyrus-sasl-dev \
  && chown pegaprox:pegaprox /opt/venv

USER pegaprox
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"
RUN pip install --no-cache-dir -r /app/requirements.txt

USER root
RUN apk del .build-deps
USER pegaprox
COPY --chown=pegaprox:pegaprox . /app/pegaprox
RUN ls -al /app/pegaprox

VOLUME ["/app/pegaprox/config"]
EXPOSE 5000
ENTRYPOINT ["/opt/venv/bin/python", "/app/pegaprox/pegaprox_multi_cluster.py"]
