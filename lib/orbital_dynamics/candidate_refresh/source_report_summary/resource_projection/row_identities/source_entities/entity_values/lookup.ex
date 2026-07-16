defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup do
  @moduledoc false

  alias __MODULE__.NestedValues
  alias __MODULE__.SourceValues
  alias __MODULE__.StableValues

  def stable_source_entity_value(row, direct_fields, nested_sources) do
    row
    |> SourceValues.value(direct_fields, nested_sources, &nested_value/2)
    |> StableValues.id()
  end

  def nested_value(row, candidates) when is_map(row) and is_list(candidates) do
    NestedValues.value(row, candidates)
  end

  def nested_value(row, key, fields) when is_map(row) do
    NestedValues.value(row, key, fields)
  end
end
