defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def field_counts(reports, field) do
    reports
    |> Enum.map(&RowValues.count_field(&1, field))
    |> merge_count_maps()
  end

  def activity_id_counts(reports) do
    reports
    |> Enum.map(&RowValues.activity_id_counts/1)
    |> merge_count_maps()
  end
end
