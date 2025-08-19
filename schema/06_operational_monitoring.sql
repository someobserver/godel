-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Operational Monitoring: coordination detection, escalation prediction, evolution, and indexes
-- File: schema/06_operational_monitoring.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Provides
--   - Coordination detection via coupling analysis
--   - Escalation prediction via field dynamics
--   - Coherence field evolution simulation
--   - Monitoring views and performance indexes

-- Coordination detection
--   Clusters high-coupling cross-user pairs into hourly buckets; derives confidence score
CREATE OR REPLACE FUNCTION godel.detect_coordination_via_coupling(
-- Purpose: Identify cross-user coordination clusters via high coupling and geometric coherence.
-- Method: pairwise coupling filter (≥ threshold) within window → hourly bucket clustering.
-- Score: rft_coordination_confidence = clip(avg(coupling)·avg(coherence)·(count/10)·(avg_mass/100)).
-- Returns: clusters with confidence and mass concentration; filtered to rft_confidence > 0.5.
    time_window INTERVAL DEFAULT '24 hours',
    coupling_threshold FLOAT DEFAULT 0.8,
    min_cluster_size INTEGER DEFAULT 3
) RETURNS TABLE (
    cluster_id TEXT,
    cluster_size INTEGER,
    avg_coupling_strength FLOAT,
    geometric_coherence FLOAT,
    rft_coordination_confidence FLOAT,
    semantic_mass_concentration FLOAT
) LANGUAGE SQL AS $$
    WITH coupling_analysis AS (
        SELECT 
            mp1.id as point1_id,
            mp2.id as point2_id,
            mp1.user_fingerprint as user1,
            mp2.user_fingerprint as user2,
            mp1.creation_timestamp,
            rc.coupling_magnitude,
            rc.coupling_tensor,
            mp1.semantic_mass as semantic_mass_1,
            mp2.semantic_mass as semantic_mass_2,
            -- Combined influence score
            (mp1.semantic_mass + mp2.semantic_mass) / 2.0 as avg_pair_semantic_mass,
            -- Geometric similarity adjusted for constraint density
            CASE 
                WHEN mp1.metric_determinant > 0 AND mp2.metric_determinant > 0
                THEN 1.0 - (mp1.coherence_field <-> mp2.coherence_field) / 
                     sqrt(mp1.metric_determinant * mp2.metric_determinant)
                ELSE 1.0 - (mp1.coherence_field <-> mp2.coherence_field)
            END as geometric_coherence
        FROM godel.manifold_points mp1
        JOIN godel.recursive_coupling rc ON mp1.id = rc.point_p
        JOIN godel.manifold_points mp2 ON mp2.id = rc.point_q
        WHERE 
            mp1.creation_timestamp >= NOW() - time_window
            AND mp2.creation_timestamp >= NOW() - time_window
            AND mp1.user_fingerprint != mp2.user_fingerprint
            AND rc.coupling_magnitude >= coupling_threshold
    ),
    cluster_analysis AS (
        SELECT 
            concat('rft_cluster_', floor(extract(epoch from min(creation_timestamp))/3600)::text) as cluster_id,
            count(*) as cluster_size,
            avg(coupling_magnitude) as avg_coupling_strength,
            avg(geometric_coherence) as geometric_coherence,
            -- Coordination confidence score
            LEAST(1.0, 
                avg(coupling_magnitude) * 
                avg(geometric_coherence) * 
                (count(*) / 10.0) *
                (avg(avg_pair_semantic_mass) / 100.0)
            ) as rft_coordination_confidence,
            avg(avg_pair_semantic_mass) as semantic_mass_concentration
        FROM coupling_analysis
        GROUP BY floor(extract(epoch from creation_timestamp)/3600)
        HAVING count(*) >= min_cluster_size
    )
    SELECT * FROM cluster_analysis
    WHERE rft_coordination_confidence > 0.5
    ORDER BY rft_coordination_confidence DESC, semantic_mass_concentration DESC;
$$;

