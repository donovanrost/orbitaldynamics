defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourceIdentityEvents do
  @moduledoc false

  def timeline_diff_changed_resource_identity_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      timeline_diff_changed_resource_identity_mismatch?(row, callbacks) and
      timeline_diff_changed_resource_identity_field(row, callbacks) not in [nil, ""]
  end

  def timeline_diff_changed_resource_identity_events(row, source_path, callbacks) do
    if timeline_diff_changed_resource_identity_pressure_row?(row, callbacks) do
      [timeline_diff_changed_resource_identity_event(row, source_path, callbacks)]
    else
      []
    end
  end

  defp timeline_diff_changed_resource_identity_event(row, source_path, callbacks) do
    field = timeline_diff_changed_resource_identity_field(row, callbacks)
    spacecraft_id = timeline_diff_changed_resource_identity_spacecraft_id(row, callbacks)
    planned_resource_id = timeline_diff_changed_planned_resource_id(row, callbacks)
    realized_resource_id = timeline_diff_changed_realized_resource_id(row, callbacks)

    %{
      "type" => "resource_availability_constraint",
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      field => false,
      "available" => false,
      "resource_id" => planned_resource_id || realized_resource_id,
      "planned_resource_id" => planned_resource_id,
      "realized_resource_id" => realized_resource_id,
      "resource_match_status" => "mismatch",
      "resource_identity_mismatch_fields" => ["resource"],
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
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
        "timeline_diff_changed_resource_identity",
        "resource_mismatch",
        "#{field}_timeline_diff_resource_mismatch"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => spacecraft_id,
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp timeline_diff_changed_resource_identity_mismatch?(row, callbacks) do
    case timeline_diff_changed_resource_identity_match_status(row, callbacks) do
      "mismatch" -> true
      _status -> false
    end
  end

  defp timeline_diff_changed_resource_identity_match_status(row, callbacks) do
    explicit =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "resource_match_status",
        "source_resource_match_status",
        "replacement_resource_match_status",
        ["source_activity_context", "resource_match_status"],
        ["replacement_activity_context", "resource_match_status"]
      ])
      |> callback!(callbacks, :normalized_status_token).()

    if explicit in ["matched", "mismatch", "planned_only", "realized_only"] do
      explicit
    else
      callback!(callbacks, :timeline_diff_match_status).(
        timeline_diff_changed_planned_resource_id(row, callbacks),
        timeline_diff_changed_realized_resource_id(row, callbacks)
      )
    end
  end

  defp timeline_diff_changed_planned_resource_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "planned_resource_id",
      "source_planned_resource_id",
      "source_resource_id",
      ["source_activity_context", "planned_resource_id"],
      ["source_activity_context", "resource_id"],
      ["source_activity_context", "resource", "resource_id"],
      ["source_activity_context", "resource", "id"]
    ])
  end

  defp timeline_diff_changed_realized_resource_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "realized_resource_id",
      "replacement_realized_resource_id",
      "replacement_resource_id",
      ["replacement_activity_context", "realized_resource_id"],
      ["replacement_activity_context", "resource_id"],
      ["replacement_activity_context", "resource", "resource_id"],
      ["replacement_activity_context", "resource", "id"]
    ])
  end

  defp timeline_diff_changed_resource_identity_field(row, callbacks) do
    cond do
      callback!(callbacks, :timeline_diff_changed_observation?).(row) ->
        "payload_available"

      callback!(callbacks, :timeline_diff_changed_downlink?).(row) or
        callback!(callbacks, :timeline_diff_changed_contact?).(row) or
          callback!(callbacks, :timeline_diff_changed_command?).(row) ->
        "antenna_available"

      callback!(callbacks, :timeline_diff_changed_maneuver?).(row) ->
        "spacecraft_available"

      true ->
        nil
    end
  end

  defp timeline_diff_changed_resource_identity_spacecraft_id(row, callbacks) do
    [
      row["spacecraft_id"],
      row["scenario_id"],
      get_in(row, ["source_activity_context", "spacecraft_id"]),
      get_in(row, ["source_activity_context", "scenario_id"]),
      get_in(row, ["replacement_activity_context", "spacecraft_id"]),
      get_in(row, ["replacement_activity_context", "scenario_id"])
    ]
    |> Enum.map(&callback!(callbacks, :encode_value).(&1))
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
