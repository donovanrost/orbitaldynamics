defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def direct_value(row, fields) do
    Enum.find_value(fields, &Map.get(row, &1))
  end

  def entity_id(%{} = entity, fields) do
    entity = EncodedValue.stringify_keys(entity)
    Enum.find_value(fields, &Map.get(entity, &1))
  end
end
