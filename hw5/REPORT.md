# hw5

1. Сделал [docker-compose файл](./docker-compose.yml) где запускаю контейнер с postgres 18.

2. Открываю две сессии используя psql:
```bash
psql -U postgres -d postgres -h localhost -p 5432 
```
Отключаю autocommit:
```
\set AUTOCOMMIT off
```

3. Создаю таблицу и вставляю несколько записей:
```sql
CREATE TABLE orders(id serial, created_at timestamptz, amount numeric);

INSERT INTO orders VALUES (50500, now(), 100), (50501, now(), 200), (50502, now(), 300);
```

4. Провожу тесты на разных уровнях изоляции

### READ COMMITED

1. В сессии 2 начинаю транзакцию и достаю заказы за 1 минуту
```
BEGIN TRANSACTION;
SELECT COUNT(*), SUM(amount) FROM orders WHERE created_at >= now() - INTERVAL '1 minute';

// result
 count | sum 
-------+-----
     0 |    
(1 строка)
```
По дефолту транзакции в постгресе работают именно с READ COMMITED уровнем изоляции, по-этому
я ничего специально не указываю после BEGIN TRANSACTION.

2. В сессии 1 вставляю заказ и выполняю commit:
```
BEGIN TRANSACTION;
INSERT INTO orders VALUES (50503, now(), 400);
COMMIT;
```

3. Повторяю запрос из пункта 1 - достаю заказы за последнюю минуту:
```
BEGIN TRANSACTION;
SELECT COUNT(*), SUM(amount) FROM orders WHERE created_at >= now() - INTERVAL '1 minute';

// result
 count | sum 
-------+-----
     1 | 400
(1 строка)
```

Какой делаем вывод - нарушена изоляция транзакций, а именно мы видим аномалию - фантомное чтение, 
так как в нашей незакомиченной транзакции под номером 2 поменялось количество строк в рамках одного запроса на выборку заказов.

### REPEATABLE READ
1. В сессии 2 начинаю транзакцию и достаю заказы за 1 минуту:
```
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*), SUM(amount) FROM orders WHERE created_at >= now() - INTERVAL '1 minute';

// result
 count | sum 
-------+-----
     0 |    
(1 строка)
```

2. В сессии 1 вставляю заказ и выполняю commit:
```
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
INSERT INTO orders VALUES (50503, now(), 400);
COMMIT;
```

3. Повторяю запрос из пункта 1 - достаю заказы за последнюю минуту:
```
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*), SUM(amount) FROM orders WHERE created_at >= now() - INTERVAL '1 minute';

// result
 count | sum 
-------+-----
     0 |    
(1 строка)
```
В этот раз мы видим, что другая транзакция не повлияла на результат нашего запроса, 
так как мы используем более строгий уровень изоляции REPEATABLE READ, который гарантирует, 
что в рамках одной транзакции мы видим только те данные, которые были доступны на момент начала транзакции. 
Стоит отметить что это особенность postgres, так как в других СУБД при уровне изоляции REPEATABLE READ 
может возникать фантомное чтение.

REPEATABLE READ, в отличие от READ COMMITED, создаёт один снимок данных в момент начала транзакции 
(в READ COMMITED - в момент каждого запроса).
Все последующие запросы внутри этой транзакции работают с этим же снимком.

## Выводы
Чтобы отчет был консистентным рекомендуется использовать REPEATABLE READ.
Ведь это гарантируется что в рамках создания отчета (одной транзакции) данные не будут меняться: 
мы будем избавлены от аномалий фантомного чтения и неповторяющегося чтения.