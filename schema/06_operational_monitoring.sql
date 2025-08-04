-- PRISMA: Pattern Recognition in Semantic Manifold Analysis
-- Operational Monitoring: real-time coordination detection, escalation prediction, and field evolution
-- File: 06_operational_monitoring.sql
-- Updated: 2025-08-04
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Instantiates:
--   - Coordination detection via coupling analysis
--   - Escalation prediction via field dynamics
--   - Coherence field evolution simulation
--   - Performance optimization indexes and views

-- Coordination detection
-- Geometric coupling analysis for suspicious interaction clusters
CREATE OR REPLACE FUNCTION prisma.detect_coordination_via_coupling(
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
        FROM prisma.manifold_points mp1
        JOIN prisma.recursive_coupling rc ON mp1.id = rc.point_p
        JOIN prisma.manifold_points mp2 ON mp2.id = rc.point_q
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
-- Trajectory analysis via coherence acceleration and curvature
CREATE OR REPLACE FUNCTION prisma.detect_escalation_via_field_evolution(
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
        SELECT * FROM prisma.manifold_points 
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
                        SELECT 1 FROM prisma.wisdom_field wf 
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
-- Geometric field dynamics with constraint curvature and regulatory forces
CREATE OR REPLACE FUNCTION prisma.evolve_coherence_field_complete(
    point_id UUID,
    dt FLOAT DEFAULT 0.01
) RETURNS VECTOR(2000) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    new_coherence VECTOR(2000);
    metric_tensor FLOAT[];
    metric_inverse FLOAT[];
    christoffel_symbols FLOAT[];
    semantic_mass FLOAT;
    
    -- Field evolution terms
    dalembertian VECTOR(2000);
    attractor_gradient VECTOR(2000);
    autopoietic_gradient VECTOR(2000);
    humility_constraint VECTOR(2000);
    
    -- Geometric computation variables
    second_covariant_deriv FLOAT;
    ricci_coupling_term FLOAT;
    
    dim INTEGER := 100;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    coherence_mag FLOAT;
    h FLOAT := 1e-6;  -- Finite difference step
BEGIN
    SELECT coherence_field, metric_tensor, christoffel_symbols, semantic_mass
    INTO current_coherence, metric_tensor, christoffel_symbols, semantic_mass
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    END IF;
    
    -- Compute metric inverse
    metric_inverse := prisma.compute_metric_inverse(metric_tensor, dim);
    
    -- Compute coherence magnitude
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) FROM generate_series(1, LEAST(dim, 2000)) i)));
    
    -- Initialize evolution terms
    dalembertian := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    attractor_gradient := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    autopoietic_gradient := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    humility_constraint := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    
    -- Field propagation with constraint curvature effects
    FOR i IN 1..LEAST(dim, 2000) LOOP
        second_covariant_deriv := 0.0;
        
        FOR j IN 1..dim LOOP
            FOR k IN 1..dim LOOP
                DECLARE
                    metric_idx INTEGER := (j-1)*dim + k;
                    christoffel_idx INTEGER;
                    connection_correction FLOAT := 0.0;
                    l INTEGER;
                BEGIN
                    FOR l IN 1..dim LOOP
                        christoffel_idx := (j-1)*dim*dim + (k-1)*dim + l;
                        IF christoffel_idx <= array_length(christoffel_symbols, 1) THEN
                            connection_correction := connection_correction - 
                                christoffel_symbols[christoffel_idx] * 
                                (current_coherence[LEAST(l, 2000)] - 
                                 COALESCE(current_coherence[GREATEST(l-1, 1)], 0.0)) / h;
                        END IF;
                    END LOOP;
                    
                    IF metric_idx <= array_length(metric_inverse, 1) THEN
                        second_covariant_deriv := second_covariant_deriv + 
                            metric_inverse[metric_idx] * connection_correction;
                    END IF;
                END;
            END LOOP;
        END LOOP;
        
        -- Semantic mass gravitational effects
        ricci_coupling_term := 0.0;
        FOR j IN 1..dim LOOP
            IF i = j THEN
                ricci_coupling_term := ricci_coupling_term - semantic_mass * current_coherence[LEAST(j, 2000)];
            END IF;
        END LOOP;
        
        dalembertian[i] := second_covariant_deriv + ricci_coupling_term;
    END LOOP;
    
    -- Stability attractor forces
    FOR i IN 1..LEAST(dim, 2000) LOOP
        attractor_gradient[i] := -(coherence_mag - 0.7) * current_coherence[i] / (coherence_mag + 1e-10);
    END LOOP;
    
    -- Autopoietic potential above coherence threshold
    IF coherence_mag >= 0.7 THEN
        FOR i IN 1..LEAST(dim, 2000) LOOP
            autopoietic_gradient[i] := 2.0 * (coherence_mag - 0.7) * current_coherence[i] / (coherence_mag + 1e-10);
        END LOOP;
    END IF;
    
    -- Humility constraint damping
    FOR i IN 1..LEAST(dim, 2000) LOOP
        humility_constraint[i] := -0.1 * coherence_mag * current_coherence[i];
    END LOOP;
    
    -- Integrate all evolution forces
    new_coherence := ARRAY(SELECT 0.0::REAL FROM generate_series(1, 2000));
    FOR i IN 1..LEAST(dim, 2000) LOOP
        new_coherence[i] := current_coherence[i] + dt * (
            dalembertian[i] + attractor_gradient[i] + autopoietic_gradient[i] + humility_constraint[i]
        );
    END LOOP;
    
    RETURN new_coherence;
