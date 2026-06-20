# hw3

1. Сделал [docker-compose файл](./docker-compose.yml) где запускаю контейнер с postgres18.

2. Подключаюсь через psql под суперюзером postgres:
```bash
psql -U postgres -d postgres -h localhost -p 5432 
```

3. Создаю схему testnm:
```sql
CREATE SCHEMA testnm;
```

4. Удостоверяюсь что схема создана:
```
\dn *

              Список схем
        Имя         |     Владелец      
--------------------+-------------------
 information_schema | postgres
 pg_catalog         | postgres
 pg_toast           | postgres
 public             | pg_database_owner
 testnm             | postgres
(5 строк)
```

5. Создаем таблицу t1 с колонкой c1.
Вставляем одну запись.
```
CREATE TABLE t1(c1 int);

INSERT INTO t1(c1) VALUES(500);

SELECT * FROM t1;
c1  
-----
 500
(1 строка)
```

6. Создаем роль readonly, выдаем ей CONNECT к postgres, USAGE на testnm, SELECT на таблицы схемы testnm:
```sql
CREATE ROLE readonly;

GRANT CONNECT ON DATABASE postgres TO readonly;

GRANT USAGE ON SCHEMA testnm TO readonly;

GRANT SELECT ON TABLE t1 TO readonly;
```

7. Создаем юзера testread с ролью readonly:
```sql
CREATE USER testread WITH PASSWORD 'somepwd' IN ROLE readonly;
```

8. Коннектимся под этим юзером к БД:
```bash
\c postgres testread
```

9. Выполняем `select * from t1`:
```
SELECT * FROM t1;

 c1  
-----
 500
(1 строка)
```

10. Пересоздаю таблицу t1, однако теперь не в дефолтной `public` схеме, а в схеме что мы сделали: `testnm`;
```
DROP TABLE t1;

CREATE TABLE testnm.t1(c1 int);

INSERT INTO testnm.t1(c1) VALUES(500);
```

11. Делаем SELECT запрос в таблицу `t1`:
```
// под юзером testread
SELECT * FROM t1;
ERROR:  relation "t1" does not exist
СТРОКА 1: SELECT * FROM t1;

SELECT * FROM testnm.t1;
ERROR:  permission denied for table t1

// под суперюзером
GRANT SELECT ON TABLE testnm.t1 TO readonly;

// под юзером testread
SELECT * FROM testnm.t1;
 c1  
-----
 500
(1 строка)
```

12. Настраиваем поведение так, чтобы обращение к t1 было предсказуемым.
Не очень понимаю что подразумевается под предсказуемым поведением.
Можно предположить что это чтобы не надо было указывать схему при обращении к t1.
Можно добавить эту схему в search path:
```
SET search_path = testnm, public;

SELECT * FROM t1;
 c1  
-----
 500
(1 строка)

SELECT * FROM testnm.t1;
 c1  
-----
 500
(1 строка)
```
Все работает!

13. Пытаемся под ролью readonly сделать мутирующие операции:
```
CREATE TABLE t2(c1 int);
ERROR:  permission denied for schema testnm
СТРОКА 1: CREATE TABLE t2(c1 int);

INSERT INTO t1(c1) VALUES(1000);
ERROR:  permission denied for table t1
```
Все работает как ожидается, ведь мы давали доступ лишь на read.