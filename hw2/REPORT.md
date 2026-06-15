# hw1

1. Сделаем директории на хост машине, где будем имитировать "диски" для postgres:
```bash
mkdir -p ~/hw2_postgres_old_disk
mkdir -p ~/hw2_postgres_new_disk
```
2. Сделал [docker-compose файл](./docker-compose.yml) где запускаю контейнер с postgres18 используя "старый" диск.
```yaml
services:
  postgres:
    image: postgres:18
    container_name: postgres

    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

    ports:
      - "5432:5432"

    volumes:
      - ~/hw2_postgres_old_disk:/var/lib/postgresql
```

```bash
docker compose up -d
```
2. Удостоверился что кластер запущен (выполнил `docker ps` и `pg_isready` внутри контейнера):
```
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS                   PORTS                                         NAMES
e090f1ec05b3   postgres:18   "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
```

```
/var/run/postgresql:5432 - accepting connections
```
3. Коннекчусь к БД через psql. Для этого запускаю на контейнере:
```bash
psql -U postgres -d postgres
```

Создаю таблицу test и добавляю несколько строк:
```postgresql
CREATE TABLE test (
    id          SERIAL PRIMARY KEY,
    data        TEXT NOT NULL
);

INSERT INTO test(data) VALUES('foo');
INSERT INTO test(data) VALUES('bar');
```
4. Останавливаю кластер (`docker compose stop`):
5. Добавляю новый "диск":
На хост машине:
```bash
mkdir -p ~/hw2_postgres_new_disk
```
6. Копирую данные на новый "диск":
```bash
rsync -av ~/hw2_postgres_old_disk/ ~/hw2_postgres_new_disk/
```
7. Запускаем с новым диском, 
```yaml
services:
  postgres:
    image: postgres:18
    container_name: postgres

    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

    ports:
      - "5432:5432"

    volumes:
       - ~/hw2_postgres_new_disk:/mnt/data
```
8. Запускаю контейнер через `docker-compose up -d`:
Вижу что pg стартовал.
```
2026-06-15 05:52:55.848 UTC [1] LOG:  database system is ready to accept connections
```
Однако psql говорит что таблиц нет:
```
postgres=# \dt
Did not find any tables.
```
9. Надо указать правильный путь с каталогом данных.
```
docker compose stop
```

docker-compose.yaml (см. на command):
```yaml
services:
  postgres:
    image: postgres:18
    container_name: postgres

    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

    ports:
      - "5432:5432"

    volumes:
      - ~/hw2_postgres_new_disk:/mnt/data

    command: ["postgres", "-c", "data_directory=/mnt/data/18/docker"]
```
10. Запускаю контейнер еще раз, однако он не стартует:
```
2026-06-15 06:43:13.718 UTC [1] FATAL:  data directory "/mnt/data" has invalid permissions
2026-06-15 06:43:13.718 UTC [1] DETAIL:  Permissions should be u=rwx (0700) or u=rwx,g=rx (0750).
```

Добавим прав на директорию:
```bash
chmod 700 ~/hw2_postgres_new_disk/18/docker
```
11. Еще раз пробуем запустить. Видим лог:
```
LOG:  database system is ready to accept connections
```

Проверяем что работаем с новым "диском":
```
docker exec -it postgres psql -U postgres

postgres=# SHOW data_directory;
   data_directory    
---------------------
 /mnt/data/18/docker
(1 row)

postgres=# SELECT * FROM test;
 id | data 
----+------
  1 | foo
  2 | bar
(2 rows)
```

Данные есть - успех.
