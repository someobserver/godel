-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Observer-Coupling Signatures: interpretation operator breakdown
-- File: schema/05_observer_coupling_signatures.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Provides
--   - Paranoid Interpretation: negative bias with threat-pattern concentration
--   - Observer Solipsism: interpretation divergence exceeds fraction of field magnitude
--   - Semantic Narcissism: self-coupling dominates with weak external references

-- Paranoid Interpretation
--   Criterion: sustained negative interpretation bias and threat hyperattractor concentration
CREATE OR REPLACE FUNCTION godel.detect_paranoid_interpretation(
-- Purpose: Detect negative interpretation bias with threat attraction.
-- Condition: mean negative bias > threshold and threat pattern concentration > τ.
-- Inputs: manifold_points (coherence, mass), recursive_coupling (as external influence proxy).
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    bias_threshold FLOAT DEFAULT 0.3,
    threat_hyperattractor_threshold FLOAT DEFAULT 0.8
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    semantic_mass FLOAT;
    user_fp TEXT;
    
    negative_interpretation_bias FLOAT := 0.0;
    threat_pattern_concentration FLOAT := 0.0;
    interpretation_divergence FLOAT := 0.0;
    paranoid_signature FLOAT;
    
    sample_count INTEGER := 0;
    threat_interpretation_count INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT mp.coherence_field, mp.semantic_mass, mp.user_fingerprint
    INTO current_coherence, semantic_mass, user_fp
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    FOR rec IN (
        SELECT mp.coherence_field, mp.semantic_mass, mp.creation_timestamp,
               rc.coupling_magnitude
        FROM godel.manifold_points mp
        LEFT JOIN godel.recursive_coupling rc ON mp.id = rc.point_p
        WHERE mp.user_fingerprint = user_fp
        AND mp.creation_timestamp >= NOW() - INTERVAL '12 hours'
        ORDER BY mp.creation_timestamp DESC
        LIMIT 20
    ) LOOP
        sample_count := sample_count + 1;
        
        negative_interpretation_bias := negative_interpretation_bias + 
            GREATEST(0, 0.5 - COALESCE(public.vector_norm(public.subvector(rec.coherence_field, 1, godel.get_small_window()))
            , 0.0));
        
        IF rec.semantic_mass > 0.6 AND COALESCE(rec.coupling_magnitude, 0) < 0.3 THEN
            threat_interpretation_count := threat_interpretation_count + 1;
        END IF;
        
        interpretation_divergence := interpretation_divergence + 
            abs(0.5 - COALESCE(public.vector_norm(public.subvector(rec.coherence_field, 1, godel.get_small_window()))
            , 0.0));
    END LOOP;
    
    IF sample_count > 3 THEN
        negative_interpretation_bias := negative_interpretation_bias / sample_count;
        interpretation_divergence := interpretation_divergence / sample_count;
        threat_pattern_concentration := threat_interpretation_count::FLOAT / sample_count;
        
        IF negative_interpretation_bias > bias_threshold AND 
           threat_pattern_concentration > threat_hyperattractor_threshold THEN
            
            paranoid_signature := negative_interpretation_bias * threat_pattern_concentration;
            
            RETURN QUERY SELECT 
                'PARANOID_INTERPRETATION'::TEXT,
                LEAST(1.0, paranoid_signature * 2.0),
                ARRAY[negative_interpretation_bias, threat_pattern_concentration, interpretation_divergence, sample_count::FLOAT],
                format(
                    'Negative bias: %s > threshold, threat patterns: %s%% (samples: %s)', 
                    to_char(negative_interpretation_bias::numeric, 'FM999990.000'),
                    to_char((threat_pattern_concentration * 100)::numeric, 'FM999990.0'),
                    sample_count
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Observer Solipsism
--   Criterion: ∥I_ψ[C] - C∥ > τ∥C∥ over recent trajectory
CREATE OR REPLACE FUNCTION godel.detect_observer_solipsism(
-- Purpose: Detect divergence between self-interpretation and consensus.
-- Condition: (mean self divergence)/∥C∥ > τ with adequate samples.
-- Inputs: manifold_points (own/cohort coherence trajectories).
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    divergence_threshold FLOAT DEFAULT 0.5,
    time_window INTERVAL DEFAULT '8 hours'
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    user_fp TEXT;
    
    interpretation_divergence FLOAT := 0.0;
    consensus_divergence FLOAT := 0.0;
    field_magnitude FLOAT;
    solipsism_ratio FLOAT;
    solipsism_signature FLOAT;
    
    baseline_coherence VECTOR(2000);
    sample_count INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT mp.coherence_field, mp.user_fingerprint
    INTO current_coherence, user_fp
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL OR user_fp IS NULL THEN
        RETURN;
    END IF;
    
    field_magnitude := COALESCE(
        (SELECT coherence_magnitude FROM godel.manifold_points WHERE id = point_id),
        CASE WHEN current_coherence IS NOT NULL THEN COALESCE(public.vector_norm(current_coherence), 0.0) ELSE 0.0 END
    );
    
    -- Baseline latest consensus sample
    SELECT mp.coherence_field INTO baseline_coherence
    FROM godel.manifold_points mp
    WHERE mp.user_fingerprint != user_fp
    ORDER BY mp.creation_timestamp DESC LIMIT 1;
    
    IF baseline_coherence IS NULL THEN
        RETURN;
    END IF;
    
    FOR rec IN (
        SELECT coherence_field
        FROM godel.manifold_points mp
        WHERE mp.user_fingerprint = user_fp
        ORDER BY mp.creation_timestamp DESC LIMIT 10
    ) LOOP
        sample_count := sample_count + 1;
        
        interpretation_divergence := interpretation_divergence + (
            public.subvector(rec.coherence_field, 1, godel.get_active_dimension()) <->
            public.subvector(current_coherence, 1, godel.get_active_dimension())
        );
        consensus_divergence := consensus_divergence + (
            public.subvector(rec.coherence_field, 1, godel.get_active_dimension()) <->
            public.subvector(baseline_coherence, 1, godel.get_active_dimension())
        );
    END LOOP;
    
    IF sample_count > 2 AND field_magnitude > 0.1 THEN
        interpretation_divergence := interpretation_divergence / sample_count;
        consensus_divergence := consensus_divergence / sample_count;
        
        solipsism_ratio := interpretation_divergence / field_magnitude;
        
        IF solipsism_ratio > divergence_threshold THEN
            solipsism_signature := solipsism_ratio * consensus_divergence;
            
            RETURN QUERY SELECT 
                'OBSERVER_SOLIPSISM'::TEXT,
                LEAST(1.0, solipsism_signature),
                ARRAY[interpretation_divergence, field_magnitude, solipsism_ratio, consensus_divergence],
                format(
                    'Interpretation divergence: %s > %s * field magnitude: %s (ratio: %s)', 
                    to_char(interpretation_divergence::numeric, 'FM999990.000'),
                    to_char(divergence_threshold::numeric, 'FM999990.0'),
                    to_char(field_magnitude::numeric, 'FM999990.000'),
                    to_char(solipsism_ratio::numeric, 'FM999990.000')
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Semantic Narcissism
--   Criterion: self-coupling fraction above threshold with weak external references
CREATE OR REPLACE FUNCTION godel.detect_semantic_narcissism(
-- Purpose: Detect dominance of self-coupling over total coupling mass.
-- Condition: self_coupling/total > τ and external fraction < θ with sufficient refs.
-- Inputs: recursive_coupling joined to `manifold_points` by user.
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    self_coupling_threshold FLOAT DEFAULT 0.8,
    external_reference_threshold FLOAT DEFAULT 0.2
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    user_fp TEXT;
    
    self_coupling_strength FLOAT := 0.0;
    total_coupling_strength FLOAT := 0.0;
    external_coupling_strength FLOAT := 0.0;
    narcissism_ratio FLOAT;
    narcissism_signature FLOAT;
    
    self_reference_count INTEGER := 0;
    external_reference_count INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT mp.user_fingerprint
    INTO user_fp
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF user_fp IS NULL THEN
        RETURN;
    END IF;
    
    FOR rec IN (
        SELECT rc.coupling_magnitude, rc.point_p, rc.point_q
        FROM godel.recursive_coupling rc
        JOIN godel.manifold_points mp1 ON mp1.id = rc.point_p
        JOIN godel.manifold_points mp2 ON mp2.id = rc.point_q
        WHERE mp1.user_fingerprint = user_fp
          AND rc.computed_at >= NOW() - INTERVAL '12 hours'
    ) LOOP
        total_coupling_strength := total_coupling_strength + COALESCE(rec.coupling_magnitude, 0.0);
        
        IF rec.point_p = rec.point_q THEN
            self_coupling_strength := self_coupling_strength + COALESCE(rec.coupling_magnitude, 0.0);
            self_reference_count := self_reference_count + 1;
        ELSE
            external_coupling_strength := external_coupling_strength + COALESCE(rec.coupling_magnitude, 0.0);
            external_reference_count := external_reference_count + 1;
        END IF;
    END LOOP;
    
    IF total_coupling_strength > 0 AND (self_reference_count + external_reference_count) > 3 THEN
        narcissism_ratio := self_coupling_strength / total_coupling_strength;
        
        IF narcissism_ratio > self_coupling_threshold AND 
           external_coupling_strength / total_coupling_strength < external_reference_threshold THEN
            
            narcissism_signature := narcissism_ratio * (1.0 - external_coupling_strength / total_coupling_strength);
            
            RETURN QUERY SELECT 
                'SEMANTIC_NARCISSISM'::TEXT,
                LEAST(1.0, narcissism_signature),
                ARRAY[self_coupling_strength, external_coupling_strength, narcissism_ratio, (self_reference_count + external_reference_count)::FLOAT],
                format(
                    'Self-coupling: %s%% of total, external coupling: %s%% < threshold (refs: %s/%s)',
                    to_char((narcissism_ratio * 100)::numeric, 'FM999990.0'),
                    to_char(((external_coupling_strength / total_coupling_strength) * 100)::numeric, 'FM999990.0'),
                    self_reference_count, external_reference_count
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Combined observer-coupling model
CREATE OR REPLACE FUNCTION godel.detect_observer_coupling_signatures(
    point_id UUID
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM godel.detect_paranoid_interpretation(point_id);
    RETURN QUERY SELECT * FROM godel.detect_observer_solipsism(point_id);
    RETURN QUERY SELECT * FROM godel.detect_semantic_narcissism(point_id);
    RETURN;
END;
$$;  