# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness source/report identity extraction.

Status:
Completed and pushed in `1a5b8947`.

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
- Added `OrbitalDynamics.OperationalReadiness.SourceIdentity` as the owner of
  source artifact type/ID precedence, stable fragment encoding, readiness
  report IDs, and quality-gate report/row IDs.
- Wired readiness report construction and quality-gate report/row projection
  directly to the owner while preserving OperationalReadiness and root APIs.
- Kept review/import construction, evidence collection, gate decisions, and
  all summary projections outside the boundary.
- `operational_readiness.ex` moved from 1,541 to 1,474 lines; the new owner is
  80 lines.

Verification:
- Strict focused baseline passed all 31 OperationalReadiness tests.
- Exact old/new public parity passed for four deterministic artifacts:
  special-character manifest readiness identity, its quality-gate report/row
  identities, review-package source identity, and missing-source-ID fallback.
- Post-extraction focused and adjacent readiness, replay-summary,
  operator-review, schema-contract, and validation verification passed all 49
  tests.
- Static checks confirm source identity precedence and stable readiness and
  quality-gate ID helpers left the facade; xref reports only
  OperationalReadiness as a runtime caller.
- Strict warning-clean forced compile passed for 4,022 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness source/report identity extraction, selected in `bbd440b7`
and implemented in `1a5b8947`.
`operational_readiness.ex` moved from 1,541 to 1,474 lines; the dedicated
SourceIdentity owner is 80 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. RecommendationRiskContext is now the largest ordinary eligible
facade at 1,527 lines, followed by OperationalReadiness.

Blocked:
No.
