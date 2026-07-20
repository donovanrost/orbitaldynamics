defmodule OrbitalDynamics.Schema.CandidateDiffSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
      {:candidate_diff_row_json_schema, 0} => fn -> candidate_diff_row(stable_id_pattern) end,
      {:candidate_refresh_scoped_context_json_schema_properties, 0} => fn ->
        scoped_context_properties(stable_id_pattern)
      end,
      {:invalidated_candidate_json_schema, 0} => fn ->
        invalidated_candidate(stable_id_pattern)
      end,
      {:source_window_lineage_json_schema, 0} => fn ->
        source_window_lineage(stable_id_pattern)
      end
    }
  end

  def source_window_lineage(stable_id_pattern) do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.source_window_lineage_from_context(
      stable_id_pattern: stable_id_pattern,
      scoped_context_properties: fn -> scoped_context_properties(stable_id_pattern) end
    )
  end

  defp invalidated_candidate(stable_id_pattern) do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.invalidated_candidate_from_context(
      stable_id_pattern: stable_id_pattern,
      scoped_context_properties: fn -> scoped_context_properties(stable_id_pattern) end
    )
  end

  defp candidate_diff_row(stable_id_pattern) do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      scoped_context_properties: fn -> scoped_context_properties(stable_id_pattern) end
    )
  end

  defp scoped_context_properties(stable_id_pattern) do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.candidate_refresh_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end
end
