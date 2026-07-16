defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.StationFeedback.StationState.StateValues do
  @moduledoc false

  alias __MODULE__.AvailabilityValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias OrbitalDynamics.CandidateRefresh.StationCapacity

  def state(%{} = intent) do
    availability = AvailabilityValues.unavailable_or_reserved(intent)
    capacity_fraction = station_capacity_fraction(intent)

    cond do
      availability in ["unavailable", "maintenance"] ->
        %{"availability" => "unavailable", "status" => "unavailable"}

      availability == "reserved" ->
        %{"availability" => "reserved", "status" => "reserved"}

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

      true ->
        nil
    end
  end

  defp station_capacity_fraction(station) do
    StationCapacity.fraction(station, &NumericValue.value/1)
  end
end
