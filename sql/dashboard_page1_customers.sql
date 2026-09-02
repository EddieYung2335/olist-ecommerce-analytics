-- Looker Studio data source: Page 1 (Overview), customer grain.
-- One row per customer_unique_id. Feeds the Repeat Purchase Rate scorecard as AVG(is_repeat).

-- Joined on customer_unique_id, never customer_id: customer_id is order-scoped, so a
-- returning customer gets a new one per order and every repeat rate computed on it is 0.

-- Separate from dashboard_page1_fact because repeat rate is a customer-level average.
-- Computing it over order-item rows would weight each customer by how much they bought.

WITH customer_orders AS (
  SELECT
    c.customer_unique_id,
    c.customer_state,
    o.order_id
  FROM orders AS o
    JOIN customers AS c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
)

SELECT
  customer_unique_id,
  -- one customer_unique_id can span several customer_id rows with different states; take the most common
  MODE() WITHIN GROUP (ORDER BY customer_state) AS customer_state,
  CASE WHEN COUNT(DISTINCT order_id) > 1 THEN 1 ELSE 0 END AS is_repeat
FROM
  customer_orders
GROUP BY
  customer_unique_id;
