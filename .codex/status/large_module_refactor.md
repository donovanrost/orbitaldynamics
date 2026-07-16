# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh contact-intent direction-routing extraction.

Status:
Complete and published.

Result:
- Extracted contact-intent route shape, stable-ID/fraction maps, and
  aggregate-consistency validation into the new 179-line
  `CandidateRefreshContactIntentRoutingContracts` owner.
- Preserved `CandidateRefreshReportContracts.validate_contact_intent_direction_routing/5`
  as the public facade and delegated internal contact-intent context validation
  to the same owner.
- Moved shared single-field-map construction into `CollectionAggregation` so
  contact-intent and station-calendar validation do not duplicate it.
- Removed all stale routing helpers from the multi-family parent, reducing it
  from 1,646 to 1,464 lines without changing public signatures or errors.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused contact-intent routing/provenance/schema coverage passed 21/21.
- The full `test/orbital_dynamics/candidate_refresh` directory passed 755/755.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Parent/new-module xref, formatting, new-file whitespace, and `git diff --check`
  passed.
- The read-only reviewer found no issues, independently passed compile and 17
  focused tests, and verified errors, ordering, alias precedence, shared-helper
  behavior, public signatures, and narrow dependency shape against `HEAD`.

Verification gaps:
- Full repository suite not run.

Last commit:
Published implementation `e760af01`.

Next candidate:
- Candidate-refresh station-calendar routing extraction. The parent still owns
  a cohesive station-calendar stable-ID, direction-map, direction-route, and
  provider-contention cluster. Extract it behind the existing public
  `validate_station_calendar_context/4` flow with focused station-calendar
  routing replay tests.

Blocked:
No.
