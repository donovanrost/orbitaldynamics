defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.DirectionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.RowValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.Normalization

  def normalize_direction_count_map(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {RowValues.normalize_direction(direction), Normalization.numeric_value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> Normalization.non_empty_map()
  end

  def normalize_direction_count_map(_counts), do: nil
end
