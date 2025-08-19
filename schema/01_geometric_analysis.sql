-- GODEL: Geometric Ontology Detecting Emergent Logics
-- Geometric Analysis: differential geometry and coupling primitives
-- File: schema/01_geometric_analysis.sql
-- Updated: 2025-08-19
--
-- Copyright 2025 Inside The Black Box LLC
-- Licensed under MIT License
-- 
-- SPDX-License-Identifier: MIT

-- Purpose: Provide geometric operators and linear algebra utilities over induced constraint geometry.
-- Exposes:
--   - Compute Christoffel symbols; compute covariant derivatives
--   - Compute metric tensor and inverse; compute Ricci and scalar curvature
--   - Integrate geodesic distances between points
--   - Compute recursive coupling tensor
-- Conventions:
--   - Active dimension n=100; vectors stored as VECTOR(2000) and truncated when computing
--   - Flatten all arrays in row‑major order; expand symmetric metrics to full n×n for inversion
--   - Apply determinant/diagonal regularization when near-singular

-- Geometric operators

-- Summary: Compute Christoffel symbols Γ^k_{ij} from metric and its derivatives.
-- Inputs:
--   - metric_components FLOAT[] — flattened symmetric g_ij (row‑major upper-triangular stored)
--   - metric_derivatives FLOAT[][] — ∂_i g_{jl} in flattened layout
--   - dimension INTEGER — active dimension n (default 100)
-- Assumptions: Flatten Γ index as (k-1)n^2 + (i-1)n + j; compute g^{-1} via compute_metric_inverse.
-- Numerical guards: Regularize inversion in compute_metric_inverse when |det g| < ε.
-- Returns: FLOAT[] — flattened Γ^k_{ij} (length n^3), row‑major.
-- Complexity: O(n^4).
CREATE OR REPLACE FUNCTION godel.compute_christoffel_symbols(
    metric_components FLOAT[],
    metric_derivatives FLOAT[][],
    dimension INTEGER DEFAULT 100
) RETURNS FLOAT[] LANGUAGE plpgsql AS $$
DECLARE
    christoffel FLOAT[];
    i INTEGER; j INTEGER; k INTEGER; l INTEGER;
    idx INTEGER := 1;
    g_inv FLOAT[][];
BEGIN
    christoffel := ARRAY(SELECT 0.0 FROM generate_series(1, dimension * dimension * dimension));
    
    g_inv := godel.compute_metric_inverse(metric_components, dimension);
    
    FOR k IN 1..dimension LOOP
        FOR i IN 1..dimension LOOP
            FOR j IN 1..dimension LOOP
                christoffel[idx] := 0.0;
                
                FOR l IN 1..dimension LOOP
                    christoffel[idx] := christoffel[idx] + 0.5 * g_inv[(k-1)*dimension + l] * (
                        metric_derivatives[i][j*dimension + l] + 
                        metric_derivatives[j][i*dimension + l] - 
                        metric_derivatives[l][i*dimension + j]
                    );
                END LOOP;
                
                idx := idx + 1;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RETURN christoffel;
END;
$$;

-- Summary: Evaluate a covariant derivative component for a vector-like field.
-- Inputs:
--   - field_components VECTOR(2000) — vector-like field V
--   - field_derivatives FLOAT[][] — partials ∂_i V_j
--   - christoffel_symbols FLOAT[] — flattened Γ^k_{ij}
--   - i_index INTEGER — i component
--   - j_index INTEGER — j component
--   - dimension INTEGER — active dimension n (default 100)
-- Assumptions: Truncate VECTOR(2000) to active dimension; use flattened Γ indexing.
-- Numerical guards: Guard array access by length; clip indices to [1, len].
-- Returns: FLOAT — (∇_i V)_j = ∂_i V_j − Γ^k_{ij} V_k.
CREATE OR REPLACE FUNCTION godel.covariant_derivative(
    field_components VECTOR(2000),
    field_derivatives FLOAT[][],
    christoffel_symbols FLOAT[],
    i_index INTEGER,
    j_index INTEGER,
    dimension INTEGER DEFAULT 100
) RETURNS FLOAT LANGUAGE plpgsql AS $$
DECLARE
    result FLOAT := 0.0;
    k INTEGER;
    gamma_idx INTEGER;
    arr_field FLOAT[];
