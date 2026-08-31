-- Revenue vs review score mismatch
-- Which categories sell well but get bad reviews?
-- High revenue + low review = burn brand trust

WITH order_review AS (
  -- collapse the 547 multi-review orders to one row each,
  -- otherwise joining reviews fans out order_items and inflates revenue
  SELECT order_id, AVG(review_score) AS score
  FROM order_reviews
  GROUP BY order_id
),

category_stats AS (
  SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown') AS category,
    SUM(oi.price) AS revenue,
    AVG(orr.score) AS avg_review_score
  FROM
    order_items AS oi
  JOIN
    orders AS o ON oi.order_id = o.order_id
  JOIN
    products AS p ON oi.product_id = p.product_id
  LEFT JOIN
    product_category_translation AS pct ON p.product_category_name = pct.product_category_name
  LEFT JOIN
    order_review AS orr ON oi.order_id = orr.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY
    category
  HAVING SUM(oi.price) > 10000
)

SELECT
  category,
  revenue,
  ROUND(avg_review_score, 2) AS avg_review_score
FROM category_stats
WHERE avg_review_score < (SELECT AVG(avg_review_score) FROM category_stats)
ORDER BY revenue DESC;



