# hw1

1. Сделал [docker-compose файл](./docker-compose.yml) где запускаю контейнер с postgres18.
В целом можно было обойтись и Dockerfile, но мне удобнее работать с docker compose.
```bash
docker compose up -d
```
2. С помощью привычной мне Goland IDE делаю новое подключение в БД:
```
host: localhost
post: 5432
database: postgres
```
3. Создаю таблицу `orders_test` - к сожалению не нашел какие колонки нужно делать - видимо это будет в будущих ДЗ.
Пока сделаем три колонки - автоинкрементный id, абстракный id покупателя и дата создания:
```postgresql
CREATE TABLE orders_test
(
    id          SERIAL PRIMARY KEY,
    customer_id INT  NOT NULL,
    created_at  DATE NOT NULL default CURRENT_DATE
);
```
4. Вставляем пару строк в таблицу:
```postgresql
INSERT INTO orders_test (customer_id, created_at) VALUES (50501, now());
INSERT INTO orders_test (customer_id, created_at) VALUES (50502, now());
```
5. Делаем проверочный select:
```postgresql
SELECT * FROM orders_test;
```
Данные были вставлены успешно:
```postgresql
1,50501,2026-06-07
2,50502,2026-06-07
```
6. Делаю пункт 8 из ДЗ - останавлию контейнер и убиваю его, затем запускаю даново.
```bast
docker compose down
docker compose up -d
```
7. Через тот же select проверяю, что данные сохранились - и они действительно там.