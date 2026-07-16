defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields.ExpirationFields.TimestampValues do
  @moduledoc false

  alias __MODULE__.NumericList
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def expires_at_s(summary) do
    summary
    |> Map.get("station_reservation_expires_at_s")
    |> NumericList.value()
  end

  def expiration_now_s(summary) do
    summary
    |> Map.get("station_reservation_expiration_now_s")
    |> NumericValue.value()
  end

  def earliest_expires_at_s(summary) do
    summary
    |> Map.get("earliest_station_reservation_expires_at_s")
    |> NumericValue.value()
  end
end
