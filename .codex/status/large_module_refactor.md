# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner cadence-import pressure aggregation extraction.

Status:
Selected.

Selected slice:
Extract prior-plan and mission-state cadence-import pressure collection plus
source-review/direct fallback dispatch from `OrbitalDynamics.CampaignPlanner`
into `CampaignPlanner.CadenceImportPressureBranches`.

Why this slice:
The adjacent cluster is the sole owner of cadence-import pressure aggregation:
it gathers rows from prior-plan or mission-state manifests, preserves import
trust boundaries, delegates embedded review rows to the extracted
operator-review registry, and falls back to direct import pressure branches.
The strategy facade can delegate both sources without callback plumbing.

Public facade to preserve:
All `OrbitalDynamics.CampaignPlanner` public functions, exact branch/event
artifacts, deterministic ordering, source paths, approval statuses, and trust
boundaries.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- new `lib/orbital_dynamics/campaign_planner/cadence_import_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused strategy cadence-import, review-import, and review-row tests
- strategy branch regression coverage
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The planner delegates both cadence-import sources to one internal aggregator;
embedded review precedence, direct fallback, indices, policies, source paths,
approval status, trust boundaries, and emitted branches remain exact; focused
tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Campaign-planner operator-review pressure dispatch published as `72f92514`:
all 22 review types and the unknown fallback now live in one cohesive internal
registry, all three callers delegate through it, 39 focused/regression tests
passed, and bounded review found no finding.

Next candidate:
After this slice, audit branch candidate-plan staging or branch-event
application. Select only if private helper ownership can move without a broad
callback bag.

Blocked:
No.
