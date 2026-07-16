defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets do
  @moduledoc false

  alias __MODULE__.SpacecraftFields
  alias __MODULE__.StationFields

  def direct_station_id_fields, do: StationFields.direct_id_fields()

  def spacecraft_id_fields, do: SpacecraftFields.id_fields()

  def station_sources, do: StationFields.sources()

  def spacecraft_sources, do: SpacecraftFields.sources()
end
