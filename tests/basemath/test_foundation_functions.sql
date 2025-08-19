-- GODEL: Test Foundation Functions
-- File: tests/basemath/test_foundation_functions.sql
-- Updated: 2025-08-19
--
-- Tests for core mathematical functions in 00_foundation.sql
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License

\echo 'Semantic Mass: basic case (D=2, det=0.5, A=0.5) → expect 2.0'
SELECT godel_test.assert_float_equals(
    'semantic_mass_basic_calculation',
    2.0,  -- expected: 2 * (1/0.5) * 0.5 = 2.0
    godel.compute_semantic_mass(2.0, 0.5, 0.5),
    1e-6,
    'foundation'
);

\echo 'Semantic Mass: small determinant regularization (det=1e-6) → expect 1e6 ± 1e-3'
SELECT godel_test.assert_float_equals(
    'semantic_mass_regularization',
    1000000.0,  -- expected: 1 * (1/1e-6) * 1 = 1e6
    godel.compute_semantic_mass(1.0, 1e-6, 1.0),
    1e-3,
    'foundation'
);

\echo 'Semantic Mass: zero determinant clamps to 1e-10 → expect 1e10 ± 1e6'
SELECT godel_test.assert_float_equals(
    'semantic_mass_zero_determinant',
    10000000000.0,  -- expected: 1 * (1/1e-10) * 1 = 1e10
    godel.compute_semantic_mass(1.0, 0.0, 1.0),
    1e6,
    'foundation'
);

\echo 'Semantic Mass: negative recursive depth → result < 0'
SELECT godel_test.assert_true(
    'semantic_mass_handles_negatives',
    godel.compute_semantic_mass(-1.0, 1.0, 1.0) < 0,
    'foundation',
    'Semantic mass should handle negative recursive depth'
);

\echo 'Core Functions: large inputs across mass/auto/humility → executes without error'
SELECT godel_test.assert_no_error(
    'functions_handle_large_inputs',
    'SELECT godel.compute_semantic_mass(1e6, 1e6, 1e6), 
            godel.compute_autopoietic_potential(1e6), 
            godel.compute_humility_operator(1e6)',
    'foundation'
);

\echo 'Autopoietic Potential: C=0.8, C_thr=0.7, α=1, β=2 → expect 0.01'
SELECT godel_test.assert_float_equals(
    'autopoietic_above_threshold',
    0.01,  -- expected: 1.0 * (0.8 - 0.7)^2 = 0.01
    godel.compute_autopoietic_potential(0.8, 0.7, 1.0, 2.0),
    1e-6,
    'foundation'
);

\echo 'Autopoietic Potential: below threshold → expect 0.0'
SELECT godel_test.assert_float_equals(
    'autopoietic_below_threshold',
    0.0,
    godel.compute_autopoietic_potential(0.5, 0.7, 1.0, 2.0),
    1e-6,
    'foundation'
);

\echo 'Autopoietic Potential: at threshold → expect 0.0'
SELECT godel_test.assert_float_equals(
    'autopoietic_at_threshold',
    0.0,
    godel.compute_autopoietic_potential(0.7, 0.7, 1.0, 2.0),
    1e-6,
    'foundation'
);

\echo 'Autopoietic Potential: custom parameters α=2, β=1 → expect 0.4'
SELECT godel_test.assert_float_equals(
    'autopoietic_custom_parameters',
    0.4,  -- expected: 2.0 * (0.9 - 0.7)^1 = 2.0 * 0.2 = 0.4
    godel.compute_autopoietic_potential(0.9, 0.7, 2.0, 1.0),
    1e-6,
    'foundation'
);

\echo 'Humility Operator: at optimal recursion (R=0.5, R_opt=0.5, k=2) → expect 0.5'
SELECT godel_test.assert_float_equals(
    'humility_at_optimal',
    0.5,  -- expected: 0.5 * exp(-2*(0.5-0.5)) = 0.5 * exp(0) = 0.5
    godel.compute_humility_operator(0.5, 0.5, 2.0),
    1e-6,
    'foundation'
);

\echo 'Humility Operator: above optimal recursion → decays (value < 1.0)'
SELECT godel_test.assert_true(
    'humility_above_optimal_decays',
    godel.compute_humility_operator(1.0, 0.5, 2.0) < 1.0,
    'foundation',
    'Humility should decay when above optimal recursion'
);

\echo 'Humility Operator: below optimal recursion → increases (value > 0.2)'
SELECT godel_test.assert_true(
    'humility_below_optimal_increases',
    godel.compute_humility_operator(0.2, 0.5, 2.0) > 0.2,
    'foundation',
    'Humility increases when below optimal recursion due to positive exponent'
);

\echo 'Humility Operator: zero coupling → expect 0.0'
SELECT godel_test.assert_float_equals(
    'humility_zero_coupling',
    0.0,
    godel.compute_humility_operator(0.0, 0.5, 2.0),
    1e-6,
    'foundation'
);

\echo 'Humility Operator: monotonic decay away from optimum → far < optimal'
DO $$
DECLARE
    h_at_optimal FLOAT;
    h_far_from_optimal FLOAT;
BEGIN
    h_at_optimal := godel.compute_humility_operator(0.5, 0.5, 2.0);
    h_far_from_optimal := godel.compute_humility_operator(2.0, 0.5, 2.0);
    
    PERFORM godel_test.assert_true(
        'humility_monotonic_decay',
        h_far_from_optimal < h_at_optimal,
        'foundation',
        'Humility should decrease as we move further from optimal'
    );
END;
$$;

\echo ''
\echo 'Completed foundation function tests.'