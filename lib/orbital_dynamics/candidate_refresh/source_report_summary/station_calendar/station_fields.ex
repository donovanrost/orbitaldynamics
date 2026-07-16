defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.CapacityFields
  alias __MODULE__.IdMaps

  def fields(reports) do
    reports
    |> BaseFields.fields()
    |> Map.merge(IdMaps.fields(reports))
    |> Map.merge(CapacityFields.fields(reports))
  end
end
