defmodule OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback do
  @moduledoc false

  @context_keys [
    "execution_success_feedback_risk_types",
    "execution_success_feedback_activity_ids",
    "execution_success_feedback_scenario_ids",
    "execution_success_feedback_timeline_ids",
    "execution_success_feedback_source_activity_ids",
    "execution_success_feedback_replacement_activity_ids",
    "execution_success_feedback_command_success_factor_values",
    "execution_success_feedback_maneuver_success_factor_values",
    "execution_success_feedback_command_results",
    "execution_success_feedback_maneuver_results",
    "execution_success_feedback_realized_statuses",
    "execution_success_feedback_ground_station_ids",
    "execution_success_feedback_planned_ground_station_ids",
    "execution_success_feedback_realized_ground_station_ids",
    "execution_success_feedback_ground_station_match_statuses",
    "execution_success_feedback_directions",
    "execution_success_feedback_planned_directions",
    "execution_success_feedback_realized_directions",
    "execution_success_feedback_direction_match_statuses",
    "execution_success_feedback_source_window_ids",
    "execution_success_feedback_planned_source_window_ids",
    "execution_success_feedback_realized_source_window_ids",
    "execution_success_feedback_source_window_match_statuses",
    "execution_success_feedback_command_identity_mismatch_fields",
    "execution_success_feedback_start_values_s",
    "execution_success_feedback_end_values_s",
    "execution_success_feedback_changed_fields",
    "execution_success_feedback_status_transition_maps",
    "execution_success_feedback_transition_types",
    "execution_success_feedback_transition_categories",
    "execution_success_feedback_transition_reasons",
    "execution_success_feedback_required_operator_actions",
    "execution_success_feedback_requires_operator_review_values",
    "execution_success_feedback_feedback_sources",
    "execution_success_feedback_feedback_scopes",
    "execution_success_feedback_feedback_keys",
    "execution_success_feedback_trust_boundaries",
    "execution_success_feedback_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    execution_success_feedback_risks =
      Enum.filter(risks, &execution_success_feedback_risk?/1)

    %{
      "execution_success_feedback_risk_types" =>
        risk_context_values(execution_success_feedback_risks, ["type", "risk_type"]),
      "execution_success_feedback_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, "activity_id"),
      "execution_success_feedback_scenario_ids" =>
        risk_context_values(execution_success_feedback_risks, "scenario_id"),
      "execution_success_feedback_timeline_ids" =>
        risk_context_values(execution_success_feedback_risks, "timeline_id"),
      "execution_success_feedback_source_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "execution_success_feedback_replacement_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, "replacement_activity_id"),
      "execution_success_feedback_command_success_factor_values" =>
        risk_context_values(execution_success_feedback_risks, "command_success_factor"),
      "execution_success_feedback_maneuver_success_factor_values" =>
        risk_context_values(execution_success_feedback_risks, "maneuver_success_factor"),
      "execution_success_feedback_command_results" =>
        risk_context_values(execution_success_feedback_risks, "command_result"),
      "execution_success_feedback_maneuver_results" =>
        risk_context_values(execution_success_feedback_risks, "maneuver_result"),
      "execution_success_feedback_realized_statuses" =>
        risk_context_values(execution_success_feedback_risks, "realized_status"),
      "execution_success_feedback_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "ground_station_id"),
      "execution_success_feedback_planned_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "planned_ground_station_id"),
      "execution_success_feedback_realized_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "realized_ground_station_id"),
      "execution_success_feedback_ground_station_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "ground_station_match_status"),
      "execution_success_feedback_directions" =>
        risk_context_values(execution_success_feedback_risks, "direction"),
      "execution_success_feedback_planned_directions" =>
        risk_context_values(execution_success_feedback_risks, "planned_direction"),
      "execution_success_feedback_realized_directions" =>
        risk_context_values(execution_success_feedback_risks, "realized_direction"),
      "execution_success_feedback_direction_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "direction_match_status"),
      "execution_success_feedback_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "source_window_id"),
      "execution_success_feedback_planned_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "planned_source_window_id"),
      "execution_success_feedback_realized_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "realized_source_window_id"),
      "execution_success_feedback_source_window_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "source_window_match_status"),
      "execution_success_feedback_command_identity_mismatch_fields" =>
        risk_context_values(execution_success_feedback_risks, [
          "command_identity_mismatch_fields"
        ]),
      "execution_success_feedback_start_values_s" =>
        risk_context_values(execution_success_feedback_risks, "starts_at_s"),
      "execution_success_feedback_end_values_s" =>
        risk_context_values(execution_success_feedback_risks, "ends_at_s"),
      "execution_success_feedback_changed_fields" =>
        risk_context_values(execution_success_feedback_risks, ["changed_fields"]),
      "execution_success_feedback_status_transition_maps" =>
        risk_context_values(execution_success_feedback_risks, "status_transition"),
      "execution_success_feedback_transition_types" =>
        risk_context_values(execution_success_feedback_risks, "transition_type"),
      "execution_success_feedback_transition_categories" =>
        risk_context_values(execution_success_feedback_risks, "transition_category"),
      "execution_success_feedback_transition_reasons" =>
        risk_context_values(execution_success_feedback_risks, "transition_reason"),
      "execution_success_feedback_required_operator_actions" =>
        risk_context_values(execution_success_feedback_risks, "required_operator_action"),
      "execution_success_feedback_requires_operator_review_values" =>
        risk_context_values(execution_success_feedback_risks, "requires_operator_review"),
      "execution_success_feedback_feedback_sources" =>
        risk_context_values(execution_success_feedback_risks, "feedback_source"),
      "execution_success_feedback_feedback_scopes" =>
        risk_context_values(execution_success_feedback_risks, "feedback_scope"),
      "execution_success_feedback_feedback_keys" =>
        risk_context_values(execution_success_feedback_risks, "feedback_key"),
      "execution_success_feedback_trust_boundaries" =>
        risk_context_values(execution_success_feedback_risks, "trust_boundary"),
      "execution_success_feedback_derivation_reasons" =>
        risk_context_values(execution_success_feedback_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp execution_success_feedback_risk?(%{"type" => type}) when is_binary(type) do
    type in ["command_success_rate_low", "maneuver_success_rate_low"]
  end

  defp execution_success_feedback_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in ["command_success_rate_low", "maneuver_success_rate_low"]
  end

  defp execution_success_feedback_risk?(_risk), do: false

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
