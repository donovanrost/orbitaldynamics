defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.CapacityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  alias __MODULE__.NumericMaps

  def fields(reports) do
    %{
      "station_reservation_expires_at_s" =>
        StationCalendarReport.reservation_expires_at_s(reports),
      "earliest_station_reservation_expires_at_s" =>
        reports
        |> StationCalendarReport.reservation_expires_at_s()
        |> min_list(),
      "station_capacity_fractions" => StationCalendarReport.capacity_fractions(reports),
      "minimum_station_capacity_fraction" =>
        reports
        |> StationCalendarReport.capacity_fractions()
        |> min_list()
    }
    |> Map.merge(NumericMaps.fields(reports))
  end

  defp min_list(values) when is_list(values), do: Enum.min(values, fn -> nil end)
  defp min_list(_values), do: nil
end
