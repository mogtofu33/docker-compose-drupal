# Database dump

The folder `dump` contain all database dumps for _MySQL_ or _PgSQL_ created with :

```bash
./scripts/mysql dump
./scripts/pgsql dump
```

To automatically import a database dump on first launch or when the stack has been destroyed, you can copy the dump in respective folders:

```bash
./database/mysql-init
./database/pgsql-init
```

# MySQL database init

Place your uncompressed _.sql_ files in `mysql-init` to be imported when starting the stack (docker-compose up -d).

# PGSQL database init

Place your uncompressed _dump.pg_dump_ file in `pgsql-init` to be imported when starting
the stack (docker-compose up -d).
