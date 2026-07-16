defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets do
  @moduledoc false

  alias __MODULE__.SpacecraftFields
  alias __MODULE__.FieldSpecs
  alias __MODULE__.StationFields

  def activity_id_fields, do: FieldSpecs.activity_id_fields()

  def station_sources, do: StationFields.sources()

  def spacecraft_sources, do: SpacecraftFields.sources()
end
