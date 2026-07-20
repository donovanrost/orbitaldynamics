# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext relay-data-path extraction.

Status:
Completed and pushed in `574e2a13`.

Selected boundary:
Extract relay-data-path context key ownership, risk selection, normalization,
and context projection into
`OrbitalDynamics.RecommendationRiskContext.RelayDataPath`.
Preserve all RecommendationRiskContext and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,772 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates fourteen focused risk families,
  while relay-data-path keys and projection remain inline at lines 265-298,
  1,077-1,159, and 1,702-1,706.
- The selected block has one responsibility: project relay route, custody,
  latency, routing-count, feedback, trust, and assumption evidence from matching
  risks.
- All other risk families, shared public facades, and downstream strategy
  assembly remain outside the boundary.
- Exact shallow key normalization, risk matching, key aliases, list flattening,
  uniqueness, empty omission, output keys, public output, and non-list behavior
  must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.RelayDataPath` as the owner
  of relay-data-path context keys, risk selection, shallow normalization, and
  route/custody/latency/feedback context projection.
- Wired the existing key and context facades directly to the owner while
  preserving RecommendationRiskContext and downstream public APIs.
- Kept every other risk family and downstream strategy assembly outside the
  boundary.
- `recommendation_risk_context.ex` moved from 1,772 to 1,650 lines; the new
  owner is 155 lines.

Verification:
- The focused pressure-events baseline and post-extraction test pass; its two
  pre-existing signed-zero pattern warnings still abort `--warnings-as-errors`
  after successful execution.
- Exact old/new public parity passed for five deterministic key/context results:
  advertised keys, dense mixed-key risks, one dense risk, empty risks, and
  non-list input.
- The adjacent warning-clean strategy-recommendation explanation suite passed
  all 3 tests under `--warnings-as-errors`.
- Static checks confirm relay key ownership, context projection, and risk
  selection left the facade; xref reports only RecommendationRiskContext as a
  runtime caller.
- Strict warning-clean forced compile passed for 4,011 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext relay-data-path extraction, selected in `189a5e6a`
and implemented in `574e2a13`.
`recommendation_risk_context.ex` moved from 1,772 to 1,650 lines; the dedicated
RelayDataPath owner is 155 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `operational_readiness.ex` is now the largest ordinary eligible
facade at 1,768 lines, followed by ContactAllocation and StationCalendar.

Blocked:
No.