-- Escalation detection
--   Uses coherence acceleration with scalar curvature to estimate trajectory and urgency
CREATE OR REPLACE FUNCTION godel.detect_escalation_via_field_evolution(
-- Purpose: Estimate escalation trajectory using coherence acceleration and curvature along a conversation.
-- Inputs: ordered `manifold_points` ids; uses scalar_curvature and semantic_mass.
-- Returns: per-point acceleration, curvature, trajectory, and intervention urgency.
    conversation_points UUID[]
) RETURNS TABLE (
    point_id UUID,
    coherence_acceleration FLOAT,
    semantic_curvature FLOAT,
    escalation_trajectory FLOAT,
    intervention_urgency FLOAT
) LANGUAGE plpgsql AS $$
DECLARE
    point_rec RECORD;
    prev_coherence VECTOR(2000);
    prev_timestamp TIMESTAMP;
    coherence_velocity FLOAT;
    coherence_accel FLOAT;
BEGIN
    FOR point_rec IN 
        SELECT * FROM godel.manifold_points 
        WHERE id = ANY(conversation_points)
        ORDER BY creation_timestamp
    LOOP
        IF prev_coherence IS NOT NULL THEN
            -- Rate of coherence change
            coherence_velocity := (point_rec.coherence_field <-> prev_coherence) / 
                                  GREATEST(EXTRACT(EPOCH FROM point_rec.creation_timestamp - prev_timestamp), 1.0);
            
            -- Constraint geometry effects
            coherence_accel := COALESCE(point_rec.scalar_curvature * coherence_velocity, 0.0);
            
            RETURN QUERY SELECT 
                point_rec.id,
                coherence_accel,
                COALESCE(point_rec.scalar_curvature, 0.0),
                -- Predicted escalation trajectory
                CASE 
                    WHEN coherence_accel > 0.2 AND point_rec.semantic_mass > 0.5
                    THEN coherence_accel * point_rec.semantic_mass * 2.0
                    ELSE coherence_accel * 0.5
                END,
                -- Intervention priority
                CASE 
                    WHEN coherence_accel > 0.3 AND EXISTS(
                        SELECT 1 FROM godel.wisdom_field wf 
                        WHERE wf.point_id = point_rec.id 
                        AND wf.humility_factor < 0.3
                    )
                    THEN LEAST(1.0, coherence_accel * point_rec.semantic_mass * 1.5)
                    ELSE 0.3
                END;
        END IF;
        
        prev_coherence := point_rec.coherence_field;
        prev_timestamp := point_rec.creation_timestamp;
    END LOOP;
END;
$$;

-- Coherence field evolution
--   Integrates dalembertian + attractor gradient + autopoietic gradient + humility damping
CREATE OR REPLACE FUNCTION godel.evolve_coherence_field_complete(
-- Purpose: Integrate coherence field update under geometric and regulatory forces.
-- Terms: dalembertian (covariant second derivative + Ricci term), stability attractor, autopoietic, humility damping.
-- Assumptions: active dimension n=100; vector(2000) truncated; metric inverse computed each step.
-- Numerical: finite differences with step h=1e-6; diagonal mass term; linear integration with step dt.
-- Returns: updated field as VECTOR(2000).
    point_id UUID,
    dt FLOAT DEFAULT 0.01
) RETURNS VECTOR(2000) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    arr_current FLOAT[];
    arr_new FLOAT[];
    metric_tensor FLOAT[];
    metric_inverse FLOAT[];
    christoffel_symbols FLOAT[];
    semantic_mass FLOAT;
    
    -- Field evolution terms
    arr_dalembertian FLOAT[];
    arr_attractor_gradient FLOAT[];
    arr_autopoietic_gradient FLOAT[];
    arr_humility_constraint FLOAT[];
    
    -- Geometric computation variables
    second_covariant_deriv FLOAT;
    ricci_coupling_term FLOAT;
    
    dim INTEGER := 100;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    coherence_mag FLOAT;
    h FLOAT := 1e-6;  -- Finite difference step
    -- Performance locals (do not change math)
    arr_len INTEGER;
    n INTEGER;
    metric_len INTEGER;
    christoffel_len INTEGER;
    metric_idx INTEGER;
    christoffel_idx INTEGER;
    connection_correction FLOAT;
    l INTEGER;
    val_i FLOAT;
    arr_delta FLOAT[];
    second_covariant_total FLOAT;
