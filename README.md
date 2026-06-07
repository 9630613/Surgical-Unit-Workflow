# Surgical Unit Workflow 
 Optimization and Simulation for Industrial Automation

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Simulink Model Design](#simulink-model-design)
  - [Entity Attributes](#entity-attributes)
  - [Servers](#servers)
  - [Instrumentation for Calculating Flow-time](#instrumentation-for-calculating-flow-time)
- [Scenario 1 — Emergency Setting](#scenario-1--emergency-setting)
  - [Problem Setup](#problem-setup)
  - [Baseline Simulation](#baseline-simulation-emergencym)
  - [Optimization Problem](#optimization-problem)
  - [Optimization Algorithm](#optimization-algorithm-emergency_optimizationm)
  - [Results](#results)
- [Scenario 2 — Hospital Setting](#scenario-2--hospital-setting)
  - [Problem Setup](#problem-setup-1)
  - [Random Arrival Baseline](#random-arrival-baseline-hospitalm)
  - [Optimized Scheduling](#optimized-scheduling)
  - [Results](#results-1)
- [File Structure](#file-structure)
- [How to Run](#how-to-run)
- [Key Concepts Demonstrated](#key-concepts-demonstrated)
- [Results Summary](#results-summary)

## Overview

This project models, simulates, and optimizes the patient flow of a surgical unit performing **appendectomies** and **tonsillectomies**. The system is implemented in **MATLAB/Simulink** using discrete-event simulation, with a focus on:

- Minimizing patient flow-time through the surgical pipeline
- Minimizing operational costs through room allocation optimization
- Comparing greedy heuristic scheduling against random ordering

Two distinct scenarios are studied: an **Emergency Scenario** with continuous stochastic patient arrivals, and a **Hospital Scenario** with a fixed batch of scheduled patients.

## System Architecture

The surgical unit is modeled as a three-stage sequential pipeline:

```
[Waiting Room] → [Stage 1: Anesthesia] → [Stage 2: Operation] → [Stage 3: Recovery]
     (∞ FIFO)           m1 rooms               m2 rooms              m3 rooms
```

**Blocking rules:**
- If Stage 3 (Recovery) is full, patients remain in Stage 2 (Operation)
- If Stage 2 (Operation) is full, patients remain in Stage 1 (Anesthesia)
- If Stage 1 (Anesthesia) is full, patients wait in an infinite-capacity FIFO queue

**Patient types and service time distributions (exponential):**

| Stage | Appendectomy (h) | Tonsillectomy (h)|
|---|---|---|
| Anesthesia | 1 | 0.5 |
| Operation | 2 | 2 |
| Recovery | 0.5 | 1.5 |

Service times are assigned as entity attributes at generation time using `exprnd(mean)`, so each patient carries their own timing profile through all stages.

## Simulink Model Design

### Entity Attributes
Each generated patient entity carries four attributes:
- `Type` — 1 for appendectomy, 2 for tonsillectomy
- `Stage1` — pre-sampled anesthesia service time
- `Stage2` — pre-sampled operation service time
- `Stage3` — pre-sampled recovery service time

### Servers
Three server blocks represent the three stages. Each server reads the entity's corresponding attribute to determine service duration. Server capacity is set to m1, m2, m3 respectively.

### Instrumentation for Calculating Flow-time
- `get_arrival()` — MATLAB function called at entity generation step; logs patient type and ID with timestamp
- `get_departure()` — MATLAB function called after Stage 3; logs departure time, enabling flow-time computation

<p align="center">
  <img width="600" height="300" alt="Screenshot 2026-06-06 170406" src="https://github.com/user-attachments/assets/bdab78a8-a03e-45e5-b751-791c6e27a804" />

  <br/>
  <em>Overview of simulated workflow </em>
</p>


## Scenario 1 — Emergency Setting

### Problem Setup
Patients arrive continuously via a **Poisson process**:
- Appendectomy: λ_A = 1 patient/hour
- Tonsillectomy: λ_T = 2 patients/hour

Simulation horizon: **1000 hours** (to reach steady-state behavior).

Two independent generators produce entities with their respective arrival rates using `exprnd(1/rate)`.

### Baseline Simulation (`emergency.m`)
Initial configuration: **m1 = m2 = m3 = 10 rooms**

The baseline run establishes the feasibility of a symmetric allocation and provides the reference flow-time distribution for both patient types.

### Optimization Problem

**Objective:** Minimize total room cost  
**Constraint:** Average system flow-time S ≤ 20 hours  
**Decision variables:** m1, m2, m3 (integer number of rooms per stage)

**Cost function:**

```
minimize  C(m1, m2, m3) = c1·m1 + c2·m2 + c3·m3
subject to  S(m1, m2, m3) ≤ 20 hours
```

### Optimization Algorithm (`emergency_optimization.m`)

A two-phase **greedy heuristic**:

**Phase 1 — Relaxed solution (equal rooms):**  
Starting with m=10, the simulation is run iteratively while reducing m equally across all stages. For each value of m, the system flowtime is calculated. The smallest value, m*, that still satisfies the condition S≤20 is identified as the critical symmetric point, which serves as the initial upper bound for Phase 2.

**Phase 2 — Asymmetric search with pruning:**  
Three nested loops explore combinations (m1, m2, m3) with maximum value m* + 1. Two pruning strategies are applied:
- **Cost pruning:** Skip configurations whose cost exceeds the current best
- **Feasibility pruning:** If reducing rooms in the current branch violates S ≤ 20, break early (further reduction will only worsen flow-time)

### Results

| Configuration | Cost | Avg Flow-Time |
|---|---|---|
| m1=10, m2=10, m3=10 (baseline) | — | 3.84 (hr) feasible |
| m1=5, m2=5, m3=5 (relaxed critical) | — |  100.52 (hr) boundary |
| **m1=4, m2=6, m3=6 (optimal)** | **352 k€** | **19.78 (hr)** |

The optimal solution allocates fewer rooms to anesthesia (the shortest stage) and more to operation and recovery, reflecting the asymmetric bottleneck structure of the system.
<p align="center">
  <img width="400" height="300" alt="image" src="https://github.com/user-attachments/assets/66fce50f-3ebe-4b90-8275-c7da09ab2ec1" />

  <br/>
  <em>Histogram of distribution of patient's number in each type based on flow-time in m=10 </em>
</p>

## Scenario 2 — Hospital Setting

### Problem Setup
A fixed batch of **N = 20 patients** (10 appendectomy + 10 tonsillectomy) is processed with **m1 = m2 = m3 = 1 room**. Service times are pre-sampled at t = 0.

**Objective:** Optimize the order in which patients are processed to minimize average flow-time.

### Random Arrival Baseline (`hospital.m`)

All 20 patients are generated simultaneously at t = 0 using a custom `dt = gen()` function:
- Returns `dt = 0` for the first 20 patients
- Returns `dt = Inf` thereafter (no further arrivals)

Since all patients arrive at t = 0, flow-time equals departure time. The random ordering provides the unoptimized baseline.

### Optimized Scheduling

A **batch generator / batch splitter** architecture is used:
1. All 20 entities accumulate in the batch generator
2. Their service times are passed to `get_servicetime()` for optimization
3. The optimized ordering is assigned back to entities via `optimise()` at the queue entry before Stage 1

**Scheduling algorithm:** Greedy sort by total service time (Stage1 + Stage2 + Stage3) in ascending order — patients with the shortest total processing time are served first. This heuristic approximates the Shortest Processing Time (SPT) rule, known to minimize average completion time in single-machine scheduling and adapted here to the three-stage pipeline.
<p align="center">
  <img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/2256e2cc-e3a7-4add-933c-14264fffcc6c" />

  <br/>
  <em>Overall view of optimised Hospital scenario simulation blocks</em>
</p>



### Results

| Scenario | Avg Flow-Time |
|---|---|
| Random ordering | 20.0847 (hr) baseline |
| **Greedy SPT ordering** | **11.9857 (hr)** |

The optimized schedule consistently reduces average flow-time by approximately 8 hours compared to random patient ordering.

<p align="center">
  <img width="300" height="250" alt="image" src="https://github.com/user-attachments/assets/517e67a7-ea1d-4723-8a61-fd3e2742ff54" /> <img width="300" height="250" alt="image" src="https://github.com/user-attachments/assets/b2c318f2-46ac-48ed-bf51-d0bc288576dc" />

  <br/>
  <em> Flow-Time Distribution of Random vs Optimized Scheduling </em>
</p>


## File Structure

```
├── emergency.m                            # Baseline simulation — emergency scenario
├── emergency_optimization.m               # Two-phase greedy optimization — emergency scenario
├── emergency_optimization.slx             # Smilation of emergency workflow
├── hospital.m                             # Baseline + optimized simulation — hospital scenario
├── hospital_scenario.slx                  # Simulation of hospital scenario workflow
└── hospital_scenario_optimisation.slx     # Simulation of optimised hospital scenario workflow                       
```

## How to Run

**Emergency Scenario (baseline):**
```matlab
run('emergency.m')
```

**Emergency Scenario (optimization):**
```matlab
run('emergency_optimization.m')
```

**Hospital Scenario:**
```matlab
% Open hospital.m and uncomment the desired section:
% - Section 1: Random arrival baseline
% - Section 2: Optimized arrival
run('hospital.m')
```

**Requirements:** MATLAB R2021b or later with the SimEvents toolbox (for discrete-event simulation blocks).


## Key Concepts Demonstrated

- **Discrete-event simulation** using MATLAB SimEvents
- **Queueing theory** — multi-server systems with blocking and finite capacity
- **Stochastic modeling** — Poisson arrivals, exponential service times
- **Combinatorial optimization** — cost minimization under flow-time constraints
- **Greedy heuristics** with pruning (feasibility-based and cost-based early termination)
- **Scheduling algorithms** — Shortest Processing Time (SPT) heuristic for batch scheduling
- **Performance analysis** — flow-time histograms, steady-state metrics


## Results Summary

| Scenario | Method | Key Result |
|---|---|---|
| Emergency | Greedy room optimization | Optimal: m1=4, m2=6, m3=6 — Cost: 352 k€, Flow-time: 19.78h |
| Hospital | SPT greedy scheduling | ~8 hour reduction in average flow-time vs. random ordering |
