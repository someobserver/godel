-- PRISM: Pathology Recognition in Semantic Manifolds
-- Foundation: schema definitions and base tables
-- File: 00_foundation.sql
-- Updated: 2025-07-01
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Instantiates:
--   - Manifold point representation with semantic properties
--   - Recursive coupling tensors
--   - Wisdom field regulatory mechanisms

-- PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS prism;

-- Main tables

-- Semantic manifold points
CREATE TABLE prism.manifold_points (
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

-- Recursive coupling analysis
CREATE TABLE prism.recursive_coupling (
    id UUID PRIMARY KEY,
    point_p UUID NOT NULL REFERENCES prism.manifold_points(id),
    point_q UUID NOT NULL REFERENCES prism.manifold_points(id),
    
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

-- Wisdom field regulatory mechanisms
CREATE TABLE prism.wisdom_field (
    point_id UUID PRIMARY KEY REFERENCES prism.manifold_points(id),

    -- Regulation metrics
    wisdom_value FLOAT,
    forecast_sensitivity FLOAT,
    gradient_response FLOAT,

    -- humility operators
    humility_factor FLOAT,
    recursion_regulation FLOAT,
    
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Utility functions

-- Semantic Mass: M(p,t) = D(p,t) * ρ(p,t) * A(p,t)
CREATE OR REPLACE FUNCTION prism.compute_semantic_mass(
    recursive_depth FLOAT,
    metric_determinant FLOAT,
    attractor_stability FLOAT
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        recursive_depth * 
        (1.0 / GREATEST(metric_determinant, 1e-10)) *
        attractor_stability
$$;

-- Autopoietic Function: Φ(C) = α(C_mag - C_threshold)^β for C >= threshold
CREATE OR REPLACE FUNCTION prism.compute_autopoietic_potential(
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

-- Humility Operator: H[R] = |R|_F * exp(-k(|R|_F - R_optimal))
CREATE OR REPLACE FUNCTION prism.compute_humility_operator(
    coupling_magnitude FLOAT,
    optimal_recursion FLOAT DEFAULT 0.5,
    decay_constant FLOAT DEFAULT 2.0
) RETURNS FLOAT LANGUAGE SQL AS $$
    SELECT 
        coupling_magnitude * 
        EXP(-decay_constant * (coupling_magnitude - optimal_recursion))
$$; 