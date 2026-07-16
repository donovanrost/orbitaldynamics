defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.AggregateFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.ChangedCounts.FieldDefinitions,
    as: ChangedCountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.FeedbackCounts.RowCountValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.ObjectiveCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &Rows.row_count/1),
      "removed_downlink_count" =>
        sum_report_count(
          reports,
          &RowCountValues.removed_downlink_count/1
        ),
      "removed_observation_count" =>
        sum_report_count(
          reports,
          &ObjectiveCounts.removed_observation_count/1
        )
    }
    |> Map.merge(ChangedCountFields.aggregate_fields(reports))
  end
end
