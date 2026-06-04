# Maneuver Review Report

`OrbitalDynamics.maneuver_review_report/2` builds
`maneuver_review_report.v1` rows from `maneuver_recommendation.v1` entries.
Rows carry maneuver IDs, scenario IDs, epoch, frame, delta-v vector and
magnitude, approval status, required operator action, source recommendation,
declared/missing execution-uncertainty metadata, optional maneuver-success
confidence factors, and the no-command-execution boundary. Executable
validation checks report-level `model_limits` against
`OrbitalDynamics.ManeuverReview.capabilities/0`, so standalone maneuver review
tables cannot drift from the no-command-execution/no-schedule-mutation
boundary while still passing schema lint. Report-level maneuver, review-required,
invalid-recommendation, and declared/missing uncertainty counts are now checked
against emitted rows, and invalid recommendation ID lists plus approval/action
count maps are validated from the same maneuver-review evidence. When a source
recommendation supplies execution uncertainty, review
rows preserve it and derive `timing_3sigma_s`, `delta_v_3sigma_km_s`, and
`delta_v_3sigma_magnitude_km_s` fields for review policy context; this remains
review metadata, not a command-execution or finite-burn model. Reports also
derive max timing, max delta-v, and total declared delta-v 3-sigma envelopes
from declared row uncertainty so operators can inspect review risk without
implying propagated maneuver dispersion. The preserved raw
map uses the same typed execution-uncertainty schema shape as operational
timeline rows. Maneuver success confidence and source labels are also copied
into approval-policy context so factor-threshold action rules can classify
standalone maneuver review rows; review-row `maneuver_success_factor` values
use the same unit-interval confidence contract as policy decision evidence.
Maneuver-review ingress accepts clean numeric strings for maneuver epoch,
delta-v vector/magnitude, maneuver-success confidence, and execution-uncertainty
timing/vector fields before policy classification and schema validation.
Malformed numeric maneuver metadata stays on the invalid recommendation review
path with the raw source evidence preserved.
Supplying an
`approval_policy` classifies each maneuver-review row with approval
requirements, approval-rule matches, and embedded `policy_decision.v1` evidence;
`maneuver_authority_v1` is the built-in artifact-only bundle for maneuver timing
and impulsive-burn authority review.
Cadence import manifests preserve maneuver rows as typed `review_maneuver`
adapter gates with delta-v vector/magnitude, timing, frame, maneuver-success
confidence, source recommendation, source maneuver-review row, policy evidence,
and matched policy-escalation level, queue, role, authority, and SLA metadata
for downstream review tooling. Study result artifacts with maneuver recommendations include
the same report for downstream review tooling.
Standalone `maneuver_recommendation.v1` rows can also be normalized directly
through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`, producing the same
`maneuver_review` / `review_maneuver` handoff rows without requiring a wrapper
`maneuver_review_report.v1`. When a result artifact carries both
`maneuver_recommendations` and an embedded `maneuver_review_report.v1`,
the embedded review rows are treated as authoritative and duplicate
recommendation-derived rows are suppressed, avoiding duplicate Cadence review
or import queue entries for the same burn. V3 strategy replay applies the same
result-artifact unwrapping and duplicate suppression before deriving
branch-local maneuver success or execution-uncertainty feedback, so a
result-set artifact can be used directly as prior evidence without pre-extracting
its maneuver review report.
Malformed recommendation rows inside a maneuver-review input list are preserved
as `review_invalid_maneuver_recommendation` rows with invalid-reason evidence
instead of aborting report generation; malformed optional execution-uncertainty
or maneuver-success confidence metadata is treated the same way, so raw provider
values remain in `source_recommendation` without leaking invalid typed fields
into review/import rows. When an approval policy is supplied, invalid
recommendation rows carry the same approval requirements, rule matches, and
`policy_decision.v1` evidence as valid maneuver-review rows.
The exported maneuver recommendation and review schemas type `delta_v_km_s` as
three-number vectors. The standalone `maneuver_recommendation_v1.json` fixture
keeps the source recommendation contract lintable before it is lifted into a
maneuver-review report, including row-level `validation_level` and
`model_limits` checked against
`ManeuverReview.recommendation_model_limits/0`.
Executable validation treats maneuver-review counts and row ranks as integer
queue/cardinality values while leaving epoch, delta-v, and uncertainty fields
numeric.
