-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Rigidity Signatures: over-constraint detection
-- File: schema/02_rigidity_signatures.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Purpose: Detect over‑constraint failure modes in the constraint geometry.
-- Exposes:
--   - Detect Attractor Dogmatism: constraining force dominates generative potential
--   - Detect Belief Calcification: low response rate under pressure
--   - Detect Metric Crystallization: ∂g/∂t → 0 with persistent curvature
-- Conventions:
--   - Return tables include (signature_type, severity ∈ [0,1], geometric_signature[], mathematical_evidence)
--   - Use stored coherence_magnitude when present; else compute over active dimension

-- Attractor Dogmatism

-- Summary: Detect over‑constraint where attractor stability and constraining force dominate generative potential.
-- Condition: A > A_crit ∧ ((|C−C_thr| · C_mag)/Φ(C)) > τ, guarding Φ(C)=0 with ε.
-- Inputs:
--   - point_id UUID — target point
--   - attractor_threshold FLOAT — A_crit (default 0.8)
--   - force_ratio_threshold FLOAT — τ (default 3.0)
-- Assumptions: Prefer stored coherence_magnitude else compute over active dimension.
-- Numerical guards: Use ε=1e-10 when Φ(C)=0 to avoid division by zero.
-- Returns: TABLE(signature_type, severity ∈ [0,1], geometric_signature FLOAT[], mathematical_evidence TEXT).
-- Severity scaling: severity = clip((constraining_force/Φ(C))/10).
CREATE OR REPLACE FUNCTION godel.detect_attractor_dogmatism(
    point_id UUID,
    attractor_threshold FLOAT DEFAULT 0.8,
    force_ratio_threshold FLOAT DEFAULT 3.0
) RETURNS TABLE(
    signature_type TEXT,
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
    SELECT mp.coherence_field, mp.semantic_mass, mp.attractor_stability
    INTO current_coherence, semantic_mass, attractor_stability
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    -- Use stored magnitude if available; else compute via helper
    coherence_mag := COALESCE(
        (SELECT coherence_magnitude FROM godel.manifold_points WHERE id = point_id),
        CASE WHEN current_coherence IS NOT NULL THEN COALESCE(public.vector_norm(current_coherence), 0.0) ELSE 0.0 END
    );
    
    IF attractor_stability > attractor_threshold AND coherence_mag > 0.7 THEN
        autopoietic_potential := godel.compute_autopoietic_potential(
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
                format(
                    'Attractor stability: %s > threshold, constraining force: %s >> generative potential: %s (ratio: %s)',
                    to_char(attractor_stability::numeric, 'FM999990.000'),
                    to_char(constraining_force::numeric, 'FM999990.000'),
                    to_char(autopoietic_potential::numeric, 'FM999990.000'),
                    to_char(force_ratio::numeric, 'FM999990.0')
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Belief Calcification

-- Summary: Detect low responsiveness of coherence under nontrivial external pressure.
-- Condition: mean ΔC over window < ε ∧ avg semantic_mass > θ.
-- Inputs:
--   - point_id UUID — target point
--   - responsiveness_threshold FLOAT — ε (default 0.01)
--   - time_window INTERVAL — horizon (default '6 hours')
-- Assumptions: Use conversation-local trajectory over window; external pressure proxied by semantic_mass.
-- Numerical guards: Use ε=1e-10 in ratios; require >1 sample.
-- Returns: TABLE(signature_type, severity ∈ [0,1], geometric_signature FLOAT[], mathematical_evidence TEXT).
-- Severity scaling: severity = clip(responsiveness_failure/50).
CREATE OR REPLACE FUNCTION godel.detect_belief_calcification(
    point_id UUID,
    responsiveness_threshold FLOAT DEFAULT 0.01,
    time_window INTERVAL DEFAULT '6 hours'
) RETURNS TABLE(
    signature_type TEXT,
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
    SELECT mp.coherence_field, mp.semantic_mass
    INTO current_coherence, semantic_mass
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    SELECT wf.wisdom_value INTO wisdom_value
    FROM godel.wisdom_field wf
    WHERE wf.point_id = detect_belief_calcification.point_id
    ORDER BY wf.computed_at DESC LIMIT 1;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    FOR rec IN (
        SELECT mp.coherence_field, mp.creation_timestamp, mp.semantic_mass
        FROM godel.manifold_points mp
        WHERE mp.conversation_id = (
            SELECT conversation_id FROM godel.manifold_points WHERE id = point_id
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
                format(
                    'Coherence response rate: %s ≈ 0 despite external pressure: %s (samples: %s)',
                    to_char(coherence_change_rate::numeric, 'FM999990.000000'),
                    to_char(avg_external_pressure::numeric, 'FM999990.000'),
                    num_samples
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Metric Crystallization

-- Summary: Detect static metric evolution with persistent curvature pressure.
-- Condition: evolution_rate < ε ∧ mean |R| > κ.
-- Inputs:
--   - point_id UUID — target point
--   - evolution_threshold FLOAT — ε (default 0.01)
--   - curvature_threshold FLOAT — κ (default 0.1)
-- Assumptions: Estimate evolution rate from |semantic_mass|; average |R| over active dimension.
-- Numerical guards: Use ε in ratios; handle NULL curvature arrays.
-- Returns: TABLE(signature_type, severity ∈ [0,1], geometric_signature FLOAT[], mathematical_evidence TEXT).
-- Severity scaling: severity = clip((curvature_pressure/(evolution_rate+ε))/100).
CREATE OR REPLACE FUNCTION godel.detect_metric_crystallization(
    point_id UUID,
    evolution_threshold FLOAT DEFAULT 0.01,
    curvature_threshold FLOAT DEFAULT 0.1
) RETURNS TABLE(
    signature_type TEXT,
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
    SELECT mp.metric_tensor, mp.ricci_curvature, mp.semantic_mass
    INTO current_metric, ricci_curvature, semantic_mass
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
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
            format(
                'Constraint evolution rate: %s → 0 while curvature pressure: %s ≠ 0 (ratio: %s)',
                to_char(metric_evolution_rate::numeric, 'FM999990.000000'),
                to_char(curvature_pressure::numeric, 'FM999990.000'),
                to_char(crystallization_signature::numeric, 'FM999990.0')
            );
    END IF;
    
    RETURN;
END;
$$;

-- Combined rigidity model
CREATE OR REPLACE FUNCTION godel.detect_rigidity_signatures(
    point_id UUID
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM godel.detect_attractor_dogmatism(point_id);
    RETURN QUERY SELECT * FROM godel.detect_belief_calcification(point_id);
    RETURN QUERY SELECT * FROM godel.detect_metric_crystallization(point_id);
    RETURN;
END;
$$;

 