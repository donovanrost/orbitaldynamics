defmodule OrbitalDynamics.CampaignPlanner.StrategyCandidateSource do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh

  def branch_source(branch, request, repair_result, derive_refresh_request_fun) do
    base_source =
      repair_result
      |> get_in(["assumptions", "candidate_source"])
      |> Kernel.||(%{})

    candidate_refresh_request =
      Map.get(branch, "candidate_refresh_request") ||
        if generated_branch_candidate_source?(base_source, request) do
          derive_refresh_request_fun.(branch, request)
        end

    source =
      base_source
      |> report_inputs(candidate_refresh_request)
      |> request_result_artifact_report_inputs(request)
      |> event_report_inputs(branch)

    scope =
      cond do
        Map.get(branch, "candidate_refresh") -> "branch"
        Map.get(branch, "candidate_refresh_request") -> "branch_generated"
        generated_branch_candidate_source?(source, request) -> "branch_generated"
        request.candidate_refresh -> "strategy_request"
        true -> "prior_plan"
      end

    Map.put(source, "scope", scope)
  end

  def report_inputs(source, nil), do: source

  def report_inputs(source, candidate_refresh_request) do
    paths = candidate_refresh_source_report_input_paths(candidate_refresh_request)
    summary = candidate_refresh_request_source_report_summary(candidate_refresh_request)

    source
    |> put_report_input_paths(paths)
    |> put_candidate_source_request_report_input_paths(paths)
    |> maybe_put_candidate_source_request_report_summary(summary)
  end

  def report_provenance_inputs(source, %{} = candidate_refresh) do
    paths =
      candidate_refresh
      |> CandidateRefresh.source_report_summary()
      |> Map.get("source_report_paths", [])

    put_report_input_paths(source, paths)
  end

  def request_result_artifact_report_inputs(source, request) do
    paths =
      %{"mission_state" => stringify_keys(request.mission_state || %{})}
      |> candidate_refresh_result_artifact_source_report_input_paths()

    put_report_input_paths(source, paths)
  end

  def event_report_inputs(source, branch) do
    paths =
      branch
      |> Map.get("events", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "feedback_source"))
      |> Enum.flat_map(&candidate_source_report_feedback_paths/1)
      |> Enum.uniq()

    put_report_input_paths(source, paths)
  end

  def put_report_input_paths(source, []), do: source

  def put_report_input_paths(source, paths) do
    merged_paths =
      source
      |> Map.get("source_report_input_paths")
      |> List.wrap()
      |> Kernel.++(paths)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    Map.put(source, "source_report_input_paths", merged_paths)
  end

  defp generated_branch_candidate_source?(%{"type" => "candidate_refresh.v1"} = source, request) do
    is_nil(request.candidate_refresh) or
      Map.get(source, "refresh_id") != Map.get(request.candidate_refresh || %{}, "refresh_id")
  end

  defp generated_branch_candidate_source?(_source, _request), do: false

  defp candidate_refresh_request_source_report_summary(candidate_refresh_request) do
    request = stringify_keys(candidate_refresh_request || %{})
    refresh = Map.get(request, "candidate_refresh", request)

    CandidateRefresh.source_report_summary(refresh)
  end

  defp maybe_put_candidate_source_request_report_summary(
         source,
         %{"source_report_count" => count} = summary
       )
       when is_integer(count) and count > 0 do
    Map.put(source, "candidate_refresh_request_source_report_summary", summary)
  end

  defp maybe_put_candidate_source_request_report_summary(source, _summary), do: source

  defp put_candidate_source_request_report_input_paths(source, []), do: source

  defp put_candidate_source_request_report_input_paths(source, paths) do
    Map.put(source, "candidate_refresh_request_source_report_input_paths", paths)
  end

  defp candidate_source_report_feedback_paths("mission_state." <> _rest = source) do
    source_report_feedback_paths(source)
  end

  defp candidate_source_report_feedback_paths("prior_plan." <> _rest = source) do
    source_report_feedback_paths(source)
  end

  defp candidate_source_report_feedback_paths(_source), do: []

  defp source_report_feedback_paths(source) do
    segments = String.split(source, ".")

    segments
    |> Enum.find_index(&source_report_feedback_segment?/1)
    |> case do
      nil -> []
      report_index -> [segments |> Enum.take(report_index + 1) |> Enum.join(".")]
    end
  end

  defp source_report_feedback_segment?(segment) when is_binary(segment) do
    String.ends_with?(segment, "_report") or String.ends_with?(segment, "_summary") or
      Regex.match?(~r/_(report|summary)\[\d+\]$/, segment)
  end

  defp source_report_feedback_segment?(_segment), do: false

  defp candidate_refresh_source_report_input_paths(candidate_refresh_request) do
    request = stringify_keys(candidate_refresh_request || %{})
    refresh = Map.get(request, "candidate_refresh", request)

    direct_paths = candidate_refresh_direct_source_report_input_paths(refresh)

    normalized_paths =
      refresh
      |> CandidateRefresh.source_report_summary()
      |> Map.get("source_report_paths", [])

    (direct_paths ++
       candidate_refresh_result_artifact_source_report_input_paths(refresh) ++
       normalized_paths)
    |> Enum.uniq()
  end

  defp candidate_refresh_direct_source_report_input_paths(refresh) do
    [
      {nil, refresh},
      {"accepted_planning_state", Map.get(refresh, "accepted_planning_state")},
      {"mission_state", Map.get(refresh, "mission_state")}
    ]
    |> Enum.flat_map(fn {prefix, source} ->
      source = stringify_keys(source || %{})

      source_report_input_fields()
      |> Enum.flat_map(fn {source_key, canonical_key} ->
        [source_key, canonical_key]
        |> Enum.flat_map(fn key ->
          value = Map.get(source, key)

          if source_report_input_present?(value) do
            [candidate_refresh_source_report_input_path(prefix, key)]
          else
            []
          end
        end)
      end)
    end)
  end

  defp candidate_refresh_source_report_input_path(nil, key), do: key
  defp candidate_refresh_source_report_input_path(prefix, key), do: "#{prefix}.#{key}"

  def source_report_input_fields do
    [
      {"source_timeline_feedback_report", "timeline_feedback_report"},
      {"source_operational_timeline_report", "operational_timeline_report"},
      {"source_candidate_diff_report", "candidate_diff_report"},
      {"source_candidate_rejection_report", "candidate_rejection_report"},
      {"source_provider_counteroffer_report", "provider_counteroffer_report"},
      {"source_provider_counteroffer_review_summary", "provider_counteroffer_review_summary"},
      {"source_provider_counteroffer_import_readiness_summary",
       "provider_counteroffer_import_readiness_summary"},
      {"source_provider_counteroffer_plan_impact_summary",
       "provider_counteroffer_plan_impact_summary"},
      {"source_schema_validation_report", "schema_validation_report"},
      {"source_schema_validation_batch_report", "schema_validation_batch_report"},
      {"source_operational_readiness_report", "operational_readiness_report"},
      {"source_operational_import_eligibility_summary", "operational_import_eligibility_summary"},
      {"source_operational_readiness_gate_summary", "operational_readiness_gate_summary"},
      {"source_operational_execution_boundary_summary", "operational_execution_boundary_summary"},
      {"source_quality_gate_report", "quality_gate_report"},
      {"source_operational_quality_gate_summary", "operational_quality_gate_summary"},
      {"source_operational_quality_gate_unavailable_resource_summary",
       "operational_quality_gate_unavailable_resource_summary"},
      {"source_operational_quality_gate_operator_training_summary",
       "operational_quality_gate_operator_training_summary"},
      {"source_operational_quality_gate_schema_validation_summary",
       "operational_quality_gate_schema_validation_summary"},
      {"source_operational_quality_gate_import_readiness_summary",
       "operational_quality_gate_import_readiness_summary"},
      {"source_model_acceptance_report", "model_acceptance_report"},
      {"source_validation_safety_case_summary", "validation_safety_case_summary"},
      {"source_freshness_report", "freshness_report"},
      {"source_refresh_budget_report", "refresh_budget_report"},
      {"source_command_window_report", "command_window_report"},
      {"source_maneuver_review_report", "maneuver_review_report"},
      {"source_station_calendar_report", "station_calendar_report"},
      {"source_station_calendar_precedence_summary", "station_calendar_precedence_summary"},
      {"source_station_reservation_report", "station_reservation_report"},
      {"source_station_reservation_hold_summary", "station_reservation_hold_summary"},
      {"source_station_reservation_hold_import_readiness_summary",
       "station_reservation_hold_import_readiness_summary"},
      {"source_contact_intent", "contact_intent"},
      {"source_contact_intents", "contact_intents"},
      {"source_contact_intent_summary", "contact_intent_summary"},
      {"source_contact_filter_report", "contact_filter_report"},
      {"source_contact_allocation_report", "contact_allocation_report"},
      {"source_contact_allocation_summary", "contact_allocation_summary"},
      {"source_contact_allocation_station_pressure_summary",
       "contact_allocation_station_pressure_summary"},
      {"source_contact_allocation_reservation_conflict_summary",
       "contact_allocation_reservation_conflict_summary"},
      {"source_contact_allocation_capacity_pack_summary",
       "contact_allocation_capacity_pack_summary"},
      {"source_contact_allocation_provider_reservation_request_summary",
       "contact_allocation_provider_reservation_request_summary"},
      {"source_contact_contention_report", "contact_contention_report"},
      {"source_contact_contention_resolution_report", "contact_contention_resolution_report"},
      {"source_contact_contention_resolution_summary", "contact_contention_resolution_summary"},
      {"source_operator_review_package", "operator_review_package"},
      {"source_cadence_import_manifest", "cadence_import_manifest"},
      {"source_link_capacity_report", "link_capacity_report"},
      {"source_link_capacity_summary", "link_capacity_summary"},
      {"source_resource_projection_report", "resource_projection_report"},
      {"source_resource_projection_flow_summary", "resource_projection_flow_summary"},
      {"source_resource_filter_report", "resource_filter_report"},
      {"source_resource_filter_summary", "resource_filter_summary"},
      {"source_timeline_diff_report", "timeline_diff_report"},
      {"source_timeline_diff_summary", "timeline_diff_summary"},
      {"source_timeline_integrity_report", "timeline_integrity_report"},
      {"source_timeline_dependency_impact_summary", "timeline_dependency_impact_summary"},
      {"source_timeline_activity_precondition_summary", "timeline_activity_precondition_summary"},
      {"source_timeline_preservation_report", "timeline_preservation_report"},
      {"source_timeline_preservation_status", "timeline_preservation_status"},
      {"source_timeline_publication_summary", "timeline_publication_summary"},
      {"source_timeline_transition_application_summary",
       "timeline_transition_application_summary"},
      {"source_timeline_activity_state", "timeline_activity_state"},
      {"source_timeline_activity_status_state", "timeline_activity_status_state"},
      {"source_timeline_activity_approval_state", "timeline_activity_approval_state"},
      {"source_timeline_lifecycle_state_summary", "timeline_lifecycle_state_summary"},
      {"source_timeline_activity_lifecycle_state", "timeline_activity_lifecycle_state"},
      {"source_timeline_transition_application_report", "timeline_transition_application_report"},
      {"source_constraint_report", "constraint_report"},
      {"source_objective_satisfaction_report", "objective_satisfaction_report"},
      {"source_objective_tradeoff_report", "objective_tradeoff_report"},
      {"source_score_term_report", "score_term_report"},
      {"source_station_reservation_review_summary", "station_reservation_review_summary"},
      {"source_relay_data_path_summary", "relay_data_path_summary"}
    ]
  end

  defp candidate_refresh_result_artifact_source_report_input_paths(refresh) do
    [
      {"accepted_planning_state.source_result_artifact",
       get_in(refresh, ["accepted_planning_state", "source_result_artifact"])},
      {"accepted_planning_state.result_artifact",
       get_in(refresh, ["accepted_planning_state", "result_artifact"])},
      {"mission_state.source_result_artifact",
       get_in(refresh, ["mission_state", "source_result_artifact"])},
      {"mission_state.result_artifact", get_in(refresh, ["mission_state", "result_artifact"])},
      {"source_result_artifact", Map.get(refresh, "source_result_artifact")},
      {"result_artifact", Map.get(refresh, "result_artifact")}
    ]
    |> Enum.flat_map(fn {path, artifact_or_artifacts} ->
      result_artifact_source_report_input_paths(path, artifact_or_artifacts)
    end)
  end

  defp result_artifact_source_report_input_paths(path, artifacts) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_source_report_input_paths("#{path}[#{index}]", artifact)
    end)
  end

  defp result_artifact_source_report_input_paths(path, %{} = artifact) do
    artifact = stringify_keys(artifact)

    result_artifact_source_report_input_keys()
    |> Enum.flat_map(fn key ->
      value = Map.get(artifact, key)
      result_artifact_source_report_input_key_paths(path, key, value)
    end)
  end

  defp result_artifact_source_report_input_paths(_path, _artifact), do: []

  defp result_artifact_source_report_input_key_paths(path, key, values) when is_list(values) do
    if result_artifact_source_report_collection_key?(key) do
      values
      |> Enum.with_index()
      |> Enum.flat_map(fn {value, index} ->
        if source_report_input_present?(value), do: ["#{path}.#{key}[#{index}]"], else: []
      end)
    else
      if source_report_input_present?(values), do: ["#{path}.#{key}"], else: []
    end
  end

  defp result_artifact_source_report_input_key_paths(path, key, value) do
    if source_report_input_present?(value), do: ["#{path}.#{key}"], else: []
  end

  defp result_artifact_source_report_collection_key?(key) do
    String.ends_with?(key, "_report") or String.ends_with?(key, "_summary")
  end

  defp result_artifact_source_report_input_keys do
    source_report_input_fields()
    |> Enum.flat_map(fn {source_key, canonical_key} -> [source_key, canonical_key] end)
  end

  def source_report_input_present?(%{} = report), do: map_size(report) > 0
  def source_report_input_present?(reports) when is_list(reports), do: reports != []
  def source_report_input_present?(_report), do: false

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
