defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffDownlinkFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ScalarValues,
    TimelineDiffActivityFields,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def pressure_row?(row), do: pressure_row?(row, default_callbacks())

  def pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and downlink?(row) and gap?(row, callbacks)
  end

  def downlink?(row) do
    type =
      row["replacement_activity_type"] || row["source_activity_type"] ||
        get_in(row, ["replacement_activity_context", "activity_type"]) ||
        get_in(row, ["replacement_activity_context", "type"]) ||
        get_in(row, ["source_activity_context", "activity_type"]) ||
        get_in(row, ["source_activity_context", "type"])

    direction =
      row["replacement_direction"] || row["source_direction"] ||
        get_in(row, ["replacement_activity_context", "direction"]) ||
        get_in(row, ["source_activity_context", "direction"])

    type == "downlink" or (type in ["planned_contact", "contact"] and direction == "downlink")
  end

  def gap?(row), do: gap?(row, default_callbacks())

  def gap?(row, callbacks) do
    planned = planned_mb(row, callbacks)
    required = required_mb(row, callbacks)
    shortfall = shortfall_mb(row, callbacks)

    callback!(callbacks, :positive_number?).(shortfall) or
      (is_number(required) and is_number(planned) and planned < required)
  end

  def event(row, source_path), do: event(row, source_path, default_callbacks())

  def event(row, source_path, callbacks) do
    planned_downlink_mb = planned_mb(row, callbacks)
    required_downlink_mb = required_mb(row, callbacks)
    shortfall = shortfall_mb(row, callbacks)

    required_downlink_mb =
      case {required_downlink_mb, planned_downlink_mb, shortfall} do
        {value, _planned, _shortfall} when is_number(value) ->
          value

        {_required, planned, value} when is_number(planned) and is_number(value) ->
          planned + value

        {_required, _planned, value} ->
          value
      end

    %{
      "type" => "downlink_completion_gap",
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "required_contacts" => callback!(callbacks, :timeline_diff_changed_required_contacts).(row),
      "planned_contacts" => callback!(callbacks, :timeline_diff_changed_planned_contacts).(row),
      "required_downlink_mb" => required_downlink_mb,
      "planned_downlink_mb" => planned_downlink_mb,
      "downlink_shortfall_mb" => shortfall,
      "downlink_demand_sources" => demand_sources(row, callbacks),
      "downlink_completion_sources" => completion_sources(row, callbacks),
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_ids" =>
        callback!(callbacks, :timeline_diff_changed_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "changed_fields" => row["changed_fields"],
      "required_operator_action" => row["required_operator_action"],
      "status_transition" => callback!(callbacks, :timeline_diff_changed_status_transition).(row),
      "transition_type" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(row, "transition_type"),
      "transition_category" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(row, "transition_category"),
      "transition_reason" => callback!(callbacks, :timeline_diff_changed_transition_reason).(row),
      "requires_operator_review" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(
          row,
          "requires_operator_review"
        ),
      "derivation_reasons" => [
        "timeline_diff_changed_activity",
        "timeline_diff_changed_downlink_completion"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  def required_mb(row), do: required_mb(row, default_callbacks())

  def required_mb(row, callbacks) do
    [
      row["required_downlink_mb"],
      row["target_downlink_mb"],
      row["downlink_requirement_mb"],
      row["required_volume_mb"],
      row["required_data_volume_mb"],
      row["target_volume_mb"],
      row["target_data_volume_mb"],
      row["min_downlink_mb"],
      row["replacement_required_downlink_mb"],
      row["replacement_target_downlink_mb"],
      row["replacement_downlink_requirement_mb"],
      row["replacement_required_volume_mb"],
      row["replacement_required_data_volume_mb"],
      row["replacement_target_volume_mb"],
      row["replacement_target_data_volume_mb"],
      row["replacement_min_downlink_mb"],
      get_in(row, ["replacement_activity_context", "required_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "target_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "downlink_requirement_mb"]),
      get_in(row, ["replacement_activity_context", "required_volume_mb"]),
      get_in(row, ["replacement_activity_context", "required_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "target_volume_mb"]),
      get_in(row, ["replacement_activity_context", "target_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "min_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "required_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "target_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "downlink_requirement_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "required_volume_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "required_data_volume_mb"
      ]),
      get_in(row, ["replacement_activity_context", "throughput_model", "target_volume_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "target_data_volume_mb"
      ]),
      get_in(row, ["replacement_activity_context", "throughput_model", "min_downlink_mb"]),
      row["source_required_downlink_mb"],
      row["source_target_downlink_mb"],
      row["source_downlink_requirement_mb"],
      row["source_required_volume_mb"],
      row["source_required_data_volume_mb"],
      row["source_target_volume_mb"],
      row["source_target_data_volume_mb"],
      row["source_min_downlink_mb"],
      get_in(row, ["source_activity_context", "required_downlink_mb"]),
      get_in(row, ["source_activity_context", "target_downlink_mb"]),
      get_in(row, ["source_activity_context", "downlink_requirement_mb"]),
      get_in(row, ["source_activity_context", "required_volume_mb"]),
      get_in(row, ["source_activity_context", "required_data_volume_mb"]),
      get_in(row, ["source_activity_context", "target_volume_mb"]),
      get_in(row, ["source_activity_context", "target_data_volume_mb"]),
      get_in(row, ["source_activity_context", "min_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "target_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "downlink_requirement_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_volume_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_data_volume_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "target_volume_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "target_data_volume_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "min_downlink_mb"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def planned_mb(row), do: planned_mb(row, default_callbacks())

  def planned_mb(row, callbacks) do
    [
      row["planned_downlink_mb"],
      row["selected_downlink_mb"],
      row["actual_downlink_mb"],
      row["planned_data_volume_mb"],
      row["selected_data_volume_mb"],
      row["actual_data_volume_mb"],
      row["delivered_data_volume_mb"],
      row["received_data_volume_mb"],
      row["planned_volume_mb"],
      row["selected_volume_mb"],
      row["actual_volume_mb"],
      row["replacement_planned_downlink_mb"],
      row["replacement_selected_downlink_mb"],
      row["replacement_actual_downlink_mb"],
      row["replacement_delivered_downlink_mb"],
      row["replacement_estimated_throughput_mb"],
      row["replacement_planned_data_volume_mb"],
      row["replacement_selected_data_volume_mb"],
      row["replacement_actual_data_volume_mb"],
      row["replacement_delivered_data_volume_mb"],
      row["replacement_received_data_volume_mb"],
      row["replacement_planned_volume_mb"],
      row["replacement_selected_volume_mb"],
      row["replacement_actual_volume_mb"],
      get_in(row, ["replacement_activity_context", "planned_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "selected_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "actual_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "delivered_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "estimated_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "planned_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "selected_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "actual_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "delivered_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "received_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "planned_volume_mb"]),
      get_in(row, ["replacement_activity_context", "selected_volume_mb"]),
      get_in(row, ["replacement_activity_context", "actual_volume_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "planned_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "selected_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "actual_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "delivered_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "estimated_throughput_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "planned_data_volume_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "selected_data_volume_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "actual_data_volume_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "delivered_data_volume_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "received_data_volume_mb"
      ]),
      get_in(row, ["replacement_activity_context", "throughput_model", "planned_volume_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "selected_volume_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "actual_volume_mb"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def shortfall_mb(row), do: shortfall_mb(row, default_callbacks())

  def shortfall_mb(row, callbacks) do
    [
      row["downlink_shortfall_mb"],
      row["selected_downlink_shortfall_mb"],
      row["actual_downlink_shortfall_mb"],
      row["data_volume_shortfall_mb"],
      row["selected_data_volume_shortfall_mb"],
      row["actual_data_volume_shortfall_mb"],
      row["missing_data_volume_mb"],
      row["required_data_volume_gap_mb"],
      row["replacement_downlink_shortfall_mb"],
      row["replacement_selected_downlink_shortfall_mb"],
      row["replacement_actual_downlink_shortfall_mb"],
      row["replacement_data_volume_shortfall_mb"],
      row["replacement_selected_data_volume_shortfall_mb"],
      row["replacement_actual_data_volume_shortfall_mb"],
      row["replacement_missing_data_volume_mb"],
      row["replacement_required_data_volume_gap_mb"],
      get_in(row, ["replacement_activity_context", "downlink_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "selected_downlink_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "actual_downlink_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "data_volume_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["replacement_activity_context", "missing_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "required_data_volume_gap_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "downlink_shortfall_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "selected_downlink_shortfall_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "actual_downlink_shortfall_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "data_volume_shortfall_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "selected_data_volume_shortfall_mb"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "actual_data_volume_shortfall_mb"
      ]),
      get_in(row, ["replacement_activity_context", "throughput_model", "missing_data_volume_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "required_data_volume_gap_mb"
      ])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&callback!(callbacks, :positive_number?).(&1))
  end

  def demand_sources(row), do: demand_sources(row, default_callbacks())

  def demand_sources(row, callbacks) do
    sources =
      [
        row["downlink_demand_source"],
        row["downlink_demand_sources"],
        get_in(row, ["throughput_model", "downlink_demand_source"]),
        get_in(row, ["throughput_model", "downlink_demand_sources"]),
        get_in(row, ["replacement_activity_context", "downlink_demand_source"]),
        get_in(row, ["replacement_activity_context", "downlink_demand_sources"]),
        get_in(row, ["replacement_activity_context", "throughput_model", "downlink_demand_source"]),
        get_in(row, [
          "replacement_activity_context",
          "throughput_model",
          "downlink_demand_sources"
        ]),
        get_in(row, ["source_activity_context", "downlink_demand_source"]),
        get_in(row, ["source_activity_context", "downlink_demand_sources"]),
        get_in(row, ["source_activity_context", "throughput_model", "downlink_demand_source"]),
        get_in(row, ["source_activity_context", "throughput_model", "downlink_demand_sources"])
      ]
      |> source_list(callbacks)

    case sources do
      nil -> completion_sources(row, callbacks)
      sources -> sources
    end
  end

  def completion_sources(row), do: completion_sources(row, default_callbacks())

  def completion_sources(row, callbacks) do
    [
      row["downlink_completion_source"],
      row["downlink_completion_sources"],
      get_in(row, ["throughput_model", "downlink_completion_source"]),
      get_in(row, ["throughput_model", "downlink_completion_sources"]),
      get_in(row, ["replacement_activity_context", "downlink_completion_source"]),
      get_in(row, ["replacement_activity_context", "downlink_completion_sources"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "downlink_completion_source"
      ]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "downlink_completion_sources"
      ]),
      get_in(row, ["source_activity_context", "downlink_completion_source"]),
      get_in(row, ["source_activity_context", "downlink_completion_sources"]),
      get_in(row, ["source_activity_context", "throughput_model", "downlink_completion_source"]),
      get_in(row, ["source_activity_context", "throughput_model", "downlink_completion_sources"])
    ]
    |> source_list(callbacks)
  end

  defp source_list(values, callbacks) do
    values
    |> List.flatten()
    |> Enum.map(&callback!(callbacks, :encode_value).(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      sources -> sources
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      positive_number?: &ScalarValues.positive_number?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_ground_station_id: &TimelineDiffActivityFields.ground_station_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_required_contacts: &TimelineDiffActivityFields.required_contacts/1,
      timeline_diff_changed_planned_contacts: &TimelineDiffActivityFields.planned_contacts/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end
end
