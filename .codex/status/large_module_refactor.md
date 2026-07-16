# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: Monte Carlo reproducibility callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Move Monte Carlo capability limits into the reproducibility contract module,
move generic duplicate-ID rejection into stable-ID support, and remove its
thirteen-callback facade bag.

Why this slice:
Runtime and JSON export already share the same Monte Carlo capability source;
all validation callbacks map to primitive/stable-ID support or simple local
list normalization.

Current coupling/problem:
Resolved. Capability limits are family-owned, duplicate rejection is stable-ID
support-owned, primitive/stable-ID validation is direct, list normalization is
local, and the facade only delegates artifacts.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/monte_carlo_reproducibility_contracts.ex`
- `lib/orbital_dynamics/schema/stable_id_validation.ex`

Definition of done:
Capability limits have one family-owned source, duplicate rejection is
support-owned, callback plumbing is gone, focused runtime/export tests and
fingerprint pass, and xref shows direct support/capability dependencies.

Behavior/schema changes:
None. Capability limits, generated IDs/counts, duplicate ordering, vectors,
paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed after removing one unused facade import.
- Five focused reproducibility, result-artifact, validation-fixture, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct Monte Carlo capability, primitive,
  and stable-ID dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused five-test reproducibility/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`6635d48d` (`Collapse Monte Carlo report callbacks`).

Next candidate:
Collapse optimizer-contract callback ownership after moving generic list-count
and map-field stable-ID validation into their existing support modules.

Blocked:
No.

Notes:
- `schema.ex` is 14,277 lines after this slice (down from 14,317).
- `MonteCarloReproducibilityContracts` is 116 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
