# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent summary projection extraction.

Status:
Completed and pushed in `f9d3fd44`.

Selected boundary:
Extract contact-intent capacity-demand summary construction, direction/station
routing, required-capacity aggregation, row-derived counts, and deterministic
ID grouping into `OrbitalDynamics.Communications.ContactIntent.Summary`.
Preserve all ContactIntent and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_intent.ex` at 1,785 lines, the
  largest ordinary eligible facade.
- ContactIntent currently delegates only capacity evidence and provider-result
  interpretation, while summary construction remains inline at lines 277-537.
- The selected block has one responsibility: derive the compact summary and its
  capacity/direction/station routing solely from supplied intent rows.
- Activity normalization, intent construction, policy decisions, station
  calendar interpretation, identity validation, and all public contracts remain
  outside the boundary.
- Exact capacity-context precedence, direction aliases, totals, source counts,
  nested routing maps, ID sorting, empty-map omission, assumptions, public
  output, idempotent summary handling, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactIntent.Summary` as the owner of
  capacity-demand summary construction, direction/station routing,
  required-capacity aggregation, row-derived counts, and deterministic ID
  grouping.
- Wired the existing summary facade directly to the owner while preserving
  ContactIntent and root public APIs.
- Kept activity normalization, intent construction, policy decisions, station
  calendar interpretation, and identity validation in the facade and their
  existing owners.
- `contact_intent.ex` moved from 1,785 to 1,529 lines; the new owner is 285
  lines.

Verification:
- Strict focused baseline passed all 27 ContactIntent tests.
- Exact old/new public parity passed for four deterministic summary results:
  activity-to-summary routing, raw atom/alias rows, idempotent existing-summary
  input, and empty input.
- Post-extraction focused and adjacent ContactIntent, operator-review,
  replay-summary, required-capacity routing, and strategy source-report
  verification passed all 39 tests.
- Static checks confirm the summary aggregation/routing helper family left the
  facade; xref reports only ContactIntent as a runtime caller.
- Strict warning-clean forced compile passed for 4,010 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent summary projection extraction, selected in `d7dbf991` and
implemented in `f9d3fd44`.
`communications/contact_intent.ex` moved from 1,785 to 1,529 lines; the
dedicated Summary owner is 285 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `recommendation_risk_context.ex` is now the largest ordinary
eligible facade at 1,772 lines, followed by OperationalReadiness and
ContactAllocation.

Blocked:
No.
