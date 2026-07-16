defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactContentionResolutionSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "conflict_group_count" => Map.get(artifact, "conflict_group_count"),
      "recommendation_count" => Map.get(artifact, "recommendation_count"),
      "recommendation_group_ids" =>
        artifact
        |> list_values("recommendation_group_ids")
        |> Enum.join("|"),
      "review_group_ids" =>
        artifact
        |> list_values("review_group_ids")
        |> Enum.join("|"),
      "selected_contact_ids" =>
        artifact
        |> list_values("selected_contact_ids")
        |> Enum.join("|"),
      "selected_contact_ids_by_group_id" =>
        Map.get(artifact, "selected_contact_ids_by_group_id") || %{},
      "deferred_contact_ids" =>
        artifact
        |> list_values("deferred_contact_ids")
        |> Enum.join("|"),
      "deferred_contact_ids_by_group_id" =>
        Map.get(artifact, "deferred_contact_ids_by_group_id") || %{},
      "review_contact_ids" =>
        artifact
        |> list_values("review_contact_ids")
        |> Enum.join("|"),
      "review_contact_ids_by_group_id" =>
        Map.get(artifact, "review_contact_ids_by_group_id") || %{},
      "review_recommendation_count" => Map.get(artifact, "review_recommendation_count"),
      "resource_scope_counts" => Map.get(artifact, "resource_scope_counts") || %{},
      "selected_contact_ids_by_resource_scope" =>
        Map.get(artifact, "selected_contact_ids_by_resource_scope") || %{},
      "deferred_contact_ids_by_resource_scope" =>
        Map.get(artifact, "deferred_contact_ids_by_resource_scope") || %{},
      "review_contact_ids_by_resource_scope" =>
        Map.get(artifact, "review_contact_ids_by_resource_scope") || %{},
      "selection_reason_counts" => Map.get(artifact, "selection_reason_counts") || %{},
      "selected_contact_ids_by_selection_reason" =>
        Map.get(artifact, "selected_contact_ids_by_selection_reason") || %{},
      "action_counts" => Map.get(artifact, "action_counts") || %{},
      "review_contact_ids_by_action" => Map.get(artifact, "review_contact_ids_by_action") || %{},
      "ambiguous_group_ids" =>
        artifact
        |> list_values("ambiguous_group_ids")
        |> Enum.join("|"),
      "ambiguous_duplicate_contact_ids" =>
        artifact
        |> list_values("ambiguous_duplicate_contact_ids")
        |> Enum.join("|"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        Map.get(artifact, "ambiguous_duplicate_contact_ids_by_group_id") || %{},
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "candidate_mutation" => get_in(artifact, ["assumptions", "candidate_mutation"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "no_provider_reservation" => "no_provider_reservation" in model_limits,
      "no_candidate_suppression" => "no_candidate_suppression" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_link_budget_model" => "no_link_budget_model" in model_limits
    }
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
