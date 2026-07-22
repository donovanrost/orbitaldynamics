# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Correlate primary allocation outcome identities.

Status:
Verified; ready to publish.

Selection evidence:
- Compact allocated, returned, deferred, blocked, and policy-blocked count/ID
  pairs currently accept counts below unique identity cardinality.
- Existing replay deliberately preserves identity-only evidence when a scalar is
  absent or stale, so identities must not be discarded or force equality.
- Raw occurrence counts can validly exceed de-duplicated contact-ID lists.

Intended behavior:
- Canonicalize the five primary outcome ID lists as sorted unique stable IDs.
- Preserve identity-only evidence and count-only evidence independently.
- Retain an occurrence count alongside IDs only when it is at least the unique
  ID cardinality; compact schema validation rejects stale count/list pairs.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Planned files:
- primary allocation outcome count/ID correlation across raw/flattened/replay
- stale-count and noncanonical-ID compact schema/replay challenges
- allocation artifact documentation and autonomous-loop ledger

Verification:
- Focused replay/schema challenges: `14 passed`.
- Contact-allocation family: `184 passed`.
- Golden artifacts: `12 passed`.
- Schema lint: `155` artifacts, no errors or warnings.
- Full suite: `3814 passed`.
- `mix format` and `git diff --check` passed.

Review:
- Raw, flattened, and replay boundaries share canonical sorted unique stable
  identity normalization for the five selected outcome pairs.
- Identity-only and count-only pressure remain usable; only a supplied scalar
  below canonical ID cardinality is removed, while larger occurrence counts
  preserve duplicate-event evidence.
- Compact schema rejects undersized scalars and noncanonical identity lists.
- Station routing, blocked-input identities, and execution boundaries are
  unchanged and remain separately scoped.

Last published slice:
- `d4c1f7ad` Correlate allocation row pressure counts (`3812 passed`).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep aggregate station-pressure maps provenance-only.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After publish, audit blocked-input allocation identity correlation.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.
