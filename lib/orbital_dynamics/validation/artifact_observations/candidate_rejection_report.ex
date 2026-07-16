defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateRejectionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    reason_counts = Map.get(artifact, "rejection_reason_counts") || %{}
    candidate_ids_by_reason = Map.get(artifact, "candidate_id_sets_by_rejection_reason") || %{}
    required_operator_action_counts = Map.get(artifact, "required_operator_action_counts") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "candidate_count" => Map.get(artifact, "candidate_count"),
      "row_count" => Map.get(artifact, "row_count"),
      "rejected_count" => Map.get(artifact, "rejected_count"),
      "not_rejected_count" => Map.get(artifact, "not_rejected_count"),
      "invalid_candidate_input_count" => Map.get(artifact, "invalid_candidate_input_count"),
      "reviewable_count" => Map.get(artifact, "reviewable_count"),
      "rejection_reason_family_count" => map_size(reason_counts),
      "required_operator_review_count" =>
        Map.get(required_operator_action_counts, "review_candidate_rejection"),
      "rejected_candidate_id_order" =>
        artifact
        |> list_values("rejected_candidate_ids")
        |> Enum.join("|"),
      "reviewable_candidate_id_order" =>
        artifact
        |> list_values("reviewable_candidate_ids")
        |> Enum.join("|"),
      "invalid_candidate_input_id_order" =>
        artifact
        |> list_values("invalid_candidate_input_ids")
        |> Enum.join("|"),
      "station_reserved_candidate_ids" =>
        candidate_ids_by_reason
        |> list_values("station_reserved")
        |> Enum.join("|"),
      "declared_rejection_candidate_ids" =>
        candidate_ids_by_reason
        |> list_values("declared_rejection")
        |> Enum.join("|"),
      "no_target_visibility_candidate_ids" =>
        candidate_ids_by_reason
        |> list_values("no_target_visibility_window")
        |> Enum.join("|"),
      "contact_too_short_count" => Map.get(reason_counts, "contact_too_short"),
      "station_reserved_count" => Map.get(reason_counts, "station_reserved"),
      "quality_gate_failed_count" => Map.get(reason_counts, "quality_gate_failed"),
      "invalid_candidate_input_reason_count" => Map.get(reason_counts, "invalid_candidate_input"),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
