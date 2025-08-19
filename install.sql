-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Main Runner
-- File: install.sql
-- Updated: 2025-08-07
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

\echo '============================================================'
\echo '                          GODEL'
\echo '    -- Geometric Ontology Detecting Emergent Logics --'
\echo ''
\echo '  a field analysis engine for semantic database structures'
\echo '============================================================'
\echo ''
\echo ''

SET client_min_messages TO warning;

\echo 'Sequence: schema/00_foundation.sql'
\echo '          schema/01_geometric_analysis.sql'
\echo '          schema/02_rigidity_signatures.sql'
\echo '          schema/03_fragmentation_signatures.sql'
\echo '          schema/04_inflation_signatures.sql'
\echo '          schema/05_observer_coupling_signatures.sql'
\echo '          schema/06_operational_monitoring.sql'
\echo ''
\echo '====================  RFT Foundation  ======================'
\echo ''
\i schema/00_foundation.sql
\echo ''

\echo '==================  Geometric Analysis  ===================='
\echo ''
\i schema/01_geometric_analysis.sql
\echo ''

\echo '==================  Rigidity Signatures  ==================='
\echo ''
\i schema/02_rigidity_signatures.sql
\echo ''

\echo '===============  Fragmentation Signatures  ================='
\echo ''
\i schema/03_fragmentation_signatures.sql
\echo ''

\echo '=================  Inflation Signatures  ==================='
\echo ''
\i schema/04_inflation_signatures.sql
\echo ''

\echo '==============  Observer-Coupling Signatures  =============='
\echo ''
\i schema/05_observer_coupling_signatures.sql
\echo ''

\echo '================  Operational Monitoring  =================='
\echo ''
\i schema/06_operational_monitoring.sql
\echo ''

SET client_min_messages TO notice;

\echo 'GODEL engine loaded successfully.'
\echo ''