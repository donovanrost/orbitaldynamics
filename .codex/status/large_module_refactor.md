# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter candidate-input extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract candidate shape coercion, provider/station direction contracts,
stable-identity validation, station-calendar ID-list normalization,
provider-contact inference, feedback-factor validation, and invalid-candidate
construction into `OrbitalDynamics.ResourceFilter.CandidateInput`. Preserve all
ResourceFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_filter.ex` at 1,964 lines, the largest
  ordinary eligible facade.
- ResourceFilter currently delegates only summary generation; candidate
  normalization and validation occupy lines 1,306-1,659, with their stable
  identity and station-calendar contracts still declared in the facade.
- The selected block has one responsibility: turn heterogeneous candidate
  inputs into valid normalized rows or deterministic reviewable invalid rows.
- Resource-summary normalization/ambiguity, suppression policy, approval
  routing, risk mapping, provenance counts, filter summaries, and all other
  capability contracts remain outside the boundary.
- Exact alias maps, stable-ID rules, station-calendar ID-list handling,
  direction/contact inference, time parsing, source-candidate preservation,
  report rows, summaries, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention station-calendar context extraction, selected in `5e23d9f3`
and implemented in `935abd1b`.
`communications/contact_contention.ex` moved from 1,978 to 1,665 lines; the
dedicated StationCalendarContext owner is 333 lines.

Next candidate:
Complete the selected ResourceFilter candidate-input extraction.

Blocked:
No.
