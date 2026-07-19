# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness adapter-boundary evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract adapter-shaped context detection, nested trust-boundary collection,
trust-boundary token classification, and declared/missing/untrusted frequency
projection into
`OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence`. Preserve all
public OperationalReadiness report and summary facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,500 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected helper family spans lines 2,202-2,319 and exclusively derives
  adapter trust-boundary status counts from the source artifact, review rows,
  and import rows.
- Readiness evidence construction is the single consumer of the classifier.
- Adapter gate decisions, generic count projection, other evidence families,
  report/summary construction, public clauses, and artifact contracts remain
  outside this boundary.
- Existing direct and nested adapter-key detection, blank-value rejection,
  trust-boundary precedence, missing/untrusted token matching, substring
  matching, duplicate counting, and empty-map behavior must remain unchanged.

Implementation:
- Selection was recorded and pushed in `f917e600`.
- Implementation was committed and pushed in `967b7ade`.
- `operational_readiness.ex` moved from 2,500 to 2,385 lines.
- `OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence` is a
  121-line owner reached through a private facade delegate.

Verification:
- Strict warning-clean compilation passed across 3,965 files.
- The focused OperationalReadiness file and five adjacent operator-review,
  quality-gate, Cadence-import, replay-routing, and schema consumers passed
  together: 44 tests.
- Exact old/new public parity passed for 10 reports covering empty evidence;
  direct missing, declared, and untrusted boundaries; nested adapter evidence;
  blank adapter values; missing-token and substring-untrusted normalization;
  mixed counts; artifact-level context; and public-error behavior.
- `mix xref callers` reports only the OperationalReadiness facade; the
  compile-connected graph reports the new owner and facade.
- The removed classifier helpers are absent from the facade apart from the
  thin delegate, formatting and `git diff --check` passed, and the final diff
  is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness adapter-boundary evidence extraction, selected in
`f917e600` and implemented in `967b7ade`.
`operational_readiness.ex` moved from 2,500 to 2,385 lines; the dedicated
adapter-boundary evidence owner is 121 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
