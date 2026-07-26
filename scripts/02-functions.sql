-- ==========================================================
-- PostgreSQL Advanced Practice: Data Generation Helper Functions
-- ==========================================================

-- ==========================================================
-- MATHEMATICAL & RANDOM GENERIC UTILITIES
-- ==========================================================

CREATE OR REPLACE FUNCTION random_between(min_val int, max_val int)
RETURNS int AS $$
BEGIN
    RETURN floor(random() * (max_val - min_val + 1))::int + min_val;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_between(min_val numeric, max_val numeric)
RETURNS numeric AS $$
BEGIN
    RETURN round((random() * (max_val - min_val) + min_val)::numeric, 2);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_date(start_date date, end_date date)
RETURNS date AS $$
BEGIN
    RETURN (start_date + floor(random() * (end_date - start_date + 1))::int);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_timestamp(start_ts timestamptz, end_ts timestamptz)
RETURNS timestamptz AS $$
BEGIN
    RETURN start_ts + (random() * (end_ts - start_ts));
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ==========================================================
-- POLYMORPHIC ARRAY SELECTORS
-- ==========================================================

CREATE OR REPLACE FUNCTION random_item(arr anyarray)
RETURNS anyelement AS $$
DECLARE
    idx int;
BEGIN
    IF arr IS NULL OR array_length(arr, 1) IS NULL THEN
        RETURN NULL;
    END IF;
    idx := floor(random() * array_length(arr, 1)) + 1;
    RETURN arr[idx];
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_weighted_item(arr anyarray, weights int[])
RETURNS anyelement AS $$
DECLARE
    t_sum int := 0;
    t_rand int;
    i int;
    curr_sum int := 0;
BEGIN
    IF arr IS NULL OR weights IS NULL OR array_length(arr, 1) != array_length(weights, 1) THEN
        RETURN random_item(arr);
    END IF;

    -- calculate sum of weights
    FOR i IN 1..array_length(weights, 1) LOOP
        t_sum := t_sum + weights[i];
    END LOOP;
    
    t_rand := floor(random() * t_sum) + 1;
    
    FOR i IN 1..array_length(weights, 1) LOOP
        curr_sum := curr_sum + weights[i];
        IF t_rand <= curr_sum THEN
            RETURN arr[i];
        END IF;
    END LOOP;
    
    RETURN arr[1]; -- fallback
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ==========================================================
-- REALISTIC TEXT DATA GENERATORS
-- ==========================================================

CREATE OR REPLACE FUNCTION random_first_name()
RETURNS text AS $$
DECLARE
    names text[] := ARRAY[
        'John', 'Jane', 'Michael', 'Emily', 'David', 'Sarah', 'James', 'Jessica', 'Robert', 'Karen',
        'William', 'Nancy', 'Joseph', 'Betty', 'Thomas', 'Lisa', 'Daniel', 'Dorothy', 'Matthew', 'Sandra',
        'Mark', 'Ashley', 'Donald', 'Kimberly', 'Steven', 'Donna', 'Paul', 'Michelle', 'Joshua', 'Carol',
        'Kenneth', 'Amanda', 'Kevin', 'Melissa', 'Brian', 'Deborah', 'George', 'Stephanie', 'Edward', 'Rebecca',
        'Ronald', 'Sharon', 'Timothy', 'Laura', 'Jason', 'Cynthia', 'Jeffrey', 'Kathleen', 'Charles', 'Helen',
        'Gary', 'Nicholas', 'Maria', 'Eric', 'Heather', 'Stephen', 'Diane', 'Andrew', 'Alice', 'Arthur',
        'Benjamin', 'Charlotte', 'Dennis', 'Diana', 'Frank', 'Grace', 'Henry', 'Irene', 'Jack', 'Julia',
        'Louis', 'Martha', 'Patrick', 'Rose', 'Samuel', 'Theresa', 'Walter', 'Victoria', 'Wayne', 'Gloria'
    ];
BEGIN
    RETURN random_item(names);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_last_name()
RETURNS text AS $$
DECLARE
    names text[] := ARRAY[
        'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
        'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
        'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
        'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
        'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts',
        'Gomez', 'Phillips', 'Evans', 'Turner', 'Diaz', 'Parker', 'Cruz', 'Edwards', 'Collins', 'Reyes',
        'Stewart', 'Morris', 'Morales', 'Murphy', 'Cook', 'Rogers', 'Gutierrez', 'Ortiz', 'Morgan', 'Cooper',
        'Peterson', 'Bailey', 'Reed', 'Kelly', 'Howard', 'Ramos', 'Kim', 'Cox', 'Ward', 'Richardson'
    ];
BEGIN
    RETURN random_item(names);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_company_name()
RETURNS text AS $$
DECLARE
    prefixes text[] := ARRAY[
        'Apex', 'BlueSky', 'Core', 'Delta', 'Elite', 'Fusion', 'Genesis', 'Horizon', 'Infinity', 'Summit',
        'Vertex', 'Nova', 'Quantum', 'Stellar', 'Prime', 'Matrix', 'Nexus', 'Vanguard', 'Pinnacle', 'Synergy',
        'Aero', 'Bio', 'Clear', 'Eco', 'Geo', 'Logi', 'Micro', 'Nano', 'Omni', 'Opti'
    ];
    middles text[] := ARRAY[
        'Tech', 'Solutions', 'Logistics', 'Industries', 'Ventures', 'Systems', 'Global', 'Enterprises', 'Partners', 'Dynamics',
        'Networks', 'Resources', 'Designs', 'Consulting', 'Labs', 'Group', 'Media', 'Capital', 'Technologies', 'Services'
    ];
    suffixes text[] := ARRAY['Inc', 'LLC', 'Corp', 'Ltd', 'Co', 'Group'];
