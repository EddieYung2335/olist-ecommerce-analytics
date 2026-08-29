CREATE TABLE customers (
  customer_id VARCHAR(32) PRIMARY KEY,
  customer_unique_id CHAR(32) NOT NULL,
  customer_zip_code_prefix VARCHAR(32) NOT NULL,
  customer_city VARCHAR(100),
  customer_state CHAR(2)
);

CREATE TABLE sellers (
  seller_id VARCHAR(32) PRIMARY KEY,
  seller_zip_code_prefix VARCHAR(32) NOT NULL,
  seller_city VARCHAR(100),
  seller_state CHAR(2)
);

CREATE TABLE products (
  product_id VARCHAR(50) PRIMARY KEY,
  product_category_name VARCHAR(100) NULL,
  product_name_lenght INT NULL,
  product_description_lenght INT NULL,
  product_photos_qty INT NULL,
  product_weight_g INT NULL,
  product_length_cm INT NULL,
  product_height_cm INT NULL,
  product_width_cm INT NULL
);

CREATE TABLE product_category_translation (
  product_category_name VARCHAR(100) PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);

CREATE TABLE orders (
  order_id VARCHAR(32) PRIMARY KEY,
  customer_id CHAR(32) NOT NULL,
  order_status VARCHAR(32),
  order_purchase_timestamp TIMESTAMP NOT NULL,
  order_approved_at TIMESTAMP NULL,
  order_delivered_carrier_date TIMESTAMP NULL,
  order_delivered_customer_date TIMESTAMP NULL,
  order_estimated_delivery_date TIMESTAMP NULL,
  
  -- Foreign Key customer_id
  CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
  order_id VARCHAR(50) NOT NULL,
  order_item_id INT NOT NULL,
  product_id VARCHAR(50),
  seller_id VARCHAR(50) NOT NULL,
  shipping_limit_date TIMESTAMP,
  price NUMERIC(10, 2),
  freight_value NUMERIC(10, 2),

  -- Primary Key 
  PRIMARY KEY (order_id, order_item_id),

  -- Foreign Key 
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),
  CONSTRAINT fk_order_items_products 
    FOREIGN KEY (product_id)
    REFERENCES products(product_id),
  CONSTRAINT fk_order_items_sellers 
    FOREIGN KEY (seller_id)
    REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
  order_id VARCHAR(50) NOT NULL,
  payment_sequential INT NOT NULL,
  payment_type VARCHAR(50) NOT NULL,
  payment_installments INT Not NULL,
  payment_value NUMERIC(10, 2) NOT NULL,

  -- Primary Key 
  PRIMARY KEY (order_id, payment_sequential),

  -- Foreign Key 
  CONSTRAINT fk_order_payments_order 
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
  review_id VARCHAR(50) NOT NULL,
  order_id VARCHAR(50) NOT NULL,
  review_score INT CHECK (review_score BETWEEN 1 AND 5),
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date TIMESTAMP,
  review_answer_timestamp TIMESTAMP,

  -- Foreign Key 
  CONSTRAINT fk_order_reviews_order 
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);

CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);

