defmodule OrbitalDynamics.Validation.ArtifactObservations.ResultArtifact do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    campaign_plan = map_field(artifact, "campaign_plan")
    candidate_refresh = map_field(artifact, "candidate_refresh")
    execution_report = map_field(artifact, "execution_report")
    payload_metrics = map_field(artifact, "payload_metrics")
    run = map_field(artifact, "run")

    %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "study_id" => Map.get(artifact, "study_id"),
      "top_level_key_count" => map_size(artifact),
      "trajectory_count" => count(artifact, "trajectories"),
      "access_window_count" => count(artifact, "access_windows"),
      "eclipse_interval_count" => count(artifact, "eclipse_intervals"),
      "target_visibility_window_count" => count(artifact, "target_visibility_windows"),
      "ground_track_crossing_count" => count(artifact, "ground_track_crossings"),
      "maneuver_recommendation_count" => count(artifact, "maneuver_recommendations"),
      "error_count" => count(artifact, "errors"),
      "has_campaign_plan" => map_size(campaign_plan) > 0,
      "has_candidate_refresh" => map_size(candidate_refresh) > 0,
      "has_constraint_report" => map_size(map_field(artifact, "constraint_report")) > 0,
      "has_maneuver_review_report" => map_size(map_field(artifact, "maneuver_review_report")) > 0,
      "has_monte_carlo_reproducibility_report" =>
        map_size(map_field(artifact, "monte_carlo_reproducibility_report")) > 0,
      "campaign_activity_count" => count(campaign_plan, "activities"),
      "campaign_proposed_contact_count" => count(campaign_plan, "proposed_contacts"),
      "campaign_contact_intent_count" => count(campaign_plan, "contact_intents"),
      "campaign_candidate_activity_count" => count(campaign_plan, "candidate_activities"),
      "campaign_ranked_timeline_count" => count(campaign_plan, "ranked_timelines"),
      "candidate_refresh_candidate_activity_count" =>
        count(candidate_refresh, "candidate_activities"),
      "candidate_refresh_contact_intent_count" => count(candidate_refresh, "contact_intents"),
      "candidate_refresh_refreshed_window_count" =>
        count_collection(candidate_refresh, "refreshed_windows"),
      "candidate_refresh_warning_count" => count(candidate_refresh, "warnings"),
      "execution_report_status" => Map.get(execution_report, "status"),
      "execution_report_scenario_count" => count(execution_report, "scenarios"),
      "execution_report_declared_scenario_count" => Map.get(execution_report, "scenario_count"),
      "execution_report_failed_scenario_count" =>
        Map.get(execution_report, "failed_scenario_count"),
      "payload_metrics_contract" => Map.get(payload_metrics, "schema_contract"),
      "payload_metrics_top_level_key_count" => Map.get(payload_metrics, "top_level_key_count"),
      "payload_metrics_section_count" => count_collection(payload_metrics, "sections"),
      "payload_metrics_artifact_body_bytes" => Map.get(payload_metrics, "artifact_body_bytes"),
      "run_status" => Map.get(run, "status"),
      "run_study_id" => Map.get(run, "study_id"),
      "run_scenario_count" => get_in(run, ["metadata", "scenario_count"]),
      "run_trajectory_count" => get_in(run, ["metadata", "trajectory_count"]),
      "run_event_result_count" => get_in(run, ["metadata", "event_result_count"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
      _value -> 0
    end
  end

  defp map_field(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
