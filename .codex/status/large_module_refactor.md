# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation-handoff generic callback ownership phase.

Status:
Complete; ready to publish.

Result:
- Removed 11 generic primitive and stable-ID entries from the 13-entry handoff
  callback bag; only duplicate-evidence and override-count domain checks remain.
- Renamed the remaining two-entry bag to describe its handoff-domain role.
- Kept optional stable-ID map and nested-map composites local with the same
  type-check-then-content-validation order.
- Preserved `validate_expiration_summary/4`, `validate_allocation_fields/4`, and
  the public `OrbitalDynamics.Schema` facade.
- Reduced `schema.ex` from 12,768 to 12,757 lines and the handoff contracts
  module from 1,081 to 936 lines.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Candidate-refresh handoff, shared contact-allocation contract, and default
  equality-message coverage passed 18/18.
- Full contact-allocation coverage passed 69/70; the only failure was the
  previously reproduced line-1247 overlap-count baseline.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue, and `git diff --check` passed.
- The read-only reviewer found no issues, independently passed compile and 3
  focused handoff tests, and confirmed the 13-to-2 AST callback count.

Verification gaps:
- Full repository suite not run.
- `test/orbital_dynamics/communications/contact_allocation_test.exs:1247`
  still expects `must equal 2` but receives a nil message; this is unrelated
  baseline debt reproduced before these phases.

Last commit:
Pending publication; prior summary-phase handoff `9d431644`.

Next candidate:
- Operator-review-row generic callback ownership phase. Its 1,189-line contract
  module is now the next large schema family below the already-audited contact
  allocation reports. Map its broad schema callback bag and remove only generic
  entries with established direct owners while preserving review-domain calls.

Blocked:
No.
