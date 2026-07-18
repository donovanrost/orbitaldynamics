defmodule OrbitalDynamics.CampaignPlanner.DerivedStationPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    StationCalendarPressureBranches,
    StationReservationPressureReports,
    StationSourceReports
  }

  def build(prior_plan, mission_state) do
    []
    |> Kernel.++(prior_station_calendar(prior_plan))
    |> Kernel.++(mission_station_calendar(mission_state))
    |> Kernel.++(mission_reservation_review_summary(mission_state))
    |> Kernel.++(mission_reservation_hold(mission_state))
  end

  defp prior_station_calendar(prior_plan) do
    prior_plan
    |> StationSourceReports.prior_plan_station_calendar_reports()
    |> StationCalendarPressureBranches.from_reports()
  end

  defp mission_station_calendar(mission_state) do
    mission_state
    |> StationSourceReports.station_calendar_reports()
    |> StationCalendarPressureBranches.from_reports()
  end

  defp mission_reservation_review_summary(mission_state) do
    mission_state
    |> StationReservationPressureReports.review_summary_reports()
    |> StationCalendarPressureBranches.from_reports(
      provider_contention_source_path: fn _report, source_path ->
        "#{source_path}.review_rows"
      end
    )
  end

  defp mission_reservation_hold(mission_state) do
    mission_state
    |> StationReservationPressureReports.hold_pressure_reports()
    |> StationCalendarPressureBranches.from_reports(
      provider_contention_source_path: fn report, source_path ->
        "#{source_path}.#{report["source_row_collection"] || "review_rows"}"
      end
    )
  end
end
