defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelinePublicationSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    source_timeline_diff_summary =
      stringify_keys(Map.get(artifact, "source_timeline_diff_summary") || %{})

    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "publication_id" => Map.get(artifact, "publication_id"),
      "publication_sequence" => Map.get(artifact, "publication_sequence"),
      "publication_status" => Map.get(artifact, "publication_status"),
      "downstream_invalidation_status" => Map.get(artifact, "downstream_invalidation_status"),
      "publication_authority" => Map.get(artifact, "publication_authority"),
      "supersedes_artifact_ids" =>
        artifact
        |> list_values("supersedes_artifact_ids")
        |> Enum.join("|"),
      "downstream_product_ids" =>
        artifact
        |> list_values("downstream_product_ids")
        |> Enum.join("|"),
      "invalidated_downstream_product_ids" =>
        artifact
        |> list_values("invalidated_downstream_product_ids")
        |> Enum.join("|"),
      "downstream_invalidation_reason_counts" =>
        Map.get(artifact, "downstream_invalidation_reason_counts"),
      "invalidated_downstream_product_ids_by_reason" =>
        Map.get(artifact, "invalidated_downstream_product_ids_by_reason"),
      "dependency_impact_status" => Map.get(artifact, "dependency_impact_status"),
      "dependency_impact_row_count" => Map.get(artifact, "dependency_impact_row_count"),
      "impacted_source_activity_ids" =>
        artifact
        |> list_values("impacted_source_activity_ids")
        |> Enum.join("|"),
      "impacted_source_timeline_ids" =>
        artifact
        |> list_values("impacted_source_timeline_ids")
        |> Enum.join("|"),
      "dependent_activity_ids" =>
        artifact
        |> list_values("dependent_activity_ids")
        |> Enum.join("|"),
      "dependent_timeline_ids" =>
        artifact
        |> list_values("dependent_timeline_ids")
        |> Enum.join("|"),
      "source_dependent_activity_ids" =>
        artifact
        |> list_values("source_dependent_activity_ids")
        |> Enum.join("|"),
      "source_dependent_timeline_ids" =>
        artifact
        |> list_values("source_dependent_timeline_ids")
        |> Enum.join("|"),
      "replacement_dependent_activity_ids" =>
        artifact
        |> list_values("replacement_dependent_activity_ids")
        |> Enum.join("|"),
      "replacement_dependent_timeline_ids" =>
        artifact
        |> list_values("replacement_dependent_timeline_ids")
        |> Enum.join("|"),
      "impacted_dependency_activity_ids" =>
        artifact
        |> list_values("impacted_dependency_activity_ids")
        |> Enum.join("|"),
      "impacted_dependency_timeline_ids" =>
        artifact
        |> list_values("impacted_dependency_timeline_ids")
        |> Enum.join("|"),
      "impacted_exclusive_with_activity_ids" =>
        artifact
        |> list_values("impacted_exclusive_with_activity_ids")
        |> Enum.join("|"),
      "impacted_exclusive_with_timeline_ids" =>
        artifact
        |> list_values("impacted_exclusive_with_timeline_ids")
        |> Enum.join("|"),
      "timeline_diff_row_count" => Map.get(artifact, "timeline_diff_row_count"),
      "timeline_diff_changed_count" => Map.get(artifact, "timeline_diff_changed_count"),
      "timeline_diff_review_required_count" =>
        Map.get(artifact, "timeline_diff_review_required_count"),
      "changed_field_counts" => Map.get(artifact, "changed_field_counts"),
      "changed_timeline_ids" =>
        artifact
        |> list_values("changed_timeline_ids")
        |> Enum.join("|"),
      "review_timeline_ids" =>
        artifact
        |> list_values("review_timeline_ids")
        |> Enum.join("|"),
      "timeline_ids_by_changed_field" => Map.get(artifact, "timeline_ids_by_changed_field"),
      "source_timeline_diff_row_count" => Map.get(source_timeline_diff_summary, "row_count"),
      "source_timeline_diff_review_required_count" =>
        Map.get(source_timeline_diff_summary, "review_required_count"),
      "source_timeline_diff_changed_count" =>
        Map.get(source_timeline_diff_summary, "changed_count"),
      "source_timeline_diff_changed_field_counts" =>
        Map.get(source_timeline_diff_summary, "changed_field_counts"),
      "source_timeline_diff_review_timeline_ids" =>
        source_timeline_diff_summary
        |> list_values("review_timeline_ids")
        |> Enum.join("|"),
      "source_timeline_diff_review_timeline_ids_by_required_operator_action" =>
        Map.get(
          source_timeline_diff_summary,
          "review_timeline_ids_by_required_operator_action"
        ),
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "notification_delivery" => get_in(artifact, ["assumptions", "notification_delivery"]),
      "assumption_publication_authority" =>
        get_in(artifact, ["assumptions", "publication_authority"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_command_execution" => "no_command_execution" in model_limits,
      "derived_identity_when_no_persistent_timeline_id" =>
        "derived_identity_when_no_persistent_timeline_id" in model_limits
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
