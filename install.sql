-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Main Runner
-- File: install.sql
-- Updated: 2025-08-07
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

\echo 'Loading GODEL...'

\echo '1/7: Foundation...'
\i schema/00_foundation.sql

\echo '2/7: Geometric Analysis...'
\i schema/01_geometric_analysis.sql

\echo '3/7: Rigidity Signatures...'
\i schema/02_rigidity_signatures.sql

\echo '4/7: Fragmentation Signatures...'
\i schema/03_fragmentation_signatures.sql

\echo '5/7: Inflation Signatures...'
\i schema/04_inflation_signatures.sql

\echo '6/7: Observer-Coupling Signatures...'
\i schema/05_observer_coupling_signatures.sql

\echo '7/7: Operational Monitoring...'
\i schema/06_operational_monitoring.sql

\echo ''
\echo 'GODEL Loaded Successfully'
\echo ''
\echo 'Components:'
\echo '- 12 Geometric Detection Functions (4 categories x 3 signatures each)'
\echo '- Geometric field analysis'
\echo '- Coordination detection'
\echo '- Escalation prediction'
\echo '- Monitoring dashboards'
\echo ''
\echo 'Functions:'
\echo '- detect_all_signatures(point_id)'
\echo '- detect_coordination_via_coupling()'
\echo '- detect_escalation_via_field_evolution(point_ids)'
\echo ''
\echo 'Views: coordination_alerts, geometric_alerts'
\echo 'Ready.' 