defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReservationDirectReportSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReservationDirectReportSourceFields

  def station_reservation_sources(refresh) do
    StationScheduleReservationDirectReportSourceFields.scoped_sources(
      refresh,
      "accepted_planning_state"
    ) ++
      StationScheduleReservationDirectReportSourceFields.scoped_sources(refresh, "mission_state") ++
      StationScheduleReservationDirectReportSourceFields.root_sources(refresh)
  end
end
