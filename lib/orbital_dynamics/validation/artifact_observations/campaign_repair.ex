defmodule OrbitalDynamics.Validation.ArtifactObservations.CampaignRepair do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    candidate_rejection_report = map_field(artifact, "source_candidate_rejection_report")
    operator_review_package = map_field(artifact, "operator_review_package")
    cadence_import_manifest = map_field(artifact, "cadence_import_manifest")
    cadence_import_rows = list_values(cadence_import_manifest, "rows")

    %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "planner" => Map.get(artifact, "planner"),
      "activity_count" => count(artifact, "activities"),
      "delta_count" => count(artifact, "deltas"),
      "approval_requirement_count" => count(artifact, "approval_requirements"),
      "source_candidate_count" => count(artifact, "source_candidate_activities"),
      "source_candidate_rejection_report_count" =>
        if(map_size(candidate_rejection_report) > 0, do: 1, else: 0),
      "source_candidate_rejection_row_count" => count(candidate_rejection_report, "rows"),
      "source_candidate_rejection_rejected_count" =>
        Map.get(candidate_rejection_report, "rejected_count"),
      "source_candidate_rejection_reviewable_count" =>
        Map.get(candidate_rejection_report, "reviewable_count"),
      "source_contact_intent_count" => count(artifact, "source_contact_intents"),
      "source_resource_summary_count" => count(artifact, "source_resource_summaries"),
      "operator_review_candidate_rejection_review_count" =>
        Map.get(operator_review_package, "candidate_rejection_review_count"),
      "cadence_import_candidate_rejection_row_count" =>
        Enum.count(
          cadence_import_rows,
          &(&1["source_review_type"] == "candidate_rejection_review")
        ),
      "warning_count" => count(artifact, "warnings"),
      "policy_decision_contract" => get_in(artifact, ["policy_decision", "schema_contract"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_field(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
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
