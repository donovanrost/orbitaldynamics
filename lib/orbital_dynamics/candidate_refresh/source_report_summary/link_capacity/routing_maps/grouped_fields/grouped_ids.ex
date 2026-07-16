defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RoutingMaps.GroupedFields.GroupedIds do
  @moduledoc false

  alias __MODULE__.{GroundStationFields, SpacecraftFields}

  def fields(reports) do
    GroundStationFields.fields(reports)
    |> Map.merge(SpacecraftFields.fields(reports))
  end
end
