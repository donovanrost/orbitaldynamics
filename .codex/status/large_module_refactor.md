# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operational-mode decision extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent capacity-evidence extraction, selected in `85949f03` and
implemented in `f01406f6`.
`communications/contact_intent.ex` moved from 2,038 to 1,785 lines; the
dedicated capacity-evidence owner is 281 lines.

Next candidate:
Complete the selected OperationalReadiness operational-mode decision
extraction.

Blocked:
No.
