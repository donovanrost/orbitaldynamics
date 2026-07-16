defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffRemovedFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ProviderResultValues,
    ScalarValues,
    ScoreTermIdentifiers,
    TimelineDiffActivityFields
  }

  @realized_completion_statuses ~w(completed executed)

  def pressure_row?(row), do: pressure_row?(row, default_callbacks())

  def pressure_row?(row, callbacks) do
    row["diff_status"] == "removed" and
      row["source_status"] not in callback!(callbacks, :realized_completion_statuses).()
  end

  def events(row, source_path), do: events(row, source_path, default_callbacks())

  def events(row, source_path, callbacks) do
    row
    |> activity_type()
    |> case do
      "observe" ->
        [observation_event(row, source_path, callbacks)]

      type
      when type in [
             "downlink",
             "tracking",
             "command",
             "health_check",
             "maneuver",
             "impulsive_burn",
             "planned_contact",
             "contact"
           ] ->
        cond do
          downlink?(row) ->
            [downlink_event(row, source_path, callbacks)]

          command?(row) ->
            [command_event(row, source_path, callbacks)]

          contact?(row) ->
            [contact_event(row, source_path, callbacks)]

          maneuver?(row) ->
            [maneuver_event(row, source_path, callbacks)]

          true ->
            []
        end

      _type ->
        []
    end
  end

  defp activity_type(row) do
    row["source_activity_type"] ||
      get_in(row, ["source_activity_context", "activity_type"]) ||
      get_in(row, ["source_activity_context", "type"])
  end

  defp downlink?(row) do
    type = activity_type(row)
    direction = row["source_direction"] || get_in(row, ["source_activity_context", "direction"])

    type == "downlink" or (type in ["planned_contact", "contact"] and direction == "downlink")
  end

  defp contact?(row) do
    type = activity_type(row)
    direction = row["source_direction"] || get_in(row, ["source_activity_context", "direction"])

    type == "tracking" or (type in ["planned_contact", "contact"] and direction == "tracking")
  end

  defp command?(row) do
    type = activity_type(row)
    direction = row["source_direction"] || get_in(row, ["source_activity_context", "direction"])

    type in ["command", "health_check"] or
      (type in ["planned_contact", "contact"] and
         direction in ["command", "uplink", "health_check"])
  end

  defp maneuver?(row) do
    type = activity_type(row)

    operational_kind =
      row["source_operational_kind"] ||
        get_in(row, ["source_activity_context", "operational_kind"])

    type in ["maneuver", "impulsive_burn"] or operational_kind == "maneuver"
  end

  defp observation_event(row, source_path, callbacks) do
    %{
      "type" => "urgent_target",
      "objective_type" => "target_revisit",
      "target_id" => target_id(row, callbacks),
      "scenario_id" =>
        row["scenario_id"] || get_in(row, ["source_activity_context", "scenario_id"]),
      "required_observations" => 1,
      "planned_observations" => 0,
      "source_activity_id" => row["source_activity_id"],
      "source_activity_ids" => callback!(callbacks, :timeline_diff_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "required_operator_action" => row["required_operator_action"],
      "derivation_reason" => "timeline_diff_removed_observation",
      "derivation_reasons" => [
        "timeline_diff_removed_activity",
        "timeline_diff_removed_observation"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  defp downlink_event(row, source_path, callbacks) do
    %{
      "type" => "downlink_completion_gap",
      "scenario_id" =>
        row["scenario_id"] || get_in(row, ["source_activity_context", "scenario_id"]),
      "ground_station_id" => ground_station_id(row, callbacks),
      "starts_at_s" => window_start_s(row, callbacks),
      "ends_at_s" => window_end_s(row, callbacks),
      "required_contacts" => required_contacts(row, callbacks),
      "planned_contacts" => planned_contacts(row, callbacks),
      "required_downlink_mb" => downlink_mb(row, callbacks),
      "planned_downlink_mb" => 0.0,
      "source_activity_id" => row["source_activity_id"],
      "source_activity_ids" => callback!(callbacks, :timeline_diff_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "required_operator_action" => row["required_operator_action"],
      "derivation_reasons" => [
        "timeline_diff_removed_activity",
        "timeline_diff_removed_downlink"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  defp contact_event(row, source_path, callbacks) do
    %{
      "type" => "contact_success_feedback",
      "scenario_id" =>
        row["scenario_id"] || get_in(row, ["source_activity_context", "scenario_id"]),
      "ground_station_id" => ground_station_id(row, callbacks),
      "starts_at_s" => window_start_s(row, callbacks),
      "ends_at_s" => window_end_s(row, callbacks),
      "contact_success_factor" => 0.0,
      "contact_result" => contact_result(row, callbacks),
      "realized_status" => "missed",
      "source_activity_id" => row["source_activity_id"],
      "source_activity_ids" => callback!(callbacks, :timeline_diff_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "required_operator_action" => row["required_operator_action"],
      "derivation_reasons" => [
        "timeline_diff_removed_activity",
        "timeline_diff_removed_contact"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => ground_station_id(row, callbacks),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  defp command_event(row, source_path, callbacks) do
    %{
      "type" => "command_success_feedback",
      "activity_id" => row["source_activity_id"],
      "scenario_id" =>
        row["scenario_id"] || get_in(row, ["source_activity_context", "scenario_id"]),
      "starts_at_s" => window_start_s(row, callbacks),
      "ends_at_s" => window_end_s(row, callbacks),
      "command_success_factor" => 0.0,
      "command_result" => command_result(row, callbacks),
      "realized_status" => "missed",
      "source_activity_id" => row["source_activity_id"],
      "source_activity_ids" => callback!(callbacks, :timeline_diff_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "required_operator_action" => row["required_operator_action"],
      "derivation_reasons" => [
        "timeline_diff_removed_activity",
        "timeline_diff_removed_command"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => row["source_activity_id"],
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  defp maneuver_event(row, source_path, callbacks) do
    %{
      "type" => "maneuver_success_feedback",
      "activity_id" => row["source_activity_id"],
      "scenario_id" =>
        row["scenario_id"] || get_in(row, ["source_activity_context", "scenario_id"]),
      "starts_at_s" => window_start_s(row, callbacks),
      "ends_at_s" => window_end_s(row, callbacks),
      "maneuver_success_factor" => 0.0,
      "maneuver_result" => maneuver_result(row, callbacks),
      "realized_status" => "missed",
      "source_activity_id" => row["source_activity_id"],
      "source_activity_ids" => callback!(callbacks, :timeline_diff_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "required_operator_action" => row["required_operator_action"],
      "derivation_reasons" => [
        "timeline_diff_removed_activity",
        "timeline_diff_removed_maneuver"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => row["source_activity_id"],
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  defp contact_result(row, callbacks) do
    [
      row["source_contact_result"],
      row["contact_result"],
      get_in(row, ["source_activity_context", "contact_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp command_result(row, callbacks) do
    [
      row["source_command_result"],
      row["command_result"],
      get_in(row, ["source_activity_context", "command_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp maneuver_result(row, callbacks) do
    [
      row["source_maneuver_result"],
      row["maneuver_result"],
      get_in(row, ["source_activity_context", "maneuver_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp downlink_mb(row, callbacks) do
    [
      row["source_estimated_throughput_mb"],
      row["required_downlink_mb"],
      get_in(row, ["source_activity_context", "estimated_throughput_mb"]),
      get_in(row, ["source_activity_context", "planned_estimated_throughput_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_downlink_mb"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  defp target_id(row, callbacks) do
    source_context = Map.get(row, "source_activity_context", %{})

    [
      row["source_target_id"],
      callback!(callbacks, :score_term_entity_id).(row["source_target"], ["target_id", "id"]),
      get_in(row, ["source_activity_context", "target_id"]),
      callback!(callbacks, :score_term_entity_id).(source_context["target"], ["target_id", "id"])
    ]
    |> Enum.find(&callback!(callbacks, :stable_id_string?).(&1))
  end

  defp ground_station_id(row, callbacks) do
    source_context = Map.get(row, "source_activity_context", %{})

    [
      row["source_ground_station_id"],
      callback!(callbacks, :score_term_entity_id).(row["source_ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      get_in(row, ["source_activity_context", "ground_station_id"]),
      get_in(row, ["source_activity_context", "station_id"]),
      callback!(callbacks, :score_term_entity_id).(source_context["ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(source_context["station"], [
        "ground_station_id",
        "station_id",
        "id"
      ])
    ]
    |> Enum.find(&callback!(callbacks, :stable_id_string?).(&1))
  end

  defp window_start_s(row, callbacks) do
    [
      row["source_starts_at_s"],
      row["starts_at_s"],
      row["start_s"],
      get_in(row, ["source_activity_context", "starts_at_s"]),
      get_in(row, ["source_activity_context", "start_s"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  defp window_end_s(row, callbacks) do
    [
      row["source_ends_at_s"],
      row["ends_at_s"],
      row["end_s"],
      get_in(row, ["source_activity_context", "ends_at_s"]),
      get_in(row, ["source_activity_context", "end_s"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  defp required_contacts(row, callbacks) do
    [
      row["required_contacts"],
      row["required_contact_count"],
      get_in(row, ["source_activity_context", "required_contacts"]),
      get_in(row, ["source_activity_context", "required_contact_count"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 1
    end
  end

  defp planned_contacts(row, callbacks) do
    [
      row["planned_contacts"],
      row["planned_contact_count"],
      get_in(row, ["source_activity_context", "planned_contacts"]),
      get_in(row, ["source_activity_context", "planned_contact_count"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 0
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      realized_completion_statuses: fn -> @realized_completion_statuses end,
      timeline_diff_source_activity_ids: &TimelineDiffActivityFields.source_activity_ids/1,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      stable_id_string?: &ScalarValues.stable_id_string?/1
    ]
  end
end
