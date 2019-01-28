# PGSQL database dump

Place your uncompressed _dump.pg_dump_ file here to be imported when starting
the stack (docker-compose up -d).

When the stack is started, you can use this command to create a *PgSQL* dump in *./database-dump*.

```bash
./scripts/pgsql dump
```

Then if you copy the file in *./database-pgsql-init* and rename to
_dump.pg_dump_ , it will automatically be imported when the stack is started
after being destroyed (docker-compose down && docker-compose up -d).
