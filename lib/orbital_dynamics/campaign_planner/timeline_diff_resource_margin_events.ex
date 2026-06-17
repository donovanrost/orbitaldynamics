defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourceMarginEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceMarginFields

  def timeline_diff_changed_resource_margin_pressure_row?(row, policy, callbacks) do
    row["diff_status"] == "changed" and
      timeline_diff_changed_resource_margin_events(row, "timeline_diff", policy, callbacks) != []
  end

  def timeline_diff_changed_resource_margin_events(row, source_path, policy, callbacks) do
    evidence = TimelineDiffResourceMarginFields.evidence(row, callbacks)
    spacecraft_id = TimelineDiffResourceMarginFields.spacecraft_id(row, evidence)

    ["fuel_margin", "power_margin", "storage_margin", "downlink_margin", "thermal_margin_c"]
    |> Enum.flat_map(fn field ->
      value = callback!(callbacks, :numeric_or_nil).(evidence[field])

      threshold =
        TimelineDiffResourceMarginFields.threshold(evidence, policy, field, callbacks)

      if is_number(value) and is_number(threshold) and value <= threshold do
        [
          timeline_diff_changed_resource_margin_event(
            row,
            source_path,
            evidence,
            spacecraft_id,
            field,
            value,
            threshold,
            callbacks
          )
        ]
      else
        []
      end
    end)
  end

  defp timeline_diff_changed_resource_margin_event(
         row,
         source_path,
         evidence,
         spacecraft_id,
         field,
         value,
         threshold,
         callbacks
       ) do
    %{
      "type" => "resource_margin_pressure",
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      field => value * 1.0,
      "#{field}_threshold" => threshold,
      "temperature_c" => evidence["temperature_c"],
      "actual_temperature_c" => evidence["actual_temperature_c"],
      "measured_temperature_c" => evidence["measured_temperature_c"],
      "planned_temperature_c" => evidence["planned_temperature_c"],
      "min_operating_temperature_c" => evidence["min_operating_temperature_c"],
      "max_operating_temperature_c" => evidence["max_operating_temperature_c"],
      "thermal_status" => evidence["thermal_status"],
      "thermal_model" => evidence["thermal_model"],
      "thermal_source" => evidence["thermal_source"],
      "thermal_confidence" => evidence["thermal_confidence"],
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
        "timeline_diff_changed_resource_margin",
        "#{field}_timeline_diff_low"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => spacecraft_id,
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
