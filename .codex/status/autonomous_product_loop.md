# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 contact-intent pressure explanations to source evidence.

Status:
Complete; ready to publish.

Selection evidence:
- Current replacement-ranking validation constrains field types, known sorted
  statuses, arithmetic, and nonzero evidence presence, but does not prove that
  candidate statuses or penalties match `source_contact_intents`.
- Current V2 score validation pins numeric term totals and optional score-term
  report rows, but a contact-intent term can still disagree with exact selected
  source identities if the enclosing score is changed with it.
- The shared contact-intent identity classifier and selected-downlink logic
  already define deterministic expected evidence for both surfaces.

Intended behavior:
- Derive one candidate-ID to sorted pressure-status map from embedded validated
  source contact intents through the shared identity classifier.
- For current ranking rows, reconcile every emitted contact-intent penalty and
  status list to that exact map and the artifact's `risk_weight`.
- Require consistent current-field presence across a ranking once any row uses
  the new contact-intent explanation; continue accepting all-prechange rows.
- When the final contact-intent score term is present, reconcile it to unique
  pressured downlink IDs in the repaired activities and the same risk weight.
- Add exact mismatch, partial-current-row, zero-weight, final-term, and legacy
  compatibility tests; document the executable cross-field guarantee.

Level 6 pillar advanced:
Durable schema-versioned V2 explanations with executable source reconciliation.

Last published slice:
- `6b1396b3` Rank V2 replacements with contact intent pressure (`3709 passed`).

Likely files:
- V2 campaign-repair runtime contract modules
- replacement-ranking and repair contact-intent contract tests
- V2 capability and roadmap docs

Verification:
- Focused ranking, score, and source-handoff contracts: `16 passed`.
- Campaign-repair schema fixtures: `11 passed`.
- Repair-path suite: `72 passed`.
- Schema suite plus schema-lint task tests: `389 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3709 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only contract hardening required no generated schema changes.

Review:
- Producer and validator share the same exact identity-to-status map helper, so
  contact classification, deduplication, and sorting cannot drift locally.
- Cross-field validation tolerates malformed surrounding rows long enough for
  the existing structural validators to report them instead of raising.
- Current rows reconcile penalties and statuses at zero and nonzero risk weight;
  all-prechange rows remain valid as an explicit compatibility mode.
- A present final score term reconciles unique selected downlink identities and
  cannot be disguised by changing the total and score-term report together.

Remaining maturity gaps:
- Continue candidate-specific resource/contact/readiness selection or ranking
  effects only where stable identity evidence supports them.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
