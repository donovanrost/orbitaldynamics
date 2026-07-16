defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets.StationFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  def sources do
    [
      {"first_resource_pressure", FieldSpecs.id_fields()},
      {"source_activity", FieldSpecs.id_fields()},
      {"source_contact", FieldSpecs.id_fields()}
    ]
  end
end