BEGIN
    SELECT mp.coherence_field, mp.metric_tensor, mp.christoffel_symbols, mp.semantic_mass
    INTO current_coherence, metric_tensor, christoffel_symbols, semantic_mass
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    END IF;
    
    -- Convert vector to array once for element-wise access
    arr_current := godel.vector_to_real_array(current_coherence);
    arr_len := COALESCE(array_length(arr_current, 1), 0);
    n := LEAST(dim, GREATEST(arr_len, 1));

    -- Compute metric inverse
    metric_inverse := godel.compute_metric_inverse(metric_tensor, dim);
    metric_len := COALESCE(array_length(metric_inverse, 1), 0);
    christoffel_len := COALESCE(array_length(christoffel_symbols, 1), 0);
    
    -- Compute coherence magnitude
    coherence_mag := COALESCE(
        (SELECT coherence_magnitude FROM godel.manifold_points WHERE id = point_id),
        COALESCE(public.vector_norm(current_coherence), 0.0)
    );
    
    -- Initialize evolution terms
    arr_dalembertian := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    arr_attractor_gradient := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    arr_autopoietic_gradient := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    arr_humility_constraint := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    
    -- Precompute finite-difference deltas once
    arr_delta := ARRAY(SELECT 0.0 FROM generate_series(1, n));
    FOR l IN 1..n LOOP
        arr_delta[l] := (
            arr_current[LEAST(l, arr_len)] - 
            COALESCE(arr_current[GREATEST(l-1, 1)], 0.0)
        ) / h;
    END LOOP;
    
    -- Field propagation with constraint curvature effects
    -- Hoist i-invariant covariant contribution
    second_covariant_total := 0.0;
    IF metric_len > 0 AND christoffel_len > 0 THEN
        FOR j IN 1..dim LOOP
            FOR k IN 1..dim LOOP
                metric_idx := (j-1)*dim + k;
                connection_correction := 0.0;
                FOR l IN 1..n LOOP
                    christoffel_idx := (j-1)*dim*dim + (k-1)*dim + l;
                    IF christoffel_idx <= christoffel_len THEN
                        connection_correction := connection_correction - 
                            christoffel_symbols[christoffel_idx] * arr_delta[l];
                    END IF;
                END LOOP;
                IF metric_idx <= metric_len THEN
                    second_covariant_total := second_covariant_total + 
                        metric_inverse[metric_idx] * connection_correction;
                END IF;
            END LOOP;
        END LOOP;
    END IF;

    FOR i IN 1..LEAST(dim, 2000) LOOP
        -- Semantic mass gravitational effects (diagonal)
        ricci_coupling_term := - semantic_mass * arr_current[LEAST(i, GREATEST(arr_len, 1))];
        arr_dalembertian[i] := second_covariant_total + ricci_coupling_term;
    END LOOP;
    
    -- Stability attractor forces
    FOR i IN 1..LEAST(dim, 2000) LOOP
        val_i := arr_current[LEAST(i, GREATEST(arr_len, 1))];
        arr_attractor_gradient[i] := -(coherence_mag - 0.7) * val_i / (coherence_mag + 1e-10);
    END LOOP;
    
    -- Autopoietic potential above coherence threshold
    IF coherence_mag >= 0.7 THEN
        FOR i IN 1..LEAST(dim, 2000) LOOP
            val_i := arr_current[LEAST(i, GREATEST(arr_len, 1))];
            arr_autopoietic_gradient[i] := 2.0 * (coherence_mag - 0.7) * val_i / (coherence_mag + 1e-10);
        END LOOP;
    END IF;
    
    -- Humility constraint damping
    FOR i IN 1..LEAST(dim, 2000) LOOP
        val_i := arr_current[LEAST(i, GREATEST(arr_len, 1))];
        arr_humility_constraint[i] := -0.1 * coherence_mag * val_i;
    END LOOP;
    
    -- Integrate all evolution forces
    arr_new := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    FOR i IN 1..LEAST(dim, 2000) LOOP
        val_i := arr_current[LEAST(i, GREATEST(arr_len, 1))];
        arr_new[i] := 
            val_i + dt * (
                arr_dalembertian[i] + arr_attractor_gradient[i] + arr_autopoietic_gradient[i] + arr_humility_constraint[i]
            );
    END LOOP;
    
    RETURN arr_new::vector(2000);
