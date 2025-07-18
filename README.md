# PRISM: Pathology Recognition In Semantic Manifolds

## Overview

PRISM detects pathological patterns, identifying 12 distinct signatures across four categorical domains. Using differential geometry, field theory, and autopoietic dynamics, PRISM can predict emergent coordination and escalation.

Dynamic systems fail in mathematically predictable ways. Individual cognition, cultural dynamics, and institutional behavior alike exhibit the same geometric signatures when adaptive capacity breaks down.

## Key Features

### Pathology Detection
- Detects 12 distinct patterns across 4 categories
- Scores severity in real-time (0.0-1.0 scale)
- Generates mathematical evidence for each detection
- Configures detection thresholds

### Coordination Analysis
- Analyzes geometric coupling for suspicious clusters
- Computes Recurgent Field Theory (RFT) confidence scores
- Measures semantic mass concentration
- Calculates cluster size and coherence

### Escalation Prediction
- Analyzes coherence field acceleration
- Computes semantic curvature trajectories
- Scores intervention urgency
- Simulates field evolution

### Operational Monitoring
- Generates real-time pathology alerts with severity classification
- Detects coordination with confidence levels
- Provides performance-optimized monitoring views

## Mathematical Framework

### Semantic Manifold Points
- Semantic field vectors `S(p,t) ∈ ℝ²⁰⁰⁰`
- Coherence field vectors `C(p,t) ∈ ℝ²⁰⁰⁰` 
- Metric tensor `g_{ij}(p,t)` derived from field gradients
- Semantic mass `M(p,t) = D(p,t) · ρ(p,t) · A(p,t)`

### Recursive Coupling Tensors
- Coupling magnitude `‖R_{ijk}(p,q,t)‖`
- Self-coupling and hetero-coupling decomposition
- Temporal evolution dynamics

### Regulatory Mechanisms
- Autopoietic function: `Φ(C) = α(C_{mag} - C_{threshold})^β` for `C ≥ threshold`
- Humility operator: `H[R] = ‖R‖_F · exp(-k(‖R‖_F - R_{optimal}))`
- Wisdom field modulation: `W(p,t)`

## Pathology Categories

### Rigidity Pathologies (Over-constraint)
- **Attractor Dogmatism**: `A(p,t) > A_{crit} ∧ ‖∇V(C)‖ ≫ Φ(C)`
- **Belief Calcification**: `\lim_{ε→0} dC/dt|_{C+ε} ≈ 0`
- **Metric Crystallization**: `∂g_{ij}/∂t → 0 \text{ while } R_{ij} ≠ 0`

### Fragmentation Pathologies (Under-constraint)
- **Attractor Splintering**: `dN_{attractors}/dt > κ · dΦ(C)/dt`
- **Coherence Dissolution**: `‖∇C‖ ≫ ‖C‖ ∧ d²C/dt² > 0`
- **Reference Decay**: `d‖R_{ijk}‖/dt < 0 \text{ without compensatory mechanism}`

### Inflation Pathologies (Runaway autopoiesis)
- **Delusional Expansion**: `Φ(C) ≫ V(C), H[R] ≈ 0, W(p,t) < W_{min}`
- **Semantic Hypercoherence**: `C(p,t) > C_{max}, ∮F_i·dS^i < F_{leakage}`
- **Recurgent Parasitism**: `d/dt∫_Ω M(p,t) dV > 0, d/dt∫_{M∖Ω} M(p,t) dV < 0`

### Observer-Coupling Pathologies (Interpretation breakdown)
- **Paranoid Interpretation**: `Ĉ_ψ(q,t) ≪ C(q,t), ∀q ∈ Q`
- **Observer Solipsism**: `‖I_ψ[C] - C‖ > τ‖C‖`
- **Semantic Narcissism**: `‖R_{ijk}(p,p,t)‖/∫‖R_{ijk}(p,q,t)‖dq → 1`

## Technical Architecture

### Database Schema
- Stores semantic field vectors with geometric properties
- Maintains inter-point relationship tensors
- Tracks regulatory mechanism values
- Provides specialized indices for vector similarity and temporal analysis

### Core Functions
- Implements 12 pathology detection functions (one per pathology)
- Provides 4 category detection functions (one per pathology class)
- Performs coordination detection via coupling analysis
- Executes escalation prediction via field evolution
- Enables comprehensive pathology scanning

### Performance Optimization
- Utilizes HNSW indices for semantic and coherence field vectors
- Maintains composite indices for temporal-semantic queries
- Indexes coupling magnitude and point relationships
- Configures severity thresholds for alert tuning

## Installation

### Requirements
- PostgreSQL with `vector` extension
- `pg_trgm` extension for text similarity

### Setup
```sql
\i install.sql
```

All seven schema components are then loaded in dependency order:
1. Foundation (core structures)
2. Geometric analysis (differential geometry)
3. Rigidity Pathologies
4. Fragmentation Pathologies  
5. Inflation Pathologies
6. Observer-coupling Pathologies
7. Operational monitoring

## Usage

### Primary Detection Interface
```sql
-- Comprehensive pathology scan
SELECT * FROM prism.detect_all_pathologies(point_id);

-- Category-specific detection
SELECT * FROM prism.detect_rigidity_pathologies(point_id);
SELECT * FROM prism.detect_fragmentation_pathologies(point_id);
SELECT * FROM prism.detect_inflation_pathologies(point_id);
SELECT * FROM prism.detect_observer_coupling_pathologies(point_id);
```

### Coordination Analysis
```sql
-- Detect suspicious coordination patterns
SELECT * FROM prism.detect_coordination_via_coupling(
    time_window => '24 hours',
    coupling_threshold => 0.8,
    min_cluster_size => 3
);
```

### Escalation Prediction
```sql
-- Predict escalation trajectories
SELECT * FROM prism.detect_escalation_via_field_evolution(conversation_points);
```

### Field Evolution Simulation
```sql
-- Simulate coherence field evolution
SELECT prism.evolve_coherence_field_complete(point_id, dt => 0.01);
```

### Monitoring Views
```sql
-- Real-time alerts
SELECT * FROM prism.coordination_alerts WHERE priority = 'HIGH';
SELECT * FROM prism.pathology_alerts WHERE severity > 0.6;
```

## Applications

- **Trust & Safety**: Coordination detection, escalation prediction, automated content moderation
- **Social Media**: Astroturfing detection, toxic conversation prevention, community health monitoring  
- **Research**: Discourse analysis, social dynamics, communication pattern studies
- **Enterprise**: Team communication health, organizational dynamics analysis

## License

MIT License - Copyright 2025 Inside The Black Box LLC 