BEGIN
    RETURN random_item(prefixes) || ' ' || random_item(middles) || ' ' || random_item(suffixes);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_city()
RETURNS text AS $$
DECLARE
    cities text[] := ARRAY[
        'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose',
        'Austin', 'Jacksonville', 'San Francisco', 'Indianapolis', 'Columbus', 'Fort Worth', 'Charlotte', 'Seattle', 'Denver', 'El Paso',
        'Boston', 'Detroit', 'Nashville', 'Memphis', 'Portland', 'Oklahoma City', 'Las Vegas', 'Louisville', 'Baltimore', 'Milwaukee',
        'Albuquerque', 'Tucson', 'Fresno', 'Sacramento', 'Mesa', 'Kansas City', 'Atlanta', 'Omaha', 'Colorado Springs', 'Raleigh',
        'Miami', 'Virginia Beach', 'Oakland', 'Minneapolis', 'Tulsa', 'Arlington', 'New Orleans', 'Wichita', 'Bakersfield', 'Tampa'
    ];
BEGIN
    RETURN random_item(cities);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_country()
RETURNS text AS $$
DECLARE
    countries text[] := ARRAY[
        'United States', 'Canada', 'United Kingdom', 'Germany', 'France', 'Japan', 'Australia', 'Brazil', 'Mexico', 'India',
        'China', 'South Africa', 'Spain', 'Italy', 'Netherlands', 'Sweden', 'Switzerland', 'South Korea', 'Singapore', 'New Zealand'
    ];
BEGIN
    RETURN random_item(countries);
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_address(city text, country text)
RETURNS text AS $$
DECLARE
    streets text[] := ARRAY[
        'Main St', 'Broadway', 'Oak Ave', 'Pine Rd', 'Maple Dr', 'Cedar Ln', 'Elm St', 'Washington Blvd',
        'Lakeview Dr', 'Hilltop Rd', 'Park Pl', 'Sunset Blvd', 'Forest Ave', 'River Rd', 'Ridge Dr', 'Meadow Ln',
        'Highland Ave', 'Spring St', 'Market St', 'Second St', 'Chestnut St', 'Walnut St', 'Willow Way', 'Parkway Dr'
    ];
    num int;
BEGIN
    num := floor(random() * 9999) + 1;
    RETURN num || ' ' || random_item(streets) || ', ' || city || ', ' || country;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_phone()
RETURNS text AS $$
BEGIN
    RETURN '+1-' || floor(random() * 900 + 100)::text || '-' || floor(random() * 900 + 100)::text || '-' || floor(random() * 9000 + 1000)::text;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_email(first_name text, last_name text, company text)
RETURNS text AS $$
DECLARE
    clean_first text;
    clean_last text;
    clean_company text;
    domains text[] := ARRAY['gmail.com', 'yahoo.com', 'outlook.com', 'protonmail.com', 'icloud.com'];
BEGIN
    clean_first := lower(regexp_replace(first_name, '[^a-zA-Z]', '', 'g'));
    clean_last := lower(regexp_replace(last_name, '[^a-zA-Z]', '', 'g'));
    
    IF company IS NOT NULL AND random() > 0.4 THEN
        clean_company := lower(regexp_replace(split_part(company, ' ', 1), '[^a-zA-Z0-9]', '', 'g')) || '.com';
        RETURN clean_first || '.' || clean_last || '@' || clean_company;
    ELSE
        RETURN clean_first || '.' || clean_last || random_between(10, 999)::text || '@' || random_item(domains);
    END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ==========================================================
-- JSONB STRUCTURED DATA GENERATORS
-- ==========================================================

CREATE OR REPLACE FUNCTION random_json_preferences()
RETURNS jsonb AS $$
DECLARE
    themes text[] := ARRAY['light', 'dark', 'system'];
    langs text[] := ARRAY['en', 'es', 'fr', 'de', 'ja', 'zh'];
    email_notify boolean := random() > 0.2;
    sms_notify boolean := random() > 0.7;
    push_notify boolean := random() > 0.5;
BEGIN
    RETURN jsonb_build_object(
        'theme', random_item(themes),
        'language', random_item(langs),
        'notifications', jsonb_build_object(
            'email', email_notify,
            'sms', sms_notify,
            'push', push_notify
        ),
        'marketing_opt_in', random() > 0.6
    );
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION random_json_metadata()
RETURNS jsonb AS $$
DECLARE
    browsers text[] := ARRAY['Chrome', 'Firefox', 'Safari', 'Edge', 'Opera'];
    oss text[] := ARRAY['Windows 11', 'macOS 14', 'Ubuntu 22.04', 'iOS 17', 'Android 14'];
    app_versions text[] := ARRAY['1.0.0', '1.1.2', '2.0.0', '2.1.0-rc1'];
BEGIN
    RETURN jsonb_build_object(
        'client', jsonb_build_object(
            'browser', random_item(browsers),
            'os', random_item(oss),
            'ip_resolve_method', random_weighted_item(ARRAY['GEOIP', 'LOCAL', 'NONE'], ARRAY[80, 15, 5])
        ),
        'app_version', random_item(app_versions),
        'execution_details', jsonb_build_object(
            'cached', random() > 0.85,
            'api_gateway_delay_ms', random_between(2.0, 45.0)
        )
    );
END;
$$ LANGUAGE plpgsql VOLATILE;
