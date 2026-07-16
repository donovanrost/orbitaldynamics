defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap.EntryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias __MODULE__.DirectFields
  alias __MODULE__.ProviderReservationFields

  def route_entry(direction, field_maps) do
    DirectFields.fields(direction, field_maps)
    |> Map.merge(ProviderReservationFields.fields(direction, field_maps))
    |> compact_map()
  end
end
