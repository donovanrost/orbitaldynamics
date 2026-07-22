# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Prefer canonical allocation rows over stale same-contract subsets.

Status:
Complete; ready to publish.

Selection evidence:
- The five summary contracts derive their subset collections from canonical
  `rows`, but CampaignPlanner currently unions base and subset rows.
- When `rows` is present, a stale same-contract `review_rows` or conflict/request
  subset can add a second contact decision not represented by canonical rows.
- Older partial planner fixtures omit `rows`, so subset-only compatibility must
  remain explicit rather than overriding a present canonical collection.

Implemented behavior:
- Treat present canonical `rows`, including an empty list, as authoritative.
- Use contract-owned subset rows only when the base field is absent.
- For provider-request scope, accept only subset rows that occur in canonical
  rows while retaining subset-only fallback for partial handoffs.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Files changed:
- contact-allocation compact-summary row precedence
- station-pressure and provider-request stale-subset challenge tests
- V3 strategy capability documentation and autonomous-loop ledger

Verification:
- Focused contact-allocation/provider-request tests: `12 passed`.
- Related allocation/station-pressure planner matrix: `23 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite with a 120-second per-test ceiling: `3794 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- No public artifact shape or checked-in schema export changed.

Review:
- A present canonical row collection always wins, including an intentional
  empty list; stale derived subsets cannot add planner decisions.
- Provider request/review subsets are intersected by exact canonical row value
  before scope metadata can create a provider-reservation branch.
- Subset-only compatibility remains for handoffs that omit `rows`, while direct,
  wrapped, and prior-plan paths converge on the same precedence rule.

Last published slice:
- `d41b3629` Constrain allocation pressure row families (`3792 passed`).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep aggregate station-pressure maps provenance-only.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After publish, audit the next planner-affecting compact handoff for exact source
identity or selected-candidate scope.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.
