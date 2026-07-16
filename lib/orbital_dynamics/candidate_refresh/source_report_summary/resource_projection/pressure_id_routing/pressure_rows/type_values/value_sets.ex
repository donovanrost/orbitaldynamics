defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.PressureRows.TypeValues.ValueSets do
  @moduledoc false

  def non_empty_sorted(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      types -> types
    end
  end
end
