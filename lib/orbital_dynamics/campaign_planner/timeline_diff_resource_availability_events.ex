defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourceAvailabilityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceAvailabilityEvidence

  def timeline_diff_changed_resource_availability_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      timeline_diff_changed_resource_availability_events(row, "timeline_diff", callbacks) != []
  end

  def timeline_diff_changed_resource_availability_events(row, source_path, callbacks) do
    evidence = TimelineDiffResourceAvailabilityEvidence.evidence(row, callbacks)
    spacecraft_id = TimelineDiffResourceAvailabilityEvidence.spacecraft_id(row, evidence)

    ["spacecraft_available", "payload_available", "antenna_available"]
    |> Enum.filter(&(Map.get(evidence, &1) == false))
    |> Enum.map(fn field ->
      timeline_diff_changed_resource_availability_event(
        row,
        source_path,
        evidence,
        spacecraft_id,
        field,
        callbacks
      )
    end)
  end

  defp timeline_diff_changed_resource_availability_event(
         row,
         source_path,
         evidence,
         spacecraft_id,
         field,
         callbacks
       ) do
    %{
      "type" => "resource_availability_constraint",
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      field => false,
      "available" => false,
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
      "degraded" => evidence["degraded"],
      "mode" => evidence["mode"],
      "incompatible_activity_types" =>
        evidence["incompatible_activity_types"] || evidence["suppressed_activity_types"],
      "derivation_reasons" => [
        "timeline_diff_changed_activity",
        "timeline_diff_changed_resource_availability",
        "#{field}_timeline_diff_false"
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
