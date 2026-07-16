defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets

  def station_id(row) do
    Lookup.stable_source_entity_value(
      row,
      FieldSets.direct_station_id_fields(),
      FieldSets.station_sources()
    )
  end

  def spacecraft_id(row) do
    Lookup.stable_source_entity_value(
      row,
      FieldSets.spacecraft_id_fields(),
      FieldSets.spacecraft_sources()
    )
  end
end
