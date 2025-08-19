-- GODEL: Test Observer-Coupling Signature Detection
-- File: tests/signatures/test_observer_coupling_signatures.sql
-- Updated: 2025-08-19
--
-- Tests for observer-coupling signature detection functions
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License

\echo 'Observer-coupling: paranoid interpretation → negative bias + concentrated threat patterns (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'paranoid_interpretation_executes',
        format('SELECT * FROM godel.detect_paranoid_interpretation(''%s'')', test_point),
        'observer_coupling'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Observer-coupling: observer solipsism → interpretation divergence exceeds threshold (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'observer_solipsism_executes',
        format('SELECT * FROM godel.detect_observer_solipsism(''%s'')', test_point),
        'observer_coupling'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Observer-coupling: semantic narcissism → dominant self-coupling with weak externals (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'semantic_narcissism_executes',
        format('SELECT * FROM godel.detect_semantic_narcissism(''%s'')', test_point),
        'observer_coupling'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Observer-coupling: combined signatures → multiplexed detector executes'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'observer_coupling_signatures_combined',
        format('SELECT * FROM godel.detect_observer_coupling_signatures(''%s'')', test_point),
        'observer_coupling'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Observer-coupling: schema verification → expect at least one valid row with type/severity/evidence under dominant self-coupling'
DO $$
DECLARE
    test_point UUID;
    signature_rec RECORD;
    result_count INTEGER;
BEGIN
    test_point := godel_test.create_test_manifold_point();

    -- Deterministically create coupling data to allow narcissism/paranoid interpretation to potentially trigger
    INSERT INTO godel.recursive_coupling (id, point_p, point_q, coupling_magnitude, coupling_tensor, computed_at)
    VALUES 
        (gen_random_uuid(), test_point, test_point, 0.95, ARRAY[0.0], NOW() - INTERVAL '15 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.90, ARRAY[0.0], NOW() - INTERVAL '10 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.85, ARRAY[0.0], NOW() - INTERVAL '7 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.80, ARRAY[0.0], NOW() - INTERVAL '5 minutes');

    -- Also add one weak external coupling to keep external_reference low
    INSERT INTO godel.recursive_coupling (id, point_p, point_q, coupling_magnitude, coupling_tensor, computed_at)
    SELECT gen_random_uuid(), test_point, id, 0.05, ARRAY[0.0], NOW() - INTERVAL '7 minutes'
    FROM godel.manifold_points WHERE id != test_point LIMIT 1;

    -- Assert at least one observer-coupling signature row is returned (non-zero count)
    SELECT COUNT(*) INTO result_count FROM godel.detect_observer_coupling_signatures(test_point);
    PERFORM godel_test.assert_true(
        'observer_coupling_signatures_present',
        result_count > 0,
        'observer_coupling',
        'At least one observer-coupling signature should be detected with dominant self-coupling and minimal external references'
    );

    FOR signature_rec IN 
        SELECT * FROM godel.detect_observer_coupling_signatures(test_point)
    LOOP
        PERFORM godel_test.assert_true(
            'observer_coupling_signature_type_valid',
            signature_rec.signature_type IN ('PARANOID_INTERPRETATION', 'OBSERVER_SOLIPSISM', 'SEMANTIC_NARCISSISM'),
            'observer_coupling',
            'Signature type should be valid observer-coupling type'
        );
        
        PERFORM godel_test.assert_true(
            'observer_coupling_severity_range',
            signature_rec.severity >= 0.0 AND signature_rec.severity <= 1.0,
            'observer_coupling',
            'Severity should be between 0.0 and 1.0'
        );
    END LOOP;
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Observer-coupling: performance → combined detector ≤ 3s'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_performance(
        'observer_coupling_signatures_performance',
        format('SELECT * FROM godel.detect_observer_coupling_signatures(''%s'')', test_point),
        '3 seconds',
        'observer_coupling'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo ''
\echo 'Completed observer-coupling signature tests.'
