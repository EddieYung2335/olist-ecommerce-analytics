-- who first bought in month X, what % ever bought again?

-- cohort_size - how many customers made first purchase that month 
-- repeat_customers - how many of those have 2+ orders total (ever, not just that month)

WITH customer_orders AS (
  SELECT
    customers.customer_unique_id, -- actual people
    order_id,
    order_purchase_timestamp
  FROM 
    orders
  JOIN 
    customers ON orders.customer_id = customers.customer_id
  WHERE orders.order_status = 'delivered'
),

cohort AS (
  SELECT
    customer_unique_id,
    DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month,
    COUNT(DISTINCT order_id) as total_orders 
  FROM  
    customer_orders
  GROUP BY
    customer_unique_id
)

SELECT
  cohort_month, 
  COUNT(*) as cohort_size,
  SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)  as repeat_customers,
  ROUND(100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as repeat_rate_pct
FROM
  cohort
GROUP BY 
  cohort_month
ORDER BY
  cohort_month;
