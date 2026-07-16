defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.GroundStationIds do
  @moduledoc false

  alias __MODULE__.NormalizedValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds

  def values(row) do
    row
    |> StableEntityIds.station_id()
    |> NormalizedValues.ids()
  end
end
