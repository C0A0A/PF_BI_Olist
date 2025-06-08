-- PostgreSQL olist_dw database creation
-- PostgreSQL version 14.4

-- ATENTION: Uncomment if the database does not yet exist
-- CREATE DATABASE olist_dw WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';

\connect olist_dw

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = true;
SET xmloption = content;
SET client_min_messages = warning;

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
COMMENT ON EXTENSION "uuid-ossp" IS 'support for generation of UUID datatypes';


CREATE TABLE public.orders (
    order_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    customer_id UUID
);

CREATE TABLE public.order_payments (
    payment_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    payment_sequential INT,
    payment_type VARCHAR(255),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    order_id UUID
);

CREATE TABLE public.order_reviews (
    review_unique_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    review_id UUID,
    review_score INT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    order_id UUID
);

CREATE TABLE public.order_items (
    item_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    order_item_id INT,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    order_id UUID,
    product_id UUID,
    seller_id UUID
);

CREATE TABLE public.customers (
    customer_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    customer_zip_code_prefix VARCHAR(20) NOT NULL,
    customer_city VARCHAR(255) NOT NULL,
    customer_state VARCHAR(255) NOT NULL
);

CREATE TABLE public.products (
    product_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    product_category_name VARCHAR(255),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE public.product_category_name_translation (
    translation_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    product_category_name VARCHAR(255),
    product_category_name_english VARCHAR(255)
);

CREATE TABLE public.geolocation (
    geolocation_id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    geolocation_zip_code_prefix VARCHAR(20) NOT NULL,
    geolocation_lat DECIMAL(9,6),
    geolocation_lng DECIMAL(9,6),
    geolocation_city VARCHAR(255),
    geolocation_state VARCHAR(255)
);

ALTER TABLE public.orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);

ALTER TABLE public.order_payments
ADD CONSTRAINT fk_order_payments_orders
FOREIGN KEY (order_id) REFERENCES public.orders(order_id);

ALTER TABLE public.order_reviews
ADD CONSTRAINT fk_order_reviews_orders
FOREIGN KEY (order_id) REFERENCES public.orders(order_id);

ALTER TABLE public.order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id) REFERENCES public.orders(order_id);

ALTER TABLE public.order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id) REFERENCES public.products(product_id);

ALTER TABLE public.product_category_name_translation
ADD CONSTRAINT unique_product_category_name
UNIQUE (product_category_name);

ALTER TABLE public.geolocation
ADD CONSTRAINT unique_geolocation_zip_code_prefix
UNIQUE (geolocation_zip_code_prefix);

-- SP ETL JOBS
CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_customers()
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO public.customers (customer_id, customer_zip_code_prefix, customer_city, customer_state)
    SELECT
        customer_id::uuid,
        customer_zip_code_prefix::text,
        customer_city,
        customer_state
    FROM public.stg_customers;
END;
$$;

CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_orders() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.orders (order_id, order_status, order_purchase_timestamp, order_approved_at,
                               order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, customer_id)
    SELECT
		order_id::uuid,
		order_status,
        order_purchase_timestamp::timestamp,
        order_approved_at::timestamp,
        order_delivered_carrier_date::timestamp,
        order_delivered_customer_date::timestamp,
        order_estimated_delivery_date::timestamp,
        customer_id::uuid
    FROM public.stg_orders;

END;
$$;


CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_products() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.products 
	(product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    SELECT
		product_id::uuid,
		product_category_name,
		product_name_length::double precision,
		product_description_length::double precision,
		product_photos_qty::double precision,
		product_weight_g::double precision,
		product_length_cm::double precision,
		product_height_cm::double precision,
		product_width_cm::double precision
    FROM public.stg_products;

END;
$$;


CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_geolocation() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.geolocation(
	geolocation_id, geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
	SELECT
		uuid_generate_v4() geolocation_id,
		geolocation_zip_code_prefix::character varying,
		geolocation_lat::double precision,
		geolocation_lng::double precision,
		geolocation_city,
		geolocation_state
    FROM public.stg_geolocation;

END;
$$;


CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_order_items() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.order_items(
	item_id, order_item_id, shipping_limit_date, price, freight_value, order_id, product_id, seller_id)
	SELECT
		uuid_generate_v4() item_id,
		order_item_id::integer,
		shipping_limit_date::timestamp without time zone,
		price::numeric(10,2),
		freight_value::numeric(10,2),
		order_id::uuid,
		product_id::uuid,
		seller_id::uuid
    FROM public.stg_order_items;

END;
$$;

CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_order_payments() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.order_payments(
	payment_id, payment_sequential, payment_type, payment_installments, payment_value, order_id)
	SELECT
		uuid_generate_v4() payment_id,
		payment_sequential::integer,
		payment_type::character varying(255),
		payment_installments::integer,
		payment_value::numeric(10,2),
		order_id::uuid
    FROM public.stg_order_payments;

END;
$$;

CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_order_reviews() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.order_reviews(
	review_unique_id, review_id, review_score, review_creation_date, review_answer_timestamp, order_id)
	SELECT
		uuid_generate_v4() review_unique_id,
		review_id::uuid,
		review_score::integer,
		review_creation_date::timestamp without time zone,
		review_answer_timestamp::timestamp without time zone,
		order_id::uuid
    FROM public.stg_order_reviews;

END;
$$;

CREATE OR REPLACE PROCEDURE public.transfer_data_from_stg_to_product_category_name_tr() 
LANGUAGE PLPGSQL 
AS 
$$
BEGIN
    INSERT INTO public.product_category_name_translation(
	translation_id, product_category_name, product_category_name_english)
	SELECT
		uuid_generate_v4() translation_id,
		product_category_name::character varying(255),
		product_category_name_english::character varying(255)
    FROM public.stg_product_category_name_translation;

END;
$$;