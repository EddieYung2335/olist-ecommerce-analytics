-- sql/checks.sql


-- evidence file, looking and writing down what I saw
-- Prove load worked
-- Find dirt that would silently break later queries
-- Produce real numbers for check_findings.md and README
-- The file should only READ



-- Check 1: customer_id vs customer_unique_id
-- Make sure the repeated purchases is well documented
SELECT 
  COUNT(DISTINCT customer_id) AS "distinct_customer_id",
  COUNT(DISTINCT customer_unique_id) AS "distinct_customer_unique_id"
FROM  
  customers;


--
-- Check 2: delivered orders with no delivery date 
-- Delay = actual_delivery - estimated_delivery | Null date -> row silently dropped from average
SELECT
  COUNT(*) as delivered_but_no_delivery_date
FROM 
  orders
WHERE
  order_status = 'delivered'
  AND 
  order_delivered_customer_date IS NULL;



-- Check 3 categories with no English translation
-- Missing translation -> category disappear from output | shows under Portuguese name and looks like separate category
SELECT
  DISTINCT p.product_category_name
FROM 
  products as p 
LEFT JOIN 
  product_category_translation as t 
ON 
  p.product_category_name = t.product_category_name
WHERE 
  t.product_category_name_english IS NULL 
  AND
  p.product_category_name IS NOT NULL;


-- duplicate reviews
-- maria do survey twice
-- One order with 2 review rows -> every item in that order counted twice -> revenue inflated
SELECT review_id, order_id, COUNT(*) as count_of_duplicate_reviews
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;
-- This check return 0

-- one review spans on several orders (maria buy products from different seller) & one orders with many reviews (maria write several reviews for one seller) 
SELECT
  (SELECT COUNT(*) FROM (
     SELECT review_id
     FROM order_reviews
     GROUP BY review_id
     HAVING COUNT(DISTINCT order_id) > 1
   ) AS r) AS review_ids_on_multiple_orders,
  (SELECT COUNT(*) FROM (
     SELECT order_id
     FROM order_reviews
     GROUP BY order_id
     HAVING COUNT(*) > 1
   ) AS o) AS order_ids_with_multiple_reviews;




-- products with NULL category 
-- Product with no label cannot group, aim to understand how much revenue sits in that hole
SELECT COUNT(*) as product_wo_category_name
FROM products
WHERE product_category_name IS NULL;