END;
$$;

-- Comprehensive pathology detection
CREATE OR REPLACE FUNCTION prisma.detect_all_pathologies(
    point_id UUID
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM prisma.detect_rigidity_pathologies(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_fragmentation_pathologies(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_inflation_pathologies(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_observer_coupling_pathologies(point_id);
    RETURN;
END;
$$;

-- Operational monitoring views

CREATE VIEW prisma.coordination_alerts AS
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
FROM prisma.detect_coordination_via_coupling()
WHERE rft_coordination_confidence > 0.5;

CREATE VIEW prisma.pathology_alerts AS
SELECT 
    mp.id as point_id,
    mp.user_fingerprint,
    mp.creation_timestamp,
    mp.semantic_mass,
    pathology.pathology_type,
    pathology.severity,
    pathology.mathematical_evidence,
    CASE 
        WHEN pathology.severity > 0.8 THEN 'CRITICAL'
        WHEN pathology.severity > 0.6 THEN 'HIGH'
        WHEN pathology.severity > 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END as priority
FROM prisma.manifold_points mp
CROSS JOIN LATERAL prisma.detect_all_pathologies(mp.id) as pathology
WHERE pathology.severity > 0.3
ORDER BY pathology.severity DESC, mp.creation_timestamp DESC;

-- Performance optimization indices

CREATE INDEX IF NOT EXISTS idx_manifold_points_semantic_field
    ON prisma.manifold_points USING hnsw (semantic_field vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_manifold_points_coherence_field
    ON prisma.manifold_points USING hnsw (coherence_field vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_manifold_points_semantic_mass
    ON prisma.manifold_points(semantic_mass, creation_timestamp);

CREATE INDEX IF NOT EXISTS idx_manifold_points_user_timestamp
    ON prisma.manifold_points(user_fingerprint, creation_timestamp);

CREATE INDEX IF NOT EXISTS idx_recursive_coupling_magnitude
    ON prisma.recursive_coupling(coupling_magnitude, computed_at);

CREATE INDEX IF NOT EXISTS idx_recursive_coupling_points
    ON prisma.recursive_coupling(point_p, point_q, computed_at);

CREATE INDEX IF NOT EXISTS idx_wisdom_field_values
    ON prisma.wisdom_field(wisdom_value, humility_factor); 