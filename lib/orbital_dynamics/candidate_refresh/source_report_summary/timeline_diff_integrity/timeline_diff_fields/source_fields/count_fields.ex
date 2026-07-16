defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.ChangedCounts.FieldDefinitions,
    as: ChangedCountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.FeedbackCounts.RowCountValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.ObjectiveCounts

  def values(report) do
    report
    |> activity_count_fields()
    |> Map.merge(change_count_fields(report))
  end

  defp activity_count_fields(report) do
    %{
      "source_activity_id_counts" => ActivityIds.source_counts(report),
      "replacement_activity_id_counts" => ActivityIds.replacement_counts(report)
    }
  end

  defp change_count_fields(report) do
    %{
      "source_removed_downlink_count" => RowCountValues.removed_downlink_count(report),
      "source_removed_observation_count" => ObjectiveCounts.removed_observation_count(report)
    }
    |> Map.merge(ChangedCountFields.source_fields(report))
  end
end
