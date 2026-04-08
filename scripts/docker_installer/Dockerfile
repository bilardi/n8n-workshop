FROM python:3.12-alpine AS python-donor

FROM docker.n8n.io/n8nio/n8n
USER root
COPY --from=python-donor /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python-donor /usr/local/bin/python3.12 /usr/local/bin/python3.12
COPY --from=python-donor /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-donor /usr/local/lib/libpython3.12.so.1.0 /usr/local/lib/libpython3.12.so.1.0
RUN ln -sf /usr/local/lib/libpython3.12.so.1.0 /usr/local/lib/libpython3.so && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python
USER node
