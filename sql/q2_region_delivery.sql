-- sql/q2_region_delivery.sql 

-- Which states drive the most revenue but have the worst delivery performance (actual vs estimated delivery date)

-- Negative delivery_delay_days = delivered before the estimate (good). Positive = late

WITH order_delivery AS (
  SELECT
    o.order_id,
    c.customer_state,
    oi.price,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) AS delivery_delay_days
  FROM orders as o 
    JOIN customers as c ON o.customer_id = c.customer_id
    JOIN order_items as oi ON o.order_id = oi.order_id 
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL -- This filter drops 8 delivery with no date orders 
)

SELECT
  customer_state,
  SUM(price) as total_revenue,
  COUNT(DISTINCT order_id) as total_orders,
  ROUND(AVG(delivery_delay_days), 1) as avg_delivery_delay_days 
FROM 
  order_delivery
GROUP BY
  customer_state
HAVING
  SUM(price) > 0
ORDER BY
  total_revenue DESC; 



