defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.AggregateFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.RowValues,
    as: DuplicateIdentityRows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1, sum_report_count: 2]

  def fields(reports) do
    %{
      "duplicate_timeline_identity_scope_counts" =>
        reports
        |> Enum.map(&DuplicateIdentityRows.duplicate_identity_scope_counts/1)
        |> merge_count_maps(),
      "duplicate_timeline_identity_count" =>
        sum_report_count(reports, &DuplicateIdentityRows.duplicate_identity_total_count/1),
      "duplicate_source_timeline_identity_count" =>
        sum_report_count(
          reports,
          &DuplicateIdentityRows.duplicate_source_timeline_identity_count/1
        ),
      "duplicate_replacement_timeline_identity_count" =>
        sum_report_count(
          reports,
          &DuplicateIdentityRows.duplicate_replacement_timeline_identity_count/1
        )
    }
  end
end
