-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Foundation: base schema, entities, and primitive operators
-- File: schema/00_foundation.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Purpose: Establish the godel schema, vector extension, core entities, and foundational math utilities.
-- Exposes:
--   - Define core entities: manifold points, recursive coupling, wisdom field
--   - Compute semantic mass, autopoietic potential, humility operator
--   - Provide vector utilities and dimension/window conventions
-- Conventions:
--   - Active dimension n=100 for geometric operators; storage uses VECTOR(2000)
--   - Flatten matrices/tensors in row-major order; treat metrics as symmetric
--   - Apply numerical regularization (eps ∈ [1e-12, 1e-6]) to guard near-singular cases

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS godel;

-- Define core entities

CREATE TABLE IF NOT EXISTS godel.manifold_points (
    id UUID PRIMARY KEY,
    conversation_id UUID,
    user_fingerprint TEXT,
    creation_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Define semantic/coherence vectors
    semantic_field VECTOR(2000),
    coherence_field VECTOR(2000),
    coherence_magnitude FLOAT,
    
    -- Store geometric structures
    metric_tensor FLOAT[],
    metric_determinant FLOAT,
    
    -- Compute semantic mass components: M = D · ρ · A
    recursive_depth FLOAT,
    constraint_density FLOAT,
    attractor_stability FLOAT,
    semantic_mass FLOAT,
    
    -- Store differential geometry tensors
    christoffel_symbols FLOAT[],
    ricci_curvature FLOAT[],
    scalar_curvature FLOAT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS godel.recursive_coupling (
    id UUID PRIMARY KEY,
    point_p UUID NOT NULL REFERENCES godel.manifold_points(id),
    point_q UUID NOT NULL REFERENCES godel.manifold_points(id),
    
    -- Store coupling tensors
    coupling_tensor FLOAT[],
    coupling_magnitude FLOAT,
    
    -- Decompose coordination mass
    self_coupling FLOAT[],
    hetero_coupling FLOAT[],
    
    -- Track temporal dynamics
    evolution_rate FLOAT,
    latent_channels FLOAT[],
    
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS godel.wisdom_field (
    point_id UUID PRIMARY KEY REFERENCES godel.manifold_points(id),

    -- Store regulation metrics
    wisdom_value FLOAT,
    forecast_sensitivity FLOAT,
    gradient_response FLOAT,

    -- Store humility operators
    humility_factor FLOAT,
    recursion_regulation FLOAT,
    
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Utility functions (math)
-- Scope: Public primitives used across geometry and signatures.

-- Summary: Compute semantic mass M from recursion depth, metric determinant, and attractor stability.
-- Inputs:
--   - recursive_depth FLOAT — recursion depth component D
--   - metric_determinant FLOAT — det g; ρ = 1 / max(det g, 1e-10)
--   - attractor_stability FLOAT — attractor stability A
-- Assumptions: Treat inputs as normalized scalars unless specified.
-- Numerical guards: Floor det g at 1e-10 to avoid division by zero.
-- Returns: FLOAT — semantic mass M = D · ρ · A ∈ [0, ∞).
CREATE OR REPLACE FUNCTION godel.compute_semantic_mass(
    recursive_depth FLOAT,
    metric_determinant FLOAT,
    attractor_stability FLOAT
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        recursive_depth * 
        (1.0 / GREATEST(metric_determinant, 1e-10)) *
        attractor_stability
$$;

-- Summary: Compute autopoietic activation above coherence threshold.
-- Inputs:
--   - coherence_magnitude FLOAT — ‖C‖
--   - coherence_threshold FLOAT — C_thr (default 0.7)
--   - alpha FLOAT — α (default 1.0)
--   - beta FLOAT — β (default 2.0)
-- Assumptions: Apply only when ‖C‖ ≥ C_thr; else return 0.
-- Numerical guards: None beyond piecewise definition.
-- Returns: FLOAT — Φ(C) = α (‖C‖ − C_thr)^β for ‖C‖ ≥ C_thr; else 0.
CREATE OR REPLACE FUNCTION godel.compute_autopoietic_potential(
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

-- Summary: Compute humility damping against excessive recursion from coupling magnitude.
-- Inputs:
--   - coupling_magnitude FLOAT — ‖R‖_F
--   - optimal_recursion FLOAT — R_opt (default 0.5)
--   - decay_constant FLOAT — k (default 2.0)
-- Assumptions: Exponential damping centered at optimal_recursion.
-- Numerical guards: Bound exponent to [-50, 50] for numerical stability.
-- Returns: FLOAT — H[R] = ‖R‖_F · exp(−k(‖R‖_F − R_opt)).
CREATE OR REPLACE FUNCTION godel.compute_humility_operator(
    coupling_magnitude FLOAT,
    optimal_recursion FLOAT DEFAULT 0.5,
    decay_constant FLOAT DEFAULT 2.0
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        coupling_magnitude * 
        EXP(GREATEST(LEAST(-decay_constant * (coupling_magnitude - optimal_recursion), 50.0), -50.0))
$$; 

-- Vector helpers

-- Summary: Convert `vector` to `FLOAT[]` for element-wise operations.
-- Inputs:
--   - v vector — pgvector input
-- Returns: FLOAT[] — array of components in row order.
CREATE OR REPLACE FUNCTION godel.vector_to_real_array(v vector)
RETURNS FLOAT[] LANGUAGE SQL AS $$
    SELECT ARRAY(
        SELECT trim(x)::FLOAT
        FROM unnest(string_to_array(trim(both '[]' from v::TEXT), ',')) AS x
    );
$$;

-- Dimension/window configuration (conventions)
-- Summary: Provide active dimension/window sizes for geometric operators.
CREATE OR REPLACE FUNCTION godel.get_active_dimension()
RETURNS INTEGER LANGUAGE SQL AS $$
    SELECT 100
$$;

CREATE OR REPLACE FUNCTION godel.get_small_window()
RETURNS INTEGER LANGUAGE SQL AS $$
    SELECT 50
$$;

-- Summary: Compute L2 norm of a pgvector as sqrt(sum of squares)).
-- Inputs:
--   - v vector — pgvector input
-- Returns: FLOAT — Euclidean norm ‖v‖_2.
CREATE OR REPLACE FUNCTION godel.vector_l2_norm(v vector)
RETURNS FLOAT LANGUAGE SQL AS $$
    WITH elems AS (
        SELECT trim(x)::FLOAT AS val
        FROM unnest(string_to_array(trim(both '[]' from v::TEXT), ',')) AS x
    )
    SELECT sqrt(sum(val * val)) FROM elems;
$$;