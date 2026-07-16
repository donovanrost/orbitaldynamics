defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.AllowedReasons do
  @moduledoc false

  alias __MODULE__.CountMap
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  @unavailable_resource_reasons ~w(
    antenna_unavailable
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    spacecraft_unavailable
  )

  @station_availability_reasons ~w(
    ground_station_capacity_zero
    ground_station_reduced_capacity_insufficient
    ground_station_reserved
    ground_station_unavailable
  )

  def station_reason_ids(values), do: filter_reason_ids(values, @station_availability_reasons)

  def unavailable_resource_reason_ids(values),
    do: filter_reason_ids(values, @unavailable_resource_reasons)

  def station_reason_count_map(%{} = counts) do
    CountMap.values(counts, @station_availability_reasons)
  end

  defp filter_reason_ids(values, allowed_reasons) do
    values
    |> Enum.map(&NormalizedToken.value/1)
    |> Enum.filter(&(&1 in allowed_reasons))
  end
end
