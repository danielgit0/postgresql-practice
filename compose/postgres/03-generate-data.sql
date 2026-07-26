-- ==========================================================
-- PostgreSQL Advanced Practice: Data Generation Engine
-- ==========================================================

CREATE OR REPLACE PROCEDURE generate_demo_data(
    p_departments      int DEFAULT 15,
    p_employees        int DEFAULT 100,
    p_users            int DEFAULT 1000,
    p_suppliers        int DEFAULT 50,
    p_categories       int DEFAULT 30,
    p_products         int DEFAULT 200,
    p_orders           int DEFAULT 5000,
    p_max_order_items  int DEFAULT 5,
    p_sessions         int DEFAULT 3000,
    p_api_requests     int DEFAULT 15000,
    p_audit_logs       int DEFAULT 10000,
    p_inventory        boolean DEFAULT true,
    p_payments         boolean DEFAULT true,
    p_shipments        boolean DEFAULT true,
    p_logins_per_user  int DEFAULT 12  -- average logins per user
)
AS $$
DECLARE
    -- Arrays for lookup and fast in-memory random picking
    v_dept_ids bigint[];
    v_mgr_ids bigint[];
    v_user_ids uuid[];
    v_supplier_ids bigint[];
    v_category_ids bigint[];
    v_prod_ids bigint[];
    v_prod_prices numeric[];
    
    -- Count variables
    v_mgr_count int;
    v_root_cat_count int;
    v_total_users int;
    v_total_orders int;
    v_total_products int;
    v_total_sessions int;
    
    -- Names lists for departments and enums
    dept_names text[] := ARRAY[
        'Engineering', 'Sales', 'Marketing', 'Human Resources', 'Finance', 
        'Operations', 'Legal', 'Product Management', 'Customer Success', 'IT Support',
        'Quality Assurance', 'Security', 'Research & Development', 'Procurement', 'Public Relations'
    ];
    
    cat_names text[] := ARRAY[
        'Electronics', 'Home & Kitchen', 'Apparel & Fashion', 'Books & Media', 'Sports & Outdoors',
        'Beauty & Personal Care', 'Automotive', 'Toys & Games', 'Office Products', 'Garden & Outdoor',
        'Tools & Home Improvement', 'Pet Supplies', 'Grocery & Gourmet Food', 'Health & Household', 'Baby'
    ];
    
    sub_names text[] := ARRAY[
        'Audio & Headphones', 'Computers & Accessories', 'Mobile Phones', 'Television & Video', 'Cameras',
        'Cookware', 'Furniture', 'Bedding', 'Appliances', 'Smart Home',
        'Mens Clothing', 'Womens Clothing', 'Footwear', 'Accessories', 'Luggage',
        'Fiction', 'Non-Fiction', 'Biographies', 'Self-Help', 'Childrens Books',
        'Fitness & Exercise', 'Camping & Hiking', 'Cycling', 'Water Sports', 'Team Sports',
        'Makeup', 'Skincare', 'Haircare', 'Fragrances', 'Tools & Accessories'
    ];
    
    adjectives text[] := ARRAY[
        'Ultra', 'Premium', 'Smart', 'Eco', 'Classic', 'Pro', 'Wireless', 'Portable', 'HD', 'Ergonomic', 
        'Compact', 'Deluxe', 'Pocket', 'Heavy-Duty', 'Advanced', 'Digital', 'Hybrid', 'Mini', 'Super', 'Active'
    ];
    
    nouns text[] := ARRAY[
        'Gadget', 'Device', 'Machine', 'Assistant', 'Organizer', 'Shield', 'Charger', 'Hub', 'Bottle', 'Pack', 
        'Toolkit', 'Monitor', 'Light', 'Case', 'Stand', 'Station', 'Tracker', 'Brush', 'Speaker', 'Keyboard'
    ];
    
    providers text[] := ARRAY['Stripe', 'PayPal', 'Apple Pay', 'Google Pay', 'Visa', 'Mastercard', 'Wire Transfer'];
    carriers text[] := ARRAY['FedEx', 'UPS', 'DHL', 'USPS', 'Amazon Logistics'];
    
    user_agents text[] := ARRAY[
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/605.1.15',
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0'
    ];
    
    operations text[] := ARRAY['INSERT', 'UPDATE', 'DELETE'];
    entities text[] := ARRAY['users', 'orders', 'products'];
