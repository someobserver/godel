-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Fragmentation Signatures: under-constraint detection
-- File: schema/03_fragmentation_signatures.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Provides
--   - Attractor Splintering: attractor count growth vs generative rate
--   - Coherence Dissolution: large gradient vs magnitude with positive acceleration
--   - Reference Decay: coupling decay without compensatory wisdom

-- Attractor Splintering
--   Criterion: attractor-generation rate dominates stabilization capacity
CREATE OR REPLACE FUNCTION godel.detect_attractor_splintering(
-- Purpose: Detect proliferation of attractor directions beyond stabilization capacity.
-- Condition: attractor_generation_rate / autopoietic_generation_rate > threshold.
-- Inputs: manifold_points (coherence_field, coherence_magnitude; same conversation over window).
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    splintering_threshold FLOAT DEFAULT 2.0,
    time_window INTERVAL DEFAULT '2 hours'
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    coherence_mag FLOAT;
    
    attractor_generation_rate FLOAT := 0.0;
    autopoietic_generation_rate FLOAT := 0.0;
    unique_directions INTEGER := 0;
    total_samples INTEGER := 0;
    splintering_ratio FLOAT;
    
    rec RECORD;
    prev_coherence VECTOR(2000);
    direction_variance FLOAT := 0.0;
BEGIN
    SELECT mp.coherence_field
    INTO current_coherence
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := COALESCE(
        (SELECT coherence_magnitude FROM godel.manifold_points WHERE id = point_id),
        CASE WHEN current_coherence IS NOT NULL THEN COALESCE(public.vector_norm(current_coherence), 0.0) ELSE 0.0 END
    );
    
    FOR rec IN (
        SELECT mp.coherence_field, mp.coherence_magnitude, mp.creation_timestamp
        FROM godel.manifold_points mp
        WHERE mp.conversation_id = (
            SELECT conversation_id FROM godel.manifold_points WHERE id = point_id
        )
        AND mp.creation_timestamp >= NOW() - time_window
        ORDER BY mp.creation_timestamp
    ) LOOP
        total_samples := total_samples + 1;
        
        IF prev_coherence IS NOT NULL THEN
            direction_variance := direction_variance + 
                (1.0 - (rec.coherence_field <-> prev_coherence));
            
            IF (1.0 - (rec.coherence_field <-> prev_coherence)) > 0.3 THEN
                unique_directions := unique_directions + 1;
            END IF;
        END IF;
        
        prev_coherence := rec.coherence_field;
    END LOOP;
    
    IF total_samples > 2 THEN
        attractor_generation_rate := unique_directions::FLOAT / 
            EXTRACT(EPOCH FROM time_window) * 3600.0;
        
        autopoietic_generation_rate := GREATEST(0.0, 
            godel.compute_autopoietic_potential(coherence_mag) * 
            direction_variance / total_samples
        );
        
        IF autopoietic_generation_rate > 0 THEN
            splintering_ratio := attractor_generation_rate / autopoietic_generation_rate;
        ELSE
            splintering_ratio := attractor_generation_rate;
        END IF;
        
        IF splintering_ratio > splintering_threshold THEN
            RETURN QUERY SELECT 
                'ATTRACTOR_SPLINTERING'::TEXT,
                LEAST(1.0, splintering_ratio / 10.0),
                ARRAY[attractor_generation_rate, autopoietic_generation_rate, direction_variance, unique_directions::FLOAT],
                format(
                    'Attractor generation: %s/hr > stabilization capacity: %s (ratio: %s, directions: %s)',
                    to_char(attractor_generation_rate::numeric, 'FM999990.000'),
                    to_char(autopoietic_generation_rate::numeric, 'FM999990.000'),
                    to_char(splintering_ratio::numeric, 'FM999990.0'),
                    unique_directions
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Coherence Dissolution
--   Criterion: ∥∇C∥ ≫ ∥C∥ and acceleration > 0
CREATE OR REPLACE FUNCTION godel.detect_coherence_dissolution(
-- Purpose: Detect unstable growth of coherence gradients.
-- Condition: ∥∇C∥ > τ · ∥C∥ and d²C/dt² > 0.
-- Inputs: manifold_points (coherence_field, metric_tensor); compute_finite_differences.
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    gradient_ratio_threshold FLOAT DEFAULT 3.0,
    acceleration_threshold FLOAT DEFAULT 0.0
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    metric_tensor FLOAT[];
    
    coherence_mag FLOAT;
    coherence_gradient_norm FLOAT;
    coherence_acceleration FLOAT;
    dissolution_signature FLOAT;
    
    derivatives RECORD;
    dim INTEGER := 100;
BEGIN
    SELECT mp.coherence_field, mp.metric_tensor
    INTO current_coherence, metric_tensor
    FROM godel.manifold_points mp WHERE mp.id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := COALESCE(public.vector_norm(current_coherence), 0.0);
    
    SELECT * INTO derivatives FROM godel.compute_finite_differences(point_id);
    
    IF derivatives IS NOT NULL THEN
        SELECT sqrt(sum(pow(derivatives.first_derivatives[i], 2)))
        INTO coherence_gradient_norm
        FROM generate_series(1, dim) i;
        
        SELECT sum(derivatives.second_derivatives[i])
        INTO coherence_acceleration
        FROM generate_series(1, dim) i;
        
        IF coherence_mag > 0.1 AND 
           coherence_gradient_norm > gradient_ratio_threshold * coherence_mag AND 
           coherence_acceleration > acceleration_threshold THEN
            
            dissolution_signature := coherence_gradient_norm / (coherence_mag + 1e-10);
            
            RETURN QUERY SELECT 
                'COHERENCE_DISSOLUTION'::TEXT,
                LEAST(1.0, dissolution_signature / 10.0),
                ARRAY[coherence_gradient_norm, coherence_mag, coherence_acceleration],
                format(
                    'Gradient magnitude: %s >> coherence: %s (ratio: %s), acceleration: %s > 0',
                    to_char(coherence_gradient_norm::numeric, 'FM999990.000'),
                    to_char(coherence_mag::numeric, 'FM999990.000'),
                    to_char(dissolution_signature::numeric, 'FM999990.0'),
                    to_char(coherence_acceleration::numeric, 'FM999990.000000')
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Reference Decay
--   Criterion: negative coupling trend with insufficient wisdom compensation
CREATE OR REPLACE FUNCTION godel.detect_reference_decay(
-- Purpose: Detect decreasing coupling strength without compensatory wisdom.
-- Condition: coupling_decay_rate < θ and compensatory_wisdom < τ.
-- Inputs: recursive_coupling (recent magnitudes), wisdom_field (wisdom, humility).
-- Returns: rows (type,severity∈[0,1],evidence[]).
    point_id UUID,
    decay_threshold FLOAT DEFAULT -0.1,
    wisdom_compensation_threshold FLOAT DEFAULT 0.3
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    current_wisdom FLOAT;
    humility_factor FLOAT;
    
    coupling_decay_rate FLOAT := 0.0;
    avg_coupling_strength FLOAT := 0.0;
    compensatory_wisdom FLOAT := 0.0;
    decay_severity FLOAT;
    sample_count INTEGER := 0;
    
    rec RECORD;
BEGIN
    SELECT wf.wisdom_value, wf.humility_factor
    INTO current_wisdom, humility_factor
    FROM godel.wisdom_field wf
    WHERE wf.point_id = detect_reference_decay.point_id
    ORDER BY wf.computed_at DESC LIMIT 1;
    
    FOR rec IN (
        SELECT rc.coupling_magnitude, rc.computed_at
        FROM godel.recursive_coupling rc
        WHERE rc.point_p = point_id OR rc.point_q = point_id
        ORDER BY rc.computed_at DESC
        LIMIT 10
    ) LOOP
        sample_count := sample_count + 1;
        avg_coupling_strength := avg_coupling_strength + rec.coupling_magnitude;
        
        IF sample_count > 1 THEN
            coupling_decay_rate := coupling_decay_rate + 
                (rec.coupling_magnitude - avg_coupling_strength / sample_count);
        END IF;
    END LOOP;
    
    IF sample_count > 1 THEN
        avg_coupling_strength := avg_coupling_strength / sample_count;
        coupling_decay_rate := coupling_decay_rate / (sample_count - 1);
        
        compensatory_wisdom := COALESCE(current_wisdom, 0.0) * COALESCE(humility_factor, 0.5);
        
        IF coupling_decay_rate < decay_threshold AND 
           compensatory_wisdom < wisdom_compensation_threshold THEN
            
            decay_severity := abs(coupling_decay_rate) * (1.0 - compensatory_wisdom);
            
            RETURN QUERY SELECT 
                'REFERENCE_DECAY'::TEXT,
                LEAST(1.0, decay_severity * 10.0),
                ARRAY[coupling_decay_rate, avg_coupling_strength, compensatory_wisdom, sample_count::FLOAT],
                format(
                    'Coupling decay rate: %s < 0, compensatory wisdom: %s < threshold (samples: %s)',
                    to_char(coupling_decay_rate::numeric, 'FM999990.000'),
                    to_char(compensatory_wisdom::numeric, 'FM999990.000'),
                    sample_count
                );
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Combined fragmentation model
CREATE OR REPLACE FUNCTION godel.detect_fragmentation_signatures(
    point_id UUID
) RETURNS TABLE(
    signature_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM godel.detect_attractor_splintering(point_id);
    RETURN QUERY SELECT * FROM godel.detect_coherence_dissolution(point_id);
    RETURN QUERY SELECT * FROM godel.detect_reference_decay(point_id);
    RETURN;
END;
$$;

-- Helper functions

-- Coherence field finite differences
CREATE OR REPLACE FUNCTION godel.compute_finite_differences(
    point_id UUID,
    h FLOAT DEFAULT 1e-6
) RETURNS TABLE(
    first_derivatives FLOAT[],
    second_derivatives FLOAT[]
) LANGUAGE plpgsql AS $$
DECLARE
    current_coherence VECTOR(2000);
    dim INTEGER := 100;
    first_deriv FLOAT[];
    second_deriv FLOAT[];
    i INTEGER;
    arr_current FLOAT[];
BEGIN
    SELECT coherence_field
    INTO current_coherence
    FROM godel.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN QUERY SELECT 
            ARRAY(SELECT 0.0 FROM generate_series(1, dim)),
            ARRAY(SELECT 0.0 FROM generate_series(1, dim));
        RETURN;
    END IF;
    
    arr_current := godel.vector_to_real_array(current_coherence);
    first_deriv := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    second_deriv := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    
    FOR i IN 1..dim LOOP
        first_deriv[i] := CASE 
            WHEN i < LEAST(dim, COALESCE(array_length(arr_current, 1), 1)) THEN 
                (arr_current[LEAST(i+1, array_length(arr_current,1))] - arr_current[GREATEST(1, i-1)]) / (2.0 * h)
            ELSE 0.0
        END;
        
        second_deriv[i] := CASE 
            WHEN i > 1 AND i < LEAST(dim, COALESCE(array_length(arr_current, 1), 1) - 1) THEN 
                (arr_current[LEAST(i+1, array_length(arr_current,1))] - 2.0 * arr_current[i] + arr_current[GREATEST(1, i-1)]) / (h * h)
            ELSE 0.0
        END;
    END LOOP;
    
    RETURN QUERY SELECT first_deriv, second_deriv;
END;
$$; 