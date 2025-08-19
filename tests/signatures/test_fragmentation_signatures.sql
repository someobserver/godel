-- GODEL: Test Fragmentation Signature Detection
-- File: tests/signatures/test_fragmentation_signatures.sql
-- Updated: 2025-08-19
--
-- Tests for fragmentation signature detection functions
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License

\echo 'Fragmentation: attractor splintering → direction variance exceeds autopoietic stabilization (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'attractor_splintering_executes',
        format('SELECT * FROM godel.detect_attractor_splintering(''%s'')', test_point),
        'fragmentation'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Fragmentation: coherence dissolution → large gradient vs magnitude with positive acceleration (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'coherence_dissolution_executes',
        format('SELECT * FROM godel.detect_coherence_dissolution(''%s'')', test_point),
        'fragmentation'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Fragmentation: reference decay → coupling trend negative with low wisdom (executes)'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'reference_decay_executes',
        format('SELECT * FROM godel.detect_reference_decay(''%s'')', test_point),
        'fragmentation'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Fragmentation: combined signatures → multiplexed detector executes'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_no_error(
        'fragmentation_signatures_combined',
        format('SELECT * FROM godel.detect_fragmentation_signatures(''%s'')', test_point),
        'fragmentation'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Fragmentation: schema verification → expect at least one valid row with type/severity/evidence under induced decay'
DO $$
DECLARE
    test_point UUID;
    signature_rec RECORD;
    result_count INTEGER;
BEGIN
    test_point := godel_test.create_test_manifold_point();

    -- Deterministically trigger REFERENCE_DECAY: create decreasing coupling magnitudes and low wisdom
    INSERT INTO godel.wisdom_field (point_id, wisdom_value, humility_factor)
    VALUES (test_point, 0.0, 0.0)
    ON CONFLICT (point_id) DO UPDATE SET wisdom_value = EXCLUDED.wisdom_value, humility_factor = EXCLUDED.humility_factor;

    INSERT INTO godel.recursive_coupling (id, point_p, point_q, coupling_magnitude, coupling_tensor, computed_at)
    VALUES 
        (gen_random_uuid(), test_point, test_point, 0.6, ARRAY[0.0], NOW() - INTERVAL '5 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.4, ARRAY[0.0], NOW() - INTERVAL '10 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.2, ARRAY[0.0], NOW() - INTERVAL '20 minutes'),
        (gen_random_uuid(), test_point, test_point, 0.1, ARRAY[0.0], NOW() - INTERVAL '30 minutes');

    -- Assert at least one fragmentation signature is detected
    SELECT COUNT(*) INTO result_count FROM godel.detect_fragmentation_signatures(test_point);
    PERFORM godel_test.assert_true(
        'fragmentation_signatures_present',
        result_count > 0,
        'fragmentation',
        'At least one fragmentation signature should be detected with decreasing coupling and low wisdom'
    );

    -- Test schema of returned rows
    FOR signature_rec IN 
        SELECT * FROM godel.detect_fragmentation_signatures(test_point)
    LOOP
        PERFORM godel_test.assert_true(
            'fragmentation_signature_type_valid',
            signature_rec.signature_type IN ('ATTRACTOR_SPLINTERING', 'COHERENCE_DISSOLUTION', 'REFERENCE_DECAY'),
            'fragmentation',
            'Signature type should be a valid fragmentation type'
        );
        
        PERFORM godel_test.assert_true(
            'fragmentation_severity_range',
            signature_rec.severity >= 0.0 AND signature_rec.severity <= 1.0,
            'fragmentation',
            'Severity should be between 0.0 and 1.0'
        );
        
        PERFORM godel_test.assert_true(
            'fragmentation_evidence_exists',
            signature_rec.mathematical_evidence IS NOT NULL,
            'fragmentation',
            'Mathematical evidence should exist'
        );
    END LOOP;
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Fragmentation: null point handling → executes without error'
SELECT godel_test.assert_no_error(
    'fragmentation_null_handling',
    'SELECT * FROM godel.detect_fragmentation_signatures(NULL)',
    'fragmentation'
);

\echo 'Fragmentation: performance → combined detector ≤ 3s'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_performance(
        'fragmentation_signatures_performance',
        format('SELECT * FROM godel.detect_fragmentation_signatures(''%s'')', test_point),
        '3 seconds',
        'fragmentation'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo ''
\echo 'Completed fragmentation signature tests.'
