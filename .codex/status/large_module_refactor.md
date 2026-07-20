# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention resolution-summary projection extraction.

Status:
Completed and pushed in `104b9d4b`.

Selected boundary:
Extract the compact resolution-summary artifact projection into
`OrbitalDynamics.Communications.ContactContention.ResolutionSummary`.
Preserve all ContactContention and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 1,665 lines,
  the largest ordinary eligible facade.
- ContactContention already delegates eight focused responsibilities, while the
  resolution-summary artifact projection remains inline at lines 406-523.
- The selected block has one responsibility: derive compact routing counts,
  identity sets, grouped identities, and capacity-pack demand fields from a
  resolution report.
- Contention detection, contact annotation, resolution recommendation policy,
  approval requirements, capabilities, and all public contracts remain outside
  the boundary.
- Exact schema/model fields, counts, identity omission and sorting, grouped
  routing maps, capacity-demand fields, assumptions, idempotent inputs, public
  output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactContention.ResolutionSummary` as
  the owner of compact resolution routing counts, identity sets, grouped
  identities, capacity-pack demand fields, and summary assumptions.
- Wired the existing resolution-summary facade directly to the owner while
  preserving validation, idempotent summary inputs, atom-key normalization,
  overloads, and root APIs.
- Kept contention detection, annotation, recommendation policy, approval
  requirements, and capabilities outside the boundary.
- `contact_contention.ex` moved from 1,665 to 1,546 lines; the new owner is 126
  lines.

Verification:
- Strict focused baseline passed all 40 ContactContention tests.
- Exact old/new public parity passed for four deterministic summary results:
  rich grouped routing and capacity demand, atom-keyed resolution input,
  idempotent summary input, and an empty resolution report.
- Post-extraction focused and adjacent ContactContention, campaign-planner,
  candidate-refresh replay/capability, operator-review, schema/export, and
  validation verification passed all 72 tests.
- Static checks confirm the summary projection and its facade-private
  aggregation wrappers left the facade; xref reports only ContactContention as
  a runtime caller.
- Strict warning-clean forced compile passed for 4,016 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention resolution-summary projection extraction, selected in
`d750f18e` and implemented in `104b9d4b`.
`communications/contact_contention.ex` moved from 1,665 to 1,546 lines; the
dedicated ResolutionSummary owner is 126 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. RecommendationRiskContext is now the largest ordinary eligible
facade at 1,650 lines, followed by OperationalReadiness at 1,635 lines.

Blocked:
No.
