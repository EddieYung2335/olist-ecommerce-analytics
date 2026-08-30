# Data Quality Findings

Six checks in `sql/checks.sql`, run against the `olist` database.

## `customer_id` is order-scoped, `customer_unique_id` is the actual person

In the dataset, there is 99,441 distinct `customer_id` and 96,096 distinct `customer_unique_id`.

Every order gets a fresh `customer_id`. The 3,345 gap is repeat customers.

## Eight delivered orders have no delivery date

There are 8 orders with `order_status = 'delivered'` and `order_delivered_customer_date = NULL`

Delivery delay needs that date, so these 8 do not factor into the average.

## Two categories have no English translation

`pc_gamer` and `portateis_cozinha_e_preparadores_de_alimentos`.

## No exact duplicate review rows

0 duplicate `(review_id, order_id)` pairs.

## 789 `review_ids` span more than one order

One survey, several orders.

Olist splits multi-seller baskets into one order per seller, then exports the same review attached to each order.

All 789 belong to the same `customer_unique_id`.

## 547 orders carry more than one review row

547 `order_id` with multiple reviews.

These are real separate surveys, just grouped.

## 610 products have no category

Category is `NULL` for these products.
