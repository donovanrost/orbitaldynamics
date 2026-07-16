defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections do
  @moduledoc false

  alias __MODULE__.ReportValues

  def direction_counts(reports) do
    reports
    |> Enum.map(&ReportValues.direction_counts/1)
    |> OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.merge_count_maps()
  end

  def candidate_ids_by_direction(reports) do
    reports
    |> Enum.map(&ReportValues.candidate_ids_by_direction/1)
    |> OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.merge_string_list_maps()
  end
end
