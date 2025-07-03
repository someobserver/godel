-- PRISM: Pathology Recognition In Semantic Manifolds
-- Inflation Pathologies: runaway autopoiesis detection
-- File: 04_inflation_pathologies.sql
-- Updated: 2025-07-01
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Instantiates:
--   - Delusional Expansion: Φ(C) >> V(C), H[R] ≈ 0, W(p,t) < W_min
--   - Semantic Hypercoherence: C(p,t) > C_max, ∮F_i·dS^i < F_leakage
--   - Recurgent Parasitism: Local mass growth at expense of broader ecology

-- Delusional Expansion
-- Signature: Φ(C) >> V(C), H[R] ≈ 0, W(p,t) < W_min
CREATE OR REPLACE FUNCTION prism.detect_delusional_expansion(
    point_id UUID,
    autopoietic_threshold FLOAT DEFAULT 5.0,
    humility_threshold FLOAT DEFAULT 0.1,
    wisdom_threshold FLOAT DEFAULT 0.2
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
    
    autopoietic_potential FLOAT;
    constraining_force FLOAT;
    humility_factor FLOAT;
    wisdom_value FLOAT;
    
    expansion_signature FLOAT;
BEGIN
    SELECT coherence_field, semantic_mass
    INTO current_coherence, semantic_mass
    FROM prism.manifold_points WHERE id = point_id;
    
    SELECT wisdom_value, humility_factor
    INTO wisdom_value, humility_factor
    FROM prism.wisdom_field
    WHERE point_id = detect_delusional_expansion.point_id
    ORDER BY computed_at DESC LIMIT 1;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) 
                              FROM generate_series(1, LEAST(100, 2000)) i)));
    
    autopoietic_potential := prism.compute_autopoietic_potential(coherence_mag);
    
    constraining_force := abs(coherence_mag - 0.7) * 0.5;
    IF autopoietic_potential > 0 AND 
       constraining_force > 0 AND
       autopoietic_potential > autopoietic_threshold * constraining_force AND
       COALESCE(humility_factor, 1.0) < humility_threshold AND
       COALESCE(wisdom_value, 1.0) < wisdom_threshold THEN
        
        expansion_signature := autopoietic_potential / (constraining_force + 1e-10) *
                              (1.0 - COALESCE(humility_factor, 0.0)) *
                              (1.0 - COALESCE(wisdom_value, 0.0));
        
        RETURN QUERY SELECT 
            'DELUSIONAL_EXPANSION'::TEXT,
            LEAST(1.0, expansion_signature / 20.0),
            ARRAY[autopoietic_potential, constraining_force, COALESCE(humility_factor, 0.0), COALESCE(wisdom_value, 0.0)],
            format('Autopoietic potential: %.3f >> constraining force: %.3f, humility: %.3f ≈ 0, wisdom: %.3f < threshold', 
                   autopoietic_potential, constraining_force, COALESCE(humility_factor, 0.0), COALESCE(wisdom_value, 0.0));
    END IF;
    
    RETURN;
END;
$$;

-- Semantic Hypercoherence
-- Signature: C(p,t) > C_max, ∮F_i·dS^i < F_leakage
CREATE OR REPLACE FUNCTION prism.detect_semantic_hypercoherence(
    point_id UUID,
    coherence_max_threshold FLOAT DEFAULT 0.95,
    leakage_threshold FLOAT DEFAULT 0.1,
    time_window INTERVAL DEFAULT '4 hours'
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
    
    boundary_permeability FLOAT := 0.0;
    external_influence_flux FLOAT := 0.0;
    hypercoherence_signature FLOAT;
    sample_count INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT coherence_field, semantic_mass
    INTO current_coherence, semantic_mass
    FROM prism.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) 
                              FROM generate_series(1, LEAST(100, 2000)) i)));
    
    IF coherence_mag > coherence_max_threshold THEN
        FOR rec IN (
            SELECT rc.coupling_magnitude, mp2.semantic_mass as external_mass
            FROM prism.recursive_coupling rc
            JOIN prism.manifold_points mp2 ON mp2.id = rc.point_q
            WHERE rc.point_p = point_id
            AND rc.computed_at >= NOW() - time_window
        ) LOOP
            sample_count := sample_count + 1;
            
            boundary_permeability := boundary_permeability + 
                rec.coupling_magnitude * rec.external_mass;
            
            external_influence_flux := external_influence_flux + rec.coupling_magnitude;
        END LOOP;
        
        IF sample_count > 0 THEN
            boundary_permeability := boundary_permeability / sample_count;
            external_influence_flux := external_influence_flux / sample_count;
        END IF;
        
        IF external_influence_flux < leakage_threshold THEN
            hypercoherence_signature := coherence_mag * (1.0 - external_influence_flux);
            
            RETURN QUERY SELECT 
                'SEMANTIC_HYPERCOHERENCE'::TEXT,
                LEAST(1.0, hypercoherence_signature),
                ARRAY[coherence_mag, external_influence_flux, boundary_permeability, sample_count::FLOAT],
                format('Coherence: %.3f > max threshold, boundary flux: %.3f < leakage threshold (samples: %s)', 
                       coherence_mag, external_influence_flux, sample_count);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Recurgent Parasitism
