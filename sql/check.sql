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
  customers
--
-- Check 2: delivered orders with no delivery date 
-- Delay = actual_delivery - estimated_delivery | Null date -> row silently dropped from average
--
-- Check 3 categories with no English translation
-- Missing translation -> category disappear from output | shows under Portuguese name and looks like separate category
--
-- duplicate reviews
-- One order with 2 review rows -> every item in that order counted twice -> revenue inflated
--
-- products with NULL category 
-- Product with no label cannot group, aim to understand how much revenue sits in that hole
