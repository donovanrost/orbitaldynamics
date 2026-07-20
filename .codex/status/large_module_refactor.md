# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness source/report identity extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract source artifact type/ID precedence and deterministic readiness and
quality-gate report/row identity construction into
`OrbitalDynamics.OperationalReadiness.SourceIdentity`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,541 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates fourteen focused responsibilities, while
  source identity precedence and stable report/row ID construction remain
  inline at lines 799-810 and 1,467-1,523.
- The selected helpers have one responsibility: resolve source artifact
  identity and encode it into deterministic readiness and quality-gate IDs.
- Review/import artifact construction, evidence collection, gate decisions,
  summaries, and all public contracts remain outside the boundary.
- Exact manifest/package/source fallback precedence, unknown fallbacks, stable
  fragment character normalization, report and row ID formats, public output,
  and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter approval-policy extraction, selected in `3dffbc73` and
implemented in `7b057dbd`.
`resource_filter.ex` moved from 1,542 to 1,310 lines; the dedicated
ApprovalPolicy owner is 271 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
