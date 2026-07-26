-- ==========================================================
-- PostgreSQL Advanced Practice Schema
-- ==========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================================
-- ENUMS
-- ==========================================================

CREATE TYPE user_status AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'SUSPENDED'
);

CREATE TYPE order_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'PAID',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
    'REFUNDED'
);

CREATE TYPE payment_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED',
    'REFUNDED'
);

CREATE TYPE shipment_status AS ENUM (
    'CREATED',
    'PICKED',
    'IN_TRANSIT',
    'DELIVERED',
    'RETURNED'
);

CREATE TYPE inventory_transaction_type AS ENUM (
    'PURCHASE',
    'SALE',
    'RETURN',
    'ADJUSTMENT'
);

-- ==========================================================
-- DEPARTMENTS
-- ==========================================================

CREATE TABLE departments (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    location        VARCHAR(200),
    budget          NUMERIC(14,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================================
-- EMPLOYEES
-- ==========================================================

CREATE TABLE employees (
    id              BIGSERIAL PRIMARY KEY,
    manager_id      BIGINT REFERENCES employees(id),
    department_id   BIGINT REFERENCES departments(id),

    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,

    hire_date       DATE NOT NULL,
    salary          NUMERIC(12,2),

    created_at      TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- USERS
-- ==========================================================

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email               VARCHAR(255) UNIQUE NOT NULL,
    username            VARCHAR(100) UNIQUE NOT NULL,

    first_name          VARCHAR(100),
    last_name           VARCHAR(100),

    phone               VARCHAR(50),

    status              user_status NOT NULL DEFAULT 'ACTIVE',

    birth_date          DATE,

    country             VARCHAR(100),
    city                VARCHAR(100),

    preferences         JSONB,

    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now(),
    last_login          TIMESTAMPTZ
);

-- ==========================================================
-- CATEGORIES
-- ==========================================================

CREATE TABLE categories (
    id              BIGSERIAL PRIMARY KEY,

    parent_id       BIGINT REFERENCES categories(id),

    name            VARCHAR(200) NOT NULL,
    description     TEXT,

    created_at      TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- SUPPLIERS
-- ==========================================================

CREATE TABLE suppliers (
    id                  BIGSERIAL PRIMARY KEY,

    company_name        VARCHAR(255) NOT NULL,

    contact_name        VARCHAR(255),

    email               VARCHAR(255),

    phone               VARCHAR(100),

    country             VARCHAR(100),

    metadata            JSONB,

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- PRODUCTS
-- ==========================================================

CREATE TABLE products (
    id                  BIGSERIAL PRIMARY KEY,

    supplier_id         BIGINT NOT NULL REFERENCES suppliers(id),
    category_id         BIGINT REFERENCES categories(id),

    sku                 VARCHAR(100) UNIQUE NOT NULL,

    name                VARCHAR(255) NOT NULL,

    description         TEXT,

    price               NUMERIC(12,2) NOT NULL,

    cost                NUMERIC(12,2),

    active              BOOLEAN NOT NULL DEFAULT true,

    metadata            JSONB,

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- INVENTORY
-- ==========================================================

CREATE TABLE inventory (
    id                  BIGSERIAL PRIMARY KEY,

    product_id          BIGINT NOT NULL REFERENCES products(id),

    quantity            INTEGER NOT NULL,

    warehouse           VARCHAR(100),

    last_updated        TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- ORDERS
-- ==========================================================

CREATE TABLE orders (
    id                  BIGSERIAL PRIMARY KEY,

    user_id             UUID NOT NULL REFERENCES users(id),

    employee_id         BIGINT REFERENCES employees(id),

    status              order_status NOT NULL,

    total_amount        NUMERIC(14,2) NOT NULL,

    shipping_address    TEXT,

    billing_address     TEXT,

    created_at          TIMESTAMPTZ DEFAULT now(),

    updated_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- ORDER ITEMS
-- ==========================================================

CREATE TABLE order_items (
    id                  BIGSERIAL PRIMARY KEY,

    order_id            BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

    product_id          BIGINT NOT NULL REFERENCES products(id),

    quantity            INTEGER NOT NULL,

    unit_price          NUMERIC(12,2) NOT NULL,

    discount            NUMERIC(10,2) DEFAULT 0
);

-- ==========================================================
-- PAYMENTS
-- ==========================================================

CREATE TABLE payments (
    id                  BIGSERIAL PRIMARY KEY,

    order_id            BIGINT NOT NULL REFERENCES orders(id),

    status              payment_status NOT NULL,

    provider            VARCHAR(100),

    transaction_id      VARCHAR(255),

    amount              NUMERIC(14,2),

    paid_at             TIMESTAMPTZ,

    metadata            JSONB,

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- SHIPMENTS
-- ==========================================================

CREATE TABLE shipments (
    id                  BIGSERIAL PRIMARY KEY,

    order_id            BIGINT NOT NULL REFERENCES orders(id),

    tracking_number     VARCHAR(255),

    carrier             VARCHAR(100),

    status              shipment_status,

    shipped_at          TIMESTAMPTZ,

    delivered_at        TIMESTAMPTZ,

    metadata            JSONB
);

-- ==========================================================
-- INVENTORY TRANSACTIONS
-- ==========================================================

CREATE TABLE inventory_transactions (
    id                  BIGSERIAL PRIMARY KEY,

    inventory_id        BIGINT NOT NULL REFERENCES inventory(id),

    transaction_type    inventory_transaction_type NOT NULL,

    quantity            INTEGER NOT NULL,

    reference           VARCHAR(200),

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- USER SESSIONS
-- ==========================================================

CREATE TABLE sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id             UUID REFERENCES users(id),

    ip_address          INET,

    user_agent          TEXT,

    started_at          TIMESTAMPTZ DEFAULT now(),

    ended_at            TIMESTAMPTZ,

    metadata            JSONB
);

-- ==========================================================
-- API REQUESTS
-- ==========================================================

CREATE TABLE api_requests (
    id                  BIGSERIAL PRIMARY KEY,

    session_id          UUID REFERENCES sessions(id),

    user_id             UUID REFERENCES users(id),

    method              VARCHAR(10),

    endpoint            TEXT,

    response_code       INTEGER,

    duration_ms         INTEGER,

    request_body        JSONB,

    response_body       JSONB,

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- AUDIT LOGS
-- ==========================================================

CREATE TABLE audit_logs (
    id                  BIGSERIAL PRIMARY KEY,

    entity_name         VARCHAR(100),

    entity_id           VARCHAR(100),

    operation           VARCHAR(20),

    performed_by        UUID REFERENCES users(id),

    changes             JSONB,

    created_at          TIMESTAMPTZ DEFAULT now()
);

-- ==========================================================
-- INDEXES
-- ==========================================================

CREATE INDEX idx_users_email
    ON users(email);

CREATE INDEX idx_users_status
    ON users(status);

CREATE INDEX idx_users_last_login
    ON users(last_login);

CREATE INDEX idx_orders_user
    ON orders(user_id);

CREATE INDEX idx_orders_status
    ON orders(status);

CREATE INDEX idx_orders_created
    ON orders(created_at);

CREATE INDEX idx_order_items_order
    ON order_items(order_id);

CREATE INDEX idx_order_items_product
    ON order_items(product_id);

CREATE INDEX idx_products_category
    ON products(category_id);

CREATE INDEX idx_products_supplier
    ON products(supplier_id);

CREATE INDEX idx_inventory_product
    ON inventory(product_id);

CREATE INDEX idx_payments_order
    ON payments(order_id);

CREATE INDEX idx_payments_status
    ON payments(status);

CREATE INDEX idx_shipments_order
    ON shipments(order_id);

CREATE INDEX idx_sessions_user
    ON sessions(user_id);

CREATE INDEX idx_api_requests_user
    ON api_requests(user_id);

CREATE INDEX idx_api_requests_session
    ON api_requests(session_id);

CREATE INDEX idx_api_requests_endpoint
    ON api_requests(endpoint);

CREATE INDEX idx_audit_entity
    ON audit_logs(entity_name, entity_id);

-- ==========================================================
-- JSONB INDEXES
-- ==========================================================

CREATE INDEX idx_users_preferences
    ON users
    USING GIN (preferences);

CREATE INDEX idx_products_metadata
    ON products
    USING GIN (metadata);

CREATE INDEX idx_suppliers_metadata
    ON suppliers
    USING GIN (metadata);

CREATE INDEX idx_payments_metadata
    ON payments
    USING GIN (metadata);

CREATE INDEX idx_shipments_metadata
    ON shipments
    USING GIN (metadata);

CREATE INDEX idx_sessions_metadata
    ON sessions
    USING GIN (metadata);

CREATE INDEX idx_api_requests_request_body
    ON api_requests
    USING GIN (request_body);

CREATE INDEX idx_api_requests_response_body
    ON api_requests
    USING GIN (response_body);

CREATE INDEX idx_audit_changes
    ON audit_logs
    USING GIN (changes);

-- ==========================================================
-- EXPRESSION INDEXES
-- ==========================================================

CREATE INDEX idx_users_lower_email
    ON users (LOWER(email));

CREATE INDEX idx_products_lower_name
    ON products (LOWER(name));

-- ==========================================================
-- PARTIAL INDEXES
-- ==========================================================

CREATE INDEX idx_active_users
    ON users(id)
    WHERE status = 'ACTIVE';

CREATE INDEX idx_pending_orders
    ON orders(created_at)
    WHERE status = 'PENDING';

CREATE INDEX idx_failed_payments
    ON payments(created_at)
    WHERE status = 'FAILED';