BEGIN
    result := field_derivatives[i_index][j_index];
    arr_field := godel.vector_to_real_array(field_components);
    
    FOR k IN 1..dimension LOOP
        gamma_idx := (k-1) * dimension * dimension + (i_index-1) * dimension + j_index;
        result := result - christoffel_symbols[gamma_idx] * 
                  arr_field[LEAST(k, GREATEST(COALESCE(array_length(arr_field, 1), 0), 1))];
    END LOOP;
    
    RETURN result;
END;
$$;

-- Metric tensors

-- Summary: Construct a heuristic metric tensor from local field differences with diagonal regularization.
-- Inputs:
--   - semantic_field VECTOR(2000) — reference field (unused in current heuristic)
--   - neighboring_fields VECTOR(2000)[] — two neighbors to estimate gradients
--   - base_metric_scale FLOAT — diagonal regularization (default 1.0)
-- Assumptions: Use two neighbors; populate upper‑triangular entries; active dimension n=100.
-- Numerical guards: Add base_metric_scale to diagonal for stability.
-- Returns: FLOAT[] — flattened n×n with upper‑triangular populated; symmetric assumption used downstream.
-- Complexity: O(n^2) per gradient fill; inner products O(n^3) total.
CREATE OR REPLACE FUNCTION godel.compute_metric_tensor_from_semantic_field(
    semantic_field VECTOR(2000),
    neighboring_fields VECTOR(2000)[],
    base_metric_scale FLOAT DEFAULT 1.0
) RETURNS FLOAT[] LANGUAGE plpgsql AS $$
DECLARE
    n_dims INTEGER := 100;
    metric_components FLOAT[];
    i INTEGER;
    j INTEGER;
    idx INTEGER := 1;
    grad_i FLOAT[];
    grad_j FLOAT[];
    inner_product FLOAT;
    arr_nb1 FLOAT[];
    arr_nb2 FLOAT[];
    len_nb1 INTEGER;
    len_nb2 INTEGER;
BEGIN
    metric_components := ARRAY(SELECT 0.0 FROM generate_series(1, n_dims * n_dims));
    
    IF array_length(neighboring_fields, 1) >= 2 THEN
        arr_nb1 := godel.vector_to_real_array(neighboring_fields[1]);
        arr_nb2 := godel.vector_to_real_array(neighboring_fields[2]);
        len_nb1 := COALESCE(array_length(arr_nb1, 1), 0);
        len_nb2 := COALESCE(array_length(arr_nb2, 1), 0);
    END IF;

    FOR i IN 1..n_dims LOOP
        grad_i := ARRAY(SELECT 0.0 FROM generate_series(1, n_dims));
        
        IF arr_nb1 IS NOT NULL AND arr_nb2 IS NOT NULL THEN
            FOR k IN 1..n_dims LOOP
                grad_i[k] := 
                    (
                        COALESCE(arr_nb2[LEAST(k, GREATEST(len_nb2, 1))], 0.0) -
                        COALESCE(arr_nb1[LEAST(k, GREATEST(len_nb1, 1))], 0.0)
                    ) * 0.5;
            END LOOP;
        END IF;
        
        FOR j IN i..n_dims LOOP
            grad_j := ARRAY(SELECT 0.0 FROM generate_series(1, n_dims));
            
            IF arr_nb1 IS NOT NULL AND arr_nb2 IS NOT NULL THEN
                FOR k IN 1..n_dims LOOP
                    grad_j[k] := 
                        (
                            COALESCE(arr_nb2[LEAST(k, GREATEST(len_nb2, 1))], 0.0) -
                            COALESCE(arr_nb1[LEAST(k, GREATEST(len_nb1, 1))], 0.0)
                        ) * 0.5;
                END LOOP;
            END IF;
            
            inner_product := 0.0;
            FOR k IN 1..n_dims LOOP
                inner_product := inner_product + grad_i[k] * grad_j[k];
            END LOOP;
            
            idx := (i-1) * n_dims + j;
            metric_components[idx] := inner_product + 
                CASE WHEN i = j THEN base_metric_scale ELSE 0.0 END;
        END LOOP;
    END LOOP;
    
    RETURN metric_components;
END;
$$;

