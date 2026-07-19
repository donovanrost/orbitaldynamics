# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention feedback-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact/command feedback aggregation, provider-result artifact
normalization, actual-throughput selection, and actual-data-rate throughput
derivation into
`OrbitalDynamics.Communications.ContactContention.FeedbackContext`. Preserve
the public ContactContention facade and private delegates used by contention
group/recommendation construction, approval-policy context copying, and
provider-contact evidence detection.

Selection evidence:
- Live re-ranking places `contact_contention.ex` at 2,805 lines, fifth behind
  Schema, Timeline, MissionPlan.Activity, and the intentionally public
  `OrbitalDynamics` facade, and ahead of LinkCapacity, StationCalendar,
  OperationalReadiness, RecommendationRiskContext, TimelineFeedback, and
  ResourceProjection.
- The selected family spans the feedback builders at lines 1,207-1,247 and
  1,627-1,770 plus throughput derivation at lines 2,484-2,603. It owns
  boolean/factor/string feedback aggregation, metadata fallback, nested
  provider-result flattening, explicit throughput aliases, data-rate unit
  conversion, duration fallback, and derivation evidence.
- Four contention group/recommendation builders consume the feedback context;
  two approval-policy paths consume the feedback field allowlist; provider
  contact evidence consumes actual throughput. Private delegates keep those
  facade callers stable.
- Station-calendar context/capacity semantics, contention grouping, approval
  requirements, resolution-policy normalization and ordering, contact
  identity, public report clauses, and artifact contracts remain outside this
  boundary.
- Existing false-dominant boolean aggregation, minimum factor aggregation,
  mixed-source/result markers, provider-result traversal order, numeric
  coercion, explicit-throughput precedence, MB/s and Mbps conversion, duration
  fallback order, non-negative rate clamping, omission behavior, and exact
  errors must remain unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused ContactContention regression file and the adjacent
  communications tests selected from live references.
- Run exact old/new parity from this selection commit across rich feedback,
  nested provider results, metadata fallback, explicit and derived throughput,
  malformed values, empty inputs, deterministic report output, and invalid
  public input errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback downlink-demand feedback extraction, selected in `d8414e9e`,
implemented in `9b8c2d55`, and handed off in `b956c1a9`.
`timeline_feedback.ex` moved from 2,809 to 2,608 lines; the dedicated
downlink-demand feedback owner is 239 lines.

Next candidate:
Implement and verify the selected ContactContention feedback-context
extraction.

Blocked:
No.