-- Signature: d/dt∫_Ω M(p,t) dV > 0, d/dt∫_{M\Ω} M(p,t) dV < 0
CREATE OR REPLACE FUNCTION prism.detect_recurgent_parasitism(
    point_id UUID,
    growth_threshold FLOAT DEFAULT 0.5,
    ecological_drain_threshold FLOAT DEFAULT -0.2,
    time_window INTERVAL DEFAULT '6 hours'
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_semantic_mass FLOAT;
    user_fingerprint TEXT;
    
    local_growth_rate FLOAT := 0.0;
    ecological_drain_rate FLOAT := 0.0;
    parasitism_signature FLOAT;
    
    local_samples INTEGER := 0;
    ecological_samples INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT semantic_mass, user_fingerprint
    INTO current_semantic_mass, user_fingerprint
    FROM prism.manifold_points WHERE id = point_id;
    
    IF current_semantic_mass IS NULL THEN
        RETURN;
    END IF;
    FOR rec IN (
        SELECT mp.semantic_mass, mp.creation_timestamp
        FROM prism.manifold_points mp
        WHERE mp.user_fingerprint = detect_recurgent_parasitism.user_fingerprint
        AND mp.creation_timestamp >= NOW() - time_window
        ORDER BY mp.creation_timestamp
    ) LOOP
        local_samples := local_samples + 1;
        
        IF local_samples > 1 THEN
            local_growth_rate := local_growth_rate + 
                (rec.semantic_mass - current_semantic_mass) / local_samples;
        END IF;
    END LOOP;
    
    FOR rec IN (
        SELECT AVG(mp.semantic_mass) as avg_mass, mp.creation_timestamp
        FROM prism.manifold_points mp
        WHERE mp.user_fingerprint != detect_recurgent_parasitism.user_fingerprint
        AND mp.creation_timestamp >= NOW() - time_window
        GROUP BY mp.creation_timestamp
        ORDER BY mp.creation_timestamp
    ) LOOP
        ecological_samples := ecological_samples + 1;
        
        IF ecological_samples > 1 THEN
            ecological_drain_rate := ecological_drain_rate + 
                (rec.avg_mass - 0.5) / ecological_samples;
        END IF;
    END LOOP;
    
    IF local_samples > 2 AND ecological_samples > 2 THEN
        local_growth_rate := local_growth_rate / (local_samples - 1);
        ecological_drain_rate := ecological_drain_rate / (ecological_samples - 1);
        
        IF local_growth_rate > growth_threshold AND 
           ecological_drain_rate < ecological_drain_threshold THEN
            
            parasitism_signature := local_growth_rate * abs(ecological_drain_rate);
            
            RETURN QUERY SELECT 
                'RECURGENT_PARASITISM'::TEXT,
                LEAST(1.0, parasitism_signature * 5.0),
                ARRAY[local_growth_rate, ecological_drain_rate, local_samples::FLOAT, ecological_samples::FLOAT],
                format('Local growth: %.3f > threshold while ecological impact: %.3f < drain threshold', 
                       local_growth_rate, ecological_drain_rate);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Combined inflation model
CREATE OR REPLACE FUNCTION prism.detect_inflation_pathologies(
    point_id UUID
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM prism.detect_delusional_expansion(point_id);
    RETURN QUERY SELECT * FROM prism.detect_semantic_hypercoherence(point_id);
    RETURN QUERY SELECT * FROM prism.detect_recurgent_parasitism(point_id);
    RETURN;
END;
$$; 