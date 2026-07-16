defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows.RowValues.Expiration do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows.RowValues.Normalization

  def expiration_now_s(report),
    do: numeric_value(Map.get(report, "station_reservation_expiration_now_s"))

  def station_reservation_expires_at_s(station) do
    [
      Map.get(station, "station_reservation_expires_at_s"),
      Map.get(station, "reservation_expires_at_s"),
      Map.get(station, "reservation_hold_expires_at_s"),
      Map.get(station, "hold_expires_at_s"),
      Map.get(station, "expires_at_s"),
      Map.get(station, "expires_at"),
      get_in(station, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "expires_at"])
    ]
    |> Enum.find_value(&numeric_value/1)
  end

  def expiration_status(nil, _now_s), do: "missing"
  def expiration_status(_expires_at_s, nil), do: "declared"
  def expiration_status(expires_at_s, now_s) when expires_at_s <= now_s, do: "expired"
  def expiration_status(_expires_at_s, _now_s), do: "active"

  defp numeric_value(value), do: Normalization.numeric_value(value)
end
