# Database dump

This folder contain all database dumps for _MySQL_ or _PgSQL_ created with :

```bash
./scripts/mysql dump
./scripts/pgsql dump
```

To automatically import a database dump on first launch or when the stack has been destroyed, you can copy the dump in respective folders:

```
./database-mysql-init
./database-pgsql-init
```

See each folder README for more information.
