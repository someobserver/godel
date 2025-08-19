-- GODEL: Geometric Ontology Detecting Emergent Logics
-- SQL Testing Framework
-- File: tests/test_framework.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Create test schema
CREATE SCHEMA IF NOT EXISTS godel_test;

-- Test results table
-- Purpose: central log for assertions with timing and error context.
-- Columns: (name, category, passed, expected_value, actual_value, execution_time, error_message, run_timestamp).
CREATE TABLE IF NOT EXISTS godel_test.test_results (
    test_id SERIAL PRIMARY KEY,
    test_name TEXT NOT NULL,
    test_category TEXT NOT NULL,
    passed BOOLEAN NOT NULL,
    error_message TEXT,
    expected_value TEXT,
    actual_value TEXT,
    execution_time INTERVAL,
    run_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reset results from previous runs
TRUNCATE godel_test.test_results;

-- Test assertion functions

-- Purpose: Assert approximate equality of floats within tolerance.
-- Inputs: (test_name, expected_val, actual_val, tolerance, category).
-- Behavior: evaluates |expected-actual| ≤ tolerance; logs timing and diff when failing.
-- Returns: boolean; inserts a row into godel_test.test_results.
CREATE OR REPLACE FUNCTION godel_test.assert_float_equals(
    test_name TEXT,
    expected_val FLOAT,
    actual_val FLOAT,
    tolerance FLOAT DEFAULT 1e-6,
    category TEXT DEFAULT 'general'
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    passed BOOLEAN;
BEGIN
    start_time := clock_timestamp();
    
    passed := ABS(expected_val - actual_val) <= tolerance;
    
    end_time := clock_timestamp();
    
    INSERT INTO godel_test.test_results (
        test_name, test_category, passed, expected_value, actual_value, execution_time,
        error_message
    ) VALUES (
        test_name, category, passed, 
        expected_val::TEXT, actual_val::TEXT, 
        end_time - start_time,
        CASE WHEN NOT passed 
             THEN format('Expected %s ± %s, got %s (diff: %s)', 
                         expected_val, tolerance, actual_val, ABS(expected_val - actual_val))
             ELSE NULL 
        END
    );
    
    RETURN passed;
END;
$$;

-- Purpose: Assert that a boolean condition is true.
-- Inputs: (test_name, condition, category, error_msg).
-- Behavior: NULL treated as false; logs timing and optional error_msg when failing.
-- Returns: boolean; inserts a row into godel_test.test_results.
CREATE OR REPLACE FUNCTION godel_test.assert_true(
    test_name TEXT,
    condition BOOLEAN,
    category TEXT DEFAULT 'general',
    error_msg TEXT DEFAULT 'Condition was false'
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    end_time := clock_timestamp();
    
    INSERT INTO godel_test.test_results (
        test_name, test_category, passed, execution_time, error_message
    ) VALUES (
        test_name, category, COALESCE(condition, false), 
        end_time - start_time,
        CASE WHEN NOT COALESCE(condition, false) THEN error_msg ELSE NULL END
    );
    
    RETURN COALESCE(condition, false);
END;
$$;

-- Purpose: Assert element-wise approximate equality of FLOAT[] arrays.
-- Inputs: (test_name, expected_array, actual_array, tolerance, category).
-- Behavior: checks length equality, then per-element tolerance; logs max difference when failing.
-- Returns: boolean; inserts a row into godel_test.test_results.
CREATE OR REPLACE FUNCTION godel_test.assert_array_equals(
    test_name TEXT,
    expected_array FLOAT[],
    actual_array FLOAT[],
    tolerance FLOAT DEFAULT 1e-6,
    category TEXT DEFAULT 'array'
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    passed BOOLEAN := true;
    i INTEGER;
    max_diff FLOAT := 0.0;
    current_diff FLOAT;
BEGIN
    start_time := clock_timestamp();
    
    -- Check array lengths match
    IF array_length(expected_array, 1) != array_length(actual_array, 1) THEN
        passed := false;
    ELSE
        -- Check each element
        FOR i IN 1..array_length(expected_array, 1) LOOP
            current_diff := ABS(expected_array[i] - actual_array[i]);
            max_diff := GREATEST(max_diff, current_diff);
            IF current_diff > tolerance THEN
                passed := false;
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    end_time := clock_timestamp();
    
    INSERT INTO godel_test.test_results (
        test_name, test_category, passed, execution_time,
        error_message
    ) VALUES (
        test_name, category, passed, 
        end_time - start_time,
        CASE WHEN NOT passed 
             THEN format('Array mismatch. Max difference: %s (tolerance: %s)', max_diff, tolerance)
             ELSE NULL 
        END
    );
    
    RETURN passed;
END;
$$;

-- Purpose: Assert that a SQL statement executes without raising an error.
-- Inputs: (test_name, sql_statement, category).
-- Behavior: EXECUTE inside exception block; records SQLERRM if thrown.
-- Returns: boolean; inserts a row into godel_test.test_results.
CREATE OR REPLACE FUNCTION godel_test.assert_no_error(
    test_name TEXT,
    sql_statement TEXT,
    category TEXT DEFAULT 'execution'
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    passed BOOLEAN := true;
    error_msg TEXT;
BEGIN
    start_time := clock_timestamp();
    
    BEGIN
        EXECUTE sql_statement;
    EXCEPTION WHEN OTHERS THEN
        passed := false;
        error_msg := SQLERRM;
    END;
    
    end_time := clock_timestamp();
    
    INSERT INTO godel_test.test_results (
        test_name, test_category, passed, execution_time, error_message
    ) VALUES (
        test_name, category, passed, end_time - start_time, error_msg
    );
    
    RETURN passed;
END;
$$;

-- Purpose: Assert a SQL statement completes within max_duration.
-- Inputs: (test_name, sql_statement, max_duration, category).
-- Behavior: measures wall-clock duration; failing rows include duration or error.
-- Returns: boolean; inserts a row into godel_test.test_results with execution_time=duration.
CREATE OR REPLACE FUNCTION godel_test.assert_performance(
    test_name TEXT,
    sql_statement TEXT,
    max_duration INTERVAL,
    category TEXT DEFAULT 'performance'
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
    passed BOOLEAN;
    error_msg TEXT;
BEGIN
    start_time := clock_timestamp();
    
    BEGIN
        EXECUTE sql_statement;
        end_time := clock_timestamp();
        duration := end_time - start_time;
        passed := duration <= max_duration;
    EXCEPTION WHEN OTHERS THEN
        end_time := clock_timestamp();
        duration := end_time - start_time;
        passed := false;
        error_msg := 'Function failed: ' || SQLERRM;
    END;
    
    INSERT INTO godel_test.test_results (
        test_name, test_category, passed, execution_time,
        error_message
    ) VALUES (
        test_name, category, passed, duration,
        CASE WHEN NOT passed AND error_msg IS NULL 
             THEN format('Function took %s, limit was %s', duration, max_duration)
             ELSE error_msg 
        END
    );
    
    RETURN passed;
END;
$$;

-- Purpose: Create a test manifold point with random semantic/coherence fields.
-- Notes: randomness seeded externally via setseed() for reproducibility.
-- Fields: sets coherence_magnitude ∈ [0.5,1.0], constraint_density ∈ [1.0,3.0],
--         attractor_stability ∈ [0.2,0.9]. Returns generated point_id.
CREATE OR REPLACE FUNCTION godel_test.create_test_manifold_point(
    test_semantic_field VECTOR(2000) DEFAULT NULL,
    test_coherence_field VECTOR(2000) DEFAULT NULL,
    test_user_fingerprint TEXT DEFAULT 'test_user'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    point_id UUID;
    default_semantic VECTOR(2000);
    default_coherence VECTOR(2000);
BEGIN
    point_id := gen_random_uuid();
    
    IF test_semantic_field IS NULL THEN
        SELECT (
            '[' || string_agg((random())::text, ',') || ']'
        )::vector(2000)
        INTO default_semantic
        FROM generate_series(1, 2000);
    ELSE
        default_semantic := test_semantic_field;
    END IF;
    
    IF test_coherence_field IS NULL THEN
        SELECT (
            '[' || string_agg((random())::text, ',') || ']'
        )::vector(2000)
        INTO default_coherence
        FROM generate_series(1, 2000);
    ELSE
        default_coherence := test_coherence_field;
    END IF;
    
    INSERT INTO godel.manifold_points (
        id, user_fingerprint, creation_timestamp,
        semantic_field, coherence_field, coherence_magnitude,
        recursive_depth, constraint_density, attractor_stability
    ) VALUES (
        point_id, test_user_fingerprint, NOW(),
        default_semantic,
        default_coherence,
        0.5 + random() * 0.5,  -- C_mag between 0.5-1.0
        1.0 + random() * 2.0,  -- D 1.0-3.0
        0.1 + random() * 0.8,  -- ρ 0.1-0.9
        0.2 + random() * 0.7   -- A 0.2-0.9
    );
    
    RETURN point_id;
END;
$$;

-- Purpose: Delete test artifacts created via create_test_manifold_point.
-- Method: gather ids with user_fingerprint LIKE 'test_%'; delete child rows first, then parents.
CREATE OR REPLACE FUNCTION godel_test.cleanup_test_data()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    test_point_ids UUID[];
BEGIN
    -- Capture test point ids
    SELECT array_agg(id) INTO test_point_ids
    FROM godel.manifold_points 
    WHERE user_fingerprint LIKE 'test_%';

    IF test_point_ids IS NULL OR array_length(test_point_ids, 1) IS NULL THEN
        RETURN;
    END IF;

    -- Child rows
    DELETE FROM godel.recursive_coupling 
    WHERE point_p = ANY(test_point_ids) OR point_q = ANY(test_point_ids);

    DELETE FROM godel.wisdom_field
    WHERE point_id = ANY(test_point_ids);

    -- Parent rows
    DELETE FROM godel.manifold_points 
    WHERE id = ANY(test_point_ids);
END;
$$;

CREATE OR REPLACE FUNCTION godel_test.teardown_test_framework(drop_schema BOOLEAN DEFAULT false)
-- Purpose: Cleanup test data and optionally drop the entire test schema.
-- Inputs: drop_schema=true will remove schema and all dependent objects after cleanup.
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    PERFORM godel_test.cleanup_test_data();
    IF drop_schema THEN
        EXECUTE 'DROP SCHEMA IF EXISTS godel_test CASCADE';
    END IF;
END;
$$;

\echo 'Test suite initialized.'
