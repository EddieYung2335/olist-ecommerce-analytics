-- What % of sellers drive 80% of revenue

-- revenue per seller 
WITH seller_rev AS (
  SELECT
    seller_id,
    SUM(price) AS revenue

  FROM
    order_items
  
  JOIN orders ON order_items.order_id = orders.order_id
  
  WHERE orders.order_status='delivered'
  
  GROUP BY seller_id
),

ranked AS (
  SELECT 
    seller_id,
    revenue,
    RANK() over (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) over (ORDER BY revenue DESC) AS running_total -- sum from everything from the first row to this row
  FROM
    seller_rev
)

SELECT
  seller_id,
  revenue,
  revenue_rank,
  ROUND(100.0 * running_total/(SELECT SUM(revenue) from seller_rev), 1) as cumulative_pct_of_revenue
FROM ranked
ORDER BY revenue_rank;
