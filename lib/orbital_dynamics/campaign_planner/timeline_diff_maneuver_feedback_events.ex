defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffManeuverFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    ManeuverReviewExecutionUncertainty,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    ScalarValues,
    TimelineDiffActivityFields,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def pressure_row?(row), do: pressure_row?(row, default_callbacks())

  def pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and maneuver?(row) and
      (gap?(row, callbacks) or uncertainty_gap?(row, callbacks))
  end

  def maneuver?(row) do
    type =
      row["replacement_activity_type"] || row["source_activity_type"] ||
        get_in(row, ["replacement_activity_context", "activity_type"]) ||
        get_in(row, ["replacement_activity_context", "type"]) ||
        get_in(row, ["source_activity_context", "activity_type"]) ||
        get_in(row, ["source_activity_context", "type"])

    operational_kind =
      row["replacement_operational_kind"] || row["source_operational_kind"] ||
        get_in(row, ["replacement_activity_context", "operational_kind"]) ||
        get_in(row, ["source_activity_context", "operational_kind"])

    type in ["maneuver", "impulsive_burn"] or operational_kind == "maneuver"
  end

  def gap?(row), do: gap?(row, default_callbacks())

  def gap?(row, callbacks) do
    case success_factor(row, callbacks) do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  def uncertainty_gap?(row), do: uncertainty_gap?(row, default_callbacks())

  def uncertainty_gap?(row, callbacks) do
    execution_uncertainty_entry(row, callbacks) != %{}
  end

  def events(row, source_path), do: events(row, source_path, default_callbacks())

  def events(row, source_path, callbacks) do
    [
      if(gap?(row, callbacks),
        do: event(row, source_path, callbacks)
      ),
      if(uncertainty_gap?(row, callbacks),
        do: uncertainty_event(row, source_path, callbacks)
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  def event(row, source_path), do: event(row, source_path, default_callbacks())

  def event(row, source_path, callbacks) do
    %{
      "type" => "maneuver_success_feedback",
      "activity_id" => row["source_activity_id"] || row["replacement_activity_id"],
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "maneuver_success_factor" => success_factor(row, callbacks),
      "maneuver_result" => result(row, callbacks),
      "realized_status" => callback!(callbacks, :timeline_diff_changed_realized_status).(row),
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
        "timeline_diff_changed_maneuver"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => row["source_activity_id"] || row["replacement_activity_id"],
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  def uncertainty_event(row, source_path),
    do: uncertainty_event(row, source_path, default_callbacks())

  def uncertainty_event(row, source_path, callbacks) do
    entry = execution_uncertainty_entry(row, callbacks)

    if entry == %{} do
      nil
    else
      %{
        "type" => "maneuver_execution_uncertainty_feedback",
        "activity_id" => row["source_activity_id"] || row["replacement_activity_id"],
        "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
        "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
        "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
        "execution_uncertainty_status" => entry["execution_uncertainty_status"],
        "execution_uncertainty" => entry["execution_uncertainty"],
        "timing_3sigma_s" => entry["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => entry["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => entry["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => entry["execution_uncertainty_source"],
        "source_activity_id" => row["source_activity_id"],
        "replacement_activity_id" => row["replacement_activity_id"],
        "source_activity_ids" =>
          callback!(callbacks, :timeline_diff_changed_source_activity_ids).(row),
        "timeline_id" => row["timeline_id"],
        "maneuver_id" =>
          row["maneuver_id"] ||
            get_in(row, ["replacement_activity_context", "maneuver_id"]) ||
            get_in(row, ["source_activity_context", "maneuver_id"]),
        "diff_status" => row["diff_status"],
        "changed_fields" => row["changed_fields"],
        "required_operator_action" => row["required_operator_action"],
        "status_transition" =>
          callback!(callbacks, :timeline_diff_changed_status_transition).(row),
        "transition_type" =>
          callback!(callbacks, :timeline_diff_changed_transition_field).(row, "transition_type"),
        "transition_category" =>
          callback!(callbacks, :timeline_diff_changed_transition_field).(
            row,
            "transition_category"
          ),
        "transition_reason" =>
          callback!(callbacks, :timeline_diff_changed_transition_reason).(row),
        "requires_operator_review" =>
          callback!(callbacks, :timeline_diff_changed_transition_field).(
            row,
            "requires_operator_review"
          ),
        "derivation_reasons" => [
          "timeline_diff_changed_activity",
          "timeline_diff_changed_maneuver_uncertainty"
        ],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_diff",
        "feedback_key" => row["source_activity_id"] || row["replacement_activity_id"],
        "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
      }
      |> callback!(callbacks, :compact_map).()
    end
  end

  def success_factor(row), do: success_factor(row, default_callbacks())

  def success_factor(row, callbacks) do
    [
      row["maneuver_success_factor"],
      row["replacement_maneuver_success_factor"],
      get_in(row, ["replacement_activity_context", "maneuver_success_factor"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        callback!(callbacks, :clamp_unit_interval).(value)

      _value ->
        row
        |> callback!(callbacks, :timeline_diff_changed_replacement_evidence).()
        |> callback!(callbacks, :maneuver_success_value).()
    end
  end

  def result(row), do: result(row, default_callbacks())

  def result(row, callbacks) do
    [
      row["replacement_maneuver_result"],
      get_in(row, ["replacement_activity_context", "maneuver_result"]),
      row["maneuver_result"],
      row["source_maneuver_result"],
      get_in(row, ["source_activity_context", "maneuver_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  def execution_uncertainty_entry(row), do: execution_uncertainty_entry(row, default_callbacks())

  def execution_uncertainty_entry(row, callbacks) do
    [
      uncertainty_evidence(row, "replacement", callbacks),
      uncertainty_evidence(row, nil, callbacks),
      uncertainty_evidence(row, "source", callbacks)
    ]
    |> Enum.map(&callback!(callbacks, :maneuver_review_execution_uncertainty_entry).(&1))
    |> Enum.find(&(&1 != %{}))
    |> case do
      nil -> %{}
      entry -> entry
    end
  end

  defp uncertainty_evidence(row, nil, _callbacks), do: row

  defp uncertainty_evidence(row, side, callbacks) do
    context =
      callback!(callbacks, :stringify_keys).(row["#{side}_activity_context"] || %{})

    row
    |> Map.merge(context)
    |> callback!(callbacks, :put_default_if_present).(
      "execution_uncertainty",
      row["#{side}_execution_uncertainty"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "execution_uncertainty_status",
      row["#{side}_execution_uncertainty_status"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "timing_3sigma_s",
      row["#{side}_timing_3sigma_s"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "delta_v_3sigma_km_s",
      row["#{side}_delta_v_3sigma_km_s"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "delta_v_3sigma_magnitude_km_s",
      row["#{side}_delta_v_3sigma_magnitude_km_s"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "execution_uncertainty_source",
      row["#{side}_execution_uncertainty_source"]
    )
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_changed_replacement_evidence:
        &TimelineDiffActivityFields.replacement_evidence/1,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1,
      maneuver_review_execution_uncertainty_entry: &ManeuverReviewExecutionUncertainty.entry/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      put_default_if_present: &put_default_if_present/3
    ]
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    Map.put_new(map, field, value)
  end
end