-- Summary: Invert a symmetric metric using Gauss–Jordan with determinant regularization.
-- Inputs:
--   - metric_components FLOAT[] — flattened upper‑triangular g_ij
--   - dimension INTEGER — active dimension n (default 100)
-- Assumptions: Expand symmetric components to full n×n before inversion.
-- Numerical guards: If |det g| < 1e-10, add 1e-6 to the diagonal before inversion.
-- Returns: FLOAT[] — flattened full inverse g^{ij} (length n^2).
-- Complexity: O(n^3).
CREATE OR REPLACE FUNCTION godel.compute_metric_inverse(
    metric_components FLOAT[],
    dimension INTEGER DEFAULT 100
) RETURNS FLOAT[] LANGUAGE plpgsql AS $$
DECLARE
    metric_matrix FLOAT[][];
    inverse_matrix FLOAT[][];
    inverse_components FLOAT[];
    det_g FLOAT;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    idx INTEGER;
    temp FLOAT;
    n INTEGER := dimension;
BEGIN
    metric_matrix := ARRAY(SELECT ARRAY(SELECT 0.0 FROM generate_series(1, n)) FROM generate_series(1, n));
    
    FOR i IN 1..n LOOP
        FOR j IN 1..n LOOP
            idx := (i-1) * n + j;
            IF i <= j THEN
                metric_matrix[i][j] := metric_components[idx];
                metric_matrix[j][i] := metric_components[idx];
            END IF;
        END LOOP;
    END LOOP;
    
    det_g := godel.matrix_determinant(metric_matrix, n);
    
    -- Regularization
    IF ABS(det_g) < 1e-10 THEN
        FOR i IN 1..n LOOP
            metric_matrix[i][i] := metric_matrix[i][i] + 1e-6;
        END LOOP;
    END IF;
    
    inverse_matrix := godel.matrix_inverse_gauss_jordan(metric_matrix, n);
    
    inverse_components := ARRAY(SELECT 0.0 FROM generate_series(1, n * n));
    idx := 1;
    FOR i IN 1..n LOOP
        FOR j IN 1..n LOOP
            inverse_components[idx] := inverse_matrix[i][j];
            idx := idx + 1;
        END LOOP;
    END LOOP;
    
    RETURN inverse_components;
END;
$$;

-- Linear algebra utilities

-- Summary: Compute determinant via LU-style elimination with partial pivoting.
-- Inputs:
--   - matrix FLOAT[][] — square matrix (n×n)
--   - n INTEGER — dimension
-- Numerical guards: Use partial pivoting; if |pivot| < 1e-12, return 0.0.
-- Returns: FLOAT — det(matrix).
-- Complexity: O(n^3).
CREATE OR REPLACE FUNCTION godel.matrix_determinant(
    matrix FLOAT[][],
    n INTEGER
) RETURNS FLOAT LANGUAGE plpgsql AS $$
DECLARE
    det FLOAT := 1.0;
    temp_matrix FLOAT[][];
    i INTEGER;
    j INTEGER;
    k INTEGER;
    pivot_row INTEGER;
    max_val FLOAT;
    temp FLOAT;
BEGIN
    temp_matrix := matrix;
    
    FOR k IN 1..n LOOP
        max_val := ABS(temp_matrix[k][k]);
        pivot_row := k;
        
        FOR i IN k+1..n LOOP
            IF ABS(temp_matrix[i][k]) > max_val THEN
                max_val := ABS(temp_matrix[i][k]);
                pivot_row := i;
            END IF;
        END LOOP;
        
        IF pivot_row != k THEN
            FOR j IN 1..n LOOP
                temp := temp_matrix[k][j];
                temp_matrix[k][j] := temp_matrix[pivot_row][j];
                temp_matrix[pivot_row][j] := temp;
            END LOOP;
            det := -det;
        END IF;
        
        IF ABS(temp_matrix[k][k]) < 1e-12 THEN
            RETURN 0.0;
        END IF;
        
        det := det * temp_matrix[k][k];
        
        FOR i IN k+1..n LOOP
            temp := temp_matrix[i][k] / temp_matrix[k][k];
            FOR j IN k..n LOOP
                temp_matrix[i][j] := temp_matrix[i][j] - temp * temp_matrix[k][j];
            END LOOP;
        END LOOP;
    END LOOP;
    
    RETURN det;
END;
$$;