END;
$$;

-- Comprehensive geometric detection
CREATE OR REPLACE FUNCTION godel.detect_all_signatures(
    point_id UUID
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM godel.detect_rigidity_signatures(point_id);
    RETURN QUERY SELECT * FROM godel.detect_fragmentation_signatures(point_id);
    RETURN QUERY SELECT * FROM godel.detect_inflation_signatures(point_id);
    RETURN QUERY SELECT * FROM godel.detect_observer_coupling_signatures(point_id);
    RETURN;
END;
$$;

-- Operational monitoring views

CREATE OR REPLACE VIEW godel.coordination_alerts AS
SELECT 
    cluster_id,
    cluster_size,
    avg_coupling_strength,
    geometric_coherence,
    rft_coordination_confidence,
    semantic_mass_concentration,
    'RFT_COORDINATION_DETECTED' as alert_type,
    CASE 
        WHEN rft_coordination_confidence > 0.8 THEN 'HIGH'
        WHEN rft_coordination_confidence > 0.6 THEN 'MEDIUM'
        ELSE 'LOW'
    END as priority
FROM godel.detect_coordination_via_coupling()
WHERE rft_coordination_confidence > 0.5;

DO $$ BEGIN
    PERFORM 1 FROM pg_matviews WHERE schemaname = 'godel' AND matviewname = 'geometric_alerts_mv';
    IF FOUND THEN
        EXECUTE 'DROP MATERIALIZED VIEW IF EXISTS godel.geometric_alerts_mv';
    END IF;
END $$;

CREATE MATERIALIZED VIEW godel.geometric_alerts_mv AS
SELECT 
    mp.id as point_id,
    mp.user_fingerprint,
    mp.creation_timestamp,
    mp.semantic_mass,
    signature.signature_type,
    signature.severity,
    signature.mathematical_evidence,
    CASE 
        WHEN signature.severity > 0.8 THEN 'CRITICAL'
        WHEN signature.severity > 0.6 THEN 'HIGH'
        WHEN signature.severity > 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END as priority
FROM godel.manifold_points mp
CROSS JOIN LATERAL godel.detect_all_signatures(mp.id) as signature
WHERE signature.severity > 0.3
  AND mp.creation_timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY signature.severity DESC, mp.creation_timestamp DESC;

CREATE INDEX IF NOT EXISTS idx_geometric_alerts_mv_point_time
    ON godel.geometric_alerts_mv(point_id, creation_timestamp);
CREATE INDEX IF NOT EXISTS idx_geometric_alerts_mv_severity_time
    ON godel.geometric_alerts_mv(severity, creation_timestamp);
CREATE INDEX IF NOT EXISTS idx_geometric_alerts_mv_priority
    ON godel.geometric_alerts_mv(priority);

CREATE OR REPLACE FUNCTION godel.refresh_geometric_alerts()
RETURNS void LANGUAGE SQL AS $$
    REFRESH MATERIALIZED VIEW godel.geometric_alerts_mv;
$$;

-- Performance optimization indexes

CREATE INDEX IF NOT EXISTS idx_manifold_points_semantic_field
    ON godel.manifold_points USING hnsw (semantic_field vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_manifold_points_coherence_field
    ON godel.manifold_points USING hnsw (coherence_field vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_manifold_points_semantic_mass
    ON godel.manifold_points(semantic_mass, creation_timestamp);

CREATE INDEX IF NOT EXISTS idx_manifold_points_user_timestamp
    ON godel.manifold_points(user_fingerprint, creation_timestamp);

CREATE INDEX IF NOT EXISTS idx_recursive_coupling_magnitude
    ON godel.recursive_coupling(coupling_magnitude, computed_at);

CREATE INDEX IF NOT EXISTS idx_recursive_coupling_points
    ON godel.recursive_coupling(point_p, point_q, computed_at);

CREATE INDEX IF NOT EXISTS idx_wisdom_field_values
    ON godel.wisdom_field(wisdom_value, humility_factor); 