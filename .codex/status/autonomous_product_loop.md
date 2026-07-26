# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve plural V2 source reservation-conflict summaries.

Status:
Implemented, reviewed, and verified; ready to publish.

Selection evidence:
- `RepairSourceReports.contact_allocation_reservation_conflict_summary/2`
  accepts direct-source and canonical CandidateRefresh values, list-wraps them,
  and selects only the first map. Later valid conflict summaries are lost.
- CandidateRefresh already routes direct-source, canonical, and wrapped
  reservation-conflict summaries as independent review evidence.
- Reservation-conflict summaries preserve exact overlap/review contacts plus
  reservation IDs, match/status/owner/expiration, direction, station, and
  direction/station routes used by operator review and Cadence.
- Repair V2 already accepts only a singular source path. Capacity-pack and
  station-pressure slices established the compatible lossless pattern: ordered
  plural evidence, exact element-zero mirror, indexed adapters, and legacy
  singular fallback without double-counting.
- Canonical repair and all 27 strategy branch repairs contain neither the
  singular nor proposed plural reservation-conflict source field, so canonical
  artifacts should remain byte-identical and only the Repair V2 schema/bundle
  should change.

Intended and delivered behavior:
- `source_contact_allocation_reservation_conflict_summaries` retains every
  valid direct-source map before every valid canonical map, without
  deduplication or first-map loss.
- `source_contact_allocation_reservation_conflict_summary` remains an exact
  element-zero compatibility mirror. Executable validation rejects mirror
  drift and a singular mirror paired with an empty plural collection.
- Operator-review aggregate folding and exact conflict/review rows prefer the
  non-empty plural collection and preserve exact array-index paths. Cadence
  retains the same index at `source_review_row.source`; neither adapter counts
  the mirror twice, and both fall back to the legacy singular path.
- Both fields remain absent when no valid source map exists. Reservations,
  schedules, scoring, approvals, provider writes, commanding, imports, and
  execution authority are unchanged.

Level 6 pillar advanced:
Fleet-scale reservation-conflict auditability and versioned artifact
compatibility.

Delivered files:
- lossless repair reservation-conflict source collection plus singular
  projection
- Repair V2 producer, registry, field type, executable validation, and schema
- plural-preferred operator-review aggregates/rows and Cadence routing with
  singular-only fallback
- shared station-pressure/reservation-conflict/capacity-pack mirror validator
  without behavior drift
- focused producer, integration, adapter, schema, compatibility, and docs proofs
- regenerated Repair V2 schema and schema bundle

Verification:
- Focused reservation-conflict producer, integration, schema, and prior mirror
  regression proofs: `33 passed`.
- Adjacent specialized allocation producer, operator-review, CandidateRefresh,
  and schema family: `75 passed`.
- Full Repair V2 source-contract family: `204 passed`.
- Contact-allocation gate: `256 passed`.
- Saved-artifact schema lint: `155 artifacts`, zero errors, warnings, or
  remediation items.
- Pre-export full suite: `5180/5181 passed` in `713.7s`; the sole failure was the
  expected checked-in schema parity mismatch for the new optional field.
- Schema/manifest exports and canonical repair/strategy reruns completed with
  passing artifact status. Canonical and manifest hashes remained byte-identical:
  - repair: `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`
  - strategy: `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`
  - manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
  - schema bundle: `cb40507bcc737d45b73e24e6e4b6d0d2a42445426ae7561077c791361ce55e9d`
- Schema export, manifest export, and golden artifact tests: `17 passed`.
- Final full suite: `5181 passed` in `685.6s`.

Review:
- Direct-source and canonical values are flattened independently in stable
  family order, map keys are normalized, and no content-based deduplication is
  performed. The singular resolver derives from the same ordered collection,
  preventing producer drift.
- Repair artifacts publish both the lossless plural collection and its exact
  first-element mirror. The executable contract accepts either field alone but
  rejects unequal or empty plural evidence when a singular mirror is present.
- The mirror validator was generalized only across the three delivered plural
  allocation families. Existing station-pressure and capacity-pack contract
  proofs pass unchanged.
- A shared reservation-conflict selector drives both row generation and
  aggregate folding. Three identical source maps produce three indexed
  review/Cadence families and three aggregate contributions, not four;
  singular-only artifacts still produce their legacy unindexed paths.
- The new registry field is optional and exports as an array. Only
  `campaign_repair.v2.schema.json` and the bundle changed; the manifest schema,
  canonical repair, and all 27 strategy branch repairs remain byte-identical.
- The 19-file worktree contains only the compact ledger, three focused docs,
  producer/adapter/contract code, two schema exports, and three focused tests.

Last published slice:
- `8353e8a8` Preserve plural V2 station-pressure summaries (`5174 passed`;
  every ordered source station-pressure map is retained and indexed without
  double-counting its exact singular compatibility mirror).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Bind additional candidate-specific projection values only when their exact
  greedy projected activity set can be reproduced without copying full reports.
- Preserve remaining source collections only with explicitly lossless plural
  V2 shapes rather than first-map coercion.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
Audit the adjacent provider-reservation-request or generic allocation summary
collection before reconsidering raw refreshed-window retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
