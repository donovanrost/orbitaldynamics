# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter station-state resolution extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract station overlap matching, direction/window filtering, severity and
ambiguity selection, capacity/availability evaluation, reservation/trust
context aggregation, and numeric evidence normalization into
`OrbitalDynamics.Communications.ContactFilter.StationState`.
Preserve all ContactFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_filter.ex` at 1,898 lines, the
  largest ordinary eligible facade.
- ContactFilter delegates contact normalization and provider-counteroffer
  context, while station-state resolution remains inline at lines 608-1,132.
- The selected block has one responsibility: resolve the applicable declared
  station state and its availability, capacity, reservation, trust, and
  ambiguity evidence for a contact window.
- Public filtering/report construction, invalid-input classification,
  suppressed-row projection, provider-contention handoff, approval policy, and
  all public contracts remain outside the boundary.
- Exact direction/window matching, severity/tie precedence, ambiguity IDs,
  capacity selection, reservation/trust aggregation, numeric normalization,
  omission behavior, public facade output, and error behavior must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity triage-summary extraction, selected in `efe6811d` and implemented
in `69e7cf13`.
`link_capacity.ex` moved from 1,904 to 1,414 lines; the dedicated Summary owner
is 536 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_filter.ex` is now the largest ordinary
eligible facade at 1,898 lines, followed by RecommendationRiskContext and
OrbitData.

Blocked:
No.
