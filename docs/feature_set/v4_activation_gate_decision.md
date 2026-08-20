# Architecture Decision: Gate V4 Activation on the Level 5 Exit Review

- Status: **accepted**
- Decision date: 2026-08-20
- Scope: Domain 16, Future V4+

## Context

Domain 16 has no missing Level 5 runtime behavior. Starting a V4 surface early
would displace closure and verification work in the other Level 5 domains.

## Decision

[V1 campaign planning](capability_map/12_v1_campaign_planning.md),
[V2 rolling repair](capability_map/13_v2_rolling_repair.md), and
[V3 strategy/orchestration](capability_map/14_v3_strategy_orchestration.md)
remain the supported public planner surfaces. No V4 implementation or V4 entry
point may enter the supported release line before a Level 5 exit review records
an activation decision that satisfies every criterion below. This is a review
and release gate; the repository does not currently enforce it at runtime.

## Activation criteria

The exit-review record must link versioned evidence for all of these conditions:

1. **Domain closure:** all 22 domains in the
   [Level 5 domain matrix](level5_domain_matrix.md) meet their exit criteria, or
   each exception records its rationale, risk, compensating controls, owner,
   expiry, and explicit adjudication.
2. **Integrated verification:** an authoritative, reproducible integrated
   verification report passes for the supported V1/V2/V3 and Level 5 workflow,
   with pinned inputs, environment, revisions, results, and approvers.
3. **Contract refresh:** schema exports and the capability catalog are refreshed
   together, are internally consistent, and pass their verification checks.
4. **Cadence conformance:** a consumer-owned Cadence conformance report accepts
   the supported planner artifacts and proves the agreed identity, authority,
   compatibility, and dry-run/idempotency behavior.
5. **Accountable ownership:** a named V4 delivery owner accepts scope, lifecycle,
   support, and retirement accountability.
6. **Operational truth:** the operational-model and truth-data authorities
   approve sources, revisions, coverage, tolerances, and update policy.
7. **Compatibility:** an approved migration and backward-compatibility plan
   covers V1/V2/V3 callers, artifacts, schemas, Cadence consumers, deprecation,
   rollback, and support windows.
8. **Resources:** the program/resource owner approves staffing, compute, data,
   verification, and operations budgets without removing resources needed for
   unresolved Level 5 closure.

Passing these criteria permits an activation decision; it does not require one.

## Required owners and evidence

Activation requires recorded approval from every role below. Each approval must
name the individual, date the decision, state approve/reject, and link evidence.
A rejection or conditional approval leaves V4 gated.

| Decision owner | Required evidence |
| --- | --- |
| OrbitalDynamics product/architecture owner | Exit-review decision, V4 scope, public-surface proposal, and compatibility/migration plan |
| Level 5 domain owners and named V4 delivery owner | 22-domain closeout or adjudicated exceptions; accepted V4 lifecycle ownership |
| Verification and operational-model/truth-data authorities | Authoritative integrated report and model/truth-data approval |
| Cadence consumer owner | Consumer-side conformance report |
| Mission operations/authority owner | Operational-use, authority, and support-model approval |
| Program/resource owner | Approved delivery and sustaining budget |

## Trigger and cadence

The product/architecture owner reviews this gate at each Level 5 wave closeout
and at least quarterly while Level 5 remains open. A formal exit review is
triggered when the evidence package claims readiness, or before any proposal
would add a V4 implementation, entry point, schema, capability advertisement,
or Cadence contract to the supported release line. Changes to the 22-domain
scope or required owners also trigger review of this decision.

## Consequences and deferral

- Level 5 closure and V1/V2/V3 compatibility take precedence over V4 delivery.
- V4 schedule, architecture, APIs, schemas, persistence, and migration execution
  remain deferred, as do persistent digital-twin integration, robust
  multi-future planning, simulation branch trees, calibrated operational
  models, broader orbital regimes, formation/deployment planning, and
  approval-bounded autonomy.
- Research may inform the exit review, but it creates no support or compatibility
  promise and may not be represented as V4 readiness.

## Emergency prototype exception

An emergency prototype may run only in an isolated branch/fork or disposable
research harness under non-V4 experimental naming. It must record a named owner,
sponsor, purpose, separate budget, expiry, and removal or promotion decision;
carry explicit non-production and unsupported markings; and expose no public
planner API/CLI, released schema or canonical artifact, capability claim, or
Cadence entry point. It may not enter the supported release line or operator
workflow unless the Level 5 exit review activates V4 under this decision.
