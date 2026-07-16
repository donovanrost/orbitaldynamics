defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary do
  @moduledoc false

  alias __MODULE__.ReservationConflicts
  alias __MODULE__.StationPressure

  def fields(reports) do
    reports
    |> StationPressure.fields()
    |> Map.merge(ReservationConflicts.fields(reports))
  end
end
