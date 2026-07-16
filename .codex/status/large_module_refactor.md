# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation-summary generic callback ownership phase.

Status:
Complete and published.

Result:
- Removed 20 generic primitive, stable-ID, and collection entries from the
  53-entry contact-allocation-summary callback bag.
- Renamed the remaining 33-entry bag to describe its capability and
  contact-allocation-report domain responsibility.
- The generic-only field-type helper no longer carries callback plumbing; the
  default equality-message composite remains local and unchanged.
- Preserved `ContactAllocationSummaryContracts.validate_summary/4` and the
  public `OrbitalDynamics.Schema` facade.
- Reduced `schema.ex` from 12,788 to 12,768 lines and the summary contracts
  module from 1,515 to 1,330 lines.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused summary, default-message, and curated validation coverage passed
  19/19.
- Full contact-allocation coverage passed 69/70; the only failure was the
  previously reproduced line-1247 overlap-count baseline.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue, and `git diff --check` passed.
- The read-only reviewer found no code issues, independently passed compile and
  17 focused tests, and confirmed the 53-to-33 AST callback count.

Verification gaps:
- Full repository suite not run.
- `test/orbital_dynamics/communications/contact_allocation_test.exs:1247`
  still expects `must equal 2` but receives a nil message; this is unrelated
  baseline debt reproduced before these phases.

Last commit:
Published implementation `c71bf58c`.

Next candidate:
- Contact-allocation-handoff generic callback ownership phase. Its 1,081-line
  module is now the next large contact-allocation contract file with generic
  validators routed through a schema callback bag. Map and remove only those
  already-owned generic entries while preserving its handoff-domain boundary.

Blocked:
No.