-- Summary: Invert a matrix using Gauss–Jordan elimination on an augmented system.
-- Inputs:
--   - matrix FLOAT[][] — square matrix (n×n)
--   - n INTEGER — dimension
-- Numerical guards: Raise if |pivot| < 1e-12; normalize each pivot row.
-- Returns: FLOAT[][] — inverse matrix (n×n).
-- Complexity: O(n^3).
CREATE OR REPLACE FUNCTION godel.matrix_inverse_gauss_jordan(
    matrix FLOAT[][],
    n INTEGER
) RETURNS FLOAT[][] LANGUAGE plpgsql AS $$
DECLARE
    augmented FLOAT[][];
    i INTEGER;
    j INTEGER;
    k INTEGER;
    pivot FLOAT;
    temp FLOAT;
BEGIN
    augmented := ARRAY(SELECT ARRAY(SELECT 0.0 FROM generate_series(1, 2*n)) FROM generate_series(1, n));
    
    FOR i IN 1..n LOOP
        FOR j IN 1..n LOOP
            augmented[i][j] := matrix[i][j];
            augmented[i][j+n] := CASE WHEN i = j THEN 1.0 ELSE 0.0 END;
        END LOOP;
    END LOOP;
    
    FOR i IN 1..n LOOP
        pivot := augmented[i][i];
        IF ABS(pivot) < 1e-12 THEN
            RAISE EXCEPTION 'Matrix is singular';
        END IF;
        
        FOR j IN 1..2*n LOOP
            augmented[i][j] := augmented[i][j] / pivot;
        END LOOP;
        
        FOR k IN 1..n LOOP
            IF k != i THEN
                temp := augmented[k][i];
                FOR j IN 1..2*n LOOP
                    augmented[k][j] := augmented[k][j] - temp * augmented[i][j];
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;
    
    FOR i IN 1..n LOOP
        FOR j IN 1..n LOOP
            matrix[i][j] := augmented[i][j+n];
        END LOOP;
    END LOOP;
    
    RETURN matrix;
END;
$$;

-- Curvature calculations

-- Summary: Compute Ricci curvature components from Γ and ∂Γ contractions.
-- Inputs:
--   - christoffel_symbols FLOAT[] — flattened Γ^k_{ij} (length n^3)
--   - christoffel_derivatives FLOAT[][][] — ∂_k Γ^k_{ij} proxies (nullable)
--   - dimension INTEGER — active dimension n (default 100)
-- Assumptions: Use flattened indexing for Γ and its derivatives; dimension=n.
-- Numerical guards: Skip derivative terms when ∂Γ is NULL.
-- Returns: FLOAT[] — flattened Ricci components R_ij (length n^2).
-- Complexity: O(n^4).
CREATE OR REPLACE FUNCTION godel.compute_ricci_curvature(
    christoffel_symbols FLOAT[],
    christoffel_derivatives FLOAT[][][],
    dimension INTEGER DEFAULT 100
) RETURNS FLOAT[] LANGUAGE plpgsql AS $$
DECLARE
    ricci_components FLOAT[];
    i INTEGER;
    j INTEGER;
    k INTEGER;
    l INTEGER;
    idx INTEGER;
    n INTEGER := dimension;
    R_ij FLOAT;
    gamma_deriv_term FLOAT;
    gamma_product_term FLOAT;
BEGIN
    ricci_components := ARRAY(SELECT 0.0 FROM generate_series(1, n * n));
    
    FOR i IN 1..n LOOP
        FOR j IN 1..n LOOP
            R_ij := 0.0;
            
            FOR k IN 1..n LOOP
                IF christoffel_derivatives IS NOT NULL THEN
                    R_ij := R_ij + christoffel_derivatives[k][i][j];
                END IF;
                IF christoffel_derivatives IS NOT NULL THEN
                    R_ij := R_ij - christoffel_derivatives[j][i][k];
                END IF;
            END LOOP;
            
            FOR k IN 1..n LOOP
                FOR l IN 1..n LOOP
                    gamma_deriv_term := christoffel_symbols[(l-1)*n*n + (i-1)*n + j] * 
                                       christoffel_symbols[(k-1)*n*n + (k-1)*n + l];
                    gamma_product_term := christoffel_symbols[(l-1)*n*n + (i-1)*n + k] * 
                                         christoffel_symbols[(k-1)*n*n + (j-1)*n + l];
                    
                    R_ij := R_ij + gamma_deriv_term - gamma_product_term;
                END LOOP;
            END LOOP;
            
            idx := (i-1) * n + j;
            ricci_components[idx] := R_ij;
        END LOOP;
    END LOOP;
    
    RETURN ricci_components;
END;
$$;

