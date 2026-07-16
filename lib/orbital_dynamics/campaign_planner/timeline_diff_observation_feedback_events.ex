defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    ObservationFeedbackEvents,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    ScalarValues,
    ScoreTermIdentifiers,
    TargetPriorityFeedbackEvents,
    TimelineDiffActivityFields,
    TimelineDiffFieldValues,
    TimelineDiffObservationIdentityEvents,
    TimelineDiffObservationLightingEvents,
    TimelineDiffObservationOutcomeEvents,
    TimelineDiffObservationPointingEvents,
    TimelineDiffObservationPriorityEvents,
    TimelineDiffObservationQualityEvents,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def pressure_row?(row, policy), do: pressure_row?(row, policy, default_callbacks())

  def pressure_row?(row, policy, callbacks) do
    row["diff_status"] == "changed" and observation?(row) and
      (observation_gap?(row, callbacks) or
         target_identity_gap?(row, callbacks) or
         product_identity_gap?(row, callbacks) or
         quality_gap?(row, callbacks) or
         pointing_gap?(row, callbacks) or
         lighting_gap?(row, callbacks) or
         target_priority_gap?(row, policy, callbacks))
  end

  def observation?(row) do
    type =
      row["replacement_activity_type"] || row["source_activity_type"] ||
        get_in(row, ["replacement_activity_context", "activity_type"]) ||
        get_in(row, ["replacement_activity_context", "type"]) ||
        get_in(row, ["source_activity_context", "activity_type"]) ||
        get_in(row, ["source_activity_context", "type"])

    type in ["observe", "observation", "target_visibility", "imaging"]
  end

  def events(row, source_path, policy),
    do: events(row, source_path, policy, default_callbacks())

  def events(row, source_path, policy, callbacks) do
    [
      if(observation_gap?(row, callbacks),
        do: observation_event(row, source_path, callbacks)
      ),
      if(target_identity_gap?(row, callbacks),
        do: target_identity_event(row, source_path, callbacks)
      ),
      if(product_identity_gap?(row, callbacks),
        do: product_identity_event(row, source_path, callbacks)
      ),
      if(quality_gap?(row, callbacks),
        do: quality_event(row, source_path, callbacks)
      ),
      if(pointing_gap?(row, callbacks),
        do: pointing_event(row, source_path, callbacks)
      ),
      if(lighting_gap?(row, callbacks),
        do: lighting_event(row, source_path, callbacks)
      ),
      if(target_priority_gap?(row, policy, callbacks),
        do: target_priority_event(row, source_path, callbacks)
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  def observation_gap?(row, callbacks) do
    TimelineDiffObservationOutcomeEvents.timeline_diff_changed_observation_gap?(
      row,
      callbacks
    )
  end

  def quality_gap?(row, callbacks) do
    TimelineDiffObservationQualityEvents.timeline_diff_changed_observation_quality_gap?(
      row,
      callbacks
    )
  end

  def observation_event(row, source_path, callbacks) do
    TimelineDiffObservationOutcomeEvents.timeline_diff_changed_observation_event(
      row,
      source_path,
      callbacks
    )
  end

  def target_identity_gap?(row, callbacks) do
    TimelineDiffObservationIdentityEvents.timeline_diff_changed_observation_target_identity_gap?(
      row,
      callbacks
    )
  end

  def target_identity_event(row, source_path, callbacks) do
    TimelineDiffObservationIdentityEvents.timeline_diff_changed_observation_target_identity_event(
      row,
      source_path,
      callbacks
    )
  end

  def product_identity_gap?(row, callbacks) do
    TimelineDiffObservationIdentityEvents.timeline_diff_changed_observation_product_identity_gap?(
      row,
      callbacks
    )
  end

  def product_identity_event(row, source_path, callbacks) do
    TimelineDiffObservationIdentityEvents.timeline_diff_changed_observation_product_identity_event(
      row,
      source_path,
      callbacks
    )
  end

  def quality_event(row, source_path, callbacks) do
    TimelineDiffObservationQualityEvents.timeline_diff_changed_observation_quality_event(
      row,
      source_path,
      callbacks
    )
  end

  def pointing_gap?(row, callbacks) do
    TimelineDiffObservationPointingEvents.timeline_diff_changed_observation_pointing_gap?(
      row,
      callbacks
    )
  end

  def pointing_event(row, source_path, callbacks) do
    TimelineDiffObservationPointingEvents.timeline_diff_changed_observation_pointing_event(
      row,
      source_path,
      callbacks
    )
  end

  def lighting_gap?(row, callbacks) do
    TimelineDiffObservationLightingEvents.timeline_diff_changed_observation_lighting_gap?(
      row,
      callbacks
    )
  end

  def lighting_event(row, source_path, callbacks) do
    TimelineDiffObservationLightingEvents.timeline_diff_changed_observation_lighting_event(
      row,
      source_path,
      callbacks
    )
  end

  def target_priority_gap?(row, policy, callbacks) do
    TimelineDiffObservationPriorityEvents.timeline_diff_changed_observation_target_priority_gap?(
      row,
      policy,
      callbacks
    )
  end

  def target_priority_event(row, source_path, callbacks) do
    TimelineDiffObservationPriorityEvents.timeline_diff_changed_observation_target_priority_event(
      row,
      source_path,
      callbacks
    )
  end

  def target_id(row), do: target_id(row, default_callbacks())

  def target_id(row, callbacks) do
    replacement_context = Map.get(row, "replacement_activity_context", %{})
    source_context = Map.get(row, "source_activity_context", %{})

    [
      row["replacement_target_id"],
      row["source_target_id"],
      callback!(callbacks, :score_term_entity_id).(row["replacement_target"], ["target_id", "id"]),
      callback!(callbacks, :score_term_entity_id).(row["source_target"], ["target_id", "id"]),
      get_in(row, ["replacement_activity_context", "target_id"]),
      get_in(row, ["source_activity_context", "target_id"]),
      callback!(callbacks, :score_term_entity_id).(replacement_context["target"], [
        "target_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(source_context["target"], ["target_id", "id"])
    ]
    |> Enum.find(&callback!(callbacks, :stable_id_string?).(&1))
  end

  def result(row), do: result(row, default_callbacks())

  def result(row, callbacks) do
    TimelineDiffObservationOutcomeEvents.timeline_diff_changed_observation_result(
      row,
      callbacks
    )
  end

  defp callback!(callbacks, key) do
    Keyword.fetch!(callbacks, key)
  end

  defp default_callbacks do
    [
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      compact_map: &ValueEncoding.compact_map/1,
      encode_value: &ValueEncoding.encode_value/1,
      high_feedback_priority?: &TargetPriorityFeedbackEvents.high_priority?/2,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      observation_quality_feedback_factor: &ObservationFeedbackEvents.quality_factor/4,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1,
      positive_number?: &ScalarValues.positive_number?/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      score_term_product_id_values: &ScoreTermIdentifiers.product_id_values/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      timeline_diff_changed_observation_result: &result/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_replacement_evidence:
        &TimelineDiffActivityFields.replacement_evidence/1,
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_target_id: &target_id/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_field_value: &TimelineDiffFieldValues.field_value/2,
      timeline_diff_first_number: &TimelineDiffFieldValues.first_number/2,
      timeline_diff_first_stable_id: &TimelineDiffFieldValues.first_stable_id/2,
      timeline_diff_first_string: &TimelineDiffFieldValues.first_string/2,
      timeline_diff_match_status: &TimelineDiffFieldValues.match_status/2,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      unit_interval_number_or_nil: &FeedbackNumericValues.unit_interval_number_or_nil/1
    ]
  end
end
