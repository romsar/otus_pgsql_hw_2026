CREATE TABLE orders_test
(
    id          SERIAL PRIMARY KEY,
    customer_id INT  NOT NULL,
    created_at  DATE NOT NULL default CURRENT_DATE
);