BEGIN
    RAISE NOTICE 'Starting data generation...';

    -- ==========================================================
    -- 1. DEPARTMENTS
    -- ==========================================================
    RAISE NOTICE 'Step 1/11: Generating departments...';
    INSERT INTO departments (name, location, budget)
    SELECT 
        CASE 
            WHEN i <= array_length(dept_names, 1) THEN dept_names[i]
            ELSE 'Department ' || i
        END,
        random_city() || ', Bldg ' || random_between(1, 10),
        random_between(50000.00, 2000000.00)
    FROM generate_series(1, p_departments) AS i
    ON CONFLICT (name) DO NOTHING;

    -- Collect department IDs
    SELECT array_agg(id) INTO v_dept_ids FROM departments;

    -- ==========================================================
    -- 2. EMPLOYEES & HIERARCHY
    -- ==========================================================
    RAISE NOTICE 'Step 2/11: Generating employees and management hierarchy...';
    
    -- Tier-1 Managers (10% of employees, min 1)
    v_mgr_count := GREATEST(1, p_employees / 10);
    
    WITH inserted_mgrs AS (
        INSERT INTO employees (manager_id, department_id, first_name, last_name, email, hire_date, salary)
        SELECT 
            NULL,
            random_item(v_dept_ids),
            f_name,
            l_name,
            lower(regexp_replace(f_name, '[^a-zA-Z]', '', 'g')) || '.' ||
                lower(regexp_replace(l_name, '[^a-zA-Z]', '', 'g')) || '.' ||
                i || '@ourcompany.com',
            random_date('2015-01-01'::date, '2023-01-01'::date),
            random_between(80000.00, 250000.00)
        FROM (
            SELECT 
                i,
                random_first_name() AS f_name, 
                random_last_name() AS l_name
            FROM generate_series(1, v_mgr_count) AS i
        ) s
        RETURNING id
    )
    SELECT array_agg(id) INTO v_mgr_ids FROM inserted_mgrs;

    -- Standard Employees referencing managers
    IF p_employees > v_mgr_count THEN
        INSERT INTO employees (manager_id, department_id, first_name, last_name, email, hire_date, salary)
        SELECT 
            random_item(v_mgr_ids),
            random_item(v_dept_ids),
            f_name,
            l_name,
            lower(regexp_replace(f_name, '[^a-zA-Z]', '', 'g')) || '.' ||
                lower(regexp_replace(l_name, '[^a-zA-Z]', '', 'g')) || '.' ||
                (v_mgr_count + i) || '@ourcompany.com',
            random_date('2018-01-01'::date, '2026-01-01'::date),
            random_between(40000.00, 120000.00)
        FROM (
            SELECT 
                i,
                random_first_name() AS f_name, 
                random_last_name() AS l_name
            FROM generate_series(1, p_employees - v_mgr_count) AS i
        ) s;
    END IF;

    -- Collect all employee IDs (will be used for orders)
    SELECT array_agg(id) INTO v_mgr_ids FROM employees;

    -- ==========================================================
    -- 3. USERS
    -- ==========================================================
    RAISE NOTICE 'Step 3/11: Generating users...';
    
    INSERT INTO users (email, username, first_name, last_name, phone, status, birth_date, country, city, preferences, created_at, updated_at)
    SELECT 
        lower(f_name) || '.' || lower(l_name) || '.' || i || '@' || random_item(ARRAY['gmail.com', 'yahoo.com', 'outlook.com', 'protonmail.com', 'icloud.com']),
        lower(f_name) || '_' || lower(l_name) || '_' || i,
        f_name,
        l_name,
        random_phone(),
        random_weighted_item(ARRAY['ACTIVE', 'INACTIVE', 'SUSPENDED']::user_status[], ARRAY[85, 10, 5]),
        random_date('1970-01-01'::date, '2005-12-31'::date),
        country,
        city,
        random_json_preferences(),
        created_ts,
        created_ts + (random() * (now() - created_ts))
    FROM (
        SELECT 
            i,
            random_first_name() AS f_name,
            random_last_name() AS l_name,
            random_country() AS country,
            random_city() AS city,
            random_timestamp(now() - INTERVAL '5 years', now() - INTERVAL '1 month') AS created_ts
        FROM generate_series(1, p_users) AS i
    ) s;

    -- Collect user IDs
    SELECT array_agg(id) INTO v_user_ids FROM users;
    v_total_users := array_length(v_user_ids, 1);

    -- ==========================================================
    -- 3b. USER LOGINS (login history per user)
    -- ==========================================================
    RAISE NOTICE 'Step 3b/11: Generating user login history...';

    INSERT INTO user_logins (user_id, login_at, ip_address, device, successful)
    SELECT
        u.id,
        -- Spread logins randomly between account creation and now
        u.created_at + (random() * (now() - u.created_at)),
        (
            random_between(24, 220) || '.' ||
            random_between(10, 240) || '.' ||
            random_between(0,  254) || '.' ||
            random_between(1,  254)
        )::inet,
        random_item(ARRAY['Chrome / Windows', 'Safari / macOS', 'Firefox / Linux',
                          'Chrome / Android', 'Safari / iOS', 'Edge / Windows']),
        -- 90% successful logins
        random_weighted_item(ARRAY[true, false], ARRAY[90, 10])
    FROM users u
    -- Generate a variable number of logins per user (1 to 2×avg)
    CROSS JOIN LATERAL generate_series(
        1,
        GREATEST(1, random_between(1, p_logins_per_user * 2))
    ) AS login_n;

    -- ==========================================================
    -- 4. CATEGORIES & HIERARCHY
    -- ==========================================================
    RAISE NOTICE 'Step 4/11: Generating categories and subcategories...';
    
    -- Root categories
    v_root_cat_count := GREATEST(3, p_categories / 5);
    v_root_cat_count := LEAST(v_root_cat_count, array_length(cat_names, 1));
    
    WITH inserted_roots AS (
        INSERT INTO categories (parent_id, name, description, created_at)
        SELECT 
            NULL,
            cat_names[i],
            'Top level category for ' || cat_names[i],
            random_timestamp(now() - INTERVAL '6 years', now() - INTERVAL '4 years')
        FROM generate_series(1, v_root_cat_count) AS i
        RETURNING id
    )
    SELECT array_agg(id) INTO v_category_ids FROM inserted_roots;
    
    -- Subcategories referencing root categories
    IF p_categories > v_root_cat_count THEN
        INSERT INTO categories (parent_id, name, description, created_at)
        SELECT 
            random_item(v_category_ids),
            CASE 
                WHEN i <= array_length(sub_names, 1) THEN sub_names[i]
                ELSE 'Subcategory ' || i
            END,
            'Subcategory description for ' || i,
            random_timestamp(now() - INTERVAL '4 years', now() - INTERVAL '2 years')
        FROM generate_series(1, p_categories - v_root_cat_count) AS i;
    END IF;

    -- Re-collect all category IDs
    SELECT array_agg(id) INTO v_category_ids FROM categories;

    -- ==========================================================
    -- 5. SUPPLIERS
    -- ==========================================================
    RAISE NOTICE 'Step 5/11: Generating suppliers...';
    
    INSERT INTO suppliers (company_name, contact_name, email, phone, country, metadata)
    SELECT 
        comp,
        f_name || ' ' || l_name,
        random_email(f_name, l_name, comp),
        random_phone(),
        country,
        random_json_metadata()
    FROM (
        SELECT 
            random_company_name() || ' ' || i AS comp,
            random_first_name() AS f_name,
            random_last_name() AS l_name,
            random_country() AS country,
            i
        FROM generate_series(1, p_suppliers) AS i
    ) s;

    -- Collect supplier IDs
    SELECT array_agg(id) INTO v_supplier_ids FROM suppliers;

    -- ==========================================================
    -- 6. PRODUCTS
    -- ==========================================================
    RAISE NOTICE 'Step 6/11: Generating products and SKUs...';
    
    INSERT INTO products (supplier_id, category_id, sku, name, description, price, cost, active, metadata)
    SELECT 
        random_item(v_supplier_ids),
        random_item(v_category_ids),
        'PRD-' || upper(random_item(ARRAY['EL', 'HM', 'AP', 'BK', 'SP', 'BE', 'AU', 'TY', 'OF', 'GD'])) || '-' || lpad(i::text, 6, '0'),
        random_item(adjectives) || ' ' || random_item(nouns) || ' ' || i,
        'High quality product generated for training and optimization testing. Description for product #' || i,
        price,
        cost,
        random() > 0.05,
        jsonb_build_object(
            'warranty_months', random_weighted_item(ARRAY[12, 24, 36, 0], ARRAY[60, 25, 5, 10]),
            'weight_kg', random_between(0.1, 25.0),
            'dimensions', jsonb_build_object(
                'width_cm', random_between(5.0, 100.0),
                'height_cm', random_between(5.0, 100.0),
                'depth_cm', random_between(5.0, 100.0)
            )
        )
    FROM (
        SELECT 
            i,
            price,
            round((price * random_between(0.5, 0.8))::numeric, 2) AS cost
        FROM (
            SELECT 
                i,
                random_between(4.99, 1499.99) AS price
            FROM generate_series(1, p_products) AS i
        ) s1
    ) s2;

    -- Collect product IDs and prices
    SELECT array_agg(id), array_agg(price) INTO v_prod_ids, v_prod_prices FROM products;
    v_total_products := array_length(v_prod_ids, 1);

    -- ==========================================================
    -- 7. INVENTORY
    -- ==========================================================
    IF p_inventory THEN
        RAISE NOTICE 'Step 7/11: Generating inventory stock & transactions...';
        
        DECLARE
            v_warehouses text[] := ARRAY['Central Warehouse', 'East Coast Hub', 'West Coast Logistics', 'Southern Distribution'];
        BEGIN
            WITH inserted_inventory AS (
                INSERT INTO inventory (product_id, quantity, warehouse, last_updated)
                SELECT 
                    p_id,
                    random_between(10, 1000),
                    random_item(v_warehouses),
                    random_timestamp(now() - INTERVAL '1 year', now())
                FROM unnest(v_prod_ids) AS p_id
                RETURNING id, quantity
            )
            INSERT INTO inventory_transactions (inventory_id, transaction_type, quantity, reference, created_at)
            SELECT 
                id,
                'PURCHASE',
                quantity,
                'INITIAL_STOCK',
                now() - INTERVAL '1 year'
            FROM inserted_inventory;
        END;
    ELSE
        RAISE NOTICE 'Step 7/11: Skipping inventory generation.';
    END IF;

    -- ==========================================================
    -- 8. ORDERS & ORDER ITEMS
    -- ==========================================================
    RAISE NOTICE 'Step 8/11: Generating orders & associated items...';
    
    -- Optimize user offset scans by joining generate_series directly using array indexing
    WITH order_data AS (
        SELECT 
            u.id AS user_id,
            CASE WHEN random() > 0.3 THEN random_item(v_mgr_ids) ELSE NULL END AS employee_id,
            random_weighted_item(
                ARRAY['PENDING', 'PROCESSING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED']::order_status[],
                ARRAY[5, 10, 20, 15, 40, 7, 3]
            ) AS status,
            random_address(u.city, u.country) AS shipping_addr,
            random_timestamp(now() - INTERVAL '3 years', now()) AS created_ts
        FROM (
            SELECT 
                v_user_ids[random_between(1, v_total_users)] AS u_id
            FROM generate_series(1, p_orders)
        ) s
        JOIN users u ON u.id = s.u_id
    )
    INSERT INTO orders (user_id, employee_id, status, total_amount, shipping_address, billing_address, created_at, updated_at)
    SELECT 
        user_id,
        employee_id,
        status,
        0.00, -- Seed total amount (updated after items insert)
        shipping_addr,
        CASE WHEN random() > 0.15 THEN shipping_addr ELSE random_address(random_city(), random_country()) END,
        created_ts,
        created_ts + (random() * (now() - created_ts))
    FROM order_data;

    -- Generate items for the newly created orders
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
    SELECT 
        o.id,
        v_prod_ids[p_idx],
        random_between(1, 5),
        v_prod_prices[p_idx],
        CASE WHEN random() > 0.8 THEN random_between(1.00, v_prod_prices[p_idx] * 0.2) ELSE 0.00 END
    FROM (
        SELECT id 
        FROM orders
        WHERE total_amount = 0.00
    ) o
    CROSS JOIN LATERAL (
        SELECT 
            random_between(1, v_total_products) AS p_idx
        FROM generate_series(1, random_between(1, p_max_order_items))
    ) items;

    -- Recalculate and update order total_amounts
    WITH order_totals AS (
        SELECT 
            order_id, 
            SUM(quantity * (unit_price - discount)) AS total
        FROM order_items
        GROUP BY order_id
    )
    UPDATE orders o
    SET total_amount = ot.total
    FROM order_totals ot
    WHERE o.id = ot.order_id AND o.total_amount = 0.00;

    -- Recalculate inventory based on order items
    IF p_inventory THEN
        -- Insert SALE transactions for items ordered
        INSERT INTO inventory_transactions (inventory_id, transaction_type, quantity, reference, created_at)
        SELECT 
            inv.id,
            'SALE',
            oi.quantity,
            'ORDER_' || oi.order_id,
            o.created_at
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        JOIN inventory inv ON inv.product_id = oi.product_id
        WHERE o.total_amount > 0.00;
        
        -- Deduct from physical stock
        WITH inventory_sales AS (
            SELECT 
                inv.id AS inv_id,
                SUM(oi.quantity) AS total_sold
            FROM order_items oi
            JOIN orders o ON o.id = oi.order_id
            JOIN inventory inv ON inv.product_id = oi.product_id
            GROUP BY inv.id
        )
        UPDATE inventory inv
        SET quantity = GREATEST(0, inv.quantity - sales.total_sold),
            last_updated = now()
        FROM inventory_sales sales
        WHERE inv.id = sales.inv_id;
    END IF;

    -- ==========================================================
    -- 9. PAYMENTS
    -- ==========================================================
    IF p_payments THEN
        RAISE NOTICE 'Step 9/11: Generating payment transactions...';
        
        INSERT INTO payments (order_id, status, provider, transaction_id, amount, paid_at, metadata, created_at)
        SELECT 
            o.id,
            p_status,
            random_item(providers),
            encode(gen_random_bytes(16), 'hex'),
            o.total_amount,
            CASE WHEN p_status IN ('SUCCESS', 'REFUNDED') THEN o.created_at + INTERVAL '5 minutes' ELSE NULL END,
            jsonb_build_object(
                'gateway_response', jsonb_build_object(
                    'code', CASE WHEN p_status = 'SUCCESS' THEN 'auth_approved' WHEN p_status = 'FAILED' THEN 'card_declined' ELSE 'pending' END,
                    'avs_match', random() > 0.1
                )
            ),
            o.created_at
        FROM orders o
        CROSS JOIN LATERAL (
            SELECT 
                CASE o.status
                    WHEN 'PENDING' THEN 'PENDING'::payment_status
                    WHEN 'PROCESSING' THEN 'SUCCESS'::payment_status
                    WHEN 'PAID' THEN 'SUCCESS'::payment_status
                    WHEN 'SHIPPED' THEN 'SUCCESS'::payment_status
                    WHEN 'DELIVERED' THEN 'SUCCESS'::payment_status
                    WHEN 'CANCELLED' THEN random_weighted_item(ARRAY['FAILED', 'SUCCESS']::payment_status[], ARRAY[80, 20])
                    WHEN 'REFUNDED' THEN 'REFUNDED'::payment_status
                END AS p_status
        ) pay_status
        WHERE o.id NOT IN (SELECT order_id FROM payments);
    ELSE
        RAISE NOTICE 'Step 9/11: Skipping payment generation.';
    END IF;

    -- ==========================================================
    -- 10. SHIPMENTS
    -- ==========================================================
    IF p_shipments THEN
        RAISE NOTICE 'Step 10/11: Generating shipping tracking records...';
        
        INSERT INTO shipments (order_id, tracking_number, carrier, status, shipped_at, delivered_at, metadata)
        SELECT 
            o.id,
            '1Z' || upper(encode(gen_random_bytes(8), 'hex')),
            random_item(carriers),
            ship_status,
            shipped_date,
            delivered_date,
            jsonb_build_object(
                'dimensions_declared', true,
                'service_type', random_item(ARRAY['Standard', 'Express', 'Overnight']),
                'shipment_fees', random_between(4.99, 45.00)
            )
        FROM orders o
        CROSS JOIN LATERAL (
            SELECT 
                CASE o.status
                    WHEN 'PAID' THEN random_weighted_item(ARRAY['CREATED', 'PICKED']::shipment_status[], ARRAY[50, 50])
                    WHEN 'SHIPPED' THEN 'IN_TRANSIT'::shipment_status
                    WHEN 'DELIVERED' THEN 'DELIVERED'::shipment_status
                    WHEN 'REFUNDED' THEN random_weighted_item(ARRAY['DELIVERED', 'RETURNED']::shipment_status[], ARRAY[40, 60])
                    ELSE NULL
                END AS ship_status
        ) s_status
        CROSS JOIN LATERAL (
            SELECT 
                CASE 
                    WHEN ship_status IN ('IN_TRANSIT', 'DELIVERED', 'RETURNED') THEN o.created_at + (random() * INTERVAL '24 hours') + INTERVAL '12 hours'
                    ELSE NULL
                END AS shipped_date
        ) s_date
        CROSS JOIN LATERAL (
            SELECT 
                CASE 
                    WHEN ship_status IN ('DELIVERED', 'RETURNED') THEN shipped_date + (random() * INTERVAL '4 days') + INTERVAL '1 day'
                    ELSE NULL
                END AS delivered_date
        ) d_date
        WHERE ship_status IS NOT NULL
          AND o.id NOT IN (SELECT order_id FROM shipments);
    ELSE
        RAISE NOTICE 'Step 10/11: Skipping shipment generation.';
    END IF;

    -- ==========================================================
    -- 11. SESSIONS, API REQUESTS & AUDIT LOGS
    -- ==========================================================
    RAISE NOTICE 'Step 11/11: Generating user sessions, API logs & audit trails...';
    
    -- Generate User Sessions
    INSERT INTO sessions (id, user_id, ip_address, user_agent, started_at, ended_at, metadata)
    SELECT 
        gen_random_uuid(),
        random_item(v_user_ids),
        (random_between(24, 220) || '.' || random_between(10, 240) || '.' || random_between(0, 254) || '.' || random_between(1, 254))::inet,
        random_item(user_agents),
        started_ts,
        started_ts + (random() * INTERVAL '3 hours') + INTERVAL '2 minutes',
        random_json_metadata()
    FROM (
        SELECT random_timestamp(now() - INTERVAL '3 years', now()) AS started_ts
        FROM generate_series(1, p_sessions)
    ) s;

    -- Store active sessions in indexed temp table for lightning fast join access
    CREATE TEMP TABLE temp_sessions (
        row_idx serial primary key,
        id uuid,
        user_id uuid,
        started_at timestamptz,
        ended_at timestamptz
    ) ON COMMIT DROP;
    
    INSERT INTO temp_sessions (id, user_id, started_at, ended_at)
    SELECT id, user_id, started_at, ended_at FROM sessions;
    
    SELECT COUNT(*) INTO v_total_sessions FROM temp_sessions;

    -- Generate API requests referencing session indexing
    IF v_total_sessions > 0 THEN
        DECLARE
            endpoints text[] := ARRAY['/api/v1/products', '/api/v1/products/search', '/api/v1/cart', '/api/v1/checkout', '/api/v1/users/profile', '/api/v1/orders', '/api/v1/categories', '/api/v1/auth/session'];
            methods text[] := ARRAY['GET', 'GET', 'POST', 'POST', 'GET', 'GET', 'GET', 'GET'];
        BEGIN
            INSERT INTO api_requests (session_id, user_id, method, endpoint, response_code, duration_ms, request_body, response_body, created_at)
            SELECT 
                ts.id,
                ts.user_id,
                meth,
                endp,
                random_weighted_item(ARRAY[200, 201, 400, 401, 404, 500], ARRAY[85, 8, 3, 2, 1, 1]),
                random_between(5, 1500),
                CASE 
                    WHEN meth IN ('POST', 'PUT') THEN jsonb_build_object('action', 'save', 'device', ts.id)
                    ELSE NULL 
                END,
                jsonb_build_object('response_time_ms', random_between(5, 50)),
                random_timestamp(ts.started_at, ts.ended_at)
            FROM (
                SELECT 
                    random_between(1, v_total_sessions) AS rand_idx,
                    random_item(methods) AS meth,
                    random_item(endpoints) AS endp
                FROM generate_series(1, p_api_requests)
            ) r
            JOIN temp_sessions ts ON ts.row_idx = r.rand_idx;
        END;
    END IF;

    -- Create temp tables for Orders & Products mapping to support fast Audit Log references
    CREATE TEMP TABLE temp_orders (
        row_idx serial primary key,
        id bigint
    ) ON COMMIT DROP;
    
    INSERT INTO temp_orders (id) SELECT id FROM orders;
    SELECT COUNT(*) INTO v_total_orders FROM temp_orders;
    
    CREATE TEMP TABLE temp_products (
        row_idx serial primary key,
        id bigint
    ) ON COMMIT DROP;
    
    INSERT INTO temp_products (id) SELECT id FROM products;
    SELECT COUNT(*) INTO v_total_products FROM temp_products;

    -- Split audit logs creation into separate set-based batches by entity type
    
    -- 1. Users Audit Logs (33% of audit logs)
    INSERT INTO audit_logs (entity_name, entity_id, operation, performed_by, changes, created_at)
    SELECT 
        'users',
        v_user_ids[random_between(1, v_total_users)]::text,
        random_weighted_item(operations, ARRAY[20, 75, 5]),
        v_user_ids[random_between(1, v_total_users)],
        jsonb_build_object('field', 'status', 'old', 'INACTIVE', 'new', 'ACTIVE'),
        random_timestamp(now() - INTERVAL '3 years', now())
    FROM generate_series(1, p_audit_logs / 3);

    -- 2. Orders Audit Logs (33% of audit logs)
    IF v_total_orders > 0 THEN
        INSERT INTO audit_logs (entity_name, entity_id, operation, performed_by, changes, created_at)
        SELECT 
            'orders',
            tor.id::text,
            random_weighted_item(operations, ARRAY[20, 75, 5]),
            v_user_ids[random_between(1, v_total_users)],
            jsonb_build_object('field', 'status', 'old', 'PROCESSING', 'new', 'PAID'),
            random_timestamp(now() - INTERVAL '3 years', now())
        FROM (
            SELECT random_between(1, v_total_orders) AS rand_idx
            FROM generate_series(1, p_audit_logs / 3)
        ) r
        JOIN temp_orders tor ON tor.row_idx = r.rand_idx;
    END IF;

    -- 3. Products Audit Logs (Remaining audit logs)
    IF v_total_products > 0 THEN
        INSERT INTO audit_logs (entity_name, entity_id, operation, performed_by, changes, created_at)
        SELECT 
            'products',
            tpr.id::text,
            random_weighted_item(operations, ARRAY[15, 80, 5]),
            v_user_ids[random_between(1, v_total_users)],
            jsonb_build_object('field', 'price', 'old', random_between(10.00, 100.00)::text, 'new', random_between(10.00, 100.00)::text),
            random_timestamp(now() - INTERVAL '3 years', now())
        FROM (
            SELECT random_between(1, v_total_products) AS rand_idx
            FROM generate_series(1, p_audit_logs - (p_audit_logs / 3) * 2)
        ) r
        JOIN temp_products tpr ON tpr.row_idx = r.rand_idx;
    END IF;

    RAISE NOTICE 'Data generation complete!';
END;
$$ LANGUAGE plpgsql;
