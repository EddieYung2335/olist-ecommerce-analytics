-- Looker Studio data source: Page 1 (Overview), fact grain.
-- One row per order_items row, delivered orders only.
-- Feeds: Total Revenue SUM(price), Total Orders COUNT_DISTINCT(order_id),
--        Avg Delivery Delay AVG(delivery_delay_days), monthly trend, category bar, state filter.

-- Negative delivery_delay_days = delivered before the estimate (good). Positive = late.
-- Left as NULL when order_delivered_customer_date is missing (8 orders) so those rows
-- still count toward revenue but are ignored by AVG.

SELECT
  oi.order_id,
  o.order_purchase_timestamp,
  c.customer_state,
  COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown') AS category,
  oi.price,
  EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) AS delivery_delay_days

FROM order_items AS oi

  JOIN orders AS o ON o.order_id = oi.order_id
  JOIN customers AS c ON c.customer_id = o.customer_id
  LEFT JOIN products AS p ON p.product_id = oi.product_id
  LEFT JOIN product_category_translation AS pct ON pct.product_category_name = p.product_category_name

WHERE o.order_status = 'delivered';
