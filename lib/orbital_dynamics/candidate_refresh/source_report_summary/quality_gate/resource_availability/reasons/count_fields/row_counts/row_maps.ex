defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.CountFields.RowCounts.RowMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def count_map(report, field) do
    case rows(report) do
      [] ->
        Map.get(report, field, %{})

      rows ->
        rows
        |> Enum.map(&Map.get(&1, field))
        |> merge_count_maps()
    end
  end

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end
end
