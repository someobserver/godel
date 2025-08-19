-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Test Suite Runner
-- File: tests/run_tests.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

\echo ''
\echo '============================================================'
\echo '                     GODEL Test Suite'
\echo '============================================================'
\echo ''
\echo 'Loading primary system schema for test environment...'
\echo ''
\i install.sql

\echo '============================================================'
\echo '                    Building Test Suite'
\echo '============================================================'
\echo ''
\i tests/test_framework.sql
\echo ''

\echo 'Initiating...'
\echo ''

-- Stabilize randomness across runs for deterministic test behavior
SELECT setseed(0.4200000000);

\echo '============================================================'
\echo '               Testing Foundation Functions'
\echo '============================================================'
\echo ''
\i tests/basemath/test_foundation_functions.sql
\echo ''

\echo '============================================================'
\echo '               Testing Geometric Analysis'
\echo '============================================================'
\echo ''
\i tests/basemath/test_geometric_analysis.sql
\echo ''

\echo '============================================================'
\echo '                 Testing Rigidity Modes'
\echo '============================================================'
\echo ''
\i tests/signatures/test_rigidity_signatures.sql
\echo ''

\echo '============================================================'
\echo '               Testing Fragmentation Modes'
\echo '============================================================'
\echo ''
\i tests/signatures/test_fragmentation_signatures.sql
\echo ''

\echo '============================================================'
\echo '                Testing Inflation Modes'
\echo '============================================================'
\echo ''
\i tests/signatures/test_inflation_signatures.sql
\echo ''

\echo '============================================================'
\echo '             Testing Observer Coupling Modes'
\echo '============================================================'
\echo ''
\i tests/signatures/test_observer_coupling_signatures.sql
\echo ''

\echo '============================================================'
\echo '               Testing System Integration'
\echo '============================================================'
\echo ''
\i tests/integration/test_complete_pipeline.sql
\echo ''

\echo '============================================================'
\echo '                   Performance Tests'
\echo '============================================================'
\echo ''
\i tests/performance/test_function_performance.sql
\echo ''

\echo ''
\echo '============================================================'
\echo '                         Summary'
\echo '============================================================'
\echo ''

SELECT 
    'PASSED' as status,
    COUNT(*) as count
FROM godel_test.test_results 
WHERE passed = true

UNION ALL

SELECT 
    'FAILED' as status,
    COUNT(*) as count
FROM godel_test.test_results 
WHERE passed = false

ORDER BY status DESC;

\echo 'Failed Tests (if noted above):'
SELECT 
    test_name,
    error_message,
    execution_time
FROM godel_test.test_results 
WHERE passed = false
ORDER BY execution_time DESC;

\echo 'Cleaning up...'
SELECT godel_test.teardown_test_framework(true);

\echo ''
\echo 'Completed. Thank you for testing.'