-- Summary: Contract scalar curvature R = g^{ij} R_{ij} using flattened arrays.
-- Inputs:
--   - ricci_components FLOAT[] — flattened R_{ij}
--   - metric_inverse FLOAT[] — flattened g^{ij}
--   - dimension INTEGER — active dimension n (default 100)
-- Returns: FLOAT — scalar curvature R.
CREATE OR REPLACE FUNCTION godel.compute_scalar_curvature(
    ricci_components FLOAT[],
    metric_inverse FLOAT[],
    dimension INTEGER DEFAULT 100
) RETURNS FLOAT LANGUAGE SQL AS $$
    WITH curvature_calc AS (
        SELECT 
            sum(
                metric_inverse[(i-1)*dimension + j] * 
                ricci_components[(i-1)*dimension + j]
            ) as scalar_R
        FROM generate_series(1, dimension) as i,
             generate_series(1, dimension) as j
    )
    SELECT scalar_R FROM curvature_calc;
$$;

-- Geodesic integration

-- Summary: Integrate geodesic distance between two manifold points over a linearized trajectory.
-- Inputs:
--   - point_a UUID — start point id
--   - point_b UUID — end point id
--   - num_steps INTEGER — integration steps (default 100)
-- Assumptions: Linearly mix Γ and g along path; use active dimension n=100; fall back to Euclidean when tensors missing.
-- Numerical guards: Guard NULL tensors; take sqrt(|ds|) to ensure non-negativity.
-- Returns: FLOAT — approximate geodesic length.
CREATE OR REPLACE FUNCTION godel.integrate_geodesic_distance(
    point_a UUID,
    point_b UUID,
    num_steps INTEGER DEFAULT 100
) RETURNS FLOAT LANGUAGE plpgsql AS $$
DECLARE
    result FLOAT := 0.0;
    pa_coords VECTOR(2000);
    pb_coords VECTOR(2000);
    pa_metric FLOAT[];
    pb_metric FLOAT[];
    pa_christoffel FLOAT[];
    pb_christoffel FLOAT[];
    
    current_pos FLOAT[];
    current_vel FLOAT[];
    next_pos FLOAT[];
    next_vel FLOAT[];
    step_size FLOAT;
    i INTEGER; j INTEGER; k INTEGER; l INTEGER;
    dim INTEGER := 100;
    
    acceleration FLOAT[];
    christoffel_term FLOAT;
    gamma_idx INTEGER;
    ds FLOAT;
    arr_pa FLOAT[];
    arr_pb FLOAT[];
    len_pa INTEGER;
    len_pb INTEGER;
BEGIN
    SELECT semantic_field, metric_tensor, christoffel_symbols
    INTO pa_coords, pa_metric, pa_christoffel
    FROM godel.manifold_points 
    WHERE id = point_a;
    
    SELECT semantic_field, metric_tensor, christoffel_symbols
    INTO pb_coords, pb_metric, pb_christoffel
    FROM godel.manifold_points 
    WHERE id = point_b;
    
    IF pa_coords IS NULL OR pb_coords IS NULL THEN
        RETURN 0.0;
    END IF;
    
    current_pos := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    current_vel := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    acceleration := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    next_pos := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    next_vel := ARRAY(SELECT 0.0 FROM generate_series(1, dim));
    
    arr_pa := godel.vector_to_real_array(pa_coords);
    arr_pb := godel.vector_to_real_array(pb_coords);
    len_pa := GREATEST(COALESCE(array_length(arr_pa, 1), 0), 1);
    len_pb := GREATEST(COALESCE(array_length(arr_pb, 1), 0), 1);
    
    FOR i IN 1..dim LOOP
        current_pos[i] := arr_pa[LEAST(i, len_pa)];
        current_vel[i] := (arr_pb[LEAST(i, len_pb)] - arr_pa[LEAST(i, len_pa)]) / num_steps;
    END LOOP;
    
    step_size := 1.0 / num_steps;
    
    FOR step IN 1..num_steps LOOP
        FOR i IN 1..dim LOOP
            acceleration[i] := 0.0;
            
            FOR j IN 1..dim LOOP
                FOR k IN 1..dim LOOP
                    gamma_idx := (i-1)*dim*dim + (j-1)*dim + k;
                    
                    IF pa_christoffel IS NOT NULL AND pb_christoffel IS NOT NULL THEN
                        christoffel_term := 
                            pa_christoffel[gamma_idx] * (1.0 - step::FLOAT/num_steps) +
                            pb_christoffel[gamma_idx] * (step::FLOAT/num_steps);
                    ELSE
                        christoffel_term := 0.0;
                    END IF;
                    
                    acceleration[i] := acceleration[i] - 
                        christoffel_term * current_vel[j] * current_vel[k];
                END LOOP;
            END LOOP;
        END LOOP;
        
        FOR i IN 1..dim LOOP
            next_pos[i] := current_pos[i] + current_vel[i] * step_size + 
                          0.5 * acceleration[i] * step_size * step_size;
            next_vel[i] := current_vel[i] + acceleration[i] * step_size;
        END LOOP;
        
        ds := 0.0;
        FOR i IN 1..dim LOOP
            FOR j IN 1..dim LOOP
                IF pa_metric IS NOT NULL AND pb_metric IS NOT NULL THEN
                    ds := ds + 
                        ((pa_metric[(i-1)*dim + j] + pb_metric[(i-1)*dim + j]) / 2.0) *
                        (next_pos[i] - current_pos[i]) * (next_pos[j] - current_pos[j]);
                ELSE
                    IF i = j THEN
                        ds := ds + (next_pos[i] - current_pos[i]) * (next_pos[i] - current_pos[i]);
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
        
        result := result + sqrt(abs(ds));
        
        current_pos := next_pos;
        current_vel := next_vel;
    END LOOP;
    
    RETURN result;
