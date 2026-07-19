# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention contact/group identity extraction.

Status:
Completed and pushed.

Selected boundary:
Extract contact/spacecraft/stable-ID resolution, contact identity validation,
group station/spacecraft/stable-ID/direction projection, contact-ID failure
behavior, and canonical contact sorting into
`OrbitalDynamics.Communications.ContactContention.ContactIdentity`. Centralize
the advertised stable identity fields with that owner. Preserve all public
ContactContention report, resolution, and summary facades.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 2,370
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 2,185-2,334 and exclusively owns
  contact identity, group identity, direction, and canonical sort semantics.
- Contention grouping, resolution, validation, capacity-demand, and summary
  construction consume this shared identity layer through private facade
  delegates.
- Candidate eligibility, contact normalization, timing/feedback/station
  context, scoring, approval policy, public clauses, and artifact contracts
  remain outside this boundary.
- Existing spacecraft/satellite/scenario precedence, nested identity
  precedence, ID fallback order, atom/integer normalization, stable-pattern
  validation, `nil` rejection, exact error text, group deduplication/sorting,
  mixed/default direction behavior, numeric-zero sort fallback, full tuple
  order, and capability metadata must remain unchanged.

Implementation:
- Selection was recorded and pushed in `21c6ee41`.
- Implementation was committed and pushed in `4c827f4c`.
- `communications/contact_contention.ex` moved from 2,370 to 2,242 lines.
- `OrbitalDynamics.Communications.ContactContention.ContactIdentity` is a
  167-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,973 files.
- The focused ContactContention file and five adjacent campaign, strategy,
  replay, operator-review, and schema consumers passed together: 77 tests.
- Exact old/new public report/resolution parity passed for 8 cases covering
  station and spacecraft groups, nested spacecraft identities, atom/integer
  IDs, duplicates, invalid identities, scenario fallback, mixed/default
  directions, provider ordering, canonical sorting, and capability metadata.
- `mix xref callers` reports only the ContactContention facade.
- The removed identity/group/sort helpers and facade-owned stable identity
  attributes are absent apart from thin delegates, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention contact/group identity extraction, selected in `21c6ee41`
and implemented in `4c827f4c`.
`communications/contact_contention.ex` moved from 2,370 to 2,242 lines; the
dedicated contact-identity owner is 167 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
