FROM pgvector/pgvector:pg15

WORKDIR /docker-entrypoint-initdb.d

# Copy database initialization files
COPY install.sql /docker-entrypoint-initdb.d/install.sql
COPY schema/ /docker-entrypoint-initdb.d/schema/

# Set consistent encoding for database initialization
ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C.UTF-8"
