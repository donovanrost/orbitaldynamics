# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter summary extraction.

Status:
Completed and pushed in `4af22e46`.

Selected boundary:
Extract `resource_filter_summary.v1` construction, report-row normalization,
review/routing counts, stable ID grouping, and duplicate-row summary evidence
into `OrbitalDynamics.ResourceFilter.Summary`. Preserve all ResourceFilter and
root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_filter.ex` at 2,059 lines,
  the largest ordinary eligible facade.
- The summary builder remains in the facade at lines 418-483 and consumes only
  an existing report plus facade-owned contract/model-limit values.
- Count, routing, stable-ID, and duplicate summary helpers form a cohesive
  output-aggregation family near lines 1,331-1,376; shared report helpers will
  remain facade-owned where still required.
- Candidate/resource-summary normalization, lookup ambiguity, suppression and
  margin policy, approval requirements, report construction, station context,
  provenance, and provider-result handling remain outside the boundary.
- Exact string/atom report parity, pass-through summary behavior, deterministic
  ID ordering, sparse omission, review status, invalid-input evidence,
  duplicate collision counts, routing maps, source defaults, and public
  exception behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.ResourceFilter.Summary` as the owner of
  `resource_filter_summary.v1` construction, report-row normalization,
  deterministic counts and routing maps, invalid-input evidence, and duplicate
  collision aggregation.
- Preserved all ResourceFilter and root public APIs; the facade passes its
  existing summary contract, source artifact contract, and model limits to the
  new owner.
- Removed the summary builder and summary-only count/routing helpers from the
  facade while retaining shared report aggregators.
- `resource_filter.ex` moved from 2,059 to 1,964 lines; the new owner is 161
  lines.

Verification:
- Strict focused baseline passed all 37 ResourceFilter tests.
- Exact old/new public parity passed for six captured cases: complex routing
  and duplicate evidence, atom normalization, empty reports, ignored options,
  and string- and atom-keyed pass-through summaries.
- Focused and adjacent verification passed 50 tests across ResourceFilter,
  operator-review handoff, and candidate-refresh construction.
- Static checks confirm the builder and summary-only helpers left the facade;
  xref reports only ResourceFilter as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,990 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter summary extraction, selected in `c2ec6ed6` and implemented in
`4af22e46`.
`resource_filter.ex` moved from 2,059 to 1,964 lines; the dedicated summary
owner is 161 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_intent.ex` is now the largest ordinary
eligible facade at 2,038 lines.

Blocked:
No.
