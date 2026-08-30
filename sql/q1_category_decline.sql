-- Did category x make less money this quarter than last quarter?

WITH category_rev AS (
  SELECT 
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown') as category, 
    DATE_TRUNC('quarter', o.order_purchase_timestamp) as quarter,
    SUM(oi.price) as revenue
  
  FROM order_items AS oi
  
  LEFT JOIN orders AS o ON o.order_id = oi.order_id
  LEFT JOIN products AS p ON p.product_id = oi.product_id
  LEFT JOIN product_category_translation AS pct ON pct.product_category_name = p.product_category_name

  WHERE o.order_status = 'delivered'
  GROUP BY category, quarter
),


qoq AS (
  SELECT
    category,
    quarter,
    revenue,
    LAG(revenue) OVER (PARTITION BY category ORDER BY quarter) AS prev_quarter_revenue
  FROM category_rev
)

SELECT 
  category,
  quarter,
  revenue,
  prev_quarter_revenue,
  ROUND(100.0 * (revenue - prev_quarter_revenue) / NULLIF(prev_quarter_revenue, 0), 1) AS pct_change
FROM qoq
WHERE prev_quarter_revenue IS NOT NULL 
ORDER BY category, quarter;
