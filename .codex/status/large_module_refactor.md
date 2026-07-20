# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity triage-summary extraction.

Status:
Completed and pushed in `69e7cf13`.

Selected boundary:
Extract link-capacity report row normalization, row-derived count/throughput
aggregation, station/contact/reservation routing, assumptions, and compact
summary construction into
`OrbitalDynamics.Communications.LinkCapacity.Summary`.
Preserve all LinkCapacity and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/link_capacity.ex` at 1,904 lines, the
  largest ordinary eligible facade.
- LinkCapacity already delegates nine focused responsibilities, while the
  compact triage-summary builder remains inline at lines 768-933 with its
  row-derived aggregation/routing helper family in the facade.
- The selected block has one responsibility: project an existing
  `link_capacity_report.v1` into its compact artifact-only summary.
- Link-capacity report construction, contact validation, throughput/downlink
  evidence resolution, approval policy, relay data paths, and all public
  contracts remain outside the boundary.
- Exact row normalization, fallback precedence, count/sum semantics, stable-ID
  sorting, station/contact/reservation routing, assumptions, omission behavior,
  public facade output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.LinkCapacity.Summary` as the owner of
  report-row normalization, row-derived count/throughput aggregation,
  station/contact/reservation routing, assumptions, and compact summary output.
- Preserved LinkCapacity and root public APIs as delegates and kept the
  facade's capability-derived model limits and assumptions authoritative.
- Removed the summary-specific aggregation/routing helper family from the
  facade while retaining generic row utilities still used by report building.
- `link_capacity.ex` moved from 1,904 to 1,414 lines; the new owner is 536
  lines.

Verification:
- Strict focused baseline passed all 44 LinkCapacity tests.
- Exact old/new public parity passed for four deterministic summaries: dense
  row-derived routing, atom-key normalization, fallback invalid-ID behavior,
  and an empty report.
- Post-extraction focused and adjacent schema verification passed all 52 tests.
- Static checks confirm the summary-specific aggregation helpers left the
  facade; xref reports only LinkCapacity as a runtime caller.
- Strict warning-clean forced compile passed for 4,002 files.
- Formatting and `git diff --check` passed.

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
