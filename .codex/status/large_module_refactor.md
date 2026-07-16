# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation-policy callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Let validation tolerance and backend acceptance policy validation call primitive
support directly, and remove the facade callback bag and level-name round trip.

Why this slice:
All six callbacks map to existing primitive support or back to the same policy
contract module; focused policy fixtures cover both valid and invalid paths.

Current coupling/problem:
Resolved. The policy contract module calls primitive support directly and owns
its level-name comparison; the facade delegates artifacts without callbacks.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_policy_contracts.ex`

Definition of done:
Policy callback plumbing and the facade level-name helper are gone, policy and
export tests pass, the fingerprint is unchanged, and xref shows direct support.

Behavior/schema changes:
None. Policy fields, tier/reference checks, validation levels, paths, messages,
and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Four validation-policy fixture and schema-export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct primitive support edge.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused four-test policy/export gate and deterministic
  fingerprint are the verification boundary for this slice.

Last commit:
`391f33db` (`Collapse validation policy callbacks`).

Next candidate:
Audit constraint-report callback ownership; model metadata remains facade-local
and must be assigned deliberately before removing its primitive callback bag.

Blocked:
No.

Notes:
- `schema.ex` is 14,423 lines after this slice (down from 14,437).
- `ValidationPolicyContracts` is 240 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
