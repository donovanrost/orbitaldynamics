defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.CountValues do
  @moduledoc false

  def count(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
