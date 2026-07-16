defmodule OrbitalDynamics.Validation.ArtifactObservations.ResourceFilterSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")
    review_rows = map_rows(artifact, "review_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "input_candidate_count" => Map.get(artifact, "input_candidate_count"),
      "kept_candidate_count" => Map.get(artifact, "kept_candidate_count"),
      "suppressed_candidate_count" => Map.get(artifact, "suppressed_candidate_count"),
      "suppression_review_status" => Map.get(artifact, "suppression_review_status"),
      "suppressed_candidate_ids" =>
        artifact
        |> list_values("suppressed_candidate_ids")
        |> Enum.join("|"),
      "suppressed_reason_counts" => Map.get(artifact, "suppressed_reason_counts") || %{},
      "suppressed_candidate_ids_by_reason" =>
        Map.get(artifact, "suppressed_candidate_ids_by_reason") || %{},
      "resource_blocking_dimension_counts" =>
        Map.get(artifact, "resource_blocking_dimension_counts") || %{},
      "suppressed_candidate_ids_by_resource_blocking_dimension" =>
        Map.get(artifact, "suppressed_candidate_ids_by_resource_blocking_dimension") || %{},
      "suppressed_candidate_ids_by_scenario_id" =>
        Map.get(artifact, "suppressed_candidate_ids_by_scenario_id") || %{},
      "suppressed_resource_source_quality_counts" =>
        Map.get(artifact, "suppressed_resource_source_quality_counts") || %{},
      "suppressed_candidate_ids_by_resource_source_quality" =>
        Map.get(artifact, "suppressed_candidate_ids_by_resource_source_quality") || %{},
      "suppressed_resource_trust_boundary_status_counts" =>
        Map.get(artifact, "suppressed_resource_trust_boundary_status_counts") || %{},
      "suppressed_candidate_ids_by_resource_trust_boundary_status" =>
        Map.get(artifact, "suppressed_candidate_ids_by_resource_trust_boundary_status") || %{},
      "invalid_candidate_input_count" => Map.get(artifact, "invalid_candidate_input_count"),
      "invalid_candidate_input_ids" =>
        artifact
        |> list_values("invalid_candidate_input_ids")
        |> Enum.join("|"),
      "invalid_resource_summary_input_count" =>
        Map.get(artifact, "invalid_resource_summary_input_count"),
      "invalid_resource_summary_input_ids" =>
        artifact
        |> list_values("invalid_resource_summary_input_ids")
        |> Enum.join("|"),
      "duplicate_suppressed_candidate_id_count" =>
        Map.get(artifact, "duplicate_suppressed_candidate_id_count"),
      "duplicate_suppressed_candidate_row_count" =>
        Map.get(artifact, "duplicate_suppressed_candidate_row_count"),
      "review_row_count" => length(review_rows),
      "review_row_ids" =>
        review_rows
        |> Enum.map(&Map.get(&1, "id"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "resource_state_propagation" =>
        get_in(artifact, ["assumptions", "resource_state_propagation"]),
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_resource_time_propagation" => "no_resource_time_propagation" in model_limits,
      "no_subsystem_simulation" => "no_subsystem_simulation" in model_limits
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
