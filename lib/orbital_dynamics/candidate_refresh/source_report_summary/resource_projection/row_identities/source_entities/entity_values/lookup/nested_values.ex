defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup.NestedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup.FieldValues

  def value(row, candidates) when is_map(row) and is_list(candidates) do
    Enum.find_value(candidates, fn {key, fields} ->
      value(row, key, fields)
    end)
  end

  def value(row, key, fields) when is_map(row) do
    case Map.get(row, key) do
      %{} = entity -> FieldValues.entity_id(entity, fields)
      _entity -> nil
    end
  end
end
