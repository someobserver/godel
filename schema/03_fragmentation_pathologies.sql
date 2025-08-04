-- PRISMA: Pattern Recognition in Semantic Manifold Analysis
-- Fragmentation Pathologies: under-constraint detection
-- File: 03_fragmentation_pathologies.sql
-- Updated: 2025-08-04
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Instantiates:
--   - Attractor Splintering: dN_attractors/dt > κ·dΦ(C)/dt
--   - Coherence Dissolution: ||∇C|| >> ||C|| AND d²C/dt² > 0
--   - Reference Decay: d||R_ijk||/dt < 0 without compensation

-- Attractor Splintering
-- Signature: dN_attractors/dt > κ·dΦ(C)/dt
CREATE OR REPLACE FUNCTION prisma.detect_attractor_splintering(
    point_id UUID,
    splintering_threshold FLOAT DEFAULT 2.0,
    time_window INTERVAL DEFAULT '2 hours'
) RETURNS TABLE(
    pathology_type TEXT,
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
    SELECT coherence_field
    INTO current_coherence
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) 
                              FROM generate_series(1, LEAST(100, 2000)) i)));
    
    FOR rec IN (
        SELECT mp.coherence_field, mp.coherence_magnitude, mp.creation_timestamp
        FROM prisma.manifold_points mp
        WHERE mp.conversation_id = (
            SELECT conversation_id FROM prisma.manifold_points WHERE id = point_id
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
            prisma.compute_autopoietic_potential(coherence_mag) * 
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
                format('Attractor generation: %.3f/hr > stabilization capacity: %.3f (ratio: %.1f, directions: %s)', 
                       attractor_generation_rate, autopoietic_generation_rate, splintering_ratio, unique_directions);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Coherence Dissolution
-- Signature: ||∇C|| >> ||C|| AND d²C/dt² > 0
CREATE OR REPLACE FUNCTION prisma.detect_coherence_dissolution(
    point_id UUID,
    gradient_ratio_threshold FLOAT DEFAULT 3.0,
    acceleration_threshold FLOAT DEFAULT 0.0
) RETURNS TABLE(
    pathology_type TEXT,
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
    SELECT coherence_field, metric_tensor
    INTO current_coherence, metric_tensor
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN;
    END IF;
    
    coherence_mag := sqrt(sum((SELECT pow(current_coherence[i], 2) 
                              FROM generate_series(1, LEAST(dim, 2000)) i)));
    
    SELECT * INTO derivatives FROM prisma.compute_finite_differences(point_id);
    
    IF derivatives IS NOT NULL THEN
        coherence_gradient_norm := sqrt(sum((SELECT pow(derivatives.first_derivatives[i], 2) 
                                            FROM generate_series(1, dim) i)));
        
        coherence_acceleration := sum((SELECT derivatives.second_derivatives[i] 
                                      FROM generate_series(1, dim) i));
        
        IF coherence_mag > 0.1 AND 
           coherence_gradient_norm > gradient_ratio_threshold * coherence_mag AND 
           coherence_acceleration > acceleration_threshold THEN
            
            dissolution_signature := coherence_gradient_norm / (coherence_mag + 1e-10);
            
            RETURN QUERY SELECT 
                'COHERENCE_DISSOLUTION'::TEXT,
                LEAST(1.0, dissolution_signature / 10.0),
                ARRAY[coherence_gradient_norm, coherence_mag, coherence_acceleration],
                format('Gradient magnitude: %.3f >> coherence: %.3f (ratio: %.1f), acceleration: %.6f > 0', 
                       coherence_gradient_norm, coherence_mag, dissolution_signature, coherence_acceleration);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Reference Decay
-- Signature: d||R_ijk||/dt < 0 without compensatory mechanism
CREATE OR REPLACE FUNCTION prisma.detect_reference_decay(
    point_id UUID,
    decay_threshold FLOAT DEFAULT -0.1,
    wisdom_compensation_threshold FLOAT DEFAULT 0.3
) RETURNS TABLE(
    pathology_type TEXT,
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
    SELECT wisdom_value, humility_factor
    INTO current_wisdom, humility_factor
    FROM prisma.wisdom_field
    WHERE point_id = detect_reference_decay.point_id
    ORDER BY computed_at DESC LIMIT 1;
    
    FOR rec IN (
        SELECT rc.coupling_magnitude, rc.computed_at
        FROM prisma.recursive_coupling rc
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
                format('Coupling decay rate: %.3f < 0, compensatory wisdom: %.3f < threshold (samples: %s)', 
                       coupling_decay_rate, compensatory_wisdom, sample_count);
        END IF;
    END IF;
    
    RETURN;
END;
$$;

-- Combined fragmentation model
CREATE OR REPLACE FUNCTION prisma.detect_fragmentation_pathologies(
    point_id UUID
) RETURNS TABLE(
    pathology_type TEXT,
    severity FLOAT,
    geometric_signature FLOAT[],
    mathematical_evidence TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT * FROM prisma.detect_attractor_splintering(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_coherence_dissolution(point_id);
    RETURN QUERY SELECT * FROM prisma.detect_reference_decay(point_id);
    RETURN;
END;
$$;

-- Helper functions

-- Coherence field derivatives
CREATE OR REPLACE FUNCTION prisma.compute_finite_differences(
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
BEGIN
    SELECT coherence_field
    INTO current_coherence
    FROM prisma.manifold_points WHERE id = point_id;
    
    IF current_coherence IS NULL THEN
        RETURN QUERY SELECT 
            ARRAY(SELECT 0.0 FROM generate_series(1, dim)),
            ARRAY(SELECT 0.0 FROM generate_series(1, dim));
        RETURN;
    END IF;
    
    first_deriv := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    second_deriv := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    
    FOR i IN 1..dim LOOP
        first_deriv[i] := CASE 
            WHEN i < LEAST(dim, 2000) THEN 
                (current_coherence[i+1] - current_coherence[GREATEST(1, i-1)]) / (2.0 * h)
            ELSE 0.0
        END;
        
        second_deriv[i] := CASE 
            WHEN i > 1 AND i < LEAST(dim, 1999) THEN 
                (current_coherence[i+1] - 2.0 * current_coherence[i] + current_coherence[i-1]) / (h * h)
            ELSE 0.0
        END;
    END LOOP;
    
    RETURN QUERY SELECT first_deriv, second_deriv;
END;
$$; 