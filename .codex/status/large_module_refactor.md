# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving internal extraction. Keep public APIs, artifact contracts,
deterministic outputs, checked-in schema exports, and behavior stable while
moving cohesive private clusters behind focused helpers.

Current slice:
Completed: Common value-count encoded-count extraction.

Status:
Nine hundred sixty-nine bounded source-summary helper/facade cleanups have been
completed in this pass. The current source-report inventory remains the best
next hotspot; continue only where a file still mixes distinct responsibilities
or contains redundant internal plumbing.

Files changed this slice:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex`
- `lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex`

Public APIs preserved:
- `OrbitalDynamics.CandidateRefresh.source_report_summary/1`
- `OrbitalDynamics.CandidateRefresh.resource_projection_replay_summary/1`
- Shared source-report summary helper behavior exposed through
  `SourceReportSummary.Common`.

Behavior/schema changes:
- No intended public behavior or schema changes.
- `SourceReportSummary.Common.ValueCounts` now delegates encoded-value count
  accumulation to `ValueCounts.EncodedCounts`.
- Encoded counts still map through `EncodedValue.value/1`, reject nil/empty
  values, and increment counts with the same reduce/update logic.
- The value-counts helper is now 27 lines; the new encoded-counts helper is 12
  lines.

Tests run:
- `mix compile --warnings-as-errors` - passed.
- `mix xref callers OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ValueCounts` - passed; caller remains `Common`.
- `mix xref callers OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ValueCounts.EncodedCounts` - passed; caller remains `ValueCounts`.
- `mix xref graph --label compile-connected --source lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex` - passed.
- `mix test test/orbital_dynamics/candidate_refresh/encoded_value_test.exs test/orbital_dynamics/candidate_refresh/resource_projection_candidate_source_replay_summary_test.exs test/orbital_dynamics/candidate_refresh/resource_projection_pressure_edge_replay_summary_test.exs test/orbital_dynamics/candidate_refresh/resource_projection_pressure_routing_replay_summary_test.exs test/orbital_dynamics/candidate_refresh/resource_projection_source_identity_replay_summary_test.exs test/orbital_dynamics/candidate_refresh/source_report_summary_test.exs test/orbital_dynamics/candidate_refresh/source_report_input_provenance_test.exs test/orbital_dynamics/candidate_refresh/capabilities_test.exs` - passed, 22 tests.
- `mix format lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex` - passed.
- `mix format --check-formatted lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex` - passed.
- `wc -l lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex` - value-counts helper is now 27 lines; new encoded-counts helper is 12 lines.
- `git diff --check -- lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts.ex lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex` - passed before ledger edit.
- `git diff --no-index --check -- /dev/null lib/orbital_dynamics/candidate_refresh/source_report_summary/common/value_counts/encoded_counts.ex` - emitted no whitespace diagnostics for the untracked encoded-counts helper before ledger edit.
- Conflict-marker scan over the touched source files - no matches before ledger
  edit.

Verification gaps:
- Full `mix test` was not run.
- The broader worktree remains dirty/untracked from prior refactor slices; leave
  unrelated files alone and keep each next slice scoped.

Last commit:
- `d47269c`

Next candidate:
- Inspect
  `OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ValueCounts`.
  It still owns normalized source-report value frequency counting beside
  report-field value routing; check whether normalized source-value counting
  can move behind a focused helper without changing shared value-count
  behavior.

Blocked:
- No.

Notes:
- The broader worktree remains dirty/untracked from prior refactor slices; leave
  unrelated files alone and verify only the exact parent/helper pair for each
  slice.
- Recent completed cleanup slices:
  - Slice 969 extracted encoded value counting into
    `SourceReportSummary.Common.ValueCounts.EncodedCounts`.
  - Slice 968 extracted station-reservation evidence field definitions into
    `SourceReportSummary.Common.StationReservationEvidence.FieldSets`.
  - Slice 967 extracted trust-boundary normalization into
    `SourceReportSummary.Common.TrustBoundaries.NormalizedValues`.
  - Slice 966 extracted common report numeric-value summing into
    `SourceReportSummary.Common.ReportCounts.NumericSums`.
  - Slice 965 extracted station-reservation row context construction into
    `SourceReportSummary.Common.StationReservationEvidence.RowContexts.Contexts`.
  - Slice 964 extracted encoded keyword-map conversion into
    `SourceReportSummary.Common.EncodedValue.Value.KeywordMaps`.
  - Slice 963 extracted common compact-map filtering into
    `SourceReportSummary.Common.FieldValues.CompactMaps`.
  - Slice 962 extracted common source-field extraction into
    `SourceReportSummary.Common.FieldValues.SourceFields`.
  - Slice 961 extracted common sorted string normalization into
    `SourceReportSummary.Common.FieldValues.SortedStrings`.
  - Slice 960 extracted common string-list-map value normalization into
    `SourceReportSummary.Common.AggregateMaps.ListMaps.StringListMaps.StringValues`.
  - Slice 959 extracted common numeric-list-map value normalization into
    `SourceReportSummary.Common.AggregateMaps.ListMaps.NumericListMaps.NumericValues`.
  - Slice 958 extracted common string-list normalization into
    `SourceReportSummary.Common.AggregateMaps.ListMaps.StringLists`.
  - Slice 957 extracted common numeric-map merging into
    `SourceReportSummary.Common.AggregateMaps.NumberMaps.NumericMaps`.
  - Slice 956 extracted common count-map merging into
    `SourceReportSummary.Common.AggregateMaps.NumberMaps.CountMaps`.
  - Slice 955 extracted common source-row extraction into
    `SourceReportSummary.Common.FieldValues.SourceRows`.
  - Slice 954 extracted common aggregate merge delegate routing into
    `SourceReportSummary.Common.AggregateDelegates`.
  - Slice 953 extracted resource-projection count-map delegate routing into
    `ResourceProjection.PressureFields.CountFields.CountMaps.CountDelegates`.
  - Slice 952 extracted activity-route pair dispatch into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs.PairDispatch`.
  - Slice 951 extracted activity-route value-function lookup into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs.ValueLookups`.
  - Slice 950 extracted station-calendar ID-family definitions into
    `ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.StationCalendarSpecs.IdFamilies`.
  - Slice 949 extracted activity-route value-function wrapping into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs.WrappedFunctions`.
  - Slice 948 extracted activity-route value-function pair construction into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs`.
  - Slice 947 extracted pressure count-field specs into
    `ResourceProjection.PressureFields.CountFields.FieldSpecs`.
  - Slice 946 extracted activity-route function lookup into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions.RouteFunctions`.
  - Slice 945 extracted row-field route-value merging into
    `ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.ReportFunctions.RouteMerges`.
  - Slice 944 extracted row-field base route specs into
    `ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.BaseSpecs`.
  - Slice 943 extracted station-calendar route spec pair construction into
    `ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.StationCalendarSpecs.SpecPairs`.
  - Slice 942 extracted activity-route key specs into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.SpecValues.KeySpecs`.
  - Slice 941 extracted activity-route spec tuple dispatch into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldDispatch`.
  - Slice 940 extracted activity-route field-pair wrapping into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.FunctionPairs`.
  - Slice 939 extracted activity-route report closure construction into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions.ReportCalls`.
  - Slice 938 extracted pressure status value collection into
    `ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.StatusCounts.StatusValues`.
  - Slice 937 extracted identity projected-row value routing into
    `ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues.ProjectedValues`.
  - Slice 936 extracted pressure type-value collection into
    `ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.TypeCounts.TypeValues`.
  - Slice 935 moved pressure status-count report extraction into
    `ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.StatusCounts`.
  - Slice 934 extracted identity count-value report routing into
    `ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.CountValues.ReportCounts`.
  - Slice 933 extracted pressure count-map merging into
    `ResourceProjection.PressureFields.CountFields.CountMaps.MergedValues`.
  - Slice 932 extracted activity route string-list merging into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.MergedValues`.
  - Slice 931 extracted row route value-function closures into
    `ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.ReportFunctions`.
  - Slice 930 extracted activity route field value-function closures into
    `ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions`.
  - Slice 929 removed unused
    `ResourceProjection.PressureIdRouting.RouteMaps.row_ids_by_key/4`.
  - Slice 928 consolidated duplicate pressure route key helpers into
    `ResourceProjection.PressureIdRouting.RouteMaps.KeyFunctions`.
  - Slice 927 extracted shared pressure route-value dispatch into
    `ResourceProjection.PressureIdRouting.RouteMaps.RouteValues`.
  - Slice 926 extracted pressure pair-builder row aggregation into
    `ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.PairValues`.
  - Slice 925 extracted pressure row-pair tuple construction into
    `ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs.PairValues`.
  - Slice 924 removed unused
    `ResourceProjection.PressureIdRouting.RouteMaps.KeyFunctions`.
  - Slice 923 extracted nested activity field specs into
    `ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets.FieldSpecs`.
  - Slice 922 extracted nested spacecraft field specs into
    `ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets.SpacecraftFields.FieldSpecs`.
  - Slice 921 extracted nested station field specs into
    `ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets.StationFields.FieldSpecs`.
  - Slice 920 extracted stable spacecraft field specs into
    `ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets.SpacecraftFields.FieldSpecs`.
  - Slice 919 extracted stable station field specs into
    `ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets.StationFields.FieldSpecs`.
  - Slice 916 extracted operational-timeline row-issue predicate field specs
    into `OperationalTimeline.IntegrityFields.RowIssues.Predicates.FieldSpecs`.
  - Slice 917 extracted input-provenance fingerprint boundary field specs into
    `InputProvenance.Summary.Deduplication.SourceReportFingerprints.BoundaryFields.FieldSpecs`.
  - Slice 918 extracted operational-timeline row-issue context field specs into
    `OperationalTimeline.IntegrityFields.RowIssues.Predicates.IssueValues.FieldSpecs`.
