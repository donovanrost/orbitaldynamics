# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: protection-decision callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic `expect_optional_field_equals/6` into primitive support, then let
`Schema.ProtectionDecisionContracts` own stable-ID, type, equality, and error
dependencies directly.

Why this slice:
The equality helper is the only callback not already support-owned; moving it
completes the decision and lifecycle-consistency responsibility boundary.

Current coupling/problem:
Resolved. Primitive support owns generic optional-field equality, protection
validation calls its support dependencies directly, and the facade delegates.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Protection decision/lifecycle consistency order and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`
- `lib/orbital_dynamics/schema/protection_decision_contracts.ex`

Definition of done:
The generic equality helper and decision dependencies are support-owned,
callback plumbing is gone, direct/broad tests and exact fingerprint pass, and
xref shows only primitive/stable-ID dependencies.

Behavior/schema changes:
None. Validation order, paths, messages, and deterministic schema output remain
unchanged.

Tests run:
- 127 selected schema, contract, resource, contact, export, and exact lifecycle
  protection regression tests passed; 126 unrelated timeline tests were
  excluded by the line selector.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers` and `mix xref graph` show the extracted contract depends
  only on primitive and stable-ID support.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the focused broad gate and deterministic fingerprint are
  the verification boundary for this slice.

Last commit:
`4a597cbc` (`Collapse protection decision callbacks`).

Next candidate:
Assess activity-context callback ownership after this cleanup.

Blocked:
No.

Notes:
- `schema.ex` is 14,601 lines after this slice (down from 14,619).
- `ProtectionDecisionContracts` is 166 lines and no longer resolves dynamic
  callbacks; generic optional-field equality now lives in primitive support.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
