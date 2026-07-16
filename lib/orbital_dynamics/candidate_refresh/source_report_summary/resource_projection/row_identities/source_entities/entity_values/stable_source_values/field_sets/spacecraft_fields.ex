defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets.SpacecraftFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  def id_fields, do: FieldSpecs.id_fields()

  def sources do
    [
      {"spacecraft", FieldSpecs.id_fields()},
      {"satellite", FieldSpecs.id_fields()}
    ]
  end
end
