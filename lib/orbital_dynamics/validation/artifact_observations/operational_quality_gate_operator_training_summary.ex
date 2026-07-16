defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalQualityGateOperatorTrainingSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    requirement_counts = Map.get(artifact, "operator_training_requirement_counts") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_quality_gate_report_id" => Map.get(artifact, "source_quality_gate_report_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "operator_training_row_count" => Map.get(artifact, "operator_training_row_count"),
      "operator_training_requirement_count" =>
        Map.get(artifact, "operator_training_requirement_count"),
      "row_derived_operator_training_requirement_count" => count_map_values(requirement_counts),
      "operator_training_requirement_counts" => requirement_counts,
      "operator_training_requirement_keys" =>
        artifact
        |> list_values("operator_training_requirement_ids")
        |> Enum.join("|"),
      "required_operator_role_keys" =>
        artifact
        |> list_values("required_operator_roles")
        |> Enum.join("|"),
      "required_training_keys" =>
        artifact
        |> list_values("required_training_ids")
        |> Enum.join("|"),
      "required_certification_keys" =>
        artifact
        |> list_values("required_certification_ids")
        |> Enum.join("|"),
      "required_qualification_keys" =>
        artifact
        |> list_values("required_qualification_ids")
        |> Enum.join("|"),
      "quality_gate_row_ids_by_status" =>
        Map.get(artifact, "quality_gate_row_ids_by_status") || %{},
      "quality_gate_row_ids_by_classification" =>
        Map.get(artifact, "quality_gate_row_ids_by_classification") || %{},
      "quality_gate_ids_by_status" => Map.get(artifact, "quality_gate_ids_by_status") || %{},
      "quality_gate_ids_by_classification" =>
        Map.get(artifact, "quality_gate_ids_by_classification") || %{},
      "review_required_quality_gate_row_keys" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> Enum.join("|"),
      "blocked_quality_gate_row_keys" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> Enum.join("|"),
      "review_only_quality_gate_row_keys" =>
        artifact
        |> list_values("review_only_quality_gate_row_ids")
        |> Enum.join("|"),
      "operator_training_gate_keys" =>
        artifact
        |> list_values("operator_training_gate_ids")
        |> Enum.join("|"),
      "operator_training_review_required" =>
        Map.get(artifact, "operator_training_review_required"),
      "row_derived_review_required_quality_gate_row_count" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> length(),
      "row_derived_review_only_quality_gate_row_count" =>
        artifact
        |> list_values("review_only_quality_gate_row_ids")
        |> length(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_map_values(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end

  defp count_map_values(_values), do: 0

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
