defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks.RoutedMaps.MapValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def with_row_ids(%{} = row_ids, report, field, row_fields) when map_size(row_ids) > 0 do
    [
      report
      |> normalized_string_list_map(field)
      |> Map.drop(row_fields),
      row_ids
    ]
    |> merge_string_list_maps()
  end

  def with_row_ids(_row_ids, report, field, _row_fields), do: list_map(report, field)

  defp normalized_string_list_map(report, field) do
    [list_map(report, field)]
    |> merge_string_list_maps()
    |> Kernel.||(%{})
  end

  defp list_map(report, field) do
    case Map.get(report, field) do
      %{} = list_map -> list_map
      _value -> %{}
    end
  end
end
