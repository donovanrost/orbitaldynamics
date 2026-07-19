# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter contact normalization extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract recursive key normalization, station/time/status/direction
canonicalization, contact/spacecraft/stable-ID resolution, and contact identity
validation into
`OrbitalDynamics.Communications.ContactFilter.ContactNormalization`.
Centralize provider direction aliases, advertised stable identity fields, and
stable-ID validation with that owner. Preserve all public ContactFilter filter,
report, and capability facades.

Selection evidence:
- Live re-ranking places `communications/contact_filter.ex` at 2,356 lines,
  the largest eligible facade behind Schema, Timeline, MissionPlan.Activity,
  and the root public facade.
- The selected normalization and identity family is concentrated at lines
  629-870, with shared direction, recursive key, and numeric helpers later in
  the facade.
- Filtering, invalid-row construction, station matching, suppression rows, and
  provider contention evidence all consume this common canonical contact layer
  through private helpers.
- Suppression decisions, station overlap/reservation/capacity semantics,
  provider counteroffer handling, approval policy, report summaries, public
  clauses, and artifact contracts remain outside this boundary.
- Existing recursive stringification, nested station and spacecraft
  precedence, time parsing, status/alias canonicalization, contact-ID fallback
  order, stable-pattern validation, `nil` rejection, invalid-shape rendering,
  exact error reasons, and capability metadata must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention contact/group identity extraction, selected in `21c6ee41`
and implemented in `4c827f4c`.
`communications/contact_contention.ex` moved from 2,370 to 2,242 lines; the
dedicated contact-identity owner is 167 lines.

Next candidate:
Implement and verify the selected ContactFilter contact-normalization boundary.

Blocked:
No.
