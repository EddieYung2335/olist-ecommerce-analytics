-- Which month spikes?

WITH monthly_orders AS (
  SELECT 
    DATE_TRUNC('month', orders.order_purchase_timestamp) as month,
    COUNT( orders.order_id) as total_orders,
    SUM(order_items.price) as revenue
  FROM
    orders
  JOIN order_items ON orders.order_id = order_items.order_id
  WHERE orders.order_status = 'delivered'
  GROUP BY month
)

SELECT
  month,
  total_orders,
  revenue,
  LAG(total_orders) OVER (ORDER BY month) as prev_month_orders,
  ROUND(100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY month))/ NULLIF(LAG(total_orders) OVER (ORDER BY month), 0), 1) as mom_pct_change
FROM
  monthly_orders
ORDER BY
  month;
