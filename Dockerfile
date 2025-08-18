FROM pgvector/pgvector:0.8.0-pg17

WORKDIR /docker-entrypoint-initdb.d

COPY install.sql /docker-entrypoint-initdb.d/install.sql
COPY schema/ /docker-entrypoint-initdb.d/schema/

ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C.UTF-8"
