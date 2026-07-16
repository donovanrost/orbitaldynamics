defmodule OrbitalDynamics.CampaignPlanner.RepairMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateRefreshOperationalFeedback,
    OperationalFeedbackNormalization,
    PriorActivityContext,
    ScalarValues,
    StrategyCandidateSource,
    ValueEncoding
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def candidate_source(prior_plan, candidate_refresh, candidate_refresh_request) do
    candidate_source(prior_plan, candidate_refresh, candidate_refresh_request, callbacks())
  end

  def candidate_source(prior_plan, candidate_refresh, candidate_refresh_request, callbacks)

  def candidate_source(prior_plan, nil, _candidate_refresh_request, callbacks) do
    source_plan_id = Keyword.fetch!(callbacks, :source_plan_id)
    prior_plan_candidate_activities = Keyword.fetch!(callbacks, :prior_plan_candidate_activities)

    %{
      "type" => "prior_plan",
      "source_plan_id" => source_plan_id.(prior_plan),
      "candidate_count" => length(prior_plan_candidate_activities.(prior_plan))
    }
  end

  def candidate_source(_prior_plan, %{} = candidate_refresh, candidate_refresh_request, callbacks) do
    source =
      %{
        "type" => "candidate_refresh.v1",
        "refresh_id" => Map.get(candidate_refresh, "refresh_id"),
        "snapshot_id" => Map.get(candidate_refresh, "snapshot_id"),
        "generated_at" => Map.get(candidate_refresh, "generated_at"),
        "candidate_count" => length(Map.get(candidate_refresh, "candidate_activities", [])),
        "maneuver_execution_delta_count" =>
          get_in(candidate_refresh, [
            "accepted_planning_state",
            "maneuver_execution_delta_count"
          ]) || 0,
        "invalidated_candidate_count" =>
          length(Map.get(candidate_refresh, "invalidated_candidates", []))
      }
      |> maybe_put_operational_feedback(candidate_refresh, callbacks)
      |> StrategyCandidateSource.report_provenance_inputs(candidate_refresh)
      |> StrategyCandidateSource.report_inputs(candidate_refresh_request)

    if candidate_refresh_request do
      Map.put(source, "scope", "repair_generated")
    else
      source
    end
  end

  def assumptions(prior_plan, request) do
    %{
      "source_plan_assumptions" => Map.get(prior_plan, "assumptions", %{}),
      "repair_model" =>
        if(request.candidate_refresh,
          do: "candidate_refresh_windows_greedy_repair",
          else: "prior_candidate_windows_greedy_repair"
        ),
      "candidate_source" => request.candidate_source,
      "remaining_horizon" => request.remaining_horizon,
      "constraints" => request.constraints,
      "scoring_policy" => request.scoring_policy,
      "policy_model" => "policy_decision_v1_artifact_only_no_execution",
      "degraded_mode_model" =>
        "suppress_incompatible_payload_activities_preserve_command_health_locked_approved"
    }
  end

  def provenance(prior_plan, candidate_source) do
    provenance(prior_plan, candidate_source, callbacks())
  end

  def provenance(prior_plan, candidate_source, callbacks) do
    source_plan_id = Keyword.fetch!(callbacks, :source_plan_id)

    %{
      "source_plan_id" => source_plan_id.(prior_plan),
      "source_plan_generated_at" => Map.get(prior_plan, "generated_at"),
      "source_study_id" => Map.get(prior_plan, "study_id"),
      "source_provenance" => Map.get(prior_plan, "provenance", %{}),
      "candidate_source" => candidate_source
    }
  end

  def id(prior_plan, realized_state, current_epoch_s, candidate_source) do
    id(prior_plan, realized_state, current_epoch_s, candidate_source, callbacks())
  end

  def id(prior_plan, realized_state, current_epoch_s, candidate_source, callbacks) do
    source_plan_id = Keyword.fetch!(callbacks, :source_plan_id)

    :crypto.hash(
      :sha256,
      :erlang.term_to_binary({
        source_plan_id.(prior_plan),
        realized_state_identity_input(realized_state),
        current_epoch_s,
        candidate_source
      })
    )
    |> Base.encode16(case: :lower)
  end

  defp callbacks,
    do: [
      source_plan_id: &source_plan_id/1,
      prior_plan_candidate_activities: &PriorActivityContext.candidate_activities/1,
      candidate_refresh_operational_feedback: &CandidateRefreshOperationalFeedback.feedback/1,
      operational_feedback_data_keys: &operational_feedback_data_keys/1
    ]

  defp source_plan_id(prior_plan) do
    Map.get(prior_plan, "plan_id") ||
      [Map.get(prior_plan, "study_id"), Map.get(prior_plan, "generated_at")]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(":")
  end

  defp operational_feedback_data_keys(feedback) do
    feedback
    |> OperationalFeedbackNormalization.normalize(operational_feedback_normalization_callbacks())
    |> Enum.filter(fn {_key, value} -> operational_feedback_value_present?(value) end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  defp operational_feedback_value_present?(%{} = value), do: map_size(value) > 0
  defp operational_feedback_value_present?(_value), do: false

  defp operational_feedback_normalization_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp maybe_put_operational_feedback(source, candidate_refresh, callbacks) do
    candidate_refresh_operational_feedback =
      Keyword.fetch!(callbacks, :candidate_refresh_operational_feedback)

    operational_feedback_data_keys = Keyword.fetch!(callbacks, :operational_feedback_data_keys)

    feedback_provenance = get_in(candidate_refresh, ["provenance", "operational_feedback"])
    input_keys = Map.get(feedback_provenance || %{}, "input_keys", [])
    feedback = candidate_refresh_operational_feedback.(candidate_refresh)

    if input_keys == [] and operational_feedback_data_keys.(feedback) == [] do
      source
    else
      source
      |> Map.put("operational_feedback_input_keys", operational_feedback_data_keys.(feedback))
      |> put_if_present(
        "operational_feedback_trust_boundary_status",
        Map.get(feedback_provenance || %{}, "trust_boundary_status")
      )
      |> put_if_present(
        "operational_feedback_trust_boundary",
        Map.get(feedback_provenance || %{}, "trust_boundary")
      )
      |> put_if_present(
        "source_operational_feedback_provenance",
        feedback_provenance
      )
    end
  end

  defp realized_state_identity_input(realized_state) when is_map(realized_state) do
    Map.delete(realized_state, "model_limits")
  end

  defp realized_state_identity_input(realized_state), do: realized_state

  defp put_if_present(map, _key, value) when value in [nil, "", [], %{}], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
