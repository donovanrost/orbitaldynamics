defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds.AggregateFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "source_activity_id_counts" =>
        reports
        |> Enum.map(&ActivityIds.source_counts/1)
        |> merge_count_maps(),
      "replacement_activity_id_counts" =>
        reports
        |> Enum.map(&ActivityIds.replacement_counts/1)
        |> merge_count_maps()
    }
  end
end
