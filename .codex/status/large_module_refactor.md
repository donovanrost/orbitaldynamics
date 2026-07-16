# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh-report generic callback ownership phase.

Status:
Complete and published.

Result:
- Removed 19 generic primitive, stable-ID, and collection entries from the
  23-entry candidate-refresh-report callback bag.
- Renamed the remaining four-entry bag to describe its three
  operational-readiness contexts plus safety-case field ownership.
- Moved nested non-negative number maps, non-negative number lists, and
  number-array maps unchanged into `PrimitiveValidation`; moved string-list maps
  unchanged into `CollectionValidation`.
- Removed generic-only callback parameters from internal report helpers while
  preserving all public `CandidateRefreshReportContracts` signatures and the
  public `OrbitalDynamics.Schema` facade.
- Reduced `schema.ex` from 12,736 to 12,673 lines and candidate-refresh-report
  contracts from 1,910 to 1,646 lines.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused provenance/readiness/communications/timeline/safety coverage passed
  29/29.
- The full `test/orbital_dynamics/candidate_refresh` directory passed 755/755.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue, and `git diff --check` passed.
- The read-only reviewer found no issues, independently passed compile and the
  comprehensive resource-provenance contract test, confirmed the 23-to-4 AST
  callback count, and verified moved-helper behavior and public signatures.

Verification gaps:
- Full repository suite not run.

Last commit:
Published implementation `293bcf4b`.

Next candidate:
- Candidate-refresh-report contact-intent direction-routing extraction. Its
  callback bag is now thin, and the cohesive routing/route-consistency cluster
  remains inside the 1,646-line module. Extract that cluster behind the existing
  public `validate_contact_intent_direction_routing/5` facade with the focused
  contact-intent routing replay tests.

Blocked:
No.
