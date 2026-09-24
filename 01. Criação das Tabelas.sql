-- Projeto: Análise dos Drivers do Frete e da Experiência do Cliente (Olist)
-- Arquivo: Criação das tabelas
-- Objetivo: Estruturar o banco de dados a partir dos datasets originais
-- SGBD: PostgreSQL

-- Tabela: itens de pedidos
CREATE TABLE order_items (
order_id TEXT,
order_item_id INTEGER,
product_id TEXT,
seller_id TEXT,
shipping_limit_date TIMESTAMP,
price NUMERIC,
freight_value NUMERIC,
PRIMARY KEY (order_id, order_item_id));

-- Tabela: clientes
CREATE TABLE customers (
customer_id TEXT PRIMARY KEY NOT NULL,
customer_unique_id TEXT,
customer_zip_code_prefix TEXT,
customer_city TEXT,
customer_state TEXT
);

-- Tabela: vendedores
CREATE TABLE sellers (
seller_id TEXT PRIMARY KEY,
seller_zip_code_prefix TEXT,
seller_city TEXT,
seller_state TEXT);

-- Tabela: pedidos
CREATE TABLE orders (
order_id TEXT PRIMARY KEY,
customer_id TEXT,
order_status TEXT,
order_purchase_timestamp TIMESTAMP,
order_approved_at TIMESTAMP,
order_delivered_carrier_date TIMESTAMP,
order_delivered_customer_date TIMESTAMP,
order_estimated_delivery_date TIMESTAMP);

-- Tabela: produtos
CREATE TABLE products (
product_id TEXT PRIMARY KEY,
product_category_name TEXT,
product_name_length INTEGER,
product_description_length INTEGER,
product_photos_qty INTEGER,
product_weight_g NUMERIC,
product_length_cm NUMERIC,
product_height_cm NUMERIC,
product_width_cm NUMERIC
);

-- Tabela: avaliações
CREATE TABLE order_reviews_dataset(
chave SERIAL PRIMARY KEY,
review_id TEXT,
order_id TEXT,
review_score NUMERIC,
review_comment_title TEXT,
review_comment_message TEXT,
review_creation_date TIMESTAMP,
review_answer_timestamp TIMESTAMP
);