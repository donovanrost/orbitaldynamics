defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues.FieldSets.StationFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  def direct_id_fields, do: FieldSpecs.direct_id_fields()

  def sources do
    [
      {"ground_station", FieldSpecs.id_fields()},
      {"station", FieldSpecs.id_fields()}
    ]
  end
end
