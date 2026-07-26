# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve plural V2 source provider-reservation-request summaries.

Status:
Implemented, reviewed, and verified; ready to publish.

Selection evidence:
- `RepairSourceReports.contact_allocation_provider_reservation_request_summary/2`
  accepts direct-source and canonical CandidateRefresh values, list-wraps them,
  and selects only the first map. Later valid provider request summaries are
  lost.
- CandidateRefresh already routes direct-source, canonical, and wrapped
  provider-reservation-request summaries as independent review evidence.
- Provider-reservation-request summaries preserve exact request/review rows,
  reservation IDs and match/status ownership, station/direction routes, and
  provider handoff context used by operator review and Cadence.
- Repair V2 already accepts only a singular source path. The three delivered
  specialized allocation slices established the compatible lossless pattern:
  ordered plural evidence, exact element-zero mirror, indexed adapters, and
  legacy singular fallback without double-counting.
- Canonical repair and all 27 strategy branch repairs contain neither the
  singular nor proposed plural provider-request source field, so canonical
  artifacts should remain byte-identical and only the Repair V2 schema/bundle
  should change.

Intended and delivered behavior:
- `source_contact_allocation_provider_reservation_request_summaries` retains
  every valid direct-source map before every valid canonical map, without
  deduplication or first-map loss.
- `source_contact_allocation_provider_reservation_request_summary` remains an
  exact element-zero compatibility mirror. Executable validation rejects mirror
  drift and a singular mirror paired with an empty plural collection.
- Operator-review aggregate folding and exact provider request/review rows
  prefer the non-empty plural collection and preserve exact array-index paths.
  Cadence retains the same index at `source_review_row.source`; neither adapter
  counts the mirror twice, and both fall back to the legacy singular path.
- Both fields remain absent when no valid source map exists. Reservations,
  schedules, scoring, approvals, provider writes, commanding, imports, and
  execution authority are unchanged.

Level 6 pillar advanced:
Fleet-scale provider-reservation auditability and versioned artifact
compatibility.

Delivered files:
- lossless repair provider-reservation-request source collection plus singular
  projection
- Repair V2 producer, registry, field type, executable validation, and schema
- plural-preferred operator-review aggregates/rows and Cadence routing with
  singular-only fallback
- shared station-pressure/reservation-conflict/capacity-pack/provider-request
  mirror validator without behavior drift
- focused producer, integration, adapter, schema, compatibility, and docs proofs
- regenerated Repair V2 schema and schema bundle

Verification:
- Focused provider-request producer, integration, schema, and prior mirror
  regression proofs: `33 passed`.
- Adjacent specialized allocation producer, operator-review, CandidateRefresh,
  and schema family: `82 passed`.
- Full Repair V2 source-contract family: `208 passed`.
- Contact-allocation gate: `262 passed`.
- Saved-artifact schema lint: `155 artifacts`, zero errors, warnings, or
  remediation items.
- Pre-export full suite: `5187/5188 passed` in `669.7s`; the sole failure was the
  expected checked-in schema parity mismatch for the new optional field.
- Schema/manifest exports and canonical repair/strategy reruns completed with
  passing artifact status. Canonical and manifest hashes remained byte-identical:
  - repair: `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`
  - strategy: `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`
  - manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
  - schema bundle: `c15b86a903e2a7b0503b76740fbf389f2a932d02b2db5a4304711c3518b05955`
- Schema export, manifest export, and golden artifact tests: `17 passed`.
- Final full suite: `5188 passed` in `690.7s`.

Review:
- Direct-source and canonical values are flattened independently in stable
  family order, map keys are normalized, and no content-based deduplication is
  performed. The singular resolver derives from the same ordered collection,
  preventing producer drift.
- Repair artifacts publish both the lossless plural collection and its exact
  first-element mirror. The executable contract accepts either field alone but
  rejects unequal or empty plural evidence when a singular mirror is present.
- The mirror validator was generalized only across the four delivered plural
  allocation families. Existing station-pressure, reservation-conflict, and
  capacity-pack contract proofs pass unchanged.
- A shared provider-reservation-request selector drives both row generation and
  aggregate folding. Three identical source maps produce three indexed pairs of
  request/review rows and six aggregate contributions, not eight; singular-only
  artifacts still produce their legacy unindexed paths.
- The new registry field is optional and exports as an array. Only
  `campaign_repair.v2.schema.json` and the bundle changed; the manifest schema,
  canonical repair, and all 27 strategy branch repairs remain byte-identical.
- The 19-file worktree contains only the compact ledger, three focused docs,
  producer/adapter/contract code, two schema exports, and three focused tests.

Last published slice:
- `b8c15389` Preserve plural V2 reservation-conflict summaries (`5181 passed`;
  every ordered source reservation-conflict map is retained and indexed without
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
Audit the generic allocation summary collection before reconsidering raw
refreshed-window retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
