defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting do
  @moduledoc false

  alias __MODULE__.ProviderContentionFields
  alias __MODULE__.RouteMap
  alias __MODULE__.StationDirectionFields

  def fields(reports) do
    station_direction_fields = StationDirectionFields.fields(reports)
    provider_contention_fields = ProviderContentionFields.fields(reports)

    station_direction_fields
    |> Map.put(
      "direction_routing",
      RouteMap.direction_routing(station_direction_fields, provider_contention_fields)
    )
    |> Map.merge(provider_contention_fields)
  end
end
