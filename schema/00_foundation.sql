-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Foundation: base schema, entities, and primitive operators
-- File: schema/00_foundation.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Purpose
--   Define core entities and minimal math utilities used by geometric analysis and signatures.
-- Entities
--   - Manifold points: semantic/coherence fields and derived tensors
--   - Recursive coupling: pairwise coupling tensors and magnitudes
--   - Wisdom field: regulation metrics for damping/compensation

-- PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS godel;

-- Main tables

CREATE TABLE IF NOT EXISTS godel.manifold_points (
    id UUID PRIMARY KEY,
    conversation_id UUID,
    user_fingerprint TEXT,
    creation_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Semantic field vectors
    semantic_field VECTOR(2000),
    coherence_field VECTOR(2000),
    coherence_magnitude FLOAT,
    
    -- Geometric structures
    metric_tensor FLOAT[],
    metric_determinant FLOAT,
    
    -- Semantic mass components: M = D * ρ * A
    recursive_depth FLOAT,
    constraint_density FLOAT,
    attractor_stability FLOAT,
    semantic_mass FLOAT,
    
    -- Differential geometry
    christoffel_symbols FLOAT[],
    ricci_curvature FLOAT[],
    scalar_curvature FLOAT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS godel.recursive_coupling (
    id UUID PRIMARY KEY,
    point_p UUID NOT NULL REFERENCES godel.manifold_points(id),
    point_q UUID NOT NULL REFERENCES godel.manifold_points(id),
    
    -- Coupling tensors
    coupling_tensor FLOAT[],
    coupling_magnitude FLOAT,
    
    -- Coordination decomposition
    self_coupling FLOAT[],
    hetero_coupling FLOAT[],
    
    -- Temporal dynamics
    evolution_rate FLOAT,
    latent_channels FLOAT[],
    
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS godel.wisdom_field (
    point_id UUID PRIMARY KEY REFERENCES godel.manifold_points(id),

    -- Regulation metrics
    wisdom_value FLOAT,
    forecast_sensitivity FLOAT,
    gradient_response FLOAT,

    -- Humility operators
    humility_factor FLOAT,
    recursion_regulation FLOAT,
    
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Utility functions (math)
-- Scope: public primitives used across geometry and signatures.

-- Semantic Mass
--   Math: M = D · ρ · A with ρ = 1 / max(det g, 1e-10)
CREATE OR REPLACE FUNCTION godel.compute_semantic_mass(
-- Purpose: Compute semantic mass M from depth, metric determinant, and attractor stability.
-- Math: M = D · ρ · A with ρ = 1 / max(det g, 1e-10).
-- Returns: scalar (FLOAT).
    recursive_depth FLOAT,
    metric_determinant FLOAT,
    attractor_stability FLOAT
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        recursive_depth * 
        (1.0 / GREATEST(metric_determinant, 1e-10)) *
        attractor_stability
$$;

-- Autopoietic Potential
--   Math: Φ(C) = α · (C - C_thr)^β for C ≥ C_thr; else 0
CREATE OR REPLACE FUNCTION godel.compute_autopoietic_potential(
-- Purpose: Piecewise autopoietic activation above coherence threshold.
-- Math: Φ(C) = α (C − C_thr)^β for C ≥ C_thr; else 0.
-- Returns: scalar (FLOAT).
    coherence_magnitude FLOAT,
    coherence_threshold FLOAT DEFAULT 0.7,
    alpha FLOAT DEFAULT 1.0,
    beta FLOAT DEFAULT 2.0
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        CASE 
            WHEN coherence_magnitude >= coherence_threshold
            THEN alpha * POWER(coherence_magnitude - coherence_threshold, beta)
            ELSE 0.0
        END
$$;

-- Humility Operator
--   Math: H[R] = ||R||_F · exp(-k( ||R||_F - R_opt )) ; bounded exponent for stability
CREATE OR REPLACE FUNCTION godel.compute_humility_operator(
-- Purpose: Damping against excessive recursion based on coupling magnitude.
-- Math: H[R] = ||R||_F · exp(−k( ||R||_F − R_opt )). Exponent bounded for stability.
-- Returns: scalar (FLOAT).
    coupling_magnitude FLOAT,
    optimal_recursion FLOAT DEFAULT 0.5,
    decay_constant FLOAT DEFAULT 2.0
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        coupling_magnitude * 
        EXP(GREATEST(LEAST(-decay_constant * (coupling_magnitude - optimal_recursion), 50.0), -50.0))
$$; 

-- Vector helpers

-- Convert pgvector to real[] for elementwise operations when necessary
CREATE OR REPLACE FUNCTION godel.vector_to_real_array(v vector)
RETURNS FLOAT[] LANGUAGE SQL AS $$
    SELECT ARRAY(
        SELECT trim(x)::FLOAT
        FROM unnest(string_to_array(trim(both '[]' from v::TEXT), ',')) AS x
    );
$$;

-- Dimension/window configuration (conventions)
CREATE OR REPLACE FUNCTION godel.get_active_dimension()
RETURNS INTEGER LANGUAGE SQL AS $$
    SELECT 100
$$;

CREATE OR REPLACE FUNCTION godel.get_small_window()
RETURNS INTEGER LANGUAGE SQL AS $$
    SELECT 50
$$;

-- L2 norm of vector (sqrt of sum of squares)
CREATE OR REPLACE FUNCTION godel.vector_l2_norm(v vector)
RETURNS FLOAT LANGUAGE SQL AS $$
    WITH elems AS (
        SELECT trim(x)::FLOAT AS val
        FROM unnest(string_to_array(trim(both '[]' from v::TEXT), ',')) AS x
    )
    SELECT sqrt(sum(val * val)) FROM elems;
$$;