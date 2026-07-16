# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: model-capability validation ownership cleanup.

Status:
Completed and published.

Selected slice:
Give canonical validation-level names a policy support owner and let model
capability validation call primitive/stable-ID/policy support directly.

Why this slice:
All nine callbacks already map to support responsibilities; facade delegates
preserve three unrelated validation-level consumers.

Current coupling/problem:
Resolved. Policy support owns level names, capability validation calls all
support dependencies directly, and the facade only delegates inputs/levels.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Environment/provider/subsystem validation order, validation levels, paths,
  and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_policy_contracts.ex`
- `lib/orbital_dynamics/schema/model_capability_contracts.ex`

Definition of done:
Level names are policy-owned, model capability callbacks/wrappers are gone,
focused/broad tests and fingerprint pass, and xref shows support dependencies.

Behavior/schema changes:
None. Validation order, canonical levels, paths, messages, and deterministic
schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 25 registry, validation-policy, JSON-schema, and export tests passed.
- Two exact curated environment/subsystem capability fixture tests passed; 179
  unrelated validation tests were excluded by line selectors.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows direct primitive, stable-ID, and validation-policy support edges.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the 27-test capability/policy/export boundary and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`2983e8d1` (`Collapse model capability callbacks`).

Next candidate:
Reassess validation-record/reference policy support; keep mixed activity-context
ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,484 lines after this slice (down from 14,507).
- `ModelCapabilityContracts` is 228 lines and callback-free.
- Validation-level facade delegation remains for record, reference, and policy
  callback consumers.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
