# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter contact normalization extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `4a188222`.
- Implementation was committed and pushed in `2e6869b4`.
- `communications/contact_filter.ex` moved from 2,356 to 2,062 lines.
- `OrbitalDynamics.Communications.ContactFilter.ContactNormalization` is a
  340-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,974 files.
- The focused ContactFilter file and five adjacent candidate-refresh,
  campaign, operator-review, schema, and Cadence-import consumers passed
  together: 52 tests.
- Exact old/new public filter/report parity passed for 8 cases covering nested
  and atom identities, recursive key stringification, station and spacecraft
  precedence, activity/type and direction aliases, numeric times, nested
  station-calendar statuses, invalid shapes and IDs, reservation matching,
  policy options, report normalization, and capability metadata.
- `mix xref callers` reports only the ContactFilter facade.
- The removed normalization/identity helpers and facade-owned provider alias,
  stable-pattern, and stable-identity attributes are absent apart from thin
  delegates, formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter contact normalization extraction, selected in `4a188222` and
implemented in `2e6869b4`.
`communications/contact_filter.ex` moved from 2,356 to 2,062 lines; the
dedicated contact-normalization owner is 340 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
