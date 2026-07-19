# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operational-mode decision extraction.

Status:
Completed and pushed in `5a80b5c7`.

Selected boundary:
Extract the analysis-mode vocabulary and aliases, option/artifact precedence,
nested mode lookup, truthy and token normalization, and analysis-only decision
reasoning into `OrbitalDynamics.OperationalReadiness.OperationalModeDecision`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 2,018 lines,
  the largest ordinary eligible facade.
- OperationalReadiness already delegates to seven focused evidence/summary
  owners; its analysis-mode vocabulary remains at lines 33-49 and the matching
  decision helper family at lines 1,868-1,943.
- The operational-mode gate has one call into this helper family, while
  capability metadata exposes the same vocabulary and alias contract.
- Source, adapter, policy, training, resource, review/import gates, evidence
  normalization, report identity, and all readiness/quality-gate summaries
  remain outside the boundary.
- Exact option-before-artifact precedence, not-for-execution precedence,
  nested path order, atom/string/boolean normalization, punctuation folding,
  alias mapping, unknown-mode fallback, decision tuples/reasons, capability
  ordering, and public report behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.OperationalReadiness.OperationalModeDecision` as the
  owner of the analysis-mode vocabulary and aliases, option/artifact
  precedence, nested mode lookup, truthy/token normalization, and analysis-only
  decision tuples.
- Preserved all OperationalReadiness and root public APIs; capability metadata
  and the operational-mode gate now call the dedicated owner.
- Removed the vocabulary attributes and complete decision helper family from
  the facade.
- `operational_readiness.ex` moved from 2,018 to 1,927 lines; the new owner is
  103 lines.

Verification:
- Strict focused baseline passed all 31 OperationalReadiness tests.
- Exact old/new public parity passed for eight captured cases: capability
  metadata, options not-for-execution, option mode aliases, artifact and nested
  not-for-execution/mode values, and unknown-mode fallback.
- Focused and operator-review handoff verification passed 34 tests.
- Static checks confirm the attributes and decision helpers left the facade;
  xref reports only OperationalReadiness as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,992 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operational-mode decision extraction, selected in
`0582a8c2` and implemented in `5a80b5c7`.
`operational_readiness.ex` moved from 2,018 to 1,927 lines; the dedicated
operational-mode decision owner is 103 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. RecommendationRiskContext and OrbitData are now tied as the largest
ordinary eligible facades at 2,016 lines.

Blocked:
No.
