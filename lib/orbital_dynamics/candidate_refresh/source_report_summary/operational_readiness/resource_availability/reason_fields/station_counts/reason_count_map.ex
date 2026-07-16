defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.StationCounts.ReasonCountMap do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  @station_availability_reasons ~w(
    ground_station_capacity_zero
    ground_station_reduced_capacity_insufficient
    ground_station_reserved
    ground_station_unavailable
  )

  def filter_reason_ids(values) do
    values
    |> Enum.map(&NormalizedToken.value/1)
    |> Enum.filter(&station_availability_reason?/1)
  end

  def counts(%{} = counts) do
    Enum.reduce(counts, %{}, fn {reason, count}, acc ->
      reason = NormalizedToken.value(reason)

      if station_availability_reason?(reason) and is_integer(count) and count > 0 do
        Map.update(acc, reason, count, &(&1 + count))
      else
        acc
      end
    end)
  end

  def counts(_counts), do: %{}

  defp station_availability_reason?(reason), do: reason in @station_availability_reasons
end
