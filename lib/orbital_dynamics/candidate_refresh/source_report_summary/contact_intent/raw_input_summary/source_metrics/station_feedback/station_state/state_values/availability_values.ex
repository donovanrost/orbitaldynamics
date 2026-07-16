defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.StationFeedback.StationState.StateValues.AvailabilityValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.StationAvailability

  def unavailable_or_reserved(intent) do
    intent
    |> values()
    |> Enum.find_value(&unavailable_or_reserved_value/1)
  end

  defp values(intent) do
    [
      intent["station_availability"],
      intent["station_calendar_status"],
      intent["availability"],
      intent["status"]
    ]
  end

  defp unavailable_or_reserved_value(value) do
    normalized = value |> EncodedValue.value() |> StationAvailability.normalized_token()
    if normalized in ["unavailable", "maintenance", "reserved"], do: normalized
  end
end
