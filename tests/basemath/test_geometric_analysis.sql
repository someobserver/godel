-- GODEL: Test Geometric Analysis Functions
-- File: tests/basemath/test_geometric_analysis.sql
-- Updated: 2025-08-19
--
-- Tests for geometric analysis functions in 01_geometric_analysis.sql
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License

\echo 'Matrix Determinant: 2x2 identity → expect 1.0'
DO $$
DECLARE
    identity_2x2 FLOAT[][];
    det_result FLOAT;
BEGIN
    identity_2x2 := ARRAY[[1.0, 0.0], [0.0, 1.0]];
    det_result := godel.matrix_determinant(identity_2x2, 2);
    
    PERFORM godel_test.assert_float_equals(
        'determinant_2x2_identity',
        1.0,
        det_result,
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Matrix Determinant: 3x3 identity → expect 1.0'
DO $$
DECLARE
    identity_3x3 FLOAT[][];
    det_result FLOAT;
BEGIN
    identity_3x3 := ARRAY[
        [1.0, 0.0, 0.0], 
        [0.0, 1.0, 0.0], 
        [0.0, 0.0, 1.0]
    ];
    det_result := godel.matrix_determinant(identity_3x3, 3);
    
    PERFORM godel_test.assert_float_equals(
        'determinant_3x3_identity',
        1.0,
        det_result,
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Matrix Determinant: [[2,1],[1,2]] → expect 3.0'
DO $$
DECLARE
    test_matrix FLOAT[][];
    det_result FLOAT;
BEGIN
    test_matrix := ARRAY[[2.0, 1.0], [1.0, 2.0]];
    det_result := godel.matrix_determinant(test_matrix, 2);
    
    PERFORM godel_test.assert_float_equals(
        'determinant_2x2_known',
        3.0,
        det_result,
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Matrix Determinant: singular (rank-deficient) → expect 0.0'
DO $$
DECLARE
    singular_matrix FLOAT[][];
    det_result FLOAT;
BEGIN
    singular_matrix := ARRAY[[1.0, 2.0], [2.0, 4.0]];  -- Second row is 2x first row
    det_result := godel.matrix_determinant(singular_matrix, 2);
    
    PERFORM godel_test.assert_float_equals(
        'determinant_singular_matrix',
        0.0,
        det_result,
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Matrix Inverse: 2x2 identity → expect identity'
DO $$
DECLARE
    identity_2x2 FLOAT[][];
    inverse_result FLOAT[][];
BEGIN
    identity_2x2 := ARRAY[[1.0, 0.0], [0.0, 1.0]];
    inverse_result := godel.matrix_inverse_gauss_jordan(identity_2x2, 2);
    
    PERFORM godel_test.assert_float_equals(
        'inverse_identity_2x2_element_11',
        1.0,
        inverse_result[1][1],
        1e-6,
        'geometric'
    );
    
    PERFORM godel_test.assert_float_equals(
        'inverse_identity_2x2_element_22',
        1.0,
        inverse_result[2][2],
        1e-6,
        'geometric'
    );
    
    PERFORM godel_test.assert_float_equals(
        'inverse_identity_2x2_element_12',
        0.0,
        inverse_result[1][2],
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Matrix Inverse: [[2,1],[1,2]] → expect [[2/3,-1/3],[-1/3,2/3]] (selected entries)'
DO $$
DECLARE
    test_matrix FLOAT[][];
    inverse_result FLOAT[][];
BEGIN
    test_matrix := ARRAY[[2.0, 1.0], [1.0, 2.0]];
    inverse_result := godel.matrix_inverse_gauss_jordan(test_matrix, 2);
    
    PERFORM godel_test.assert_float_equals(
        'inverse_known_matrix_element_11',
        2.0/3.0,
        inverse_result[1][1],
        1e-6,
        'geometric'
    );
    
    PERFORM godel_test.assert_float_equals(
        'inverse_known_matrix_element_12',
        -1.0/3.0,
        inverse_result[1][2],
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Metric Tensor: simple neighbor perturbations → executes without error'
DO $$
DECLARE
    test_semantic_field VECTOR(2000);
    test_neighbors VECTOR(2000)[];
    metric_result FLOAT[];
    test_dim INTEGER := 3;  -- Test with small dimension for verification
BEGIN
    -- Create simple test field (first 3 components are [1,0,0])
    test_semantic_field := (
        SELECT ('[' || string_agg(CASE WHEN i = 1 THEN '1' ELSE '0' END, ',') || ']')::vector(2000)
        FROM generate_series(1,2000) i
    );
    
    -- Create neighboring fields with small differences
    test_neighbors := ARRAY[
        (
            SELECT ('[' || string_agg(CASE WHEN i = 1 THEN '0.9' ELSE '0' END, ',') || ']')::vector(2000)
            FROM generate_series(1,2000) i
        ),
        (
            SELECT ('[' || string_agg(CASE WHEN i = 1 THEN '1.1' ELSE '0' END, ',') || ']')::vector(2000)
            FROM generate_series(1,2000) i
        )
    ];
    
    -- Error handling
    DECLARE
        exec_ok BOOLEAN := true;
        err_msg TEXT := NULL;
    BEGIN
        BEGIN
            PERFORM godel.compute_metric_tensor_from_semantic_field(test_semantic_field, test_neighbors, 1.0);
        EXCEPTION WHEN OTHERS THEN
            exec_ok := false;
            err_msg := SQLERRM;
        END;
        PERFORM godel_test.assert_true(
            'metric_tensor_computation_executes',
            exec_ok,
            'geometric',
            COALESCE(err_msg, 'Execution should not error')
        );
    END;
END;
$$;

\echo 'Scalar Curvature: flat Ricci + identity metric → expect 0.0'
DO $$
DECLARE
    ricci_flat FLOAT[];
    identity_metric FLOAT[];
    scalar_result FLOAT;
    dim INTEGER := 3;
BEGIN
    -- Zero Ricci tensor
    ricci_flat := ARRAY(SELECT 0.0 FROM generate_series(1, dim * dim));
    
    -- Identity metric (flattened)
    identity_metric := ARRAY(SELECT 
        CASE WHEN i = j THEN 1.0 ELSE 0.0 END
        FROM generate_series(1, dim) i,
             generate_series(1, dim) j
        ORDER BY i, j
    );
    
    scalar_result := godel.compute_scalar_curvature(ricci_flat, identity_metric, dim);
    
    PERFORM godel_test.assert_float_equals(
        'scalar_curvature_flat_space',
        0.0,
        scalar_result,
        1e-6,
        'geometric'
    );
END;
$$;

\echo 'Geodesic distance: two random points, 10 steps → executes without error'
DO $$
DECLARE
    point_a UUID;
    point_b UUID;
BEGIN
    -- Create test points
    point_a := godel_test.create_test_manifold_point();
    point_b := godel_test.create_test_manifold_point();
    
    -- Test geodesic distance calculation executes without error
    PERFORM godel_test.assert_no_error(
        'geodesic_distance_computation',
        format('SELECT godel.integrate_geodesic_distance(''%s'', ''%s'', 10)', point_a, point_b),
        'geometric'
    );
    
    -- Cleanup
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Recursive coupling tensor: two random points → executes without error'
DO $$
DECLARE
    point_p UUID;
    point_q UUID;
    coupling_result FLOAT[];
BEGIN
    -- Create test points with controlled data
    point_p := godel_test.create_test_manifold_point();
    point_q := godel_test.create_test_manifold_point();
    
    -- Test coupling tensor computation executes
    PERFORM godel_test.assert_no_error(
        'coupling_tensor_computation',
        format('SELECT godel.compute_recursive_coupling_tensor(''%s'', ''%s'')', point_p, point_q),
        'geometric'
    );
    
    -- Cleanup
    PERFORM godel_test.cleanup_test_data();
END;
$$;

\echo 'Performance: matrix determinant (100x100 identity-like) ≤ 5s'
SELECT godel_test.assert_performance(
    'matrix_determinant_performance_100x100',
    format('SELECT godel.matrix_determinant(ARRAY(SELECT ARRAY(SELECT CASE WHEN i=j THEN 1.0 ELSE 0.0 END FROM generate_series(1,100) j) FROM generate_series(1,100) i), 100)'),
    '5 seconds',
    'geometric'
);

\echo ''
\echo 'Completed geometric analysis tests.'
