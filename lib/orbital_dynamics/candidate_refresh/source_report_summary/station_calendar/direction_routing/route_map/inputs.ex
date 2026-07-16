defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Inputs do
  @moduledoc false

  alias __MODULE__.NormalizedInputs
  alias __MODULE__.ProviderContentionFields
  alias __MODULE__.StationDirectionFields

  def from_fields(station_direction_fields, provider_contention_fields) do
    station_direction_fields
    |> StationDirectionFields.values()
    |> Map.merge(ProviderContentionFields.values(provider_contention_fields))
    |> NormalizedInputs.values()
  end
end
