defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.PressureMaps.ReportValues do
  @moduledoc false

  alias __MODULE__.ActivityDirectionPairs
  alias __MODULE__.DirectionCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps

  def direction_counts(report) do
    report
    |> projected_resource_rows()
    |> DirectionCounts.from_rows()
  end

  def activity_ids_by_direction(report) do
    report
    |> projected_resource_rows()
    |> ActivityDirectionPairs.from_rows()
    |> ValueListMaps.from_pairs()
  end

  defp projected_resource_rows(report), do: Map.get(report, "projected_resources", [])
end
