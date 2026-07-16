defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryValueEncoding

  def count_source_report_rows(rows, field) do
    rows
    |> Enum.map(
      &(Map.get(&1, field)
        |> StationReservationHoldSummaryValueEncoding.normalized_source_report_token())
    )
    |> reject_empty_values()
    |> frequencies_or_nil()
  end

  def count_values(values) do
    values
    |> Enum.map(&StationReservationHoldSummaryValueEncoding.encode_value/1)
    |> reject_empty_values()
    |> frequencies_or_nil()
  end

  defp reject_empty_values(values), do: Enum.reject(values, &(&1 in [nil, ""]))

  defp frequencies_or_nil(values) do
    values
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
