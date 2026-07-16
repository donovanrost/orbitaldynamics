defmodule OrbitalDynamics.Validation.ArtifactObservations.CampaignStrategy do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    score_term_observations = embedded_score_term_report_observations(artifact)

    base_observations = %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "planner" => Map.get(artifact, "planner"),
      "branch_count" => count(artifact, "branches"),
      "recommended_branch_id" => get_in(artifact, ["recommendation", "recommended_branch_id"]),
      "ranked_branch_count" =>
        count(get_in(artifact, ["recommendation"]) || %{}, "ranked_branch_ids"),
      "approval_status" => get_in(artifact, ["recommendation", "approval_status"]),
      "warning_count" => count(artifact, "warnings")
    }

    Map.merge(base_observations, %{
      "score_term_report_model" => Map.get(score_term_observations, "model"),
      "score_term_report_source" => Map.get(score_term_observations, "source"),
      "score_term_report_row_count" => Map.get(score_term_observations, "row_count"),
      "score_term_report_derived_row_count" =>
        Map.get(score_term_observations, "derived_row_count"),
      "score_term_report_selected_row_count" =>
        Map.get(score_term_observations, "selected_row_count"),
      "score_term_report_key_count" => Map.get(score_term_observations, "score_term_key_count"),
      "score_term_report_key_counts" =>
        Map.get(score_term_observations, "score_term_key_counts") || %{},
      "score_term_report_row_derived_key_counts" =>
        Map.get(score_term_observations, "row_derived_score_term_key_counts") || %{},
      "score_term_report_validation_refresh_pressure_row_count" =>
        get_in(score_term_observations, [
          "row_derived_score_term_key_counts",
          "validation_refresh_pressure_penalty"
        ]),
      "score_term_report_score_term_source" =>
        Map.get(score_term_observations, "score_term_source"),
      "score_term_report_model_limit_count" =>
        Map.get(score_term_observations, "model_limit_count")
    })
  end

  defp embedded_score_term_report_observations(%{"score_term_report" => %{} = report}) do
    OrbitalDynamics.Validation.artifact_observations("score_term_report.v1", report)
  end

  defp embedded_score_term_report_observations(_artifact), do: %{}

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
