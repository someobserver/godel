-- PRISMA: Pattern Recognition in Semantic Manifold Analysis
-- Main Runner
-- File: run_prisma.sql
-- Updated: 2025-08-04
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

\echo 'Loading PRISMA...'

\echo '1/7: Foundation...'
\i schema/00_foundation.sql

\echo '2/7: Geometric Analysis...'
\i schema/01_geometric_analysis.sql

\echo '3/7: Rigidity Pathologies...'
\i schema/02_rigidity_pathologies.sql

\echo '4/7: Fragmentation Pathologies...'
\i schema/03_fragmentation_pathologies.sql

\echo '5/7: Inflation Pathologies...'
\i schema/04_inflation_pathologies.sql

\echo '6/7: Observer-Coupling Pathologies...'
\i schema/05_observer_coupling_pathologies.sql

\echo '7/7: Operational Monitoring...'
\i schema/06_operational_monitoring.sql

\echo ''
\echo 'PRISMA Loaded Successfully'
\echo ''
\echo 'Components:'
\echo '- 12 Pathology Detection Functions (4 categories x 3 pathologies each)'
\echo '- Geometric field analysis'
\echo '- Coordination detection'
\echo '- Escalation prediction'
\echo '- Monitoring dashboards'
\echo ''
\echo 'Functions:'
\echo '- detect_all_pathologies(point_id)'
\echo '- detect_coordination_via_coupling()'
\echo '- detect_escalation_via_field_evolution(point_ids)'
\echo ''
\echo 'Views: coordination_alerts, pathology_alerts'
\echo 'Ready.' 