END;
$$;

-- Coupling analysis

-- Summary: Compute a heuristic mixed-partial recursive coupling tensor over semantic/coherence fields.
-- Inputs:
--   - point_p UUID — source point id p
--   - point_q UUID — target point id q
--   - h FLOAT — finite difference step (unused placeholder; default 1e-6)
-- Assumptions: Map VECTOR(2000) to arrays; active dimension n=100; guard indices by array length.
-- Numerical guards: Clip array indexing to available lengths; avoid division by zero via +1 in denominator.
-- Returns: FLOAT[] — flattened R_ijk (length n^3).
-- Complexity: O(n^3).
CREATE OR REPLACE FUNCTION godel.compute_recursive_coupling_tensor(
    point_p UUID,
    point_q UUID,
    h FLOAT DEFAULT 1e-6
) RETURNS FLOAT[] LANGUAGE plpgsql AS $$
DECLARE
    semantic_p VECTOR(2000);
    semantic_q VECTOR(2000);
    coherence_p VECTOR(2000);
    coupling_tensor FLOAT[];
    
    dim INTEGER := 100;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    idx INTEGER := 1;
    mixed_partial FLOAT;
BEGIN
    SELECT semantic_field, coherence_field 
    INTO semantic_p, coherence_p
    FROM godel.manifold_points WHERE id = point_p;
    
    SELECT semantic_field
    INTO semantic_q
    FROM godel.manifold_points WHERE id = point_q;
    
    IF semantic_p IS NULL OR semantic_q IS NULL THEN
        RETURN ARRAY(SELECT 0.0 FROM generate_series(1, dim*dim*dim));
    END IF;
    
    coupling_tensor := ARRAY(SELECT 0.0 FROM generate_series(1, dim*dim*dim));
    
    -- Convert vectors to arrays once for elementwise access
    DECLARE
        arr_p FLOAT[] := godel.vector_to_real_array(semantic_p);
        arr_q FLOAT[] := godel.vector_to_real_array(semantic_q);
        arr_c FLOAT[] := godel.vector_to_real_array(coherence_p);
    BEGIN
        FOR i IN 1..dim LOOP
            FOR j IN 1..dim LOOP
                FOR k IN 1..dim LOOP
                    mixed_partial := 
                        (arr_p[LEAST(i, array_length(arr_p,1))] * 
                         arr_q[LEAST(j, array_length(arr_q,1))] * 
                         arr_c[LEAST(k, array_length(arr_c,1))]) /
                        (1.0 + abs(arr_p[LEAST(i, array_length(arr_p,1))]) + abs(arr_q[LEAST(j, array_length(arr_q,1))]));
                    
                    idx := (i-1)*dim*dim + (j-1)*dim + k;
                    coupling_tensor[idx] := mixed_partial;
                END LOOP;
            END LOOP;
        END LOOP;
    END;
    
    RETURN coupling_tensor;
END;
$$; 