-- PRISMA: Pattern Recognition in Semantic Manifold Analysis
-- Rigidity Pathologies: over-constraint detection
-- File: 02_rigidity_pathologies.sql
-- Updated: 2025-08-04
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Instantiates:
--   - Attractor Dogmatism: A(p,t) > A_crit AND ||∇V(C)|| >> Φ(C)
--   - Belief Calcification: lim(ε→0) dC/dt|C+ε ≈ 0
--   - Metric Crystallization: ∂g_ij/∂t → 0 while R_ij ≠ 0

-- Attractor Dogmatism
-- Signature: A(p,t) > A_crit AND ||∇V(C)|| >> Φ(C)
CREATE OR REPLACE FUNCTION prisma.detect_attractor_dogmatism(
    point_id UUID,
    attractor_threshold FLOAT DEFAULT 0.8,
    force_ratio_threshold FLOAT DEFAULT 3.0
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    coherence_mag FLOAT;
    semantic_mass FLOAT;
    attractor_stability FLOAT;
    
    autopoietic_potential FLOAT;
    constraining_force FLOAT;
    force_ratio FLOAT;
BEGIN
    SELECT coherence_field, semantic_mass, attractor_stability
    INTO current_coherence, semantic_mass, attractor_stability
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) 
                              FROM generate_series(1, LEAST(100, 2000)) i)));
    
    IF attractor_stability > attractor_threshold AND coherence_mag > 0.7 THEN
        autopoietic_potential := prisma.compute_autopoietic_potential(
            coherence_mag, 0.7, 2.0, 2.0
        );
        
        constraining_force := abs(coherence_mag - 0.7) * coherence_mag;
        
        IF autopoietic_potential > 0 THEN
            force_ratio := constraining_force / autopoietic_potential;
        ELSE
            force_ratio := constraining_force / 1e-10;
        END IF;
        
        IF force_ratio > force_ratio_threshold THEN
            RETURN QUERY SELECT 
                'ATTRACTOR_DOGMATISM'::TEXT,
                LEAST(1.0, force_ratio / 10.0),
                ARRAY[attractor_stability, coherence_mag, constraining_force, autopoietic_potential],
                format('Attractor stability: %.3f > threshold, constraining force: %.3f >> generative potential: %.3f (ratio: %.1f)', 
                       attractor_stability, constraining_force, autopoietic_potential, force_ratio);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Belief Calcification
-- Signature: lim(ε→0) dC/dt|C+ε ≈ 0
CREATE OR REPLACE FUNCTION prisma.detect_belief_calcification(
    point_id UUID,
    responsiveness_threshold FLOAT DEFAULT 0.01,
    time_window INTERVAL DEFAULT '6 hours'
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    rec RECORD;
    current_coherence VECTOR(2000);
    semantic_mass FLOAT;
    wisdom_value FLOAT;
    
    coherence_change_rate FLOAT := 0.0;
    avg_external_pressure FLOAT := 0.0;
    responsiveness_failure FLOAT;
    num_samples INTEGER := 0;
    i INTEGER;
BEGIN
    SELECT coherence_field, semantic_mass
    INTO current_coherence, semantic_mass
    FROM prisma.manifold_points WHERE id = point_id;
    
    SELECT wisdom_value INTO wisdom_value
    FROM prisma.wisdom_field
    WHERE point_id = detect_belief_calcification.point_id
    ORDER BY computed_at DESC LIMIT 1;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    FOR rec IN (
        SELECT mp.coherence_field, mp.creation_timestamp, mp.semantic_mass
        FROM prisma.manifold_points mp
        WHERE mp.conversation_id = (
            SELECT conversation_id FROM prisma.manifold_points WHERE id = point_id
        )
        AND mp.creation_timestamp >= NOW() - time_window
        ORDER BY mp.creation_timestamp
    ) LOOP
        num_samples := num_samples + 1;
        
        IF num_samples > 1 THEN
            coherence_change_rate := coherence_change_rate + 
                (rec.coherence_field <-> current_coherence);
        END IF;
        
        avg_external_pressure := avg_external_pressure + rec.semantic_mass;
    END LOOP;
    
    IF num_samples > 1 THEN
        coherence_change_rate := coherence_change_rate / (num_samples - 1);
        avg_external_pressure := avg_external_pressure / num_samples;
        
        IF coherence_change_rate < responsiveness_threshold AND avg_external_pressure > 0.3 THEN
            responsiveness_failure := avg_external_pressure / (coherence_change_rate + 1e-10);
            
            RETURN QUERY SELECT 
                'BELIEF_CALCIFICATION'::TEXT,
                LEAST(1.0, responsiveness_failure / 50.0),
                ARRAY[coherence_change_rate, avg_external_pressure, COALESCE(wisdom_value, 0.0), semantic_mass],
                format('Coherence response rate: %.6f ≈ 0 despite external pressure: %.3f (samples: %s)', 
                       coherence_change_rate, avg_external_pressure, num_samples);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Metric Crystallization
-- Signature: ∂g_ij/∂t → 0 while R_ij ≠ 0
CREATE OR REPLACE FUNCTION prisma.detect_metric_crystallization(
    point_id UUID,
    evolution_threshold FLOAT DEFAULT 0.01,
    curvature_threshold FLOAT DEFAULT 0.1
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_metric FLOAT[];
    ricci_curvature FLOAT[];
    semantic_mass FLOAT;
    
    metric_evolution_rate FLOAT := 0.0;
    curvature_pressure FLOAT := 0.0;
    crystallization_signature FLOAT;
    dim INTEGER := 100;
    i INTEGER;
BEGIN
    SELECT metric_tensor, ricci_curvature, semantic_mass
    INTO current_metric, ricci_curvature, semantic_mass
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_metric IS NULL THEN
        RETURN;
    END IF;
    metric_evolution_rate := abs(semantic_mass) * 0.1;
    
    IF ricci_curvature IS NOT NULL THEN
        FOR i IN 1..LEAST(dim, array_length(ricci_curvature, 1)) LOOP
            curvature_pressure := curvature_pressure + abs(ricci_curvature[i]);
        END LOOP;
        curvature_pressure := curvature_pressure / LEAST(dim, array_length(ricci_curvature, 1));
    ELSE
        curvature_pressure := 0.0;
    END IF;
    
    IF metric_evolution_rate < evolution_threshold AND curvature_pressure > curvature_threshold THEN
        crystallization_signature := curvature_pressure / (metric_evolution_rate + 1e-10);
        
        RETURN QUERY SELECT 
            'METRIC_CRYSTALLIZATION'::TEXT,
            LEAST(1.0, crystallization_signature / 100.0),
            ARRAY[metric_evolution_rate, curvature_pressure, semantic_mass],
            format('Constraint evolution rate: %.6f → 0 while curvature pressure: %.3f ≠ 0 (ratio: %.1f)', 
                   metric_evolution_rate, curvature_pressure, crystallization_signature);
    END IF;
    
    RETURN;
END;
$$;

-- Combined rigidity model
CREATE OR REPLACE FUNCTION prisma.detect_rigidity_pathologies(
    point_id UUID
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM prisma.detect_attractor_dogmatism(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_belief_calcification(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_metric_crystallization(point_id);
    RETURN;
END;
$$;

 