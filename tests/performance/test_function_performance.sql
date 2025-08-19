-- GODEL: Performance Tests
-- File: tests/performance/test_function_performance.sql
-- Updated: 2025-08-19
--
-- Performance benchmarks for GODEL functions
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License

\echo 'Performance: semantic_mass (10k evals) ≤ 1s'
SELECT godel_test.assert_performance(
    'semantic_mass_calculation_performance',
    'SELECT godel.compute_semantic_mass(generate_series(1,1000), random(), random()) FROM generate_series(1,10)',
    '1 second',
    'performance'
);

\echo 'Performance: autopoietic_potential (1k evals) ≤ 1s'
SELECT godel_test.assert_performance(
    'autopoietic_potential_performance',
    'SELECT godel.compute_autopoietic_potential(random()) FROM generate_series(1,1000)',
    '1 second',
    'performance'
);

\echo 'Performance: humility_operator (1k evals) ≤ 1s'
SELECT godel_test.assert_performance(
    'humility_operator_performance',
    'SELECT godel.compute_humility_operator(random()) FROM generate_series(1,1000)',
    '1 second',
    'performance'
);

\echo 'Performance: matrix_determinant 50x50 random SPD-like ≤ 3s'
SELECT godel_test.assert_performance(
    'matrix_determinant_50x50_performance',
    'SELECT godel.matrix_determinant(
        ARRAY(SELECT ARRAY(SELECT CASE WHEN i=j THEN 1.0 + random()*0.1 ELSE random()*0.01 END 
                          FROM generate_series(1,50) j) 
              FROM generate_series(1,50) i), 50)',
    '3 seconds',
    'performance'
);

\echo 'Performance: signature categories on realistic point ≤ 5s each'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    -- Update with realistic data
    UPDATE godel.manifold_points SET
        semantic_mass = godel.compute_semantic_mass(recursive_depth, 1.0, attractor_stability),
        metric_tensor = ARRAY(SELECT random()::FLOAT FROM generate_series(1, 10000)),
        christoffel_symbols = ARRAY(SELECT random()::FLOAT FROM generate_series(1, 1000000))
    WHERE id = test_point;
    
    -- Test individual signature performance
    PERFORM godel_test.assert_performance(
        'rigidity_signatures_performance_realistic',
        format('SELECT * FROM godel.detect_rigidity_signatures(''%s'')', test_point),
        '5 seconds',
        'performance'
    );
    
    PERFORM godel_test.assert_performance(
        'fragmentation_signatures_performance_realistic',
        format('SELECT * FROM godel.detect_fragmentation_signatures(''%s'')', test_point),
        '5 seconds',
        'performance'
    );
    
    PERFORM godel_test.assert_performance(
        'inflation_signatures_performance_realistic',
        format('SELECT * FROM godel.detect_inflation_signatures(''%s'')', test_point),
        '5 seconds',
        'performance'
    );
    
    PERFORM godel_test.assert_performance(
        'observer_coupling_signatures_performance_realistic',
        format('SELECT * FROM godel.detect_observer_coupling_signatures(''%s'')', test_point),
        '5 seconds',
        'performance'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: detect_all_signatures on point ≤ 10s'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    PERFORM godel_test.assert_performance(
        'complete_signature_detection_performance',
        format('SELECT * FROM godel.detect_all_signatures(''%s'')', test_point),
        '10 seconds',
        'performance'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: coordination detection (5-point graph) ≤ 5s'
DO $$
DECLARE
    test_points UUID[];
    test_point UUID;
    i INTEGER;
BEGIN
    test_points := ARRAY[]::UUID[];
    
    -- Create multiple test points for coordination test
    FOR i IN 1..5 LOOP
        test_point := godel_test.create_test_manifold_point(NULL, NULL, 'test_user_' || i);
        test_points := array_append(test_points, test_point);
        
        -- Create coupling data
        IF i > 1 THEN
            INSERT INTO godel.recursive_coupling (id, point_p, point_q, coupling_magnitude, coupling_tensor)
            VALUES (gen_random_uuid(), test_points[i-1], test_point, 0.8, 
                   ARRAY(SELECT random()::FLOAT FROM generate_series(1, 1000000)));
        END IF;
    END LOOP;
    
    PERFORM godel_test.assert_performance(
        'coordination_detection_performance',
        'SELECT * FROM godel.detect_coordination_via_coupling(''1 hour'', 0.7, 2)',
        '5 seconds',
        'performance'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: field evolution step ≤ 8s'
DO $$
DECLARE
    test_point UUID;
BEGIN
    test_point := godel_test.create_test_manifold_point();
    
    -- Add required geometric data
    UPDATE godel.manifold_points SET
        metric_tensor = ARRAY(SELECT CASE WHEN i=j THEN 1.0 ELSE 0.0 END::FLOAT 
                             FROM generate_series(1,100) i, generate_series(1,100) j ORDER BY i,j),
        christoffel_symbols = ARRAY(SELECT 0.0::FLOAT FROM generate_series(1, 1000000)),
        semantic_mass = 1.0
    WHERE id = test_point;
    
    PERFORM godel_test.assert_performance(
        'field_evolution_performance',
        format('SELECT godel.evolve_coherence_field_complete(''%s'', 0.01)', test_point),
        '8 seconds',
        'performance'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: bulk insertion (20 points) ≤ 5s'
SELECT godel_test.assert_performance(
    'bulk_insertion_performance',
    'SELECT godel_test.create_test_manifold_point() FROM generate_series(1,20)',
    '5 seconds',
    'performance'
);

SELECT godel_test.cleanup_test_data();

\echo 'Performance: HNSW vector similarity top-5 ≤ 2s'
DO $$
DECLARE
    test_points UUID[];
    test_point UUID;
    i INTEGER;
BEGIN
    test_points := ARRAY[]::UUID[];
    
    -- Create test points for similarity search
    FOR i IN 1..10 LOOP
        test_point := godel_test.create_test_manifold_point();
        test_points := array_append(test_points, test_point);
    END LOOP;
    
    -- Test vector similarity search performance (using HNSW index)
    PERFORM godel_test.assert_performance(
        'vector_similarity_search_performance',
        format('SELECT id FROM godel.manifold_points 
                WHERE semantic_field IS NOT NULL 
                ORDER BY semantic_field <-> (SELECT semantic_field FROM godel.manifold_points WHERE id = ''%s'') 
                LIMIT 5', test_points[1]),
        '2 seconds',
        'performance'
    );
    
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: materialized view refresh ≤ 10s'
SELECT godel_test.assert_performance(
    'materialized_view_refresh_performance',
    'SELECT godel.refresh_geometric_alerts()',
    '10 seconds',
    'performance'
);

\echo ''
\echo 'Completed function performance tests.'
