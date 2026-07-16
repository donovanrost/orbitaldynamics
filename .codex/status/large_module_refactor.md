# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline lifecycle context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract both timeline activity-lifecycle and lifecycle-state source-report
validators, including their shared action/review routing checks, behind the
existing public context functions.

Why this slice:
The two adjacent lifecycle contexts share the same count-map and route shapes.
Their only remaining private routing helpers sit at the bottom of the 1,297-line
multi-family parent, so they form one cohesive owner boundary without callbacks.

Public facade to preserve:
All `CandidateRefreshReportContracts` public signatures, especially
`validate_timeline_activity_lifecycle_context/4` and
`validate_timeline_lifecycle_state_context/4`, including their list guards.

Likely extraction target:
`CandidateRefreshTimelineLifecycleContracts`, owning both context flows,
action/review routing, route validation, and optional stable-ID array maps.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_lifecycle_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline activity-lifecycle and lifecycle-state replay/candidate-source tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
Both public functions are thin delegates to one focused lifecycle owner, shared
routing helpers are not duplicated or stale, guards/order/errors are unchanged,
and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published station-calendar extraction `15005095`.

Blocked:
No.
