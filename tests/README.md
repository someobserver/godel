## GODEL SQL Test Suite

SQL-native tests for the geometric analysis engine. Runs entirely inside PostgreSQL.

### Layout
```
tests/
├── run_tests.sql               # Orchestrates full suite
├── test_framework.sql          # Assertions, result table, helpers
├── basemath/                   # Foundational math and geometry tests
│   ├── test_foundation_functions.sql
│   └── test_geometric_analysis.sql
├── signatures/                 # Detector tests by category
│   ├── test_rigidity_signatures.sql
│   ├── test_fragmentation_signatures.sql
│   ├── test_inflation_signatures.sql
│   └── test_observer_coupling_signatures.sql
├── integration/                # End-to-end pipeline tests
│   └── test_complete_pipeline.sql
└── performance/                # Benchmarks and latency guards
    └── test_function_performance.sql
```

### Default Parameters
- **User**: godel_user
- **Password**: changeme
- **Database**: godel_db
- **Port**: 5444
- **Host**: localhost

### Run
- **All tests**:
```bash
psql postgresql://godel_user:changeme@localhost:5444/godel_db -f tests/run_tests.sql
```

- **Single category** (init framework, then run a file):
```bash
psql postgresql://godel_user:changeme@localhost:5444/godel_db -f tests/test_framework.sql
psql postgresql://godel_user:changeme@localhost:5444/godel_db -f tests/signatures/test_rigidity_signatures.sql
```

### Functionality
- `run_tests.sql` loads `install.sql`, initializes the test framework, seeds RNG (`setseed(0.42)`), runs category files, prints a summary, and calls teardown.
- `tests/test_framework.sql` creates schema `godel_test`, the `test_results` table, and assertion helpers. Every assertion logs a row with timing and error context.
- Tests use deterministic helpers:
  - `godel_test.create_test_manifold_point(...)`
  - `godel_test.cleanup_test_data()`
  - `godel_test.teardown_test_framework(drop_schema boolean)`

### Assertions (SQL API)
- `godel_test.assert_float_equals(name, expected, actual, tolerance := 1e-6, category := 'general')`
- `godel_test.assert_true(name, condition, category := 'general', error_msg := 'Condition was false')`
- `godel_test.assert_array_equals(name, expected float[], actual float[], tolerance := 1e-6, category := 'array')`
- `godel_test.assert_no_error(name, sql text, category := 'execution')`
- `godel_test.assert_performance(name, sql text, max_duration interval, category := 'performance')`

### Results
- Stored in `godel_test.test_results(test_name, test_category, passed, expected_value, actual_value, execution_time, error_message, run_timestamp)`.
- The runner prints pass/fail counts and the failure list. Inspect details manually if needed:
```sql
SELECT * FROM godel_test.test_results WHERE passed = false ORDER BY execution_time DESC;
```

#### Result retention
- The main runner (`tests/run_tests.sql`) is a function-check wrapper that calls `godel_test.teardown_test_framework(true)`, which drops the `godel_test` schema after printing the summary. That cleans up `test_results` and other artifacts.
- To retain results for post-run inspection, choose one of the following:
  - Run the framework manually and skip teardown: run `tests/test_framework.sql` then the test file(s); query `godel_test.test_results` afterwards.
  - Modify the runner to skip dropping the schema: change the teardown call to `SELECT godel_test.teardown_test_framework(false);`.
  - Export failures before teardown: e.g. in `run_tests.sql` add `\o tests/results/failed.tsv` before the failure query and `\o` to close the output stream.

Retained test artifacts should be cleaned periodically. Call `godel_test.teardown_test_framework(true)` to do so.

### Categories
- **Basemath**: semantic mass, autopoietic potential, humility operator; matrix ops, curvature, geodesics.
- **Signatures**: rigidity, fragmentation, inflation, observer-coupling detectors. Verifies row schema (type, severity ∈ [0,1], evidence) and edge handling.
- **Integration**: complete pipeline, coordination, escalation, field evolution, monitoring views.
- **Performance**: time bounds for critical functions and detectors.

### Expected bounds (guidance)
- Foundation functions: ≤ 1s for ~1k evals
- Matrix ops (50×50): ≤ 3s
- Single-category detectors: ≤ 5s per point (realistic data)
- Full `detect_all_signatures`: ≤ 10s per point
- Coordination (5 nodes): ≤ 5s
- Field evolution (single step): ≤ 8s
