-- ==========================================================
-- PostgreSQL Advanced Practice: Database Cleanup Engine
-- ==========================================================

CREATE OR REPLACE PROCEDURE cleanup_demo_data()
AS $$
BEGIN
    RAISE NOTICE 'Cleaning up all practice data...';
    
    -- Truncate all tables and reset identity sequences
    TRUNCATE TABLE 
        audit_logs,
        api_requests,
        sessions,
        inventory_transactions,
        shipments,
        payments,
        order_items,
        orders,
        inventory,
        products,
        suppliers,
        categories,
        employees,
        departments,
        users
    RESTART IDENTITY CASCADE;

    RAISE NOTICE 'All tables truncated and identity sequences reset successfully!';
END;
$$ LANGUAGE plpgsql;
