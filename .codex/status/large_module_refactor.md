# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner V1 build-artifact assembly extraction.

Status:
Ready to publish.

Selected slice:
Move the final V1 campaign-plan map construction and operator-review,
cadence-import, readiness, and quality-gate attachment from
`CampaignPlanner.build/2` into `CampaignPlanner.BuildArtifact`.

Why this slice:
`campaign_planner.ex` remains 4,602 lines. Its V2 and V3 paths already delegate
artifact ownership to `RepairArtifact` and `StrategyArtifact`, but V1 mixes
planning orchestration with a roughly 100-line serialization and downstream
handoff tail. The new owner will receive already-computed planning components;
candidate selection, scoring, filtering, IDs, and policy decisions remain in
the facade.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.build/2`, exact V1 artifact fields and nested
reports, generated timestamps and IDs, deterministic ordering, and downstream
operator-review/cadence/readiness handoffs.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/build_artifact.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused `campaign_planner_test.exs`
- V1 build family tests covering constraints, station availability, contact
  contention/intents, objectives, and eclipse filtering
- compile, format, diff hygiene, and bounded review

Definition of done:
`build/2` still performs the same planning computations in the same order, the
new owner constructs the exact map and handoff pipeline, deterministic V1 tests
pass without artifact drift, and bounded review finds no blocker.

Outcome:
`CampaignPlanner.build/2` still computes candidate selection, filtering,
scoring, reports, constraints, warnings, assumptions, provenance, and IDs.
`BuildArtifact` now owns the exact 34-field V1 map, command-window generation,
and the operator-review, cadence-import, readiness, and quality-gate attachment
pipeline. The facade shrank from 4,602 to 4,568 lines. The explicit 77-line
artifact owner increases the total boundary by 43 lines, trading duplication
of V1 serialization concerns in the facade for parity with the existing V2
`RepairArtifact` owner.

Verification gaps:
- Exact structural audit: all 34 V1 top-level fields remain present and ordered;
  operator-review, cadence-import, and readiness attachment order is exact.
- `mix compile --warnings-as-errors` passed.
- Every test file that directly calls `CampaignPlanner.build/2` passed: 36/36
  across the facade, constraints, station availability, contact contention,
  contact intents, objective/downlink, eclipse filtering, and file-backed
  facade families.
- `mix format --check-formatted` and `git diff --check` passed.
- Independent bounded review found no blocker; pure attribute construction now
  precedes command-window construction, but shares no mutation, I/O, clock
  access, or result dependency, so valid-input behavior is unchanged.

Last completed slice:
Operator-review row JSON Schema provider-manifest and shared-resolver extraction
published as `43640ea6`: all 42 schema and 11 property providers remained exact
and lazy, duplicate resolvers were removed, schema exports stayed byte-identical,
25/25 focused tests passed, and bounded review found no blocker.

Next candidate:
After the V1 artifact owner is proven, reassess the remaining `build/2`
orchestration closure before moving to `do_repair/1`. Prefer a complete
responsibility boundary over pushing private helper calls through callbacks.

Blocked:
No.
