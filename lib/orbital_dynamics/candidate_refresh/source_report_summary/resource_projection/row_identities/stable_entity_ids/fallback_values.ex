defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.FallbackValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities

  def station_id(row) do
    SourceEntities.nested_station_id(row) ||
      SourceEntities.source_entity_station_id(row)
  end

  def spacecraft_id(row) do
    SourceEntities.nested_spacecraft_id(row) ||
      SourceEntities.source_entity_spacecraft_id(row)
  end
end
