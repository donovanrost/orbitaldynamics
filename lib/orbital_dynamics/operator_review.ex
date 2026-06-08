defmodule OrbitalDynamics.OperatorReview do
  @moduledoc """
  Builds artifact-only operator review packages.

  These packages collect contact-contention recommendations, realized feedback,
  plan-delta reviews, approval requirements, warnings, risk explanations, and strategy
  recommendations into a stable import-oriented surface. They do not approve
  work, reserve provider resources, mutate schedules, or execute commands.
  """

  @schema_contract "operator_review_package.v1"
  @feedback_exception_statuses ~w(missed failed canceled cancelled rejected)
  @feedback_variance_statuses ~w(partial delayed)
  @feedback_completion_statuses ~w(completed executed)
  @cadence_import_statuses ~w(invalid missing not_applicable present)
  @provider_result_fields ~w(contact_result command_result observation_result maneuver_result)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @candidate_diff_scoped_context_fields ~w(
    target_id
    target_ids
    collection_id
    collection_ids
    product_id
    product_ids
    payload_id
    payload_ids
    instrument_id
    instrument_ids
    objective_id
    objective_ids
    objective_type
    objective_types
    objective_status
    objective_statuses
    source_objective_status
    source_objective_statuses
    latency_objective
    max_latency_s
    planned_latency_s
    required_contacts
    planned_contacts
    required_downlink_mb
    planned_downlink_mb
    contact_result
    contact_results
    realized_status
    realized_statuses
    source_activity_id
    source_activity_ids
    missed_downlink_activity_id
    missed_downlink_activity_ids
    feedback_source
    feedback_sources
    feedback_scope
    feedback_scopes
    trust_boundary
    trust_boundaries
    derivation_reasons
    candidate_downlink_mb
    downlink_completion_ratio
    selected_downlink_shortfall_mb
    downlink_requirement_status
    downlink_completion_source
    downlink_completion_sources
  )
  @source_artifact_types ~w(
    campaign_plan.v1
    campaign_repair.v2
    campaign_strategy.v3
    candidate_refresh.v1
    proposed_contact.v1
    planned_activity.v1
    realized_activity.v1
    realized_state_snapshot.v1
    result_artifact.v1
    timeline_feedback_report.v1
    operational_timeline_report.v1
    contact_contention_report.v1
    contact_contention_resolution_report.v1
    command_window_report.v1
    station_calendar_report.v1
    station_reservation_report.v1
    link_capacity_report.v1
    contact_allocation_report.v1
    resource_projection_report.v1
    resource_projection_flow_summary.v1
    contact_intent.v1
    contact_filter_report.v1
    candidate_rejection_report.v1
    provider_counteroffer_report.v1
    candidate_diff_report.v1
    invalidated_candidate.v1
    resource_filter_report.v1
    freshness_report.v1
    refresh_budget_report.v1
    model_acceptance_report.v1
    validation_safety_case_summary.v1
    constraint_report.v1
    objective_satisfaction_report.v1
    maneuver_recommendation.v1
    maneuver_execution_delta.v1
    maneuver_review_report.v1
    timeline_diff_report.v1
    timeline_diff_summary.v1
    timeline_dependency_impact_summary.v1
    timeline_publication_summary.v1
    timeline_activity_precondition_summary.v1
    timeline_activity_state.v1
    timeline_activity_status_state.v1
    timeline_activity_approval_state.v1
    timeline_activity_lifecycle_state.v1
    timeline_lifecycle_state_summary.v1
    timeline_preservation_report.v1
    timeline_preservation_status.v1
    timeline_integrity_report.v1
    timeline_transition_application_summary.v1
    timeline_transition_application_report.v1
    approval_requirement.v1
    policy_decision.v1
    branch_comparison_report.v1
    ranking_comparison_report.v1
    score_term_report.v1
    objective_tradeoff_report.v1
    pareto_frontier_report.v1
	    schema_validation_report.v1
    schema_validation_batch_report.v1
    execution_report.v1
    operational_readiness_report.v1
    quality_gate_report.v1
    operator_review_package.v1
  )

  @doc """
  Declares the operator-review package model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_operator_review_package,
      validation_level: :artifact_contract,
      review_types: [
        "contact_contention_recommendation",
        "contact_contention_review",
        "operational_timeline_review",
        "command_window_review",
        "station_calendar_review",
        "station_reservation_review",
        "link_capacity_review",
        "contact_allocation_review",
        "contact_allocation_capacity_pack_review",
        "contact_intent_review",
        "candidate_rejection_review",
        "provider_counteroffer_review",
        "candidate_diff_review",
        "freshness_review",
        "refresh_budget_review",
        "model_acceptance_review",
        "validation_safety_case_review",
        "contact_suppression",
        "realized_feedback",
        "timeline_diff_review",
        "timeline_dependency_impact_review",
        "timeline_publication_review",
        "timeline_activity_precondition_review",
        "timeline_lifecycle_state_review",
        "timeline_preservation_review",
        "timeline_integrity_review",
        "maneuver_review",
        "plan_delta_review",
        "timeline_protection",
        "approval_requirement",
        "policy_escalation",
        "resource_projection_review",
        "resource_suppression",
        "warning",
        "risk_explanation",
        "strategy_recommendation",
        "strategy_tradeoff",
        "score_term_review",
        "objective_tradeoff_review",
        "ranking_comparison_review",
        "pareto_frontier_review",
        "constraint_review",
        "objective_satisfaction_review",
        "schema_validation_review",
        "execution_review",
        "operational_readiness_review",
        "quality_gate_review"
      ],
      required_context: [
        :stable_ids,
        :source_artifact_id,
        :source_artifact_type,
        :required_operator_action,
        :reason,
        :provenance
      ],
      provider_result_map_value_keys: @provider_result_map_value_keys,
      handoff_row_semantics: [
        :schema_validation_review_rows,
        :schema_validation_issue_context,
        :schema_validation_remediation_context,
        :schema_validation_batch_nested_report_context,
        :operational_readiness_summary_rows,
        :operational_readiness_gate_rows,
        :operational_readiness_resource_summary_context,
        :operational_readiness_resource_gate_context,
        :operational_readiness_adapter_boundary_context,
        :operational_readiness_cadence_import_gate_context,
        :quality_gate_review_rows,
        :quality_gate_resource_row_context,
        :model_acceptance_review_rows,
        :model_acceptance_source_handoff_consistency,
        :validation_safety_case_review_rows,
        :validation_safety_case_source_handoff_consistency,
        :timeline_diff_summary_review_rows,
        :timeline_diff_summary_source_handoff_consistency,
        :timeline_dependency_impact_review_rows,
        :timeline_dependency_impact_source_handoff_consistency,
        :timeline_publication_review_rows,
        :timeline_publication_source_handoff_consistency,
        :timeline_activity_precondition_review_rows,
        :timeline_activity_precondition_source_handoff_consistency,
        :timeline_lifecycle_state_review_rows,
        :timeline_lifecycle_state_source_handoff_consistency,
        :timeline_preservation_review_rows,
        :timeline_preservation_source_handoff_consistency,
        :timeline_integrity_review_rows,
        :timeline_integrity_source_handoff_consistency,
        :timeline_transition_application_summary_review_rows,
        :timeline_transition_application_summary_source_handoff_consistency,
        :resource_projection_count_handoff_consistency,
        :station_calendar_count_handoff_consistency,
        :link_capacity_count_handoff_consistency,
        :link_capacity_source_handoff_consistency,
        :contact_allocation_handoff_consistency,
        :contact_allocation_source_handoff_consistency,
        :contact_allocation_capacity_pack_source_handoff_consistency,
        :contact_contention_source_handoff_consistency,
        :command_window_source_handoff_consistency,
        :provider_counteroffer_source_handoff_consistency,
        :contact_intent_source_handoff_consistency,
        :station_calendar_source_handoff_consistency,
        :provider_calendar_contention_source_handoff_consistency,
        :suppression_duplicate_handoff_consistency,
        :suppression_source_handoff_consistency
      ],
      known_limits: [
        :no_schedule_mutation,
        :no_command_execution,
        :no_external_import,
        :no_provider_reservation
      ],
      source_artifact_types: @source_artifact_types,
      cadence_import_statuses: @cadence_import_statuses
    }
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline feedback report.
  """
  def from_timeline_feedback_report(%{} = report) do
    report = stringify_keys(report)
    rows = feedback_rows(Map.get(report, "rows", []))

    package(
      rows,
      "timeline_feedback_report.v1",
      Map.get(report, "id") || "timeline_feedback_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone realized-activity row.
  """
  def from_realized_activity(%{} = activity) do
    activity = stringify_keys(activity)

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], [activity])

    rows = feedback_rows(Map.get(report, "rows", []), "realized_activity")

    package(
      rows,
      "realized_activity.v1",
      Map.get(activity, "id") || Map.get(activity, "realized_activity_id") ||
        "realized_activity",
      Map.get(activity, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a realized-state snapshot.
  """
  def from_realized_state_snapshot(%{} = snapshot) do
    snapshot = stringify_keys(snapshot)
    activities = Map.get(snapshot, "activities", [])

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], activities)

    rows = feedback_rows(Map.get(report, "rows", []), "realized_state_snapshot.activities")

    package(
      rows,
      "realized_state_snapshot.v1",
      snapshot_id(snapshot),
      Map.get(snapshot, "provenance") || Map.get(snapshot, "metadata", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a top-level study result artifact.
  """
  def from_result_artifact(%{} = artifact) do
    artifact = stringify_keys(artifact)

    rows =
      result_artifact_execution_rows(artifact) ++
        result_artifact_constraint_rows(artifact) ++
        result_artifact_maneuver_rows(artifact)

    package(
      rows,
      "result_artifact.v1",
      result_artifact_id(artifact),
      Map.get(artifact, "metadata", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone maneuver execution delta.
  """
  def from_maneuver_execution_delta(%{} = delta) do
    delta = stringify_keys(delta)

    realized_activity =
      delta
      |> Map.put_new("id", Map.get(delta, "activity_id"))
      |> Map.put_new("type", "impulsive_burn")

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], [realized_activity])

    rows = feedback_rows(Map.get(report, "rows", []), "maneuver_execution_delta")

    package(
      rows,
      "maneuver_execution_delta.v1",
      Map.get(delta, "id") || Map.get(delta, "activity_id") || "maneuver_execution_delta",
      Map.get(delta, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from an operational timeline report.
  """
  def from_operational_timeline_report(%{} = report) do
    report = stringify_keys(report)
    rows = operational_timeline_rows(Map.get(report, "rows", []))

    package(
      rows,
      "operational_timeline_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "operational_timeline_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone planned-activity row.
  """
  def from_planned_activity(%{} = activity) do
    activity = stringify_keys(activity)

    report =
      OrbitalDynamics.Timeline.operational_report([activity],
        source: "planned_activity",
        source_assumption: "standalone planned_activity.v1 row"
      )

    rows = operational_timeline_rows(Map.get(report, "rows", []), "planned_activity")

    package(
      rows,
      "planned_activity.v1",
      Map.get(activity, "id") || Map.get(activity, "activity_id") || "planned_activity",
      Map.get(activity, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline diff report.
  """
  def from_timeline_diff_report(%{} = report) do
    report = stringify_keys(report)
    rows = timeline_diff_rows(Map.get(report, "rows", []))

    package(
      rows,
      "timeline_diff_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "timeline_diff_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline diff summary.
  """
  def from_timeline_diff_summary(%{} = summary) do
    summary =
      summary
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_diff_summary.v1")

    package(
      timeline_diff_summary_rows(summary),
      "timeline_diff_summary.v1",
      Map.get(summary, "id") || Map.get(summary, "source") || "timeline_diff_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline dependency-impact summary.
  """
  def from_timeline_dependency_impact_summary(%{} = summary) do
    summary = stringify_keys(summary)
    rows = timeline_dependency_impact_rows(summary)

    package(
      rows,
      "timeline_dependency_impact_summary.v1",
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_dependency_impact_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline publication summary.
  """
  def from_timeline_publication_summary(%{} = summary) do
    summary =
      summary
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_publication_summary.v1")

    rows = timeline_publication_rows(summary)

    package(
      rows,
      "timeline_publication_summary.v1",
      Map.get(summary, "publication_id") || Map.get(summary, "source_artifact_id") ||
        "timeline_publication_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline activity precondition summary.
  """
  def from_timeline_activity_precondition_summary(%{} = summary) do
    summary =
      summary
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_activity_precondition_summary.v1")

    rows = timeline_activity_precondition_rows(summary)

    package(
      rows,
      "timeline_activity_precondition_summary.v1",
      Map.get(summary, "id") || Map.get(summary, "source") || Map.get(summary, "timeline_id") ||
        Map.get(summary, "activity_id") || "timeline_activity_precondition_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline lifecycle-state summary.
  """
  def from_timeline_lifecycle_state_summary(%{} = summary) do
    summary = stringify_keys(summary)
    rows = timeline_lifecycle_state_rows(summary)

    package(
      rows,
      "timeline_lifecycle_state_summary.v1",
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_lifecycle_state_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a compact activity-state artifact.
  """
  def from_timeline_activity_state(%{} = state) do
    state =
      state
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_activity_state.v1")

    package(
      timeline_activity_state_rows(state, "timeline_activity_state.state"),
      "timeline_activity_state.v1",
      timeline_activity_state_source_id(state, "timeline_activity_state"),
      Map.get(state, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity status-state artifact.
  """
  def from_timeline_activity_status_state(%{} = state) do
    state =
      state
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_activity_status_state.v1")

    package(
      timeline_activity_state_rows(state, "timeline_activity_status_state.state"),
      "timeline_activity_status_state.v1",
      timeline_activity_state_source_id(state, "timeline_activity_status_state"),
      Map.get(state, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity approval-state artifact.
  """
  def from_timeline_activity_approval_state(%{} = state) do
    state =
      state
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_activity_approval_state.v1")

    package(
      timeline_activity_state_rows(state, "timeline_activity_approval_state.state"),
      "timeline_activity_approval_state.v1",
      timeline_activity_state_source_id(state, "timeline_activity_approval_state"),
      Map.get(state, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity lifecycle-state artifact.
  """
  def from_timeline_activity_lifecycle_state(%{} = state) do
    state =
      state
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_activity_lifecycle_state.v1")

    package(
      timeline_activity_state_rows(state, "timeline_activity_lifecycle_state.state"),
      "timeline_activity_lifecycle_state.v1",
      timeline_activity_state_source_id(state, "timeline_activity_lifecycle_state"),
      Map.get(state, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline preservation report.
  """
  def from_timeline_preservation_report(%{} = report) do
    report =
      report
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_preservation_report.v1")

    package(
      timeline_preservation_report_rows(report),
      "timeline_preservation_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "timeline_preservation_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a single timeline preservation status artifact.
  """
  def from_timeline_preservation_status(%{} = status) do
    status =
      status
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_preservation_status.v1")

    package(
      timeline_preservation_status_rows(status, "timeline_preservation_status.status"),
      "timeline_preservation_status.v1",
      timeline_preservation_source_id(status, "timeline_preservation_status"),
      Map.get(status, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline integrity report.
  """
  def from_timeline_integrity_report(%{} = report) do
    report =
      report
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_integrity_report.v1")

    package(
      timeline_integrity_report_rows(report),
      "timeline_integrity_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "timeline_integrity_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline transition-application summary.
  """
  def from_timeline_transition_application_summary(%{} = summary, opts \\ []) do
    summary =
      summary
      |> stringify_keys()
      |> Map.put_new("schema_contract", "timeline_transition_application_summary.v1")

    package(
      timeline_transition_application_summary_rows(summary, opts),
      "timeline_transition_application_summary.v1",
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_transition_application_summary",
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline transition application report.
  """
  def from_timeline_transition_application_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    rows =
      timeline_transition_application_rows(
        Map.get(report, "applications", []),
        "timeline_transition_application_report.applications",
        option(opts, :approval_policy) || option(opts, "approval_policy")
      )

    package(
      rows,
      "timeline_transition_application_report.v1",
      Map.get(report, "id") || Map.get(report, "source") ||
        "timeline_transition_application_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a command-window report.
  """
  def from_command_window_report(%{} = report) do
    report = stringify_keys(report)
    rows = command_window_rows(Map.get(report, "rows", []))

    package(
      rows,
      "command_window_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "command_window_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a maneuver-review report.
  """
  def from_maneuver_review_report(%{} = report) do
    report = stringify_keys(report)
    rows = maneuver_review_rows(Map.get(report, "rows", []))

    package(
      rows,
      "maneuver_review_report.v1",
      Map.get(report, "id") || Map.get(report, "source_artifact_id") ||
        Map.get(report, "source") || "maneuver_review_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone maneuver recommendation.
  """
  def from_maneuver_recommendation(%{} = recommendation) do
    recommendation = stringify_keys(recommendation)

    report =
      OrbitalDynamics.ManeuverReview.report([recommendation],
        source: "maneuver_recommendation",
        source_artifact_id:
          Map.get(recommendation, "id") || Map.get(recommendation, "maneuver_id")
      )

    rows = maneuver_review_rows(Map.get(report, "rows", []), "maneuver_recommendation")

    package(
      rows,
      "maneuver_recommendation.v1",
      Map.get(recommendation, "id") || Map.get(recommendation, "maneuver_id") ||
        "maneuver_recommendation",
      Map.get(recommendation, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a station-calendar report.
  """
  def from_station_calendar_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      station_calendar_rows(Map.get(report, "affected_contacts", [])) ++
        station_calendar_provider_contention_rows(
          Map.get(report, "provider_calendar_contention_groups", [])
        )

    package(
      rows,
      "station_calendar_report.v1",
      Map.get(report, "id") || get_in(report, ["assumptions", "source"]) ||
        "station_calendar_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a station-reservation report.
  """
  def from_station_reservation_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      station_reservation_rows(Map.get(report, "affected_contacts", [])) ++
        station_reservation_provider_contention_rows(
          Map.get(report, "provider_calendar_contention_groups", [])
        )

    package(
      rows,
      "station_reservation_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "station_reservation_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a link-capacity report.
  """
  def from_link_capacity_report(%{} = report) do
    report = stringify_keys(report)

    rows = link_capacity_report_rows(report, "link_capacity_report")

    package(
      rows,
      "link_capacity_report.v1",
      link_capacity_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-allocation report.
  """
  def from_contact_allocation_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      contact_allocation_rows(Map.get(report, "rows", [])) ++
        contact_allocation_capacity_pack_rows(Map.get(report, "reduced_capacity_pack_groups", [])) ++
        contact_allocation_station_calendar_provider_contention_rows(report)

    package(
      rows,
      "contact_allocation_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "contact_allocation_report",
      Map.get(report, "provenance", %{})
    )
    |> put_contact_allocation_summaries([report])
  end

  defp contact_allocation_station_calendar_provider_contention_rows(
         report,
         source_prefix \\ "contact_allocation_report"
       ) do
    report
    |> get_in(["station_calendar_report", "provider_calendar_contention_groups"])
    |> case do
      groups when is_list(groups) ->
        station_calendar_provider_contention_rows(
          groups,
          "#{source_prefix}.station_calendar_report.provider_calendar_contention_groups"
        )

      _groups ->
        []
    end
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone contact-intent row.
  """
  def from_contact_intent(%{} = intent) do
    intent = stringify_keys(intent)
    rows = contact_intent_rows([intent], "contact_intent")

    package(
      rows,
      "contact_intent.v1",
      Map.get(intent, "id") || Map.get(intent, "activity_id") || "contact_intent",
      Map.get(intent, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-filter report.
  """
  def from_contact_filter_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      contact_suppression_rows(
        Map.get(report, "suppressed_candidates", []),
        "contact_filter_report.suppressed_candidates"
      )

    package(
      rows,
      "contact_filter_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "contact_filter_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate-diff report.
  """
  def from_candidate_diff_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      candidate_diff_report_rows(
        report,
        "candidate_diff_report",
        Map.get(report, "source_window_lineage", [])
      )

    package(
      rows,
      "candidate_diff_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "candidate_diff_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate-rejection report.
  """
  def from_candidate_rejection_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> candidate_rejection_rows("candidate_rejection_report.rows")

    package(
      rows,
      "candidate_rejection_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "candidate_rejection_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a provider-counteroffer report.
  """
  def from_provider_counteroffer_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> provider_counteroffer_rows("provider_counteroffer_report.rows")

    package(
      rows,
      "provider_counteroffer_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "provider_counteroffer_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone invalidated-candidate row.
  """
  def from_invalidated_candidate(%{} = candidate) do
    candidate = stringify_keys(candidate)
    rows = candidate_diff_rows([candidate], "invalidated_candidate")

    package(
      rows,
      "invalidated_candidate.v1",
      Map.get(candidate, "id") || Map.get(candidate, "invalidated_candidate_id") ||
        "invalidated_candidate",
      Map.get(candidate, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-filter report.
  """
  def from_resource_filter_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      resource_filter_invalid_summary_rows(Map.get(report, "invalid_resource_summary_inputs", [])) ++
        resource_suppression_rows(
          Map.get(report, "suppressed_candidates", []),
          "resource_filter_report.suppressed_candidates"
        )

    package(
      rows,
      "resource_filter_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "resource_filter_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a freshness report.
  """
  def from_freshness_report(%{} = report) do
    report = stringify_keys(report)
    rows = freshness_rows(report, "freshness_report")

    package(
      rows,
      "freshness_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "freshness_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a refresh-budget report.
  """
  def from_refresh_budget_report(%{} = report) do
    report = stringify_keys(report)
    rows = refresh_budget_rows(report, "refresh_budget_report")

    package(
      rows,
      "refresh_budget_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "refresh_budget_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-acceptance report.
  """
  def from_model_acceptance_report(%{} = report) do
    report = stringify_keys(report)
    rows = model_acceptance_report_rows(report)

    package(
      rows,
      "model_acceptance_report.v1",
      Map.get(report, "report_id") || model_acceptance_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a validation safety-case summary.
  """
  def from_validation_safety_case_summary(%{} = summary) do
    summary = stringify_keys(summary)
    rows = validation_safety_case_summary_rows(summary)

    package(
      rows,
      "validation_safety_case_summary.v1",
      Map.get(summary, "summary_id") || validation_safety_case_summary_id(summary),
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-projection report.
  """
  def from_resource_projection_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      resource_projection_invalid_activity_rows(Map.get(report, "invalid_activity_inputs", [])) ++
        resource_projection_invalid_summary_rows(
          Map.get(report, "invalid_resource_summary_inputs", [])
        ) ++
        resource_projection_rows(Map.get(report, "projected_resources", []))

    package(
      rows,
      "resource_projection_report.v1",
      resource_projection_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-projection flow summary.
  """
  def from_resource_projection_flow_summary(%{} = summary) do
    summary = stringify_keys(summary)
    rows = resource_projection_flow_summary_rows(summary)

    package(
      rows,
      "resource_projection_flow_summary.v1",
      resource_projection_flow_summary_id(summary),
      Map.get(summary, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a constraint report.
  """
  def from_constraint_report(%{} = report) do
    report = stringify_keys(report)
    rows = constraint_rows(Map.get(report, "rows", []))

    package(
      rows,
      "constraint_report.v1",
      constraint_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from an objective-satisfaction report.
  """
  def from_objective_satisfaction_report(%{} = report) do
    report = stringify_keys(report)
    rows = objective_satisfaction_rows(Map.get(report, "rows", []))

    package(
      rows,
      "objective_satisfaction_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "objective_satisfaction_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a policy-decision artifact.
  """
  def from_policy_decision(%{} = decision) do
    decision = stringify_keys(decision)
    rows = policy_escalation_rows(decision, "policy_decision.escalations")

    package(
      rows,
      "policy_decision.v1",
      Map.get(decision, "id") || Map.get(decision, "policy_bundle_id") || "policy_decision",
      Map.get(decision, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone approval requirement.
  """
  def from_approval_requirement(%{} = requirement) do
    requirement = stringify_keys(requirement)
    rows = approval_rows([requirement], "approval_requirement")

    package(
      rows,
      "approval_requirement.v1",
      Map.get(requirement, "id") || Map.get(requirement, "activity_id") ||
        "approval_requirement",
      Map.get(requirement, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-contention report.
  """
  def from_contact_contention_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      contact_contention_invalid_input_rows(Map.get(report, "invalid_contact_inputs", [])) ++
        contact_contention_group_rows(Map.get(report, "conflict_groups", []))

    package(
      rows,
      "contact_contention_report.v1",
      Map.get(report, "id") || "contact_contention_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-contention resolution report.
  """
  def from_contact_contention_resolution_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      contact_contention_rows(
        Map.get(report, "recommendations", []),
        "contact_contention_resolution_report.recommendations"
      )

    package(
      rows,
      "contact_contention_resolution_report.v1",
      Map.get(report, "id") || "contact_contention_resolution_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a branch-comparison report.
  """
  def from_branch_comparison_report(%{} = report) do
    report = stringify_keys(report)
    rows = branch_comparison_rows(Map.get(report, "rows", []))

    package(
      rows,
      "branch_comparison_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "branch_comparison_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a ranking comparison report.
  """
  def from_ranking_comparison_report(%{} = report) do
    report = stringify_keys(report)
    rows = ranking_comparison_rows(Map.get(report, "rows", []))

    package(
      rows,
      "ranking_comparison_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "ranking_comparison_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a score-term report.
  """
  def from_score_term_report(%{} = report) do
    report = stringify_keys(report)
    rows = score_term_rows(Map.get(report, "rows", []))

    package(
      rows,
      "score_term_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "score_term_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from an objective-tradeoff report.
  """
  def from_objective_tradeoff_report(%{} = report) do
    report = stringify_keys(report)
    rows = objective_tradeoff_rows(Map.get(report, "tradeoffs", []))

    package(
      rows,
      "objective_tradeoff_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "objective_tradeoff_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a Pareto-frontier report.
  """
  def from_pareto_frontier_report(%{} = report) do
    report = stringify_keys(report)
    rows = pareto_frontier_rows(Map.get(report, "rows", []))

    package(
      rows,
      "pareto_frontier_report.v1",
      Map.get(report, "id") || Map.get(report, "source") || "pareto_frontier_report",
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a schema-validation report.
  """
  def from_schema_validation_report(%{} = report) do
    report = stringify_keys(report)
    rows = schema_validation_rows(report)

    package(
      rows,
      "schema_validation_report.v1",
      schema_validation_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from a schema-validation batch report.
  """
  def from_schema_validation_batch_report(%{} = report) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("reports", [])
      |> List.wrap()
      |> Enum.flat_map(&schema_validation_batch_report_rows/1)

    package(
      rows,
      "schema_validation_batch_report.v1",
      schema_validation_batch_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from an execution report.
  """
  def from_execution_report(%{} = report) do
    report = stringify_keys(report)
    rows = execution_report_rows(report)

    package(
      rows,
      "execution_report.v1",
      execution_report_id(report),
      Map.get(report, "provenance", %{})
    )
  end

  @doc """
  Builds an `operator_review_package.v1` from an operational-readiness report.
  """
  def from_operational_readiness_report(%{} = report) do
    report = stringify_keys(report)
    rows = operational_readiness_rows(report)

    package(
      rows,
      "operational_readiness_report.v1",
      Map.get(report, "report_id") || "operational_readiness_report",
      Map.get(report, "provenance", %{})
    )
    |> put_operational_readiness_report_summary(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a quality-gate report.
  """
  def from_quality_gate_report(%{} = report) do
    report = stringify_keys(report)
    rows = quality_gate_rows(report)

    package(
      rows,
      "quality_gate_report.v1",
      Map.get(report, "report_id") || "quality_gate_report",
      Map.get(report, "provenance", %{})
    )
    |> put_quality_gate_report_summary(report)
  end

  @doc """
   Builds an `operator_review_package.v1` from a V1 campaign artifact.
  """
  def from_campaign_artifact(%{} = artifact) do
    artifact = stringify_keys(artifact)

    rows =
      contact_contention_rows(
        get_in(artifact, ["contact_contention_resolution_report", "recommendations"]) || []
      ) ++
        contact_contention_group_rows(
          get_in(artifact, ["contact_contention_report", "conflict_groups"]) || [],
          "campaign_plan.contact_contention_report.conflict_groups"
        ) ++
        operational_timeline_rows(get_in(artifact, ["operational_timeline_report", "rows"]) || []) ++
        source_timeline_integrity_report_rows(
          Map.get(artifact, "timeline_integrity_report"),
          "campaign_plan.timeline_integrity_report"
        ) ++
        source_timeline_activity_precondition_summary_rows(
          Map.get(artifact, "timeline_activity_precondition_summaries"),
          "campaign_plan.timeline_activity_precondition_summaries"
        ) ++
        command_window_rows(get_in(artifact, ["command_window_report", "rows"]) || []) ++
        contact_allocation_rows(
          get_in(artifact, ["contact_allocation_report", "rows"]) || [],
          "campaign_plan.contact_allocation_report.rows"
        ) ++
        contact_allocation_capacity_pack_rows(
          get_in(artifact, ["contact_allocation_report", "reduced_capacity_pack_groups"]) || [],
          "campaign_plan.contact_allocation_report.reduced_capacity_pack_groups"
        ) ++
        contact_intent_rows(
          Map.get(artifact, "contact_intents", []),
          "campaign_plan.contact_intents"
        ) ++
        station_calendar_rows(
          get_in(artifact, ["station_calendar_report", "affected_contacts"]) || [],
          "campaign_plan.station_calendar_report.affected_contacts"
        ) ++
        link_capacity_report_rows(
          Map.get(artifact, "link_capacity_report"),
          "campaign_plan.link_capacity_report"
        ) ++
        resource_projection_rows(
          projected_resource_rows(Map.get(artifact, "resource_projection_report")),
          "campaign_plan.resource_projection_report.projected_resources"
        ) ++
        resource_projection_flow_summary_rows(
          Map.get(artifact, "resource_projection_flow_summary") || %{},
          "campaign_plan.resource_projection_flow_summary.projected_resources"
        ) ++
        objective_satisfaction_rows(
          get_in(artifact, ["objective_satisfaction_report", "rows"]) || [],
          "campaign_plan.objective_satisfaction_report.rows"
        ) ++
        score_term_rows(
          get_in(artifact, ["score_term_report", "rows"]) || [],
          "campaign_plan.score_term_report.rows"
        ) ++
        objective_tradeoff_rows(
          get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
          "campaign_plan.objective_tradeoff_report.tradeoffs"
        ) ++
        constraint_rows(
          get_in(artifact, ["constraint_report", "rows"]) || [],
          "campaign_plan.constraint_report.rows"
        ) ++
        contact_suppression_rows(
          contact_suppressed_candidates(artifact, "contact_filter_report"),
          "campaign_plan.contact_filter_report.suppressed_candidates"
        ) ++
        resource_suppression_rows(resource_suppressed_candidates(artifact)) ++
        warning_rows(Map.get(artifact, "warnings", []), "campaign_plan.warnings")

    package(
      rows,
      "campaign_plan.v1",
      Map.get(artifact, "plan_id"),
      Map.get(artifact, "provenance", %{})
    )
    |> put_contact_allocation_count_map(artifact, [
      ["contact_allocation_report"]
    ])
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate refresh artifact.
  """
  def from_candidate_refresh_artifact(%{} = artifact) do
    artifact = stringify_keys(artifact)

    run_input_sources = candidate_refresh_run_input_sources(artifact)

    rows =
      (contact_intent_rows(
         Map.get(artifact, "contact_intents", []),
         "candidate_refresh.contact_intents"
       ) ++
         candidate_refresh_source_contact_intent_rows(artifact) ++
         candidate_refresh_contact_allocation_rows(artifact) ++
         candidate_refresh_link_capacity_rows(artifact) ++
         candidate_refresh_contact_contention_rows(artifact) ++
         candidate_refresh_contact_contention_resolution_rows(artifact) ++
         candidate_refresh_candidate_diff_rows(artifact) ++
         candidate_refresh_command_window_rows(artifact) ++
         candidate_refresh_maneuver_review_rows(artifact) ++
         candidate_refresh_timeline_diff_rows(artifact) ++
         candidate_refresh_timeline_integrity_rows(artifact) ++
         candidate_refresh_timeline_dependency_impact_rows(artifact) ++
         candidate_refresh_timeline_publication_rows(artifact) ++
         candidate_refresh_timeline_activity_precondition_rows(artifact) ++
         candidate_refresh_timeline_lifecycle_state_rows(artifact) ++
         candidate_refresh_timeline_activity_state_rows(artifact) ++
         candidate_refresh_timeline_activity_lifecycle_state_rows(artifact) ++
         candidate_refresh_timeline_preservation_rows(artifact) ++
         candidate_refresh_timeline_transition_application_rows(artifact) ++
         candidate_refresh_constraint_rows(artifact) ++
         candidate_refresh_objective_satisfaction_rows(artifact) ++
         candidate_refresh_score_term_rows(artifact) ++
         candidate_refresh_objective_tradeoff_rows(artifact) ++
         candidate_refresh_candidate_rejection_rows(artifact) ++
         candidate_refresh_freshness_rows(artifact) ++
         candidate_refresh_refresh_budget_rows(artifact) ++
         candidate_refresh_model_acceptance_rows(artifact) ++
         candidate_refresh_validation_safety_case_rows(artifact) ++
         candidate_refresh_schema_validation_rows(artifact) ++
         candidate_refresh_quality_gate_rows(artifact) ++
         candidate_refresh_timeline_feedback_rows(artifact) ++
         candidate_refresh_operational_timeline_rows(artifact) ++
         candidate_refresh_operational_readiness_rows(artifact) ++
         candidate_refresh_contact_filter_rows(artifact) ++
         candidate_refresh_resource_filter_rows(artifact) ++
         candidate_refresh_resource_projection_rows(artifact) ++
         candidate_refresh_provider_counteroffer_rows(artifact) ++
         candidate_refresh_station_calendar_rows(artifact) ++
         candidate_refresh_station_reservation_rows(artifact) ++
         candidate_refresh_warning_rows(artifact))
      |> put_candidate_refresh_run_input_sources(run_input_sources)

    package(
      rows,
      "candidate_refresh.v1",
      Map.get(artifact, "refresh_id"),
      Map.get(artifact, "provenance", %{})
    )
    |> put_candidate_refresh_contact_allocation_count_map(artifact)
  end

  @doc """
  Builds an `operator_review_package.v1` from a V2 repair artifact.
  """
  def from_repair_artifact(%{} = artifact) do
    artifact = stringify_keys(artifact)

    rows =
      approval_rows(
        Map.get(artifact, "approval_requirements", []),
        "campaign_repair.approval_requirements"
      ) ++
        policy_escalation_rows(
          Map.get(artifact, "policy_decision"),
          "campaign_repair.policy_decision"
        ) ++
        feedback_rows(
          repair_timeline_feedback_rows(artifact),
          "campaign_repair.source_timeline_feedback_report.rows"
        ) ++
        operational_timeline_rows(get_in(artifact, ["operational_timeline_report", "rows"]) || []) ++
        timeline_transition_application_rows(
          get_in(artifact, ["timeline_transition_application_report", "applications"]) || [],
          "campaign_repair.timeline_transition_application_report.applications",
          Map.get(artifact, "approval_policy")
        ) ++
        command_window_rows(get_in(artifact, ["command_window_report", "rows"]) || []) ++
        plan_delta_rows(Map.get(artifact, "deltas", []), "campaign_repair.deltas") ++
        score_term_rows(
          get_in(artifact, ["score_term_report", "rows"]) || [],
          "campaign_repair.score_term_report.rows"
        ) ++
        objective_tradeoff_rows(
          get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
          "campaign_repair.objective_tradeoff_report.tradeoffs"
        ) ++
        candidate_diff_report_rows(
          Map.get(artifact, "source_candidate_diff_report"),
          "campaign_repair.source_candidate_diff_report"
        ) ++
        constraint_rows(
          get_in(artifact, ["constraint_report", "rows"]) || [],
          "campaign_repair.constraint_report.rows"
        ) ++
        link_capacity_report_rows(
          Map.get(artifact, "link_capacity_report"),
          "campaign_repair.link_capacity_report"
        ) ++
        station_calendar_rows(
          get_in(artifact, ["source_station_calendar_report", "affected_contacts"]) || [],
          "campaign_repair.source_station_calendar_report.affected_contacts"
        ) ++
        timeline_protection_rows(
          get_in(artifact, ["repair_metadata", "timeline_protection"]),
          "campaign_repair.repair_metadata.timeline_protection"
        ) ++
        contact_suppression_rows(
          contact_suppressed_candidates(artifact, "source_contact_filter_report"),
          "campaign_repair.source_contact_filter_report.suppressed_candidates"
        ) ++
        contact_allocation_rows(
          get_in(artifact, ["source_contact_allocation_report", "rows"]) || [],
          "campaign_repair.source_contact_allocation_report.rows"
        ) ++
        contact_allocation_capacity_pack_rows(
          get_in(artifact, [
            "source_contact_allocation_report",
            "reduced_capacity_pack_groups"
          ]) || [],
          "campaign_repair.source_contact_allocation_report.reduced_capacity_pack_groups"
        ) ++
        contact_allocation_rows(
          get_in(artifact, ["contact_allocation_report", "rows"]) || [],
          "campaign_repair.contact_allocation_report.rows"
        ) ++
        contact_allocation_capacity_pack_rows(
          get_in(artifact, ["contact_allocation_report", "reduced_capacity_pack_groups"]) || [],
          "campaign_repair.contact_allocation_report.reduced_capacity_pack_groups"
        ) ++
        contact_intent_rows(
          Map.get(artifact, "source_contact_intents", []),
          "campaign_repair.source_contact_intents"
        ) ++
        resource_suppression_rows(
          resource_suppressed_candidates(artifact, "source_resource_filter_report"),
          "campaign_repair.source_resource_filter_report.suppressed_candidates"
        ) ++
        resource_projection_rows(
          projected_resource_rows(Map.get(artifact, "source_resource_projection_report")),
          "campaign_repair.source_resource_projection_report.projected_resources"
        ) ++
        freshness_rows(
          Map.get(artifact, "source_freshness_report"),
          "campaign_repair.source_freshness_report"
        ) ++
        refresh_budget_rows(
          Map.get(artifact, "source_refresh_budget_report"),
          "campaign_repair.source_refresh_budget_report"
        ) ++
        warning_rows(Map.get(artifact, "warnings", []), "campaign_repair.warnings")

    package(
      rows,
      "campaign_repair.v2",
      get_in(artifact, ["repair_metadata", "repair_id"]),
      Map.get(artifact, "provenance", %{})
    )
    |> put_contact_allocation_count_map(artifact, [
      ["source_contact_allocation_report"],
      ["contact_allocation_report"],
      ["source_contact_allocation_provider_reservation_request_summary"],
      ["contact_allocation_provider_reservation_request_summary"]
    ])
  end

  @doc """
  Builds an `operator_review_package.v1` from a V3 strategy artifact.
  """
  def from_strategy_artifact(%{} = artifact) do
    artifact = stringify_keys(artifact)
    recommendation = Map.get(artifact, "recommendation", %{})

    operational_feedback_context =
      operational_feedback_review_context(Map.get(artifact, "operational_feedback_provenance"))

    rows =
      strategy_recommendation_rows(recommendation, operational_feedback_context) ++
        strategy_tradeoff_rows(recommendation) ++
        branch_comparison_rows(
          get_in(artifact, ["branch_comparison_report", "rows"]) || [],
          "campaign_strategy.branch_comparison_report.rows"
        ) ++
        ranking_comparison_rows(
          get_in(artifact, ["ranking_comparison_report", "rows"]) || [],
          "campaign_strategy.ranking_comparison_report.rows"
        ) ++
        pareto_frontier_rows(
          get_in(artifact, ["pareto_frontier_report", "rows"]) || [],
          "campaign_strategy.pareto_frontier_report.rows"
        ) ++
        score_term_rows(
          get_in(artifact, ["score_term_report", "rows"]) || [],
          "campaign_strategy.score_term_report.rows"
        ) ++
        objective_tradeoff_rows(
          get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
          "campaign_strategy.objective_tradeoff_report.tradeoffs"
        ) ++
        approval_rows(
          Map.get(recommendation, "requires_approval", []),
          "campaign_strategy.recommendation.requires_approval"
        ) ++
        policy_escalation_rows(
          Map.get(artifact, "policy_decision"),
          "campaign_strategy.policy_decision"
        ) ++
        risk_rows(
          Map.get(recommendation, "risks_remaining", []),
          "campaign_strategy.recommendation.risks_remaining"
        ) ++
        strategy_repair_constraint_rows(Map.get(artifact, "branches", [])) ++
        strategy_repair_operational_timeline_rows(Map.get(artifact, "branches", [])) ++
        strategy_resource_projection_rows(Map.get(artifact, "branches", [])) ++
        strategy_candidate_diff_rows(Map.get(artifact, "branches", [])) ++
        strategy_contact_suppression_rows(Map.get(artifact, "branches", [])) ++
        strategy_station_calendar_rows(Map.get(artifact, "branches", [])) ++
        strategy_repair_link_capacity_rows(Map.get(artifact, "branches", [])) ++
        strategy_repair_score_term_rows(Map.get(artifact, "branches", [])) ++
        strategy_repair_objective_tradeoff_rows(Map.get(artifact, "branches", [])) ++
        strategy_contact_allocation_rows(Map.get(artifact, "branches", [])) ++
        strategy_repair_contact_allocation_rows(Map.get(artifact, "branches", [])) ++
        strategy_contact_intent_rows(Map.get(artifact, "branches", [])) ++
        strategy_resource_suppression_rows(Map.get(artifact, "branches", [])) ++
        strategy_freshness_rows(Map.get(artifact, "branches", [])) ++
        strategy_refresh_budget_rows(Map.get(artifact, "branches", [])) ++
        strategy_timeline_feedback_rows(Map.get(artifact, "branches", [])) ++
        strategy_command_window_rows(Map.get(artifact, "branches", [])) ++
        strategy_warning_rows(Map.get(artifact, "branches", []))

    package(
      rows,
      "campaign_strategy.v3",
      get_in(artifact, ["strategy_metadata", "strategy_id"]),
      Map.get(artifact, "provenance", %{})
    )
    |> put_strategy_contact_allocation_count_map(artifact)
  end

  defp package(rows, source_artifact_type, source_artifact_id, provenance) do
    rows =
      rows
      |> Enum.map(&normalize_cadence_import_statuses/1)
      |> Enum.map(&put_review_queue/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} -> Map.put(row, "rank", index) end)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "review_count" => length(rows),
      "approval_requirement_count" =>
        Enum.count(rows, &(&1["review_type"] == "approval_requirement")),
      "policy_escalation_count" => Enum.count(rows, &(&1["review_type"] == "policy_escalation")),
      "operational_timeline_count" =>
        Enum.count(rows, &(&1["review_type"] == "operational_timeline_review")),
      "contact_suppression_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_suppression")),
      "resource_projection_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "resource_projection_review")),
      "resource_suppression_count" =>
        Enum.count(rows, &(&1["review_type"] == "resource_suppression")),
      "contention_recommendation_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_contention_recommendation")),
      "contention_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_contention_review")),
      "command_window_count" => Enum.count(rows, &(&1["review_type"] == "command_window_review")),
      "station_calendar_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "station_calendar_review")),
      "station_reservation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "station_reservation_review")),
      "link_capacity_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "link_capacity_review")),
      "contact_allocation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_allocation_review")),
      "contact_allocation_capacity_pack_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_allocation_capacity_pack_review")),
      "contact_intent_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_intent_review")),
      "candidate_rejection_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "candidate_rejection_review")),
      "provider_counteroffer_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "provider_counteroffer_review")),
      "candidate_diff_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "candidate_diff_review")),
      "freshness_review_count" => Enum.count(rows, &(&1["review_type"] == "freshness_review")),
      "refresh_budget_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "refresh_budget_review")),
      "model_acceptance_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "model_acceptance_review")),
      "validation_safety_case_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "validation_safety_case_review")),
      "realized_feedback_count" => Enum.count(rows, &(&1["review_type"] == "realized_feedback")),
      "timeline_diff_count" => Enum.count(rows, &(&1["review_type"] == "timeline_diff_review")),
      "timeline_dependency_impact_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_dependency_impact_review")),
      "timeline_publication_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_publication_review")),
      "timeline_activity_precondition_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_activity_precondition_review")),
      "timeline_lifecycle_state_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_lifecycle_state_review")),
      "timeline_preservation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_preservation_review")),
      "timeline_integrity_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_integrity_review")),
      "maneuver_review_count" => Enum.count(rows, &(&1["review_type"] == "maneuver_review")),
      "plan_delta_count" => Enum.count(rows, &(&1["review_type"] == "plan_delta_review")),
      "timeline_protection_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_protection")),
      "warning_count" => Enum.count(rows, &(&1["review_type"] == "warning")),
      "risk_count" => Enum.count(rows, &(&1["review_type"] == "risk_explanation")),
      "recommendation_count" =>
        Enum.count(rows, &(&1["review_type"] == "strategy_recommendation")),
      "tradeoff_count" => Enum.count(rows, &(&1["review_type"] == "strategy_tradeoff")),
      "score_term_review_count" => Enum.count(rows, &(&1["review_type"] == "score_term_review")),
      "objective_tradeoff_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "objective_tradeoff_review")),
      "ranking_comparison_count" =>
        Enum.count(rows, &(&1["review_type"] == "ranking_comparison_review")),
      "pareto_frontier_count" =>
        Enum.count(rows, &(&1["review_type"] == "pareto_frontier_review")),
      "constraint_review_count" => Enum.count(rows, &(&1["review_type"] == "constraint_review")),
      "objective_satisfaction_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "objective_satisfaction_review")),
      "schema_validation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "schema_validation_review")),
      "execution_review_count" => Enum.count(rows, &(&1["review_type"] == "execution_review")),
      "operational_readiness_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "operational_readiness_review")),
      "quality_gate_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "quality_gate_review")),
      "review_type_counts" => count_by(rows, "review_type"),
      "review_queue_counts" => count_by(rows, "review_queue_key"),
      "approval_status_counts" => count_by(rows, "approval_status"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "source_cadence_import_status_counts" => count_by(rows, "source_cadence_import_status"),
      "replacement_cadence_import_status_counts" =>
        count_by(rows, "replacement_cadence_import_status"),
      "rows" => rows,
      "provenance" => provenance,
      "model_limits" => model_limits(),
      "assumptions" => %{
        "boundary" => "artifact_only_no_api_or_database_writes",
        "operator_review_model" =>
          "existing_approval_warning_risk_recommendation_and_tradeoff_fields_normalized_for_import"
      }
    }
  end

  defp snapshot_id(snapshot) do
    Map.get(snapshot, "snapshot_id") ||
      get_in(snapshot, ["metadata", "snapshot_id"]) ||
      "realized_state_snapshot"
  end

  defp normalize_cadence_import_statuses(%{} = row) do
    row
    |> normalize_cadence_import_status_field("cadence_import_status")
    |> normalize_cadence_import_status_field("source_cadence_import_status")
    |> normalize_cadence_import_status_field("replacement_cadence_import_status")
  end

  defp normalize_cadence_import_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, status} ->
        normalized_status = encode_value(status)

        if normalized_status in @cadence_import_statuses do
          Map.put(row, field, normalized_status)
        else
          row
          |> Map.put(field, "invalid")
          |> Map.put("unsupported_#{field}", encode_value(status))
          |> maybe_mark_invalid_cadence_import(field)
        end

      :error ->
        row
    end
  end

  defp maybe_mark_invalid_cadence_import(row, "cadence_import_status") do
    row
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("has_cadence_import", false)
    |> Map.put_new("invalid_cadence_import_reason", "unsupported_cadence_import_status")
  end

  defp maybe_mark_invalid_cadence_import(row, "source_cadence_import_status") do
    Map.put(row, "source_has_cadence_import", false)
  end

  defp maybe_mark_invalid_cadence_import(row, "replacement_cadence_import_status") do
    Map.put(row, "replacement_has_cadence_import", false)
  end

  defp maybe_mark_invalid_cadence_import(row, _field), do: row

  defp put_review_queue(row) do
    review_type = review_queue_value(row["review_type"], "review")

    review_action =
      review_queue_value(row["required_operator_action"] || row["action"], review_type)

    approval_status = review_queue_value(row["approval_status"], "unspecified")

    row
    |> Map.put("review_queue", review_action)
    |> Map.put("review_queue_key", Enum.join([review_type, review_action, approval_status], "|"))
  end

  defp review_queue_value(value, _default) when is_binary(value) and value != "", do: value
  defp review_queue_value(_value, default), do: default

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_contention_rows(recommendations),
    do:
      contact_contention_rows(
        recommendations,
        "campaign_plan.contact_contention_resolution_report.recommendations"
      )

  defp contact_contention_rows(recommendations, source) do
    recommendations
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {recommendation, index} ->
      requirement = recommendation["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = recommendation["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(recommendation["policy_decision"] || %{})
      policy_escalation = recommendation |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention", recommendation["group_id"], index]),
        "review_type" => "contact_contention_recommendation",
        "source" => source,
        "subject_id" => recommendation["group_id"],
        "action" =>
          Map.get(recommendation, "action", "recommend_preferred_contact_for_operator_review"),
        "required_operator_action" =>
          Map.get(recommendation, "action", "recommend_preferred_contact_for_operator_review"),
        "approval_status" => Map.get(recommendation, "review_status", "operator_review_required"),
        "reason" =>
          "resolve #{Map.get(recommendation, "ground_station_id", "station")} contact contention",
        "resource_scope" => recommendation["resource_scope"],
        "ground_station_id" => recommendation["ground_station_id"],
        "ground_station_ids" => recommendation["ground_station_ids"],
        "spacecraft_id" => recommendation["spacecraft_id"],
        "spacecraft_ids" => recommendation["spacecraft_ids"],
        "direction" => recommendation["direction"],
        "directions" => recommendation["directions"],
        "starts_at_s" => recommendation["starts_at_s"],
        "ends_at_s" => recommendation["ends_at_s"],
        "contention_window_s" => recommendation["contention_window_s"],
        "total_contact_duration_s" => recommendation["total_contact_duration_s"],
        "overlap_duration_s" => recommendation["overlap_duration_s"],
        "max_concurrent_contacts" => recommendation["max_concurrent_contacts"],
        "overlap_contact_pair_count" => recommendation["overlap_contact_pair_count"],
        "selected_contact_id" => recommendation["selected_contact_id"],
        "selected_contact_ids" => recommendation["selected_contact_ids"],
        "selected_priority" => recommendation["selected_priority"],
        "selected_priority_source" => recommendation["selected_priority_source"],
        "deferred_contact_ids" => Map.get(recommendation, "deferred_contact_ids", []),
        "review_contact_ids" => recommendation["review_contact_ids"],
        "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
        "candidate_count" => recommendation["candidate_count"],
        "selection_reason" => recommendation["selection_reason"],
        "resolution_selection_rule" => recommendation["resolution_selection_rule"],
        "resolution_priority_fields" => recommendation["resolution_priority_fields"],
        "requested_priority_fields" => recommendation["requested_priority_fields"],
        "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
        "priority_fields_without_numeric_evidence_count" =>
          recommendation["priority_fields_without_numeric_evidence_count"],
        "priority_fields_without_numeric_evidence" =>
          recommendation["priority_fields_without_numeric_evidence"],
        "resolution_priority_override_count" =>
          recommendation["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          recommendation["resolution_priority_override_contact_ids"],
        "ignored_priority_override_count" => recommendation["ignored_priority_override_count"],
        "ignored_priority_override_keys" => recommendation["ignored_priority_override_keys"],
        "ignored_priority_override_contact_ids" =>
          recommendation["ignored_priority_override_contact_ids"],
        "ignored_priority_override_input" => recommendation["ignored_priority_override_input"],
        "resolution_tie_breakers" => recommendation["resolution_tie_breakers"],
        "requested_selection_rule" => recommendation["requested_selection_rule"],
        "ignored_tie_breakers" => recommendation["ignored_tie_breakers"],
        "ignored_policy_input" => recommendation["ignored_policy_input"],
        "policy_warnings" => recommendation["policy_warnings"],
        "contact_success" => recommendation["contact_success"],
        "contact_success_factor" => recommendation["contact_success_factor"],
        "contact_success_factor_source" => recommendation["contact_success_factor_source"],
        "command_success" => recommendation["command_success"],
        "contact_result" => provider_result_artifact_value(recommendation["contact_result"]),
        "command_result" => provider_result_artifact_value(recommendation["command_result"]),
        "command_success_factor" => recommendation["command_success_factor"],
        "command_success_factor_source" => recommendation["command_success_factor_source"],
        "actual_throughput_mb" => recommendation["actual_throughput_mb"],
        "actual_data_rate_throughput_derivations" =>
          recommendation["actual_data_rate_throughput_derivations"],
        "resolution_status" => recommendation["resolution_status"],
        "resolution_issue" => recommendation["resolution_issue"],
        "capacity_pack_required_capacity_fraction" =>
          recommendation["capacity_pack_required_capacity_fraction"],
        "capacity_pack_selected_required_capacity_fraction" =>
          recommendation["capacity_pack_selected_required_capacity_fraction"],
        "capacity_pack_deferred_required_capacity_fraction" =>
          recommendation["capacity_pack_deferred_required_capacity_fraction"],
        "capacity_pack_required_capacity_fraction_by_status" =>
          recommendation["capacity_pack_required_capacity_fraction_by_status"],
        "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
          recommendation["capacity_pack_required_capacity_fraction_by_ground_station_id"],
        "required_capacity_fraction_source_counts" =>
          recommendation["required_capacity_fraction_source_counts"],
        "source_summary_model" => recommendation["source_summary_model"],
        "source_summary_schema_contract" => recommendation["source_summary_schema_contract"],
        "source_summary_source" => recommendation["source_summary_source"],
        "source_artifact_type" => recommendation["source_artifact_type"],
        "schema_contract" => recommendation["schema_contract"],
        "duplicate_contact_ids" => recommendation["duplicate_contact_ids"],
        "duplicate_contact_id_count" => recommendation["duplicate_contact_id_count"],
        "duplicate_contact_candidate_count" =>
          recommendation["duplicate_contact_candidate_count"],
        "duplicate_contact_candidates" => recommendation["duplicate_contact_candidates"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => recommendation["approval_requirements"],
        "approval_rule_matches" => recommendation["approval_rule_matches"],
        "source_policy_decision" => recommendation["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_contention_resolution_summary" =>
          recommendation["source_contact_contention_resolution_summary"],
        "source_recommendation" => recommendation
      }
      |> Map.merge(Map.take(recommendation, station_calendar_context_fields()))
      |> compact_map()
    end)
  end

  defp contact_contention_group_rows(
         groups,
         source \\ "contact_contention_report.conflict_groups"
       ) do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      requirement = group["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = group["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(group["policy_decision"] || %{})
      policy_escalation = group |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention_group", group["id"], index]),
        "review_type" => "contact_contention_review",
        "source" => source,
        "subject_id" => group["id"],
        "resource_scope" => group["resource_scope"],
        "ground_station_id" => group["ground_station_id"],
        "ground_station_ids" => group["ground_station_ids"],
        "spacecraft_id" => group["spacecraft_id"],
        "spacecraft_ids" => group["spacecraft_ids"],
        "starts_at_s" => group["starts_at_s"],
        "ends_at_s" => group["ends_at_s"],
        "direction" => group["direction"],
        "directions" => group["directions"],
        "contact_count" => group["contact_count"],
        "contention_window_s" => group["contention_window_s"],
        "total_contact_duration_s" => group["total_contact_duration_s"],
        "overlap_duration_s" => group["overlap_duration_s"],
        "max_concurrent_contacts" => group["max_concurrent_contacts"],
        "overlap_contact_pair_count" => group["overlap_contact_pair_count"],
        "contact_ids" => Map.get(group, "contact_ids", []),
        "duplicate_contact_ids" => group["duplicate_contact_ids"],
        "duplicate_contact_id_count" => group["duplicate_contact_id_count"],
        "duplicate_contact_candidate_count" => group["duplicate_contact_candidate_count"],
        "source_contact_candidates" => group["source_contact_candidates"],
        "contact_success" => group["contact_success"],
        "contact_success_factor" => group["contact_success_factor"],
        "contact_success_factor_source" => group["contact_success_factor_source"],
        "command_success" => group["command_success"],
        "contact_result" => provider_result_artifact_value(group["contact_result"]),
        "command_result" => provider_result_artifact_value(group["command_result"]),
        "command_success_factor" => group["command_success_factor"],
        "command_success_factor_source" => group["command_success_factor_source"],
        "actual_throughput_mb" => group["actual_throughput_mb"],
        "actual_data_rate_throughput_derivations" =>
          group["actual_data_rate_throughput_derivations"],
        "source_window_ids" => Map.get(group, "source_window_ids", []),
        "scenario_ids" => Map.get(group, "scenario_ids", []),
        "action" => Map.get(group, "required_operator_action", "review_contact_contention"),
        "required_operator_action" =>
          Map.get(group, "required_operator_action", "review_contact_contention"),
        "approval_status" => Map.get(group, "approval_status", "operator_review_required"),
        "operator_action_reason" => group["operator_action_reason"],
        "reason" => contact_contention_group_reason(group),
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => group["approval_requirements"],
        "approval_rule_matches" => group["approval_rule_matches"],
        "source_policy_decision" => group["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contention_group" => group
      }
      |> Map.merge(Map.take(group, station_calendar_context_fields()))
      |> compact_map()
    end)
  end

  defp contact_contention_invalid_input_rows(
         rows,
         source \\ "contact_contention_report.invalid_contact_inputs"
       ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention_invalid_input", row["contact_id"], index]),
        "review_type" => "contact_contention_review",
        "source" => source,
        "subject_id" => row["id"],
        "contact_id" => row["contact_id"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "direction" => row["direction"],
        "directions" => row["directions"],
        "contact_count" => Map.get(row, "contact_count", 1),
        "scenario_ids" => Map.get(row, "scenario_ids", []),
        "action" =>
          Map.get(row, "required_operator_action", "review_invalid_contact_contention_input"),
        "required_operator_action" =>
          Map.get(row, "required_operator_action", "review_invalid_contact_contention_input"),
        "approval_status" => Map.get(row, "approval_status", "operator_review_required"),
        "operator_action_reason" => row["operator_action_reason"],
        "reason" => invalid_contact_input_reason(row),
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_invalid_contact_input" => row
      }
      |> compact_map()
    end)
  end

  defp contact_contention_group_reason(%{
         "ground_station_id" => station,
         "contact_count" => contact_count
       }) do
    "review #{contact_count} overlapping contacts at #{station}"
  end

  defp contact_contention_group_reason(_group), do: "review contact contention group"

  defp invalid_contact_input_reason(%{"invalid_contact_input_reason" => reason}) do
    "review invalid contact contention input: #{reason}"
  end

  defp invalid_contact_input_reason(_row), do: "review invalid contact contention input"

  defp branch_comparison_rows(rows, source \\ "branch_comparison_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      branch_id = Map.get(row, "branch_id")
      delta = Map.get(row, "score_delta_from_recommended")

      %{
        "id" => review_id(["branch_comparison", branch_id, index]),
        "review_type" => "strategy_tradeoff",
        "source" => source,
        "subject_id" => branch_id,
        "branch_id" => branch_id,
        "action" => "review_branch_comparison",
        "required_operator_action" => "review_branch_comparison",
        "approval_status" => Map.get(row, "approval_status", "operator_review_required"),
        "reason" => branch_comparison_reason(row),
        "dimension" => "branch_score",
        "baseline" => Map.get(row, "score"),
        "recommended" => recommended_branch_score(row),
        "delta" => delta,
        "risk_count" => row["risk_count"],
        "risk_types" => row["risk_types"],
        "high_risk_types" => row["high_risk_types"],
        "branch_event_count" => row["branch_event_count"],
        "branch_event_types" => row["branch_event_types"],
        "branch_event_trust_boundary_status_counts" =>
          row["branch_event_trust_boundary_status_counts"],
        "combined_source_branch_ids" => row["combined_source_branch_ids"],
        "branch_ground_station_ids" => row["branch_ground_station_ids"],
        "branch_scenario_ids" => row["branch_scenario_ids"],
        "branch_target_ids" => row["branch_target_ids"],
        "branch_collection_ids" => row["branch_collection_ids"],
        "branch_product_ids" => row["branch_product_ids"],
        "branch_payload_ids" => row["branch_payload_ids"],
        "branch_instrument_ids" => row["branch_instrument_ids"],
        "branch_objective_ids" => row["branch_objective_ids"],
        "branch_objective_types" => row["branch_objective_types"],
        "branch_objective_statuses" => row["branch_objective_statuses"],
        "branch_source_objective_statuses" => row["branch_source_objective_statuses"],
        "branch_feedback_sources" => row["branch_feedback_sources"],
        "branch_feedback_scopes" => row["branch_feedback_scopes"],
        "branch_contact_results" => row["branch_contact_results"],
        "branch_realized_statuses" => row["branch_realized_statuses"],
        "branch_transition_types" => row["branch_transition_types"],
        "branch_transition_categories" => row["branch_transition_categories"],
        "branch_transition_reasons" => row["branch_transition_reasons"],
        "branch_requires_operator_review" => row["branch_requires_operator_review"],
        "branch_requires_operator_review_count" => row["branch_requires_operator_review_count"],
        "branch_missed_downlink_activity_ids" => row["branch_missed_downlink_activity_ids"],
        "branch_maneuver_execution_uncertainty_activity_ids" =>
          row["branch_maneuver_execution_uncertainty_activity_ids"],
        "branch_maneuver_execution_uncertainty_timeline_ids" =>
          row["branch_maneuver_execution_uncertainty_timeline_ids"],
        "branch_maneuver_execution_uncertainty_maneuver_ids" =>
          row["branch_maneuver_execution_uncertainty_maneuver_ids"],
        "branch_maneuver_execution_uncertainty_statuses" =>
          row["branch_maneuver_execution_uncertainty_statuses"],
        "branch_maneuver_execution_uncertainty_sources" =>
          row["branch_maneuver_execution_uncertainty_sources"],
        "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" =>
          row["branch_maneuver_execution_uncertainty_max_timing_3sigma_s"],
        "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" =>
          row["branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s"],
        "branch_timeline_integrity_activity_ids" => row["branch_timeline_integrity_activity_ids"],
        "branch_timeline_integrity_timeline_ids" => row["branch_timeline_integrity_timeline_ids"],
        "branch_missing_dependency_activity_ids" => row["branch_missing_dependency_activity_ids"],
        "branch_missing_dependency_timeline_ids" => row["branch_missing_dependency_timeline_ids"],
        "branch_dependency_cycle_activity_ids" => row["branch_dependency_cycle_activity_ids"],
        "branch_dependency_cycle_timeline_ids" => row["branch_dependency_cycle_timeline_ids"],
        "branch_dependency_order_violation_activity_ids" =>
          row["branch_dependency_order_violation_activity_ids"],
        "branch_dependency_order_violation_timeline_ids" =>
          row["branch_dependency_order_violation_timeline_ids"],
        "branch_exclusivity_violation_activity_ids" =>
          row["branch_exclusivity_violation_activity_ids"],
        "branch_exclusivity_violation_timeline_ids" =>
          row["branch_exclusivity_violation_timeline_ids"],
        "branch_exclusivity_violation_groups" => row["branch_exclusivity_violation_groups"],
        "branch_source_activity_ids" => row["branch_source_activity_ids"],
        "branch_directions" => row["branch_directions"],
        "branch_station_availabilities" => row["branch_station_availabilities"],
        "branch_station_contention_statuses" => row["branch_station_contention_statuses"],
        "branch_station_calendar_entry_ids" => row["branch_station_calendar_entry_ids"],
        "branch_station_calendar_provider_ids" => row["branch_station_calendar_provider_ids"],
        "branch_station_calendar_provider_entry_ids" =>
          row["branch_station_calendar_provider_entry_ids"],
        "branch_station_calendar_directions" => row["branch_station_calendar_directions"],
        "branch_station_calendar_statuses" => row["branch_station_calendar_statuses"],
        "branch_station_calendar_trust_boundary_statuses" =>
          row["branch_station_calendar_trust_boundary_statuses"],
        "branch_station_reservation_ids" => row["branch_station_reservation_ids"],
        "branch_station_reserved_by" => row["branch_station_reserved_by"],
        "branch_station_reservation_statuses" => row["branch_station_reservation_statuses"],
        "branch_station_reservation_match_statuses" =>
          row["branch_station_reservation_match_statuses"],
        "branch_image_quality_min_score" => row["branch_image_quality_min_score"],
        "branch_image_quality_statuses" => row["branch_image_quality_statuses"],
        "branch_image_quality_sources" => row["branch_image_quality_sources"],
        "branch_cloud_cover_max_fraction" => row["branch_cloud_cover_max_fraction"],
        "branch_blur_max_score" => row["branch_blur_max_score"],
        "branch_max_latency_s" => row["branch_max_latency_s"],
        "branch_planned_latency_s" => row["branch_planned_latency_s"],
        "branch_required_contacts" => row["branch_required_contacts"],
        "branch_planned_contacts" => row["branch_planned_contacts"],
        "branch_required_downlink_mb" => row["branch_required_downlink_mb"],
        "branch_planned_downlink_mb" => row["branch_planned_downlink_mb"],
        "branch_actual_downlink_completion_ratio" =>
          row["branch_actual_downlink_completion_ratio"],
        "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
        "capacity_pack_statuses" => row["capacity_pack_statuses"],
        "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
        "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
        "capacity_pack_max_required_capacity_fraction" =>
          row["capacity_pack_max_required_capacity_fraction"],
        "capacity_pack_total_required_capacity_fraction" =>
          row["capacity_pack_total_required_capacity_fraction"],
        "capacity_pack_required_capacity_sources" =>
          row["capacity_pack_required_capacity_sources"],
        "target_branch_base_id" => row["target_branch_base_id"],
        "target_branch_identity" => row["target_branch_identity"],
        "priority_commitment_required_target_count" =>
          row["priority_commitment_required_target_count"],
        "priority_commitment_satisfied_target_count" =>
          row["priority_commitment_satisfied_target_count"],
        "priority_commitment_missed_target_count" =>
          row["priority_commitment_missed_target_count"],
        "priority_commitment_required_target_ids" =>
          row["priority_commitment_required_target_ids"],
        "priority_commitment_satisfied_target_ids" =>
          row["priority_commitment_satisfied_target_ids"],
        "priority_commitment_missed_target_ids" => row["priority_commitment_missed_target_ids"],
        "priority_commitment_required_observation_count" =>
          row["priority_commitment_required_observation_count"],
        "priority_commitment_planned_observation_count" =>
          row["priority_commitment_planned_observation_count"],
        "priority_commitment_missing_observation_count" =>
          row["priority_commitment_missing_observation_count"],
        "priority_commitment_ratio" => row["priority_commitment_ratio"],
        "downlink_completion_required_contacts" => row["downlink_completion_required_contacts"],
        "downlink_completion_planned_contacts" => row["downlink_completion_planned_contacts"],
        "downlink_completion_required_downlink_mb" =>
          row["downlink_completion_required_downlink_mb"],
        "downlink_completion_planned_downlink_mb" =>
          row["downlink_completion_planned_downlink_mb"],
        "downlink_completion_ratio" => row["downlink_completion_ratio"],
        "coverage_observed_target_count" => row["coverage_observed_target_count"],
        "revisit_count" => row["revisit_count"],
        "collection_latency_ratio" => row["collection_latency_ratio"],
        "collection_latency_objective_count" => row["collection_latency_objective_count"],
        "collection_latency_observation_count" => row["collection_latency_observation_count"],
        "collection_latency_satisfied_observation_count" =>
          row["collection_latency_satisfied_observation_count"],
        "collection_latency_unsatisfied_observation_count" =>
          row["collection_latency_unsatisfied_observation_count"],
        "feedback_score_adjustment" => row["feedback_score_adjustment"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "contact_success_factor_activity_source" => row["contact_success_factor_activity_source"],
        "observation_success_factor" => row["observation_success_factor"],
        "observation_success_factor_source" => row["observation_success_factor_source"],
        "observation_success_factor_activity_source" =>
          row["observation_success_factor_activity_source"],
        "maneuver_success_factor" => row["maneuver_success_factor"],
        "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_throughput_factor" => row["station_throughput_factor"],
        "station_throughput_factor_source" => row["station_throughput_factor_source"],
        "station_throughput_factor_activity_source" =>
          row["station_throughput_factor_activity_source"],
        "feedback_risk_types" => row["feedback_risk_types"],
        "fuel_margin" => row["fuel_margin"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "power_margin" => row["power_margin"],
        "storage_margin" => row["storage_margin"],
        "downlink_capacity_margin" => row["downlink_capacity_margin"],
        "spacecraft_availability" => row["spacecraft_availability"],
        "payload_availability" => row["payload_availability"],
        "antenna_availability" => row["antenna_availability"],
        "resource_score_adjustment" => row["resource_score_adjustment"],
        "fuel_preservation_mode" => row["fuel_preservation_mode"],
        "resource_risk_types" => row["resource_risk_types"],
        "resource_pressure_statuses" => row["resource_pressure_statuses"],
        "resource_pressure_types" => row["resource_pressure_types"],
        "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
        "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
        "first_resource_pressure_kinds" => row["first_resource_pressure_kinds"],
        "first_resource_pressure_activity_id" => row["first_resource_pressure_activity_id"],
        "first_resource_pressure_activity_type" => row["first_resource_pressure_activity_type"],
        "first_resource_pressure_kind" => row["first_resource_pressure_kind"],
        "first_resource_pressure_starts_at_s" => row["first_resource_pressure_starts_at_s"],
        "first_resource_pressure_direction" => row["first_resource_pressure_direction"],
        "first_resource_pressure_ground_station_id" =>
          row["first_resource_pressure_ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          row["first_resource_pressure_station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          row["first_resource_pressure_station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          row["first_resource_pressure_station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          row["first_resource_pressure_station_calendar_directions"],
        "first_resource_pressure_source_window_id" =>
          row["first_resource_pressure_source_window_id"],
        "first_resource_pressure_source_window_type" =>
          row["first_resource_pressure_source_window_type"],
        "first_resource_pressure_source_window" => row["first_resource_pressure_source_window"],
        "source_window_id" =>
          row["source_window_id"] || row["first_resource_pressure_source_window_id"],
        "source_window_type" =>
          row["source_window_type"] || row["first_resource_pressure_source_window_type"],
        "source_window" => row["source_window"] || row["first_resource_pressure_source_window"],
        "repair_score" => row["repair_score"],
        "repair_activity_score" => row["repair_activity_score"],
        "repair_schedule_churn_penalty" => row["repair_schedule_churn_penalty"],
        "repair_schedule_move_penalty" => row["repair_schedule_move_penalty"],
        "repair_score_term_keys" => row["repair_score_term_keys"],
        "repair_link_selected_estimated_throughput_mb" =>
          row["repair_link_selected_estimated_throughput_mb"],
        "repair_link_selected_capacity_adjusted_throughput_mb" =>
          row["repair_link_selected_capacity_adjusted_throughput_mb"],
        "repair_link_required_downlink_mb" => row["repair_link_required_downlink_mb"],
        "repair_link_selected_downlink_shortfall_mb" =>
          row["repair_link_selected_downlink_shortfall_mb"],
        "repair_link_downlink_requirement_status" =>
          row["repair_link_downlink_requirement_status"],
        "repair_link_actual_throughput_mb" => row["repair_link_actual_throughput_mb"],
        "repair_link_actual_downlink_completion_ratio" =>
          row["repair_link_actual_downlink_completion_ratio"],
        "repair_link_actual_downlink_shortfall_mb" =>
          row["repair_link_actual_downlink_shortfall_mb"],
        "repair_link_actual_downlink_requirement_status" =>
          row["repair_link_actual_downlink_requirement_status"],
        "repair_constraint_count" => row["repair_constraint_count"],
        "repair_constraint_row_count" => row["repair_constraint_row_count"],
        "repair_constraint_status" => row["repair_constraint_status"],
        "repair_constraint_pass_count" => row["repair_constraint_pass_count"],
        "repair_constraint_warning_count" => row["repair_constraint_warning_count"],
        "repair_constraint_fail_count" => row["repair_constraint_fail_count"],
        "repair_constraint_failed_ids" => row["repair_constraint_failed_ids"],
        "repair_constraint_warning_ids" => row["repair_constraint_warning_ids"],
        "source_tradeoff" => row,
        "source_branch_comparison" => row
      }
      |> compact_map()
    end)
  end

  defp recommended_branch_score(%{"score" => score, "score_delta_from_recommended" => delta})
       when is_number(score) and is_number(delta) do
    score - delta
  end

  defp recommended_branch_score(_row), do: nil

  defp branch_comparison_reason(%{
         "branch_id" => branch_id,
         "score_delta_from_recommended" => delta
       }) do
    "branch #{branch_id} score delta from recommended #{encode_value(delta)}"
  end

  defp branch_comparison_reason(_row), do: "review branch comparison row"

  defp ranking_comparison_rows(rows, source \\ "ranking_comparison_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      scenario_id = Map.get(row, "scenario_id")

      %{
        "id" => review_id(["ranking_comparison", scenario_id, index]),
        "review_type" => "ranking_comparison_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "action" => "review_ranking_comparison",
        "required_operator_action" => "review_ranking_comparison",
        "approval_status" => "operator_review_required",
        "reason" => ranking_comparison_reason(row),
        "status" => Map.get(row, "status"),
        "left_rank" => Map.get(row, "left_rank"),
        "right_rank" => Map.get(row, "right_rank"),
        "rank_delta" => Map.get(row, "rank_delta"),
        "left_value" => Map.get(row, "left_value"),
        "right_value" => Map.get(row, "right_value"),
        "value_delta" => Map.get(row, "value_delta"),
        "source_ranking_comparison" => row
      }
      |> compact_map()
    end)
  end

  defp ranking_comparison_reason(%{
         "scenario_id" => scenario_id,
         "status" => status,
         "rank_delta" => rank_delta,
         "value_delta" => value_delta
       }) do
    "review ranking comparison for #{scenario_id}: #{status}, rank delta #{encode_value(rank_delta)}, value delta #{encode_value(value_delta)}"
  end

  defp ranking_comparison_reason(_row), do: "review ranking comparison row"

  defp score_term_rows(rows, source \\ "score_term_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      id = row["id"]
      scenario_id = row["scenario_id"]
      term_key = row["term_key"]

      %{
        "id" => review_id(["score_term", id || scenario_id, term_key]),
        "review_type" => "score_term_review",
        "source" => source,
        "subject_id" => id || scenario_id || term_key || "score_term",
        "scenario_id" => scenario_id,
        "branch_id" => row["branch_id"],
        "term_key" => term_key,
        "value" => row["value"],
        "timeline_score" => row["timeline_score"],
        "selected" => row["selected"],
        "action" => "review_score_term",
        "required_operator_action" => "review_score_term",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => score_term_reason(row),
        "source_score_term" => row
      }
      |> compact_map()
    end)
  end

  defp score_term_reason(row) do
    term_key = row["term_key"] || "score_term"
    scenario_id = row["scenario_id"] || row["id"] || "scenario"
    value = encode_value(row["value"])

    "review score term #{term_key} for #{scenario_id}: value #{value}"
  end

  defp objective_tradeoff_rows(rows, source \\ "objective_tradeoff_report.tradeoffs") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      scenario_id = row["scenario_id"]

      %{
        "id" => review_id(["objective_tradeoff", scenario_id, row["rank"]]),
        "review_type" => "objective_tradeoff_review",
        "source" => source,
        "subject_id" => scenario_id || "objective_tradeoff",
        "scenario_id" => scenario_id,
        "branch_id" => row["branch_id"],
        "score" => row["score"],
        "score_delta_from_selected" => row["score_delta_from_selected"],
        "activity_count" => row["activity_count"],
        "selected_observation_count" => row["selected_observation_count"],
        "selected_contact_count" => row["selected_contact_count"],
        "score_terms" => row["score_terms"],
        "activity_ids" => row["activity_ids"],
        "action" => "review_objective_tradeoff",
        "required_operator_action" => "review_objective_tradeoff",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => objective_tradeoff_reason(row),
        "source_objective_tradeoff" => row
      }
      |> compact_map()
    end)
  end

  defp objective_tradeoff_reason(row) do
    scenario_id = row["scenario_id"] || "scenario"
    delta = encode_value(row["score_delta_from_selected"])

    "review objective tradeoff for #{scenario_id}: score delta #{delta}"
  end

  defp pareto_frontier_rows(rows, source \\ "pareto_frontier_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      scenario_id = Map.get(row, "scenario_id") || Map.get(row, "id")

      %{
        "id" => review_id(["pareto_frontier", scenario_id, index]),
        "review_type" => "pareto_frontier_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "branch_id" => scenario_id,
        "action" => "review_pareto_frontier",
        "required_operator_action" => "review_pareto_frontier",
        "approval_status" => "operator_review_required",
        "reason" => pareto_frontier_reason(row),
        "frontier" => Map.get(row, "frontier"),
        "objective_keys" => Map.get(row, "objective_keys", []),
        "objective_values" => Map.get(row, "objective_values", %{}),
        "dominated_by_ids" => Map.get(row, "dominated_by_ids", []),
        "dominates_ids" => Map.get(row, "dominates_ids", []),
        "source_pareto_frontier" => row
      }
      |> compact_map()
    end)
  end

  defp pareto_frontier_reason(%{
         "scenario_id" => scenario_id,
         "frontier" => true,
         "dominates_ids" => dominates_ids
       })
       when is_list(dominates_ids) do
    "review Pareto frontier branch #{scenario_id}: dominates #{length(dominates_ids)} alternatives"
  end

  defp pareto_frontier_reason(%{
         "scenario_id" => scenario_id,
         "dominated_by_ids" => dominated_by_ids
       })
       when is_list(dominated_by_ids) do
    "review dominated branch #{scenario_id}: dominated by #{Enum.join(dominated_by_ids, ",")}"
  end

  defp pareto_frontier_reason(_row), do: "review Pareto frontier row"

  defp link_capacity_report_rows(nil, _source_prefix), do: []

  defp link_capacity_report_rows(%{} = report, source_prefix) do
    report = stringify_keys(report)

    link_capacity_rows(Map.get(report, "rows", []), "#{source_prefix}.rows") ++
      link_capacity_invalid_input_rows(
        Map.get(report, "invalid_contact_inputs", []),
        "#{source_prefix}.invalid_contact_inputs"
      ) ++
      link_capacity_invalid_input_rows(
        Map.get(report, "invalid_selected_contact_inputs", []),
        "#{source_prefix}.invalid_selected_contact_inputs"
      ) ++
      link_capacity_unmatched_rows(report, "#{source_prefix}.unmatched_selected_contact_ids") ++
      link_capacity_unresolved_actual_throughput_rows(report, source_prefix) ++
      link_capacity_unresolved_actual_completion_rows(report, source_prefix) ++
      link_capacity_invalid_policy_station_requirement_rows(report, source_prefix)
  end

  defp link_capacity_report_rows(_report, _source_prefix), do: []

  defp link_capacity_invalid_policy_station_requirement_rows(report, source_prefix) do
    station_ids =
      report
      |> Map.get("invalid_policy_required_downlink_station_ids", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case station_ids do
      [] ->
        []

      ids ->
        count = Map.get(report, "invalid_policy_required_downlink_station_count", length(ids))

        [
          %{
            "id" => review_id(["link_capacity", "invalid_policy_station_requirement"]),
            "review_type" => "link_capacity_review",
            "source" => "#{source_prefix}.invalid_policy_required_downlink_station_ids",
            "subject_id" => "invalid_policy_required_downlink_station_ids",
            "action" => "review_invalid_link_capacity_policy",
            "required_operator_action" => "review_invalid_link_capacity_policy",
            "approval_status" => "operator_review_required",
            "reason" => "review #{count} malformed station-scoped downlink policy requirements",
            "invalid_policy_required_downlink_station_count" => count,
            "invalid_policy_required_downlink_station_ids" => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              "invalid_policy_required_downlink_station_count" => count,
              "invalid_policy_required_downlink_station_ids" => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp link_capacity_rows(rows, source) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      station_id = Map.get(row, "ground_station_id")
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["link_capacity", station_id, index]),
        "review_type" => "link_capacity_review",
        "source" => source,
        "subject_id" => station_id,
        "ground_station_id" => station_id,
        "action" => "review_link_capacity_summary",
        "required_operator_action" => "review_link_capacity_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => link_capacity_reason(row),
        "contact_count" => row["contact_count"],
        "ignored_contact_count" => row["ignored_contact_count"],
        "ignored_contact_ids" => row["ignored_contact_ids"],
        "ignored_contact_reason_counts" => row["ignored_contact_reason_counts"],
        "selected_contact_count" => row["selected_contact_count"],
        "ignored_selected_contact_count" => row["ignored_selected_contact_count"],
        "ignored_selected_contact_ids" => row["ignored_selected_contact_ids"],
        "ignored_selected_contact_reason_counts" => row["ignored_selected_contact_reason_counts"],
        "estimated_throughput_mb" => row["estimated_throughput_mb"],
        "selected_estimated_throughput_mb" => row["selected_estimated_throughput_mb"],
        "capacity_adjusted_throughput_mb" => row["capacity_adjusted_throughput_mb"],
        "selected_capacity_adjusted_throughput_mb" =>
          row["selected_capacity_adjusted_throughput_mb"],
        "unused_capacity_adjusted_throughput_mb" => row["unused_capacity_adjusted_throughput_mb"],
        "selected_capacity_utilization_fraction" => row["selected_capacity_utilization_fraction"],
        "selection_utilization_status" => row["selection_utilization_status"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "required_downlink_contact_count" => row["required_downlink_contact_count"],
        "required_downlink_contact_ids" => row["required_downlink_contact_ids"],
        "downlink_completion_source" => row["downlink_completion_source"],
        "downlink_completion_sources" => row["downlink_completion_sources"],
        "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
        "downlink_requirement_status" => row["downlink_requirement_status"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_throughput_contact_count" => row["actual_throughput_contact_count"],
        "actual_throughput_contact_ids" => row["actual_throughput_contact_ids"],
        "actual_data_rate_throughput_derivations" =>
          row["actual_data_rate_throughput_derivations"],
        "actual_completion_fraction" => row["actual_completion_fraction"],
        "actual_completion_contact_count" => row["actual_completion_contact_count"],
        "actual_completion_contact_ids" => row["actual_completion_contact_ids"],
        "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
        "unmatched_actual_throughput_contact_count" =>
          row["unmatched_actual_throughput_contact_count"],
        "unmatched_actual_throughput_contact_ids" =>
          row["unmatched_actual_throughput_contact_ids"],
        "unmatched_actual_completion_contact_count" =>
          row["unmatched_actual_completion_contact_count"],
        "unmatched_actual_completion_contact_ids" =>
          row["unmatched_actual_completion_contact_ids"],
        "ambiguous_actual_throughput_contact_count" =>
          row["ambiguous_actual_throughput_contact_count"],
        "ambiguous_actual_throughput_contact_ids" =>
          row["ambiguous_actual_throughput_contact_ids"],
        "ambiguous_actual_completion_contact_count" =>
          row["ambiguous_actual_completion_contact_count"],
        "ambiguous_actual_completion_contact_ids" =>
          row["ambiguous_actual_completion_contact_ids"],
        "actual_downlink_shortfall_mb" => row["actual_downlink_shortfall_mb"],
        "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
        "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
        "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_reservation_ids" => row["station_reservation_ids"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_bys" => row["station_reserved_bys"],
        "station_reservation_statuses" => row["station_reservation_statuses"],
        "station_reservation_match_statuses" => row["station_reservation_match_statuses"],
        "capacity_fraction_min" => row["capacity_fraction_min"],
        "capacity_fraction_max" => row["capacity_fraction_max"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "selected_contact_ids" => Map.get(row, "selected_contact_ids", []),
        "duplicate_contact_ids" => row["duplicate_contact_ids"],
        "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
        "ambiguous_selected_contact_ids" => row["ambiguous_selected_contact_ids"],
        "ambiguous_selected_contact_id_count" => row["ambiguous_selected_contact_id_count"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_link_capacity" => row
      }
      |> compact_map()
    end)
  end

  defp link_capacity_unmatched_rows(report, source) do
    unmatched_ids =
      report
      |> Map.get("unmatched_selected_contact_ids", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case unmatched_ids do
      [] ->
        []

      ids ->
        count = Map.get(report, "unmatched_selected_contact_count", length(ids))

        [
          %{
            "id" => review_id(["link_capacity", "unmatched_selected_contacts"]),
            "review_type" => "link_capacity_review",
            "source" => source,
            "subject_id" => "unmatched_selected_contacts",
            "action" => "resolve_unmatched_selected_contacts",
            "required_operator_action" => "resolve_unmatched_selected_contacts",
            "approval_status" => "operator_review_required",
            "reason" =>
              "review #{count} selected downlink contacts missing from link capacity candidates",
            "unmatched_selected_contact_count" => count,
            "unmatched_selected_contact_ids" => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              "unmatched_selected_contact_count" => count,
              "unmatched_selected_contact_ids" => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp link_capacity_invalid_input_rows(rows, source) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["link_capacity", "invalid_input", row["contact_id"], index]),
        "review_type" => "link_capacity_review",
        "source" => source,
        "subject_id" => row["id"],
        "contact_id" => row["contact_id"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "input_role" => row["input_role"],
        "action" =>
          Map.get(row, "required_operator_action", "review_invalid_link_capacity_input"),
        "required_operator_action" =>
          Map.get(row, "required_operator_action", "review_invalid_link_capacity_input"),
        "approval_status" => Map.get(row, "approval_status", "operator_review_required"),
        "reason" => invalid_link_capacity_input_reason(row),
        "ground_station_id" => row["ground_station_id"],
        "direction" => row["direction"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_candidate" => row["source_contact_candidate"],
        "source_link_capacity" => row
      }
      |> compact_map()
    end)
  end

  defp invalid_link_capacity_input_reason(%{
         "invalid_contact_input_reason" => reason,
         "input_role" => role
       }) do
    "review invalid #{role} link-capacity input: #{reason}"
  end

  defp invalid_link_capacity_input_reason(%{"invalid_contact_input_reason" => reason}) do
    "review invalid link-capacity input: #{reason}"
  end

  defp link_capacity_unresolved_actual_throughput_rows(report, source_prefix) do
    link_capacity_actual_throughput_resolution_row(
      report,
      "unmatched_actual_throughput_contact_ids",
      "unmatched_actual_throughput_contact_count",
      "resolve_unmatched_actual_throughput_contacts",
      "unmatched actual-throughput downlink contacts missing from link capacity candidates",
      "#{source_prefix}.unmatched_actual_throughput_contact_ids"
    ) ++
      link_capacity_actual_throughput_resolution_row(
        report,
        "ambiguous_actual_throughput_contact_ids",
        "ambiguous_actual_throughput_contact_count",
        "resolve_ambiguous_actual_throughput_contacts",
        "ambiguous actual-throughput downlink contacts that do not map to one candidate",
        "#{source_prefix}.ambiguous_actual_throughput_contact_ids"
      )
  end

  defp link_capacity_unresolved_actual_completion_rows(report, source_prefix) do
    link_capacity_actual_throughput_resolution_row(
      report,
      "unmatched_actual_completion_contact_ids",
      "unmatched_actual_completion_contact_count",
      "resolve_unmatched_actual_completion_contacts",
      "unmatched completion-fraction downlink contacts missing from link capacity candidates",
      "#{source_prefix}.unmatched_actual_completion_contact_ids"
    ) ++
      link_capacity_actual_throughput_resolution_row(
        report,
        "ambiguous_actual_completion_contact_ids",
        "ambiguous_actual_completion_contact_count",
        "resolve_ambiguous_actual_completion_contacts",
        "ambiguous completion-fraction downlink contacts that do not map to one candidate",
        "#{source_prefix}.ambiguous_actual_completion_contact_ids"
      )
  end

  defp link_capacity_actual_throughput_resolution_row(
         report,
         id_field,
         count_field,
         action,
         reason_suffix,
         source
       ) do
    ids =
      report
      |> Map.get(id_field, [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case ids do
      [] ->
        []

      ids ->
        count = Map.get(report, count_field, length(ids))
        subject_id = String.replace(id_field, "_ids", "s")

        [
          %{
            "id" => review_id(["link_capacity", subject_id]),
            "review_type" => "link_capacity_review",
            "source" => source,
            "subject_id" => subject_id,
            "action" => action,
            "required_operator_action" => action,
            "approval_status" => "operator_review_required",
            "reason" => "review #{count} #{reason_suffix}",
            count_field => count,
            id_field => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              count_field => count,
              id_field => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp link_capacity_reason(%{
         "ground_station_id" => station_id,
         "actual_downlink_requirement_status" => "shortfall",
         "actual_downlink_shortfall_mb" => shortfall
       })
       when is_number(shortfall) do
    "review #{station_id} actual downlink throughput shortfall of #{encode_value(shortfall)} MB"
  end

  defp link_capacity_reason(%{
         "ground_station_id" => station_id,
         "downlink_requirement_status" => "shortfall",
         "selected_downlink_shortfall_mb" => shortfall
       })
       when is_number(shortfall) do
    "review #{station_id} downlink capacity shortfall of #{encode_value(shortfall)} MB"
  end

  defp link_capacity_reason(%{
         "ground_station_id" => station_id,
         "selected_estimated_throughput_mb" => selected_throughput
       }) do
    "review #{station_id} selected downlink throughput #{encode_value(selected_throughput)} MB"
  end

  defp link_capacity_reason(%{"ground_station_id" => station_id}) do
    "review #{station_id} downlink capacity summary"
  end

  defp link_capacity_reason(_row), do: "review downlink capacity summary"

  defp link_capacity_report_id(%{"id" => id}) when is_binary(id), do: id
  defp link_capacity_report_id(%{"source" => source}) when is_binary(source), do: source
  defp link_capacity_report_id(_report), do: "link_capacity_report"

  defp contact_allocation_rows(rows, source \\ "contact_allocation_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      contact_id = row["contact_id"]
      required_operator_action = contact_allocation_required_operator_action(row)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = preferred_approval_rule_match(row)
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_allocation", stable_id_fragment(source), contact_id, index]),
        "review_type" => "contact_allocation_review",
        "source" => source,
        "subject_id" => contact_id,
        "activity_id" => contact_id,
        "activity_type" => row["type"],
        "contact_id" => contact_id,
        "scenario_id" => row["scenario_id"],
        "spacecraft_id" => row["spacecraft_id"],
        "ground_station_id" => row["ground_station_id"],
        "direction" => row["direction"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "source_window" => row["source_window"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" => row["actual_data_rate_throughput_derivation"],
        "completed_fraction" => row["completed_fraction"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "candidate_downlink_mb" => row["candidate_downlink_mb"],
        "downlink_completion_ratio" => row["downlink_completion_ratio"],
        "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
        "downlink_requirement_status" => row["downlink_requirement_status"],
        "downlink_completion_source" => row["downlink_completion_source"],
        "downlink_completion_sources" => row["downlink_completion_sources"],
        "required_capacity_fraction" => row["required_capacity_fraction"],
        "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "allocation_status" => row["allocation_status"],
        "effective_allocation_status" => row["effective_allocation_status"],
        "allocation_reason" => row["allocation_reason"],
        "selected" => row["selected"],
        "contention_group_id" => row["contention_group_id"],
        "selected_contact_id" => row["selected_contact_id"],
        "deferred_contact_ids" => Map.get(row, "deferred_contact_ids", []),
        "capacity_pack_group_id" => row["capacity_pack_group_id"],
        "capacity_pack_status" => row["capacity_pack_status"],
        "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
        "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
        "selected_priority" => row["selected_priority"],
        "selected_priority_source" => row["selected_priority_source"],
        "deferred_contact_priorities" => row["deferred_contact_priorities"],
        "requested_priority_fields" => row["requested_priority_fields"],
        "priority_field_evidence_counts" => row["priority_field_evidence_counts"],
        "priority_fields_without_numeric_evidence_count" =>
          row["priority_fields_without_numeric_evidence_count"],
        "priority_fields_without_numeric_evidence" =>
          row["priority_fields_without_numeric_evidence"],
        "resolution_priority_override_count" => row["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          row["resolution_priority_override_contact_ids"],
        "ignored_priority_override_count" => row["ignored_priority_override_count"],
        "ignored_priority_override_keys" => row["ignored_priority_override_keys"],
        "ignored_priority_override_contact_ids" => row["ignored_priority_override_contact_ids"],
        "ignored_priority_override_input" => row["ignored_priority_override_input"],
        "suppressed_reason" => row["suppressed_reason"],
        "duplicate_contact_id_collision" => row["duplicate_contact_id_collision"],
        "duplicate_contact_index" => row["duplicate_contact_index"],
        "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
        "duplicate_contact_candidate_ids" => row["duplicate_contact_candidate_ids"],
        "duplicate_contact_candidates" => row["duplicate_contact_candidates"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          row["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "provenance" => row["provenance"],
        "provider_counteroffer_id" => row["provider_counteroffer_id"],
        "provider_counteroffer_status" => row["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          row["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "provider_reservation_request_status" => row["provider_reservation_request_status"],
        "provider_reservation_request_summary_model" =>
          row["provider_reservation_request_summary_model"],
        "provider_reservation_request_summary_schema_contract" =>
          row["provider_reservation_request_summary_schema_contract"],
        "provider_reservation_request_source_artifact_type" =>
          row["provider_reservation_request_source_artifact_type"],
        "provider_reservation_request_source" => row["provider_reservation_request_source"],
        "provider_reservation_request_execution_boundary" =>
          row["provider_reservation_request_execution_boundary"],
        "provider_reservation_execution" => row["provider_reservation_execution"],
        "resource_blocking_dimension" => row["resource_blocking_dimension"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "fuel_margin" => row["fuel_margin"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "power_margin" => row["power_margin"],
        "storage_margin" => row["storage_margin"],
        "downlink_margin" => row["downlink_margin"],
        "battery_capacity_wh" => row["battery_capacity_wh"],
        "battery_energy_used_wh" => row["battery_energy_used_wh"],
        "battery_energy_generated_wh" => row["battery_energy_generated_wh"],
        "battery_state_of_charge" => row["battery_state_of_charge"],
        "spacecraft_available" => row["spacecraft_available"],
        "planned_spacecraft_available" => row["planned_spacecraft_available"],
        "realized_spacecraft_available" => row["realized_spacecraft_available"],
        "spacecraft_available_match_status" => row["spacecraft_available_match_status"],
        "payload_available" => row["payload_available"],
        "planned_payload_available" => row["planned_payload_available"],
        "realized_payload_available" => row["realized_payload_available"],
        "payload_available_match_status" => row["payload_available_match_status"],
        "antenna_available" => row["antenna_available"],
        "planned_antenna_available" => row["planned_antenna_available"],
        "realized_antenna_available" => row["realized_antenna_available"],
        "antenna_available_match_status" => row["antenna_available_match_status"],
        "degraded" => row["degraded"],
        "planned_degraded" => row["planned_degraded"],
        "realized_degraded" => row["realized_degraded"],
        "degraded_match_status" => row["degraded_match_status"],
        "mode" => row["mode"],
        "planned_mode" => row["planned_mode"],
        "realized_mode" => row["realized_mode"],
        "mode_match_status" => row["mode_match_status"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "action" => required_operator_action,
        "required_operator_action" => required_operator_action,
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => contact_allocation_reason(row),
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_contact_allocation" => row,
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_candidate" => row["source_contact_candidate"],
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_suppression" => row["source_resource_suppression"],
        "source_contact_suppression" => row["source_contact_suppression"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "source_contention_recommendation" => row["source_contention_recommendation"],
        "source_provider_reservation_request_summary" =>
          row["source_provider_reservation_request_summary"]
      }
      |> compact_map()
    end)
  end

  defp contact_allocation_required_operator_action(%{
         "provider_reservation_request_status" => "request_ready"
       }),
       do: "review_provider_reservation_request"

  defp contact_allocation_required_operator_action(_row), do: "review_contact_allocation"

  defp contact_allocation_reason(%{
         "allocation_status" => status,
         "allocation_reason" => reason,
         "contact_id" => contact_id
       }) do
    "review #{status} contact allocation for #{contact_id}: #{reason}"
  end

  defp contact_allocation_reason(_row), do: "review contact allocation row"

  defp contact_allocation_capacity_pack_rows(
         groups,
         source \\ "contact_allocation_report.reduced_capacity_pack_groups"
       ) do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      group_id = group["contention_group_id"]

      %{
        "id" =>
          review_id([
            "contact_allocation_capacity_pack",
            stable_id_fragment(source),
            group_id,
            index
          ]),
        "review_type" => "contact_allocation_capacity_pack_review",
        "source" => source,
        "subject_id" => group_id,
        "contention_group_id" => group_id,
        "ground_station_id" => group["ground_station_id"],
        "capacity_fraction" => group["capacity_fraction"],
        "used_capacity_fraction" => group["used_capacity_fraction"],
        "unused_capacity_fraction" => group["unused_capacity_fraction"],
        "default_required_capacity_fraction" => group["default_required_capacity_fraction"],
        "input_contact_ids" => group["input_contact_ids"],
        "selected_contact_ids" => group["selected_contact_ids"],
        "capacity_packed_contact_ids" => group["capacity_packed_contact_ids"],
        "deferred_contact_ids" => group["deferred_contact_ids"],
        "capacity_requirement_rows" => group["capacity_requirement_rows"],
        "pack_status" => group["pack_status"],
        "action" => "review_contact_allocation_capacity_pack",
        "required_operator_action" => "review_contact_allocation_capacity_pack",
        "approval_status" => "operator_review_required",
        "reason" => contact_allocation_capacity_pack_reason(group),
        "source_contact_allocation_capacity_pack" => group,
        "source_contention_recommendation" => group["source_contention_recommendation"]
      }
      |> compact_map()
    end)
  end

  defp contact_allocation_capacity_pack_reason(%{
         "contention_group_id" => group_id,
         "ground_station_id" => station_id,
         "pack_status" => status
       }) do
    "review #{status} reduced-capacity contact packing for #{station_id} group #{group_id}"
  end

  defp contact_allocation_capacity_pack_reason(_group) do
    "review reduced-capacity contact packing group"
  end

  defp projected_resource_rows(%{} = report),
    do: Map.get(report, "projected_resources", [])

  defp projected_resource_rows(_report), do: []

  defp resource_projection_rows(rows, source \\ "resource_projection_report.projected_resources") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      spacecraft_id = Map.get(row, "spacecraft_id")
      flow_rows = resource_flow_rows(Map.get(row, "activity_resource_flow", []))
      first_pressure = first_resource_pressure(row, flow_rows)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_projection", spacecraft_id, index]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => spacecraft_id,
        "spacecraft_id" => spacecraft_id,
        "action" => "review_resource_projection",
        "required_operator_action" => "review_resource_projection",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => resource_projection_reason(row),
        "activity_count" => row["activity_count"],
        "effective_activity_count" => row["effective_activity_count"],
        "ignored_activity_count" => row["ignored_activity_count"],
        "ignored_activity_ids" => row["ignored_activity_ids"],
        "observation_count" => row["observation_count"],
        "downlink_count" => row["downlink_count"],
        "estimated_storage_produced_mb" => row["estimated_storage_produced_mb"],
        "estimated_downlink_mb" => row["estimated_downlink_mb"],
        "storage_limited_downlinked_mb" => row["storage_limited_downlinked_mb"],
        "unused_downlink_capacity_mb" => row["unused_downlink_capacity_mb"],
        "starting_storage_used_mb" => row["starting_storage_used_mb"],
        "projected_storage_used_mb" => row["projected_storage_used_mb"],
        "storage_capacity_mb" => row["storage_capacity_mb"],
        "starting_storage_margin" => row["starting_storage_margin"],
        "projected_storage_margin" => row["projected_storage_margin"],
        "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
        "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
        "downlink_capacity_mb" => row["downlink_capacity_mb"],
        "starting_downlink_margin" => row["starting_downlink_margin"],
        "projected_downlink_margin" => row["projected_downlink_margin"],
        "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
        "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
        "projected_power_margin" => row["projected_power_margin"],
        "projected_battery_energy_used_wh" => row["projected_battery_energy_used_wh"],
        "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
        "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
        "resource_pressure_status" => row["resource_pressure_status"],
        "resource_pressure_types" => row["resource_pressure_types"],
        "resource_flow_count" => length(flow_rows),
        "total_battery_energy_consumed_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_consumed_wh"),
        "total_battery_energy_generated_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_generated_wh"),
        "net_battery_energy_delta_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_delta_wh"),
        "peak_storage_overflow_mb" => peak_resource_flow_number(flow_rows, "storage_overflow_mb"),
        "peak_downlink_shortfall_mb" =>
          peak_resource_flow_number(flow_rows, "downlink_shortfall_mb"),
        "peak_battery_overuse_wh" => peak_resource_flow_number(flow_rows, "battery_overuse_wh"),
        "peak_unused_downlink_capacity_mb" =>
          peak_resource_flow_number(flow_rows, "unused_downlink_capacity_mb"),
        "first_resource_pressure_activity_id" => first_pressure["activity_id"],
        "first_resource_pressure_activity_type" => first_pressure["activity_type"],
        "first_resource_pressure_kind" => first_pressure["kind"],
        "first_resource_pressure_starts_at_s" => first_pressure["starts_at_s"],
        "first_resource_pressure_direction" => first_pressure["direction"],
        "first_resource_pressure_ground_station_id" => first_pressure["ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          first_pressure["station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          first_pressure["station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          first_pressure["station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          first_pressure["station_calendar_directions"],
        "first_resource_pressure_capacity_fraction" => first_pressure["capacity_fraction"],
        "first_resource_pressure_source_window_id" => first_pressure["source_window_id"],
        "first_resource_pressure_source_window_type" => first_pressure["source_window_type"],
        "first_resource_pressure_source_window" => first_pressure["source_window"],
        "source_window_id" => first_pressure["source_window_id"],
        "source_window_type" => first_pressure["source_window_type"],
        "source_window" => first_pressure["source_window"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "fuel_margin" => row["fuel_margin"],
        "power_margin" => row["power_margin"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "spacecraft_available" => row["spacecraft_available"],
        "payload_available" => row["payload_available"],
        "antenna_available" => row["antenna_available"],
        "mode" => row["mode"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "warnings" => Map.get(row, "warnings", []),
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_projection_flow_summary" =>
          row["source_resource_projection_flow_summary"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  defp resource_projection_flow_summary_rows(
         summary,
         source \\ "resource_projection_flow_summary.projected_resources"
       ) do
    flow_rows_by_spacecraft =
      summary
      |> Map.get("activity_resource_flow", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.group_by(&Map.get(&1, "spacecraft_id"))

    summary
    |> Map.get("projected_resources", [])
    |> List.wrap()
    |> Enum.map(fn row ->
      row = stringify_keys(row)
      spacecraft_id = row["spacecraft_id"]

      row
      |> Map.put("activity_resource_flow", Map.get(flow_rows_by_spacecraft, spacecraft_id, []))
      |> Map.put(
        "source_resource_projection_flow_summary",
        resource_projection_flow_summary_context(summary)
      )
    end)
    |> resource_projection_rows(source)
  end

  defp resource_projection_flow_summary_context(summary) do
    Map.take(summary, [
      "schema_contract",
      "schema_version",
      "model",
      "source",
      "resource_flow_status",
      "resource_pressure_status",
      "resource_pressure_count",
      "resource_pressure_types",
      "resource_pressure_spacecraft_ids",
      "resource_pressure_spacecraft_ids_by_type",
      "resource_pressure_activity_ids_by_type",
      "total_storage_produced_mb",
      "total_planned_downlink_mb",
      "total_storage_limited_downlinked_mb",
      "total_unused_downlink_capacity_mb",
      "total_projected_storage_remaining_mb",
      "minimum_projected_storage_remaining_mb",
      "total_projected_downlink_remaining_mb",
      "minimum_projected_downlink_remaining_mb",
      "total_storage_overflow_mb",
      "total_downlink_shortfall_mb",
      "latency_status",
      "latency_evidence_count",
      "latency_review_count",
      "latency_review_activity_ids",
      "total_battery_energy_consumed_wh",
      "total_battery_energy_generated_wh",
      "net_battery_energy_delta_wh",
      "peak_battery_overuse_wh",
      "assumptions",
      "model_limits"
    ])
  end

  defp resource_projection_invalid_activity_rows(
         rows,
         source \\ "resource_projection_report.invalid_activity_inputs"
       ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      activity_id = row["activity_id"] || "invalid_activity_input:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_projection", "invalid_activity_input", activity_id]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => activity_id,
        "activity_id" => activity_id,
        "activity_ids" => row["activity_ids"],
        "activity_type" => row["type"],
        "scenario_id" => row["scenario_id"],
        "spacecraft_id" => row["spacecraft_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "action" => "review_invalid_resource_projection_input",
        "required_operator_action" => "review_invalid_resource_projection_input",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "reason" =>
          "review invalid resource projection input #{activity_id}: #{row["invalid_activity_input_reason"]}",
        "invalid_activity_input" => true,
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_activity" => row["source_activity"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  defp resource_projection_invalid_summary_rows(
         rows,
         source \\ "resource_projection_report.invalid_resource_summary_inputs"
       ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      resource_summary_id = row["resource_summary_id"] || "invalid_resource_summary:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["resource_projection", "invalid_resource_summary", resource_summary_id]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => resource_summary_id,
        "spacecraft_id" => row["spacecraft_id"],
        "action" => "review_invalid_resource_projection_summary",
        "required_operator_action" => "review_invalid_resource_projection_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "reason" =>
          "review invalid resource projection summary #{resource_summary_id}: #{row["invalid_resource_summary_input_reason"]}",
        "invalid_resource_summary_input" => true,
        "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
        "duplicate_resource_summary_scope" => row["duplicate_resource_summary_scope"],
        "mixed_wildcard_resource_summary_scope" => row["mixed_wildcard_resource_summary_scope"],
        "resource_summary_key" => row["resource_summary_key"],
        "duplicate_resource_summary_index" => row["duplicate_resource_summary_index"],
        "duplicate_resource_summary_count" => row["duplicate_resource_summary_count"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  defp peak_resource_flow_number(rows, field) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp sum_resource_flow_number(rows, field) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp resource_flow_rows(rows) when is_list(rows), do: rows
  defp resource_flow_rows(_rows), do: []

  defp first_resource_pressure(row, flow_rows) do
    direct =
      %{
        "activity_id" => row["first_resource_pressure_activity_id"],
        "activity_type" => row["first_resource_pressure_activity_type"],
        "kind" => row["first_resource_pressure_kind"],
        "starts_at_s" => row["first_resource_pressure_starts_at_s"],
        "direction" => row["first_resource_pressure_direction"],
        "ground_station_id" => row["first_resource_pressure_ground_station_id"],
        "station_calendar_entry_id" => row["first_resource_pressure_station_calendar_entry_id"],
        "station_calendar_provider_id" =>
          row["first_resource_pressure_station_calendar_provider_id"],
        "station_calendar_provider_entry_id" =>
          row["first_resource_pressure_station_calendar_provider_entry_id"],
        "station_calendar_directions" =>
          row["first_resource_pressure_station_calendar_directions"],
        "capacity_fraction" => row["first_resource_pressure_capacity_fraction"],
        "source_window_id" => row["first_resource_pressure_source_window_id"],
        "source_window_type" => row["first_resource_pressure_source_window_type"],
        "source_window" => row["first_resource_pressure_source_window"]
      }
      |> compact_map()

    if Map.has_key?(direct, "activity_id") or Map.has_key?(direct, "kind") do
      direct
    else
      flow_row = first_resource_pressure_flow_row(flow_rows)

      %{
        "activity_id" => flow_row["activity_id"],
        "activity_type" => flow_row["activity_type"],
        "kind" => resource_pressure_kind(flow_row),
        "starts_at_s" => flow_row["starts_at_s"],
        "direction" => flow_row["direction"],
        "ground_station_id" => flow_row["ground_station_id"],
        "station_calendar_entry_id" => flow_row["station_calendar_entry_id"],
        "station_calendar_provider_id" => flow_row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => flow_row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => flow_row["station_calendar_directions"],
        "capacity_fraction" => flow_row["capacity_fraction"],
        "source_window_id" => flow_row["source_window_id"],
        "source_window_type" => flow_row["source_window_type"],
        "source_window" => flow_row["source_window"]
      }
      |> compact_map()
    end
  end

  defp first_resource_pressure_flow_row(rows) when is_list(rows) do
    Enum.find(rows, %{}, fn row ->
      positive_number?(row["storage_overflow_mb"]) or
        positive_number?(row["downlink_shortfall_mb"]) or
        positive_number?(row["battery_overuse_wh"])
    end)
  end

  defp resource_pressure_kind(%{"storage_overflow_mb" => overflow})
       when is_number(overflow) and overflow > 0.0,
       do: "storage_overflow"

  defp resource_pressure_kind(%{"downlink_shortfall_mb" => shortfall})
       when is_number(shortfall) and shortfall > 0.0,
       do: "downlink_shortfall"

  defp resource_pressure_kind(%{"battery_overuse_wh" => overuse})
       when is_number(overuse) and overuse > 0.0,
       do: "battery_depletion"

  defp resource_pressure_kind(_row), do: nil

  defp resource_projection_reason(%{"spacecraft_id" => spacecraft_id} = row) do
    flow_rows = resource_flow_rows(Map.get(row, "activity_resource_flow", []))

    case first_resource_pressure(row, flow_rows) do
      %{"activity_id" => activity_id, "kind" => kind} when is_binary(activity_id) ->
        "review #{spacecraft_id} resource pressure at #{activity_id}: #{kind}"

      _row ->
        resource_projection_margin_reason(spacecraft_id, row)
    end
  end

  defp resource_projection_reason(_row), do: "review resource projection"

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp resource_projection_margin_reason(spacecraft_id, %{"projected_storage_margin" => margin}) do
    "review #{spacecraft_id} projected storage margin #{encode_value(margin)}"
  end

  defp resource_projection_margin_reason(spacecraft_id, _row) do
    "review #{spacecraft_id} resource projection"
  end

  defp resource_projection_report_id(%{"id" => id}) when is_binary(id), do: id

  defp resource_projection_report_id(%{"assumptions" => %{"source" => source}})
       when is_binary(source),
       do: source

  defp resource_projection_report_id(_report), do: "resource_projection_report"

  defp resource_projection_flow_summary_id(%{"id" => id}) when is_binary(id), do: id

  defp resource_projection_flow_summary_id(%{"source" => source}) when is_binary(source),
    do: source

  defp resource_projection_flow_summary_id(%{"assumptions" => %{"source" => source}})
       when is_binary(source),
       do: source

  defp resource_projection_flow_summary_id(_summary), do: "resource_projection_flow_summary"

  defp resource_suppressed_candidates(%{"resource_filter_report" => %{} = report}) do
    Map.get(report, "suppressed_candidates", [])
  end

  defp resource_suppressed_candidates(_artifact), do: []

  defp resource_suppressed_candidates(artifact, report_key) do
    case Map.get(artifact, report_key) do
      %{} = report -> Map.get(report, "suppressed_candidates", [])
      _report -> []
    end
  end

  defp contact_suppressed_candidates(artifact, report_key) do
    case Map.get(artifact, report_key) do
      %{} = report -> Map.get(report, "suppressed_candidates", [])
      _report -> []
    end
  end

  defp contact_suppression_rows(candidates, source) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      requirement =
        candidate["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        candidate["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(candidate["policy_decision"] || %{})
      policy_escalation = candidate |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_suppression", candidate["id"], index]),
        "review_type" => "contact_suppression",
        "source" => source,
        "subject_id" => candidate["id"],
        "activity_id" => candidate["id"],
        "base_candidate_id" => candidate["base_candidate_id"],
        "activity_type" => candidate["type"],
        "action" => contact_suppression_action(candidate),
        "required_operator_action" => contact_suppression_action(candidate),
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "reason" => contact_suppression_reason(candidate),
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "source_window_id" => candidate["source_window_id"],
        "contact_success" => candidate["contact_success"],
        "contact_success_factor" => candidate["contact_success_factor"],
        "contact_success_factor_source" => candidate["contact_success_factor_source"],
        "command_success" => candidate["command_success"],
        "contact_result" => provider_result_artifact_value(candidate["contact_result"]),
        "command_result" => provider_result_artifact_value(candidate["command_result"]),
        "command_success_factor" => candidate["command_success_factor"],
        "command_success_factor_source" => candidate["command_success_factor_source"],
        "station_availability" => candidate["station_availability"],
        "station_calendar_entry_id" => candidate["station_calendar_entry_id"],
        "station_calendar_directions" => candidate["station_calendar_directions"],
        "station_calendar_status" => candidate["station_calendar_status"],
        "station_calendar_overlap_count" => candidate["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          candidate["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => candidate["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          candidate["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" =>
          candidate["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          candidate["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => candidate["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          candidate["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          candidate["station_calendar_reservation_expires_at_s"],
        "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
        "provider_counteroffer_id" => candidate["provider_counteroffer_id"],
        "provider_counteroffer_status" => candidate["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          candidate["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => candidate["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => candidate["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" =>
          candidate["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => candidate["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => candidate["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" => candidate["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => candidate["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" =>
          candidate["provider_counteroffer_duration_delta_s"],
        "station_contention_status" => candidate["station_contention_status"],
        "station_reservation_id" => candidate["station_reservation_id"],
        "station_reservation_expires_at_s" => candidate["station_reservation_expires_at_s"],
        "station_reserved_by" => candidate["station_reserved_by"],
        "station_reservation_status" => candidate["station_reservation_status"],
        "station_reservation_match_status" => candidate["station_reservation_match_status"],
        "duplicate_suppressed_candidate_id_collision" =>
          candidate["duplicate_suppressed_candidate_id_collision"],
        "duplicate_suppressed_candidate_index" =>
          candidate["duplicate_suppressed_candidate_index"],
        "duplicate_suppressed_candidate_count" =>
          candidate["duplicate_suppressed_candidate_count"],
        "invalid_contact_input" => candidate["invalid_contact_input"],
        "invalid_contact_input_reason" => candidate["invalid_contact_input_reason"],
        "review_status" => candidate["review_status"],
        "source_contact_candidate" => candidate["source_contact_candidate"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => candidate["approval_requirements"],
        "approval_rule_matches" => candidate["approval_rule_matches"],
        "source_policy_decision" => candidate["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_suppression" => candidate
      }
      |> compact_map()
    end)
  end

  defp contact_suppression_action(%{"required_operator_action" => action}) when is_binary(action),
    do: action

  defp contact_suppression_action(candidate) do
    if downlink_candidate?(candidate),
      do: "review_suppressed_contact",
      else: "review_suppressed_candidate"
  end

  defp contact_suppression_reason(%{
         "suppressed_reason" => "invalid_contact_input",
         "invalid_contact_input_reason" => reason
       })
       when is_binary(reason),
       do: "contact filter invalid input: #{reason}"

  defp contact_suppression_reason(%{"suppressed_reason" => reason}) when is_binary(reason),
    do: "contact filter suppressed candidate: #{reason}"

  defp contact_suppression_reason(_candidate), do: "contact filter suppressed candidate"

  defp resource_suppression_rows(candidates),
    do:
      resource_suppression_rows(
        candidates,
        "campaign_plan.resource_filter_report.suppressed_candidates"
      )

  defp resource_suppression_rows(candidates, source) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      requirement =
        candidate["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        candidate["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(candidate["policy_decision"] || %{})
      policy_escalation = candidate |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_suppression", candidate["id"], index]),
        "review_type" => "resource_suppression",
        "source" => source,
        "subject_id" => candidate["id"],
        "activity_id" => candidate["id"],
        "base_candidate_id" => candidate["base_candidate_id"],
        "activity_type" => candidate["type"],
        "action" => resource_suppression_action(candidate),
        "required_operator_action" => resource_suppression_action(candidate),
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "suppressed_reason" => candidate["suppressed_reason"],
        "reason" => resource_suppression_reason(candidate),
        "scenario_id" => candidate["scenario_id"],
        "spacecraft_id" => candidate["spacecraft_id"],
        "target_id" => candidate["target_id"],
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "source_window_id" => candidate["source_window_id"],
        "contact_success" => candidate["contact_success"],
        "contact_success_factor" => candidate["contact_success_factor"],
        "contact_success_factor_source" => candidate["contact_success_factor_source"],
        "command_success" => candidate["command_success"],
        "contact_result" => provider_result_artifact_value(candidate["contact_result"]),
        "command_result" => provider_result_artifact_value(candidate["command_result"]),
        "command_success_factor" => candidate["command_success_factor"],
        "command_success_factor_source" => candidate["command_success_factor_source"],
        "station_availability" => candidate["station_availability"],
        "station_calendar_entry_id" => candidate["station_calendar_entry_id"],
        "station_calendar_directions" => candidate["station_calendar_directions"],
        "station_calendar_status" => candidate["station_calendar_status"],
        "station_calendar_overlap_count" => candidate["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          candidate["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => candidate["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          candidate["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" =>
          candidate["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          candidate["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => candidate["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          candidate["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          candidate["station_calendar_reservation_expires_at_s"],
        "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
        "station_contention_status" => candidate["station_contention_status"],
        "station_reservation_id" => candidate["station_reservation_id"],
        "station_reservation_expires_at_s" => candidate["station_reservation_expires_at_s"],
        "station_reserved_by" => candidate["station_reserved_by"],
        "station_reservation_status" => candidate["station_reservation_status"],
        "station_reservation_match_status" => candidate["station_reservation_match_status"],
        "resource_source_quality" => candidate["resource_source_quality"],
        "resource_trust_boundary" => candidate["resource_trust_boundary"],
        "resource_trust_boundary_status" => candidate["resource_trust_boundary_status"],
        "resource_provenance" => candidate["resource_provenance"],
        "resource_blocking_dimension" => candidate["resource_blocking_dimension"],
        "fuel_margin" => candidate["fuel_margin"],
        "thermal_margin_c" => candidate["thermal_margin_c"],
        "power_margin" => candidate["power_margin"],
        "storage_margin" => candidate["storage_margin"],
        "downlink_margin" => candidate["downlink_margin"],
        "battery_capacity_wh" => candidate["battery_capacity_wh"],
        "battery_energy_used_wh" => candidate["battery_energy_used_wh"],
        "battery_energy_generated_wh" => candidate["battery_energy_generated_wh"],
        "battery_state_of_charge" => candidate["battery_state_of_charge"],
        "spacecraft_available" => candidate["spacecraft_available"],
        "payload_available" => candidate["payload_available"],
        "antenna_available" => candidate["antenna_available"],
        "degraded" => candidate["degraded"],
        "mode" => candidate["mode"],
        "incompatible_activity_types" => candidate["incompatible_activity_types"],
        "suppressed_activity_types" => candidate["suppressed_activity_types"],
        "duplicate_suppressed_candidate_id_collision" =>
          candidate["duplicate_suppressed_candidate_id_collision"],
        "duplicate_suppressed_candidate_index" =>
          candidate["duplicate_suppressed_candidate_index"],
        "duplicate_suppressed_candidate_count" =>
          candidate["duplicate_suppressed_candidate_count"],
        "invalid_candidate_input" => candidate["invalid_candidate_input"],
        "invalid_candidate_input_reason" => candidate["invalid_candidate_input_reason"],
        "invalid_resource_summary_input" => candidate["invalid_resource_summary_input"],
        "invalid_resource_summary_input_reason" =>
          candidate["invalid_resource_summary_input_reason"],
        "source_candidate" => candidate["source_candidate"],
        "source_resource_summary" => candidate["source_resource_summary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => candidate["approval_requirements"],
        "approval_rule_matches" => candidate["approval_rule_matches"],
        "source_policy_decision" => candidate["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_suppression" => candidate
      }
      |> compact_map()
    end)
  end

  defp resource_filter_invalid_summary_rows(
         rows,
         source \\ "resource_filter_report.invalid_resource_summary_inputs"
       ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      resource_summary_id = row["resource_summary_id"] || "invalid_resource_summary:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["resource_suppression", "invalid_resource_summary", resource_summary_id]),
        "review_type" => "resource_suppression",
        "source" => source,
        "subject_id" => resource_summary_id,
        "spacecraft_id" => row["spacecraft_id"],
        "action" => "review_invalid_resource_filter_summary",
        "required_operator_action" => "review_invalid_resource_filter_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "suppressed_reason" => "invalid_resource_summary_input",
        "reason" =>
          "review invalid resource filter summary #{resource_summary_id}: #{row["invalid_resource_summary_input_reason"]}",
        "resource_blocking_dimension" => "spacecraft_health",
        "invalid_resource_summary_input" => true,
        "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_suppression" => row
      }
      |> compact_map()
    end)
  end

  defp resource_suppression_action(candidate) do
    cond do
      resource_contact_candidate?(candidate) -> "review_suppressed_contact"
      candidate["type"] == "observe" -> "review_suppressed_observation"
      true -> "review_suppressed_candidate"
    end
  end

  defp resource_contact_candidate?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp resource_contact_candidate?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp resource_contact_candidate?(%{"direction" => direction, "ground_station_id" => station_id})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp resource_contact_candidate?(candidate), do: downlink_candidate?(candidate)

  defp downlink_candidate?(%{"type" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "tracking"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "tracking"}), do: true

  defp downlink_candidate?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(%{"direction" => "tracking", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(_candidate), do: false

  defp contact_intent_rows(intents, source) do
    intents
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.filter(fn {intent, _index} -> contact_intent_requires_review?(intent) end)
    |> Enum.map(fn {intent, index} ->
      requirement =
        intent["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        intent["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(intent["policy_decision"] || %{})
      policy_escalation = intent |> matched_policy_escalation() |> stringify_keys()
      cadence_import = intent["cadence_import"] || %{}
      action = requirement["action"] || "review_contact_intent"
      subject_id = intent["id"] || intent["activity_id"] || intent["contact_id"] || index

      %{
        "id" => review_id(["contact_intent_review", subject_id, index]),
        "review_type" => "contact_intent_review",
        "source" => source,
        "subject_id" => subject_id,
        "activity_id" => intent["activity_id"],
        "contact_id" => intent["contact_id"] || intent["id"],
        "activity_type" => intent["activity_type"],
        "timeline_id" => intent["timeline_id"],
        "timeline_identity" => intent["timeline_identity"],
        "activity_context" => intent["activity_context"],
        "scenario_id" => intent["scenario_id"],
        "spacecraft_id" => intent["spacecraft_id"],
        "ground_station_id" => intent["ground_station_id"],
        "direction" => intent["direction"],
        "starts_at_s" => intent["starts_at_s"],
        "ends_at_s" => intent["ends_at_s"],
        "estimated_throughput_mb" => intent["estimated_throughput_mb"],
        "station_availability" => intent["station_availability"],
        "capacity_fraction" => intent["capacity_fraction"],
        "capacity_fraction_min" => intent["capacity_fraction_min"],
        "capacity_fraction_max" => intent["capacity_fraction_max"],
        "required_capacity_fraction" => intent["required_capacity_fraction"],
        "required_capacity_fraction_source" => intent["required_capacity_fraction_source"],
        "capacity_pack_required_capacity_fraction" =>
          intent["capacity_pack_required_capacity_fraction"],
        "capacity_pack_contact_ids" => intent["capacity_pack_contact_ids"],
        "contact_ids" => intent["contact_ids"],
        "source_summary_model" => intent["source_summary_model"],
        "source_summary_schema_contract" => intent["source_summary_schema_contract"],
        "source_summary_source" => intent["source_summary_source"],
        "source_artifact_type" => intent["source_artifact_type"],
        "schema_contract" => intent["schema_contract"],
        "station_contention_status" => intent["station_contention_status"],
        "station_calendar_entry_id" => intent["station_calendar_entry_id"],
        "station_calendar_directions" => intent["station_calendar_directions"],
        "station_calendar_status" => intent["station_calendar_status"],
        "station_calendar_overlap_count" => intent["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => intent["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          intent["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => intent["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          intent["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => intent["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          intent["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => intent["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => intent["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          intent["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          intent["station_calendar_reservation_expires_at_s"],
        "station_calendar_trust_boundary_status" =>
          intent["station_calendar_trust_boundary_status"],
        "trust_boundary" => intent["trust_boundary"],
        "provenance" => intent["provenance"],
        "source_station_calendar_entry" => intent["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => intent["source_station_calendar_overlaps"],
        "station_reservation_id" => intent["station_reservation_id"],
        "station_reservation_expires_at_s" => intent["station_reservation_expires_at_s"],
        "station_reserved_by" => intent["station_reserved_by"],
        "station_reservation_status" => intent["station_reservation_status"],
        "station_reservation_match_status" => intent["station_reservation_match_status"],
        "schedule_conflict_status" => intent["schedule_conflict_status"],
        "contact_success" => intent["contact_success"],
        "contact_result" => provider_result_artifact_value(intent["contact_result"]),
        "contact_success_factor" => intent["contact_success_factor"],
        "contact_success_factor_source" => intent["contact_success_factor_source"],
        "command_success" => intent["command_success"],
        "command_result" => provider_result_artifact_value(intent["command_result"]),
        "command_success_factor" => intent["command_success_factor"],
        "command_success_factor_source" => intent["command_success_factor_source"],
        "dependency_activity_ids" => intent["dependency_activity_ids"],
        "dependency_timeline_ids" => intent["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => intent["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => intent["exclusive_with_timeline_ids"],
        "source_window_id" => intent["source_window_id"],
        "invalid_activity_input" => intent["invalid_activity_input"],
        "invalid_activity_input_reason" => intent["invalid_activity_input_reason"],
        "source_activity" => intent["source_activity"],
        "cadence_import_status" => cadence_import["status"] || "present",
        "cadence_import_type" => cadence_import["type"] || cadence_import["activity_type"],
        "cadence_import_id" => cadence_import["id"] || cadence_import["external_id"],
        "cadence_import_contract" =>
          cadence_import["contract"] || cadence_import["schema_contract"],
        "has_cadence_import" => intent["cadence_import"] != nil,
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => intent["approval_status"] || "operator_review_required",
        "approval_requirements" => intent["approval_requirements"],
        "approval_rule_matches" => intent["approval_rule_matches"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "requirement_type" => requirement["requirement_type"],
        "reason" =>
          requirement["reason"] || "contact intent requires policy review before import",
        "source_policy_decision" => intent["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_intent_summary" => intent["source_contact_intent_summary"],
        "source_contact_intent" => intent
      }
      |> compact_map()
    end)
  end

  defp contact_intent_requires_review?(intent) do
    intent["approval_status"] in ["operator_review_required", "blocked_by_policy"] or
      not Enum.empty?(List.wrap(intent["approval_requirements"])) or
      not Enum.empty?(List.wrap(intent["approval_rule_matches"])) or
      is_map(intent["policy_decision"])
  end

  defp candidate_refresh_source_contact_intent_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_intent",
         get_in(artifact, ["accepted_planning_state", "source_contact_intent"])},
        {"candidate_refresh.accepted_planning_state.source_contact_intents",
         get_in(artifact, ["accepted_planning_state", "source_contact_intents"])},
        {"candidate_refresh.accepted_planning_state.source_contact_intent_summary",
         get_in(artifact, ["accepted_planning_state", "source_contact_intent_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_intent_summary",
         get_in(artifact, ["accepted_planning_state", "contact_intent_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_intent",
         get_in(artifact, ["accepted_planning_state", "contact_intent"])},
        {"candidate_refresh.accepted_planning_state.contact_intents",
         get_in(artifact, ["accepted_planning_state", "contact_intents"])},
        {"candidate_refresh.mission_state.source_contact_intent",
         get_in(artifact, ["mission_state", "source_contact_intent"])},
        {"candidate_refresh.mission_state.source_contact_intents",
         get_in(artifact, ["mission_state", "source_contact_intents"])},
        {"candidate_refresh.mission_state.source_contact_intent_summary",
         get_in(artifact, ["mission_state", "source_contact_intent_summary"])},
        {"candidate_refresh.mission_state.contact_intent_summary",
         get_in(artifact, ["mission_state", "contact_intent_summary"])},
        {"candidate_refresh.mission_state.contact_intent",
         get_in(artifact, ["mission_state", "contact_intent"])},
        {"candidate_refresh.mission_state.contact_intents",
         get_in(artifact, ["mission_state", "contact_intents"])},
        {"candidate_refresh.source_contact_intent", artifact["source_contact_intent"]},
        {"candidate_refresh.source_contact_intents", artifact["source_contact_intents"]},
        {"candidate_refresh.source_contact_intent_summary",
         artifact["source_contact_intent_summary"]},
        {"candidate_refresh.contact_intent_summary", artifact["contact_intent_summary"]},
        {"candidate_refresh.contact_intent", artifact["contact_intent"]}
      ]
      |> Enum.flat_map(fn {source, intent_or_intents} ->
        source_contact_intent_rows(intent_or_intents, source)
      end)

    direct_rows ++ candidate_refresh_contact_intent_container_rows(artifact)
  end

  defp source_contact_intent_rows(intents, source) when is_list(intents) do
    intents
    |> Enum.with_index()
    |> Enum.flat_map(fn {intent, index} ->
      source_contact_intent_rows(intent, "#{source}[#{index}]")
    end)
  end

  defp source_contact_intent_rows(%{} = intent, source) do
    intent = stringify_keys(intent)

    if contact_intent_summary?(intent) do
      source_contact_intent_summary_rows(intent, source)
    else
      contact_intent_rows([intent], source)
    end
  end

  defp source_contact_intent_rows(_intent, _source), do: []

  defp source_contact_intent_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = contact_intent_summary_context(summary)

    summary
    |> contact_intent_summary_review_rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put("source_contact_intent_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_summary_source", summary["source"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> contact_intent_rows("#{source}.summary_contacts")
  end

  defp contact_intent_summary_review_rows(%{"rows" => rows}, _source)
       when is_list(rows) and rows != [] do
    rows
    |> Enum.map(&stringify_keys/1)
  end

  defp contact_intent_summary_review_rows(%{} = summary, source) do
    direction_routing = contact_intent_summary_direction_routing(summary)

    direction_routing
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn direction ->
      route = stringify_keys(direction_routing[direction] || %{})
      contact_ids = List.wrap(route["contact_ids"] || [])
      capacity_contact_ids = List.wrap(route["capacity_pack_contact_ids"] || [])
      source_fragment = stable_id_fragment(source)
      summary_intent_id = "contact_intent_summary:#{source_fragment}:#{direction}"

      %{
        "id" => summary_intent_id,
        "activity_id" => summary_intent_id,
        "contact_id" => List.first(contact_ids ++ capacity_contact_ids),
        "contact_ids" => contact_ids,
        "capacity_pack_contact_ids" => capacity_contact_ids,
        "activity_type" => "contact_intent_summary",
        "direction" => direction,
        "ground_station_id" => contact_intent_summary_single_station(summary, contact_ids),
        "required_capacity_fraction" => route["capacity_pack_required_capacity_fraction"],
        "capacity_pack_required_capacity_fraction" =>
          route["capacity_pack_required_capacity_fraction"],
        "required_capacity_fraction_source" => "contact_intent_summary.direction_routing",
        "approval_status" => "operator_review_required",
        "approval_requirements" => [
          %{
            "schema_contract" => "approval_requirement.v1",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "required_authority" => "contact_schedule_authority",
            "reason" => "review contact intent summary direction routing"
          }
        ],
        "reason" => "review #{direction} contact intent summary routing"
      }
      |> compact_map()
    end)
  end

  defp contact_intent_summary_direction_routing(%{"direction_routing" => %{} = routing}) do
    stringify_keys(routing)
  end

  defp contact_intent_summary_direction_routing(%{} = summary) do
    contact_ids_by_direction = stringify_keys(summary["contact_ids_by_direction"] || %{})

    capacity_contact_ids_by_direction =
      stringify_keys(summary["capacity_pack_contact_ids_by_direction"] || %{})

    required_capacity_by_direction =
      stringify_keys(summary["capacity_pack_required_capacity_fraction_by_direction"] || %{})

    [
      Map.keys(contact_ids_by_direction),
      Map.keys(capacity_contact_ids_by_direction),
      Map.keys(required_capacity_by_direction),
      List.wrap(summary["directions"])
    ]
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => length(List.wrap(contact_ids_by_direction[direction] || [])),
          "contact_ids" => List.wrap(contact_ids_by_direction[direction] || []),
          "capacity_pack_required_capacity_fraction" => required_capacity_by_direction[direction],
          "capacity_pack_contact_ids" =>
            List.wrap(capacity_contact_ids_by_direction[direction] || [])
        }
        |> compact_map()

      {direction, route}
    end)
  end

  defp contact_intent_summary_single_station(%{} = summary, contact_ids) do
    by_station = stringify_keys(summary["contact_ids_by_ground_station_id"] || %{})
    contact_ids = MapSet.new(List.wrap(contact_ids))

    by_station
    |> Enum.find_value(fn {station_id, station_contact_ids} ->
      station_contact_ids = MapSet.new(List.wrap(station_contact_ids))

      if MapSet.size(MapSet.intersection(contact_ids, station_contact_ids)) > 0 do
        station_id
      end
    end)
  end

  defp contact_intent_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "contact_intent_count" => summary["contact_intent_count"],
      "capacity_pack_required_contact_count" => summary["capacity_pack_required_contact_count"],
      "capacity_pack_required_capacity_fraction" =>
        summary["capacity_pack_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        summary["capacity_pack_required_capacity_fraction_by_direction"],
      "contact_ids_by_ground_station_id" => summary["contact_ids_by_ground_station_id"],
      "contact_ids_by_direction" => summary["contact_ids_by_direction"],
      "capacity_pack_contact_ids_by_ground_station_id" =>
        summary["capacity_pack_contact_ids_by_ground_station_id"],
      "capacity_pack_contact_ids_by_direction" =>
        summary["capacity_pack_contact_ids_by_direction"],
      "direction_routing" => contact_intent_summary_direction_routing(summary),
      "directions" => summary["directions"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp contact_intent_summary?(%{"schema_contract" => "contact_intent_summary.v1"}), do: true
  defp contact_intent_summary?(_summary), do: false

  defp candidate_refresh_contact_intent_container_rows(artifact) do
    [
      {:operator_review_package, "candidate_refresh.source_operator_review_package",
       artifact["source_operator_review_package"]},
      {:operator_review_package, "candidate_refresh.operator_review_package",
       artifact["operator_review_package"]},
      {:cadence_import_manifest, "candidate_refresh.source_cadence_import_manifest",
       artifact["source_cadence_import_manifest"]},
      {:cadence_import_manifest, "candidate_refresh.cadence_import_manifest",
       artifact["cadence_import_manifest"]}
    ]
    |> Enum.flat_map(fn {kind, source, package_or_manifest} ->
      contact_intent_container_rows(kind, package_or_manifest, source)
    end)
    |> Kernel.++(candidate_refresh_result_artifact_contact_intent_rows(artifact))
  end

  defp candidate_refresh_result_artifact_contact_intent_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_intent_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_intent_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_intent_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_intent_rows(
         %{"schema_contract" => "contact_intent_summary.v1"} = summary,
         source
       ) do
    source_contact_intent_rows(summary, source)
  end

  defp result_artifact_contact_intent_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_intent", artifact["source_contact_intent"]},
      {"#{source}.source_contact_intents", artifact["source_contact_intents"]},
      {"#{source}.source_contact_intent_summary", artifact["source_contact_intent_summary"]},
      {"#{source}.contact_intent_summary", artifact["contact_intent_summary"]},
      {"#{source}.contact_intent", artifact["contact_intent"]},
      {"#{source}.contact_intents", artifact["contact_intents"]}
    ]
    |> Enum.flat_map(fn {intent_source, intent_or_intents} ->
      source_contact_intent_rows(intent_or_intents, intent_source)
    end)
    |> Kernel.++(
      contact_intent_container_rows(
        :operator_review_package,
        artifact["operator_review_package"],
        "#{source}.operator_review_package"
      )
    )
    |> Kernel.++(
      contact_intent_container_rows(
        :cadence_import_manifest,
        artifact["cadence_import_manifest"],
        "#{source}.cadence_import_manifest"
      )
    )
  end

  defp result_artifact_contact_intent_rows(_artifact, _source), do: []

  defp contact_intent_container_rows(kind, containers, source) when is_list(containers) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      contact_intent_container_rows(kind, container, "#{source}[#{index}]")
    end)
  end

  defp contact_intent_container_rows(:operator_review_package, %{} = package, source) do
    package
    |> stringify_keys()
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "contact_intent_review"))
    |> rows_to_contact_intent_rows(source)
  end

  defp contact_intent_container_rows(:cadence_import_manifest, %{} = manifest, source) do
    manifest
    |> stringify_keys()
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "contact_intent_review" or
        row["import_action"] == "review_contact_intent"
    end)
    |> rows_to_contact_intent_rows(source)
  end

  defp contact_intent_container_rows(_kind, _container, _source), do: []

  defp rows_to_contact_intent_rows(rows, source) do
    rows
    |> Enum.map(&contact_intent_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.flat_map(fn {intent, index} ->
      contact_intent_rows([intent], "#{source}.rows.source_contact_intent[#{index}]")
    end)
  end

  defp contact_intent_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_contact_intent"]) ->
          row["source_contact_intent"]

        is_map(get_in(row, ["source_review_row", "source_contact_intent"])) ->
          get_in(row, ["source_review_row", "source_contact_intent"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = intent -> stringify_keys(intent)
        _intent -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("schema_contract", "contact_intent.v1")
    |> Map.put_new("id", row["activity_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("activity_id", row["activity_id"] || row["subject_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("direction", row["direction"])
    |> compact_map()
  end

  defp contact_intent_from_review_or_import_row(_row), do: nil

  defp candidate_diff_report_rows(report, source_prefix, source_window_lineage \\ []) do
    report = stringify_keys(report || %{})
    invalidated_candidates = Map.get(report, "invalidated_candidates", [])
    lineage_by_candidate_id = source_window_lineage_by_candidate_id(source_window_lineage)

    candidate_diff_rows(
      invalidated_candidates,
      source_prefix <> ".invalidated_candidates",
      lineage_by_candidate_id
    ) ++
      candidate_diff_rows(
        reviewable_new_candidate_diff_rows(
          Map.get(report, "new_candidates", []),
          invalidated_candidates
        ),
        source_prefix <> ".new_candidates",
        lineage_by_candidate_id
      ) ++
      candidate_diff_rows(
        reviewable_retained_candidate_diff_rows(Map.get(report, "retained_candidates", [])),
        source_prefix <> ".retained_candidates",
        lineage_by_candidate_id
      )
  end

  defp source_window_lineage_by_candidate_id(source_window_lineage) do
    source_window_lineage
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(is_map(&1) and is_binary(&1["candidate_activity_id"])))
    |> Map.new(&{&1["candidate_activity_id"], &1})
  end

  defp reviewable_new_candidate_diff_rows(candidates, invalidated_candidates) do
    reviewed_replacement_ids =
      invalidated_candidates
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(& &1["replacement_candidate_id"])
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    candidates
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&MapSet.member?(reviewed_replacement_ids, &1["id"]))
    |> Enum.filter(&reviewable_new_candidate_diff_row?/1)
  end

  defp reviewable_new_candidate_diff_row?(candidate) do
    List.wrap(candidate["semantic_change_reasons"]) != [] or
      not is_nil(candidate["semantic_match_status"]) or
      candidate["diff_reason"] in [
        "semantically_similar_prior_candidate_changed",
        "ambiguous_semantic_prior_candidate_match"
      ]
  end

  defp reviewable_retained_candidate_diff_rows(candidates) do
    candidates
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(List.wrap(&1["semantic_change_reasons"]) != []))
  end

  defp candidate_rejection_rows(rows, source) do
    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&candidate_rejection_review_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      candidate_id = row["candidate_id"] || row["activity_id"] || "candidate_rejection:#{index}"
      action = row["required_operator_action"] || "review_candidate_rejection"
      reason = row["primary_rejection_reason"] || "candidate_rejected"

      %{
        "id" => review_id(["candidate_rejection_review", candidate_id, index]),
        "review_type" => "candidate_rejection_review",
        "source" => source,
        "subject_id" => candidate_id,
        "candidate_id" => candidate_id,
        "activity_id" => row["activity_id"] || candidate_id,
        "timeline_id" => row["timeline_id"],
        "activity_type" => row["activity_type"],
        "operational_kind" => row["operational_kind"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => "operator_review_required",
        "reason" => "candidate rejection requires review: #{reason}",
        "candidate_rejection_status" => row["rejection_status"],
        "candidate_rejection_reasons" => row["rejection_reasons"],
        "primary_rejection_reason" => row["primary_rejection_reason"],
        "candidate_rejection_reason_count" => row["reason_count"],
        "reviewable" => row["reviewable"],
        "violated_constraint" => row["violated_constraint"],
        "required_margin" => row["required_margin"],
        "actual_margin" => row["actual_margin"],
        "activity_context" => row["activity_context"],
        "source_candidate_rejection" => row
      }
      |> compact_map()
    end)
  end

  defp candidate_rejection_review_row?(row) do
    row["rejection_status"] == "rejected" and row["reviewable"] == true
  end

  defp provider_counteroffer_rows(rows, source) do
    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&provider_counteroffer_review_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      counteroffer_id = row["provider_counteroffer_id"] || "provider_counteroffer:#{index}"
      action = row["required_operator_action"] || "review_provider_counteroffer"
      status = row["provider_counteroffer_status"] || "unknown"
      negotiation_state = row["provider_counteroffer_negotiation_state"] || "unknown"

      %{
        "id" => review_id(["provider_counteroffer_review", counteroffer_id, index]),
        "review_type" => "provider_counteroffer_review",
        "source" => source,
        "subject_id" => counteroffer_id,
        "provider_counteroffer_id" => counteroffer_id,
        "provider_counteroffer_status" => status,
        "provider_counteroffer_negotiation_state" => negotiation_state,
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" =>
          row["provider_counteroffer_start_delta_s"] ||
            numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"]),
        "provider_counteroffer_end_delta_s" =>
          row["provider_counteroffer_end_delta_s"] ||
            numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"]),
        "provider_counteroffer_duration_delta_s" =>
          row["provider_counteroffer_duration_delta_s"] ||
            provider_counteroffer_duration_delta(row),
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_availability" => row["station_availability"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => "operator_review_required",
        "cadence_import_status" => "present",
        "reason" => provider_counteroffer_review_reason(counteroffer_id, status),
        "source_provider_counteroffer" => row
      }
      |> compact_map()
    end)
  end

  defp provider_counteroffer_review_row?(row) do
    row["reviewable"] == true and
      row["required_operator_action"] == "review_provider_counteroffer"
  end

  defp provider_counteroffer_review_reason(counteroffer_id, status) do
    "provider counteroffer #{counteroffer_id} requires review with status #{status}"
  end

  defp provider_counteroffer_duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           numeric_or_nil(row["provider_counteroffer_starts_at_s"]),
         counter_finish when is_number(counter_finish) <-
           numeric_or_nil(row["provider_counteroffer_ends_at_s"]) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(left, right) do
    with left when is_number(left) <- numeric_or_nil(left),
         right when is_number(right) <- numeric_or_nil(right) do
      left - right
    else
      _value -> nil
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp candidate_rejection_report_rows(report, source) do
    report = stringify_keys(report || %{})

    report
    |> Map.get("rows", [])
    |> candidate_rejection_rows(source <> ".rows")
  end

  defp candidate_refresh_candidate_rejection_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_candidate_rejection_report",
         artifact["source_candidate_rejection_report"]},
        {"candidate_refresh.candidate_rejection_report", artifact["candidate_rejection_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_candidate_rejection_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_candidate_rejection_rows(artifact)
  end

  defp source_candidate_rejection_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_candidate_rejection_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_candidate_rejection_report_rows(%{} = report, source),
    do: candidate_rejection_report_rows(report, source)

  defp source_candidate_rejection_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_candidate_rejection_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_candidate_rejection_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_candidate_rejection_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_candidate_rejection_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_candidate_rejection_rows(
         %{"schema_contract" => "candidate_rejection_report.v1"} = report,
         source
       ) do
    source_candidate_rejection_report_rows(report, source)
  end

  defp result_artifact_candidate_rejection_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_candidate_rejection_report",
       artifact["source_candidate_rejection_report"]},
      {"#{source}.candidate_rejection_report", artifact["candidate_rejection_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_candidate_rejection_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_candidate_rejection_rows(_artifact, _source), do: []

  defp candidate_refresh_candidate_diff_rows(artifact) do
    source_window_lineage = Map.get(artifact, "source_window_lineage", [])

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_candidate_diff_report",
         get_in(artifact, ["accepted_planning_state", "source_candidate_diff_report"])},
        {"candidate_refresh.accepted_planning_state.candidate_diff_report",
         get_in(artifact, ["accepted_planning_state", "candidate_diff_report"])},
        {"candidate_refresh.mission_state.source_candidate_diff_report",
         get_in(artifact, ["mission_state", "source_candidate_diff_report"])},
        {"candidate_refresh.mission_state.candidate_diff_report",
         get_in(artifact, ["mission_state", "candidate_diff_report"])},
        {"candidate_refresh.source_candidate_diff_report",
         artifact["source_candidate_diff_report"]},
        {"candidate_refresh.candidate_diff_report", artifact["candidate_diff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_candidate_diff_report_rows(report_or_reports, source, source_window_lineage)
      end)

    direct_rows ++ candidate_refresh_result_artifact_candidate_diff_rows(artifact)
  end

  defp source_candidate_diff_report_rows(reports, source, source_window_lineage)
       when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_candidate_diff_report_rows(report, "#{source}[#{index}]", source_window_lineage)
    end)
  end

  defp source_candidate_diff_report_rows(%{} = report, source, source_window_lineage) do
    report = stringify_keys(report)
    report_source_window_lineage = Map.get(report, "source_window_lineage", source_window_lineage)

    candidate_diff_report_rows(report, source, report_source_window_lineage)
  end

  defp source_candidate_diff_report_rows(_report, _source, _source_window_lineage), do: []

  defp candidate_refresh_result_artifact_candidate_diff_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_candidate_diff_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_candidate_diff_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_candidate_diff_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_candidate_diff_rows(
         %{"schema_contract" => "candidate_diff_report.v1"} = report,
         source
       ) do
    source_candidate_diff_report_rows(report, source, [])
  end

  defp result_artifact_candidate_diff_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_candidate_diff_report", artifact["source_candidate_diff_report"]},
      {"#{source}.candidate_diff_report", artifact["candidate_diff_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_candidate_diff_report_rows(report_or_reports, report_source, [])
    end)
  end

  defp result_artifact_candidate_diff_rows(_artifact, _source), do: []

  defp candidate_refresh_command_window_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_command_window_report",
         artifact["source_command_window_report"]},
        {"candidate_refresh.command_window_report", artifact["command_window_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_command_window_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_command_window_rows(artifact)
  end

  defp source_command_window_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_command_window_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_command_window_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> command_window_rows("#{source}.rows")
  end

  defp source_command_window_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_command_window_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_command_window_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_command_window_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_command_window_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_command_window_rows(
         %{"schema_contract" => "command_window_report.v1"} = report,
         source
       ) do
    source_command_window_report_rows(report, source)
  end

  defp result_artifact_command_window_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_command_window_report", artifact["source_command_window_report"]},
      {"#{source}.command_window_report", artifact["command_window_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_command_window_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_command_window_rows(_artifact, _source), do: []

  defp candidate_refresh_maneuver_review_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_maneuver_review_report",
         artifact["source_maneuver_review_report"]},
        {"candidate_refresh.maneuver_review_report", artifact["maneuver_review_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_maneuver_review_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_maneuver_review_rows(artifact)
  end

  defp source_maneuver_review_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_maneuver_review_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_maneuver_review_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> maneuver_review_rows("#{source}.rows")
  end

  defp source_maneuver_review_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_maneuver_review_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_maneuver_review_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_maneuver_review_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_maneuver_review_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_maneuver_review_rows(
         %{"schema_contract" => "maneuver_review_report.v1"} = report,
         source
       ) do
    source_maneuver_review_report_rows(report, source)
  end

  defp result_artifact_maneuver_review_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_maneuver_review_report", artifact["source_maneuver_review_report"]},
      {"#{source}.maneuver_review_report", artifact["maneuver_review_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_maneuver_review_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_maneuver_review_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_diff_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_diff_report",
         get_in(artifact, ["accepted_planning_state", "source_timeline_diff_report"])},
        {"candidate_refresh.accepted_planning_state.timeline_diff_report",
         get_in(artifact, ["accepted_planning_state", "timeline_diff_report"])},
        {"candidate_refresh.mission_state.source_timeline_diff_report",
         get_in(artifact, ["mission_state", "source_timeline_diff_report"])},
        {"candidate_refresh.mission_state.timeline_diff_report",
         get_in(artifact, ["mission_state", "timeline_diff_report"])},
        {"candidate_refresh.source_timeline_diff_report",
         artifact["source_timeline_diff_report"]},
        {"candidate_refresh.timeline_diff_report", artifact["timeline_diff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_timeline_diff_report_rows(report_or_reports, source)
      end)

    summary_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_diff_summary",
         get_in(artifact, ["accepted_planning_state", "source_timeline_diff_summary"])},
        {"candidate_refresh.accepted_planning_state.timeline_diff_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_diff_summary"])},
        {"candidate_refresh.mission_state.source_timeline_diff_summary",
         get_in(artifact, ["mission_state", "source_timeline_diff_summary"])},
        {"candidate_refresh.mission_state.timeline_diff_summary",
         get_in(artifact, ["mission_state", "timeline_diff_summary"])},
        {"candidate_refresh.source_timeline_diff_summary",
         artifact["source_timeline_diff_summary"]},
        {"candidate_refresh.timeline_diff_summary", artifact["timeline_diff_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_diff_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ summary_rows ++ candidate_refresh_result_artifact_timeline_diff_rows(artifact)
  end

  defp source_timeline_diff_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_timeline_diff_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_diff_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> timeline_diff_rows("#{source}.rows")
  end

  defp source_timeline_diff_report_rows(_report, _source), do: []

  defp source_timeline_diff_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_diff_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_diff_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_diff_summary_rows("#{source}.review_rows")
  end

  defp source_timeline_diff_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_diff_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_diff_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_diff_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_diff_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_diff_rows(
         %{"schema_contract" => "timeline_diff_report.v1"} = report,
         source
       ) do
    source_timeline_diff_report_rows(report, source)
  end

  defp result_artifact_timeline_diff_rows(
         %{"schema_contract" => "timeline_diff_summary.v1"} = summary,
         source
       ) do
    source_timeline_diff_summary_rows(summary, source)
  end

  defp result_artifact_timeline_diff_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_diff_report", artifact["source_timeline_diff_report"]},
      {"#{source}.timeline_diff_report", artifact["timeline_diff_report"]},
      {"#{source}.source_timeline_diff_summary", artifact["source_timeline_diff_summary"]},
      {"#{source}.timeline_diff_summary", artifact["timeline_diff_summary"]}
    ]
    |> Enum.flat_map(fn
      {summary_source, %{} = summary_or_report} ->
        summary_or_report = stringify_keys(summary_or_report)

        case summary_or_report["schema_contract"] do
          "timeline_diff_summary.v1" ->
            source_timeline_diff_summary_rows(summary_or_report, summary_source)

          _contract ->
            source_timeline_diff_report_rows(summary_or_report, summary_source)
        end

      {summary_source, summaries_or_reports} ->
        source_timeline_diff_report_rows(summaries_or_reports, summary_source) ++
          source_timeline_diff_summary_rows(summaries_or_reports, summary_source)
    end)
  end

  defp result_artifact_timeline_diff_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_integrity_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_integrity_report",
         get_in(artifact, ["accepted_planning_state", "source_timeline_integrity_report"])},
        {"candidate_refresh.accepted_planning_state.timeline_integrity_report",
         get_in(artifact, ["accepted_planning_state", "timeline_integrity_report"])},
        {"candidate_refresh.mission_state.source_timeline_integrity_report",
         get_in(artifact, ["mission_state", "source_timeline_integrity_report"])},
        {"candidate_refresh.mission_state.timeline_integrity_report",
         get_in(artifact, ["mission_state", "timeline_integrity_report"])},
        {"candidate_refresh.source_timeline_integrity_report",
         artifact["source_timeline_integrity_report"]},
        {"candidate_refresh.timeline_integrity_report", artifact["timeline_integrity_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_timeline_integrity_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_integrity_rows(artifact)
  end

  defp source_timeline_integrity_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_timeline_integrity_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_integrity_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> timeline_integrity_report_rows("#{source}.rows")
  end

  defp source_timeline_integrity_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_timeline_integrity_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_integrity_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_integrity_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_integrity_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_integrity_rows(
         %{"schema_contract" => "timeline_integrity_report.v1"} = report,
         source
       ) do
    source_timeline_integrity_report_rows(report, source)
  end

  defp result_artifact_timeline_integrity_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_integrity_report",
       artifact["source_timeline_integrity_report"]},
      {"#{source}.timeline_integrity_report", artifact["timeline_integrity_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_timeline_integrity_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_timeline_integrity_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_dependency_impact_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_timeline_dependency_impact_summary",
         artifact["source_timeline_dependency_impact_summary"]},
        {"candidate_refresh.timeline_dependency_impact_summary",
         artifact["timeline_dependency_impact_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_dependency_impact_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_dependency_impact_rows(artifact)
  end

  defp source_timeline_dependency_impact_summary_rows(summaries, source)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_dependency_impact_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_dependency_impact_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_dependency_impact_rows("#{source}.dependency_impact_rows")
  end

  defp source_timeline_dependency_impact_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_dependency_impact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_dependency_impact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_dependency_impact_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_dependency_impact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_dependency_impact_rows(
         %{"schema_contract" => "timeline_dependency_impact_summary.v1"} = summary,
         source
       ) do
    source_timeline_dependency_impact_summary_rows(summary, source)
  end

  defp result_artifact_timeline_dependency_impact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_dependency_impact_summary",
       artifact["source_timeline_dependency_impact_summary"]},
      {"#{source}.timeline_dependency_impact_summary",
       artifact["timeline_dependency_impact_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_timeline_dependency_impact_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_timeline_dependency_impact_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_publication_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_timeline_publication_summary",
         artifact["source_timeline_publication_summary"]},
        {"candidate_refresh.timeline_publication_summary",
         artifact["timeline_publication_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_publication_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_publication_rows(artifact)
  end

  defp source_timeline_publication_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_publication_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_publication_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_publication_rows(source)
  end

  defp source_timeline_publication_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_publication_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_publication_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_publication_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_publication_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_publication_rows(
         %{"schema_contract" => "timeline_publication_summary.v1"} = summary,
         source
       ) do
    source_timeline_publication_summary_rows(summary, source)
  end

  defp result_artifact_timeline_publication_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_publication_summary",
       artifact["source_timeline_publication_summary"]},
      {"#{source}.timeline_publication_summary", artifact["timeline_publication_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_timeline_publication_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_timeline_publication_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_activity_precondition_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_timeline_activity_precondition_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.timeline_activity_precondition_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_activity_precondition_summary"])},
        {"candidate_refresh.mission_state.source_timeline_activity_precondition_summary",
         get_in(artifact, ["mission_state", "source_timeline_activity_precondition_summary"])},
        {"candidate_refresh.mission_state.timeline_activity_precondition_summary",
         get_in(artifact, ["mission_state", "timeline_activity_precondition_summary"])},
        {"candidate_refresh.source_timeline_activity_precondition_summary",
         artifact["source_timeline_activity_precondition_summary"]},
        {"candidate_refresh.timeline_activity_precondition_summary",
         artifact["timeline_activity_precondition_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_activity_precondition_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_activity_precondition_rows(artifact)
  end

  defp source_timeline_activity_precondition_summary_rows(summaries, source)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_activity_precondition_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_activity_precondition_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_activity_precondition_rows("#{source}.summary")
  end

  defp source_timeline_activity_precondition_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_activity_precondition_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_activity_precondition_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_activity_precondition_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_activity_precondition_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_activity_precondition_rows(
         %{"schema_contract" => "timeline_activity_precondition_summary.v1"} = summary,
         source
       ) do
    source_timeline_activity_precondition_summary_rows(summary, source)
  end

  defp result_artifact_timeline_activity_precondition_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_precondition_summary",
       artifact["source_timeline_activity_precondition_summary"]},
      {"#{source}.timeline_activity_precondition_summary",
       artifact["timeline_activity_precondition_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_timeline_activity_precondition_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_timeline_activity_precondition_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_lifecycle_state_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_lifecycle_state_summary",
         get_in(artifact, ["accepted_planning_state", "source_timeline_lifecycle_state_summary"])},
        {"candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_lifecycle_state_summary"])},
        {"candidate_refresh.mission_state.source_timeline_lifecycle_state_summary",
         get_in(artifact, ["mission_state", "source_timeline_lifecycle_state_summary"])},
        {"candidate_refresh.mission_state.timeline_lifecycle_state_summary",
         get_in(artifact, ["mission_state", "timeline_lifecycle_state_summary"])},
        {"candidate_refresh.source_timeline_lifecycle_state_summary",
         artifact["source_timeline_lifecycle_state_summary"]},
        {"candidate_refresh.timeline_lifecycle_state_summary",
         artifact["timeline_lifecycle_state_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_lifecycle_state_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_lifecycle_state_rows(artifact)
  end

  defp source_timeline_lifecycle_state_summary_rows(summaries, source)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_lifecycle_state_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_lifecycle_state_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_lifecycle_state_rows("#{source}.review_rows")
  end

  defp source_timeline_lifecycle_state_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_lifecycle_state_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_lifecycle_state_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_lifecycle_state_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_lifecycle_state_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_lifecycle_state_rows(
         %{"schema_contract" => "timeline_lifecycle_state_summary.v1"} = summary,
         source
       ) do
    source_timeline_lifecycle_state_summary_rows(summary, source)
  end

  defp result_artifact_timeline_lifecycle_state_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_lifecycle_state_summary",
       artifact["source_timeline_lifecycle_state_summary"]},
      {"#{source}.timeline_lifecycle_state_summary", artifact["timeline_lifecycle_state_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_timeline_lifecycle_state_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_timeline_lifecycle_state_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_activity_state_rows(artifact) do
    direct_rows =
      candidate_refresh_timeline_activity_state_sources(artifact)
      |> Enum.flat_map(fn {source, state_or_states} ->
        source_timeline_activity_state_rows(state_or_states, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_activity_state_rows(artifact)
  end

  defp candidate_refresh_timeline_activity_state_sources(artifact) do
    [
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_state"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_status_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_status_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_status_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_status_state"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_approval_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_approval_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_approval_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_approval_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_state"])},
      {"candidate_refresh.mission_state.timeline_activity_state",
       get_in(artifact, ["mission_state", "timeline_activity_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_status_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_status_state"])},
      {"candidate_refresh.mission_state.timeline_activity_status_state",
       get_in(artifact, ["mission_state", "timeline_activity_status_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_approval_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_approval_state"])},
      {"candidate_refresh.mission_state.timeline_activity_approval_state",
       get_in(artifact, ["mission_state", "timeline_activity_approval_state"])},
      {"candidate_refresh.source_timeline_activity_state",
       artifact["source_timeline_activity_state"]},
      {"candidate_refresh.timeline_activity_state", artifact["timeline_activity_state"]},
      {"candidate_refresh.source_timeline_activity_status_state",
       artifact["source_timeline_activity_status_state"]},
      {"candidate_refresh.timeline_activity_status_state",
       artifact["timeline_activity_status_state"]},
      {"candidate_refresh.source_timeline_activity_approval_state",
       artifact["source_timeline_activity_approval_state"]},
      {"candidate_refresh.timeline_activity_approval_state",
       artifact["timeline_activity_approval_state"]}
    ]
  end

  defp source_timeline_activity_state_rows(states, source) when is_list(states) do
    states
    |> Enum.with_index()
    |> Enum.flat_map(fn {state, index} ->
      source_timeline_activity_state_rows(state, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_activity_state_rows(%{} = state, source) do
    state
    |> stringify_keys()
    |> timeline_activity_state_rows("#{source}.state")
  end

  defp source_timeline_activity_state_rows(_state, _source), do: []

  defp candidate_refresh_result_artifact_timeline_activity_state_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_activity_state_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_activity_state_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_activity_state_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_activity_state_rows(
         %{"schema_contract" => schema_contract} = state,
         source
       )
       when schema_contract in [
              "timeline_activity_state.v1",
              "timeline_activity_status_state.v1",
              "timeline_activity_approval_state.v1"
            ] do
    source_timeline_activity_state_rows(state, source)
  end

  defp result_artifact_timeline_activity_state_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_state", artifact["source_timeline_activity_state"]},
      {"#{source}.timeline_activity_state", artifact["timeline_activity_state"]},
      {"#{source}.source_timeline_activity_status_state",
       artifact["source_timeline_activity_status_state"]},
      {"#{source}.timeline_activity_status_state", artifact["timeline_activity_status_state"]},
      {"#{source}.source_timeline_activity_approval_state",
       artifact["source_timeline_activity_approval_state"]},
      {"#{source}.timeline_activity_approval_state", artifact["timeline_activity_approval_state"]}
    ]
    |> Enum.flat_map(fn {state_source, state_or_states} ->
      source_timeline_activity_state_rows(state_or_states, state_source)
    end)
  end

  defp result_artifact_timeline_activity_state_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_activity_lifecycle_state_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_activity_lifecycle_state",
         get_in(artifact, ["accepted_planning_state", "source_timeline_activity_lifecycle_state"])},
        {"candidate_refresh.accepted_planning_state.timeline_activity_lifecycle_state",
         get_in(artifact, ["accepted_planning_state", "timeline_activity_lifecycle_state"])},
        {"candidate_refresh.mission_state.source_timeline_activity_lifecycle_state",
         get_in(artifact, ["mission_state", "source_timeline_activity_lifecycle_state"])},
        {"candidate_refresh.mission_state.timeline_activity_lifecycle_state",
         get_in(artifact, ["mission_state", "timeline_activity_lifecycle_state"])},
        {"candidate_refresh.source_timeline_activity_lifecycle_state",
         artifact["source_timeline_activity_lifecycle_state"]},
        {"candidate_refresh.timeline_activity_lifecycle_state",
         artifact["timeline_activity_lifecycle_state"]}
      ]
      |> Enum.flat_map(fn {source, state_or_states} ->
        source_timeline_activity_lifecycle_state_rows(state_or_states, source)
      end)

    direct_rows ++
      candidate_refresh_result_artifact_timeline_activity_lifecycle_state_rows(artifact)
  end

  defp source_timeline_activity_lifecycle_state_rows(states, source) when is_list(states) do
    states
    |> Enum.with_index()
    |> Enum.flat_map(fn {state, index} ->
      source_timeline_activity_lifecycle_state_rows(state, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_activity_lifecycle_state_rows(%{} = state, source) do
    state
    |> stringify_keys()
    |> timeline_activity_state_rows("#{source}.state")
  end

  defp source_timeline_activity_lifecycle_state_rows(_state, _source), do: []

  defp candidate_refresh_result_artifact_timeline_activity_lifecycle_state_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_activity_lifecycle_state_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_activity_lifecycle_state_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_activity_lifecycle_state_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_activity_lifecycle_state_rows(
         %{"schema_contract" => "timeline_activity_lifecycle_state.v1"} = state,
         source
       ) do
    source_timeline_activity_lifecycle_state_rows(state, source)
  end

  defp result_artifact_timeline_activity_lifecycle_state_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_lifecycle_state",
       artifact["source_timeline_activity_lifecycle_state"]},
      {"#{source}.timeline_activity_lifecycle_state",
       artifact["timeline_activity_lifecycle_state"]}
    ]
    |> Enum.flat_map(fn {state_source, state_or_states} ->
      source_timeline_activity_lifecycle_state_rows(state_or_states, state_source)
    end)
  end

  defp result_artifact_timeline_activity_lifecycle_state_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_preservation_rows(artifact) do
    direct_rows =
      candidate_refresh_timeline_preservation_sources(artifact)
      |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
        source_timeline_preservation_rows(artifact_or_artifacts, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_preservation_rows(artifact)
  end

  defp candidate_refresh_timeline_preservation_sources(artifact) do
    [
      {"candidate_refresh.accepted_planning_state.source_timeline_preservation_report",
       get_in(artifact, ["accepted_planning_state", "source_timeline_preservation_report"])},
      {"candidate_refresh.accepted_planning_state.timeline_preservation_report",
       get_in(artifact, ["accepted_planning_state", "timeline_preservation_report"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_preservation_status",
       get_in(artifact, ["accepted_planning_state", "source_timeline_preservation_status"])},
      {"candidate_refresh.accepted_planning_state.timeline_preservation_status",
       get_in(artifact, ["accepted_planning_state", "timeline_preservation_status"])},
      {"candidate_refresh.mission_state.source_timeline_preservation_report",
       get_in(artifact, ["mission_state", "source_timeline_preservation_report"])},
      {"candidate_refresh.mission_state.timeline_preservation_report",
       get_in(artifact, ["mission_state", "timeline_preservation_report"])},
      {"candidate_refresh.mission_state.source_timeline_preservation_status",
       get_in(artifact, ["mission_state", "source_timeline_preservation_status"])},
      {"candidate_refresh.mission_state.timeline_preservation_status",
       get_in(artifact, ["mission_state", "timeline_preservation_status"])},
      {"candidate_refresh.source_timeline_preservation_report",
       artifact["source_timeline_preservation_report"]},
      {"candidate_refresh.timeline_preservation_report",
       artifact["timeline_preservation_report"]},
      {"candidate_refresh.source_timeline_preservation_status",
       artifact["source_timeline_preservation_status"]},
      {"candidate_refresh.timeline_preservation_status", artifact["timeline_preservation_status"]}
    ]
  end

  defp source_timeline_preservation_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      source_timeline_preservation_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_preservation_rows(
         %{"schema_contract" => "timeline_preservation_report.v1"} = report,
         source
       ) do
    source_timeline_preservation_report_rows(report, source)
  end

  defp source_timeline_preservation_rows(
         %{"schema_contract" => "timeline_preservation_status.v1"} = status,
         source
       ) do
    source_timeline_preservation_status_rows(status, source)
  end

  defp source_timeline_preservation_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    cond do
      Map.has_key?(artifact, "rows") ->
        source_timeline_preservation_report_rows(artifact, source)

      Map.has_key?(artifact, "timeline_preservation_status") ->
        source_timeline_preservation_status_rows(artifact, source)

      true ->
        []
    end
  end

  defp source_timeline_preservation_rows(_artifact, _source), do: []

  defp source_timeline_preservation_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_preservation_review_row(row, index, "#{source}.rows", report, row)
    end)
  end

  defp source_timeline_preservation_status_rows(%{} = status, source) do
    status = stringify_keys(status)
    [timeline_preservation_review_row(status, 1, "#{source}.status", status, status)]
  end

  defp candidate_refresh_result_artifact_timeline_preservation_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_preservation_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_preservation_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_preservation_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_preservation_rows(
         %{"schema_contract" => schema_contract} = artifact,
         source
       )
       when schema_contract in [
              "timeline_preservation_report.v1",
              "timeline_preservation_status.v1"
            ] do
    source_timeline_preservation_rows(artifact, source)
  end

  defp result_artifact_timeline_preservation_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_preservation_report",
       artifact["source_timeline_preservation_report"]},
      {"#{source}.timeline_preservation_report", artifact["timeline_preservation_report"]},
      {"#{source}.source_timeline_preservation_status",
       artifact["source_timeline_preservation_status"]},
      {"#{source}.timeline_preservation_status", artifact["timeline_preservation_status"]}
    ]
    |> Enum.flat_map(fn {artifact_source, artifact_or_artifacts} ->
      source_timeline_preservation_rows(artifact_or_artifacts, artifact_source)
    end)
  end

  defp result_artifact_timeline_preservation_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_transition_application_rows(artifact) do
    report_rows =
      [
        {"candidate_refresh.source_timeline_transition_application_report",
         artifact["source_timeline_transition_application_report"]},
        {"candidate_refresh.timeline_transition_application_report",
         artifact["timeline_transition_application_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_timeline_transition_application_report_rows(report_or_reports, source)
      end)

    summary_rows =
      [
        {"candidate_refresh.source_timeline_transition_application_summary",
         artifact["source_timeline_transition_application_summary"]},
        {"candidate_refresh.timeline_transition_application_summary",
         artifact["timeline_transition_application_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_timeline_transition_application_summary_rows(summary_or_summaries, source)
      end)

    report_rows ++
      summary_rows ++
      candidate_refresh_result_artifact_timeline_transition_application_rows(artifact)
  end

  defp source_timeline_transition_application_report_rows(reports, source)
       when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_timeline_transition_application_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_transition_application_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    timeline_transition_application_rows(
      Map.get(report, "applications", []),
      "#{source}.applications",
      nil
    )
  end

  defp source_timeline_transition_application_report_rows(_report, _source), do: []

  defp source_timeline_transition_application_summary_rows(summaries, source)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_timeline_transition_application_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_transition_application_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> timeline_transition_application_summary_rows([], "#{source}.review_applications")
  end

  defp source_timeline_transition_application_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_timeline_transition_application_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_transition_application_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_transition_application_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_transition_application_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_transition_application_rows(
         %{"schema_contract" => "timeline_transition_application_summary.v1"} = summary,
         source
       ) do
    source_timeline_transition_application_summary_rows(summary, source)
  end

  defp result_artifact_timeline_transition_application_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_transition_application_summary",
       artifact["source_timeline_transition_application_summary"]},
      {"#{source}.timeline_transition_application_summary",
       artifact["timeline_transition_application_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_timeline_transition_application_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_timeline_transition_application_rows(_artifact, _source), do: []

  defp candidate_refresh_constraint_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_constraint_report", artifact["source_constraint_report"]},
        {"candidate_refresh.constraint_report", artifact["constraint_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_constraint_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_constraint_rows(artifact)
  end

  defp source_constraint_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_constraint_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_constraint_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> constraint_rows("#{source}.rows")
  end

  defp source_constraint_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_constraint_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_constraint_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_constraint_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_constraint_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_constraint_rows(
         %{"schema_contract" => "constraint_report.v1"} = report,
         source
       ) do
    source_constraint_report_rows(report, source)
  end

  defp result_artifact_constraint_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_constraint_report", artifact["source_constraint_report"]},
      {"#{source}.constraint_report", artifact["constraint_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_constraint_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_constraint_rows(_artifact, _source), do: []

  defp candidate_refresh_objective_satisfaction_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_objective_satisfaction_report",
         artifact["source_objective_satisfaction_report"]},
        {"candidate_refresh.objective_satisfaction_report",
         artifact["objective_satisfaction_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_objective_satisfaction_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_objective_satisfaction_rows(artifact)
  end

  defp source_objective_satisfaction_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_objective_satisfaction_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_objective_satisfaction_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> objective_satisfaction_rows("#{source}.rows")
  end

  defp source_objective_satisfaction_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_objective_satisfaction_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_objective_satisfaction_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_objective_satisfaction_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_objective_satisfaction_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_objective_satisfaction_rows(
         %{"schema_contract" => "objective_satisfaction_report.v1"} = report,
         source
       ) do
    source_objective_satisfaction_report_rows(report, source)
  end

  defp result_artifact_objective_satisfaction_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_objective_satisfaction_report",
       artifact["source_objective_satisfaction_report"]},
      {"#{source}.objective_satisfaction_report", artifact["objective_satisfaction_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_objective_satisfaction_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_objective_satisfaction_rows(_artifact, _source), do: []

  defp candidate_refresh_score_term_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_score_term_report", artifact["source_score_term_report"]},
        {"candidate_refresh.score_term_report", artifact["score_term_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_score_term_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_score_term_rows(artifact)
  end

  defp source_score_term_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_score_term_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_score_term_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> score_term_rows("#{source}.rows")
  end

  defp source_score_term_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_score_term_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_score_term_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_score_term_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_score_term_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_score_term_rows(
         %{"schema_contract" => "score_term_report.v1"} = report,
         source
       ) do
    source_score_term_report_rows(report, source)
  end

  defp result_artifact_score_term_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_score_term_report", artifact["source_score_term_report"]},
      {"#{source}.score_term_report", artifact["score_term_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_score_term_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_score_term_rows(_artifact, _source), do: []

  defp candidate_refresh_objective_tradeoff_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_objective_tradeoff_report",
         artifact["source_objective_tradeoff_report"]},
        {"candidate_refresh.objective_tradeoff_report", artifact["objective_tradeoff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_objective_tradeoff_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_objective_tradeoff_rows(artifact)
  end

  defp source_objective_tradeoff_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_objective_tradeoff_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_objective_tradeoff_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("tradeoffs", [])
    |> objective_tradeoff_rows("#{source}.tradeoffs")
  end

  defp source_objective_tradeoff_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_objective_tradeoff_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_objective_tradeoff_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_objective_tradeoff_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_objective_tradeoff_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_objective_tradeoff_rows(
         %{"schema_contract" => "objective_tradeoff_report.v1"} = report,
         source
       ) do
    source_objective_tradeoff_report_rows(report, source)
  end

  defp result_artifact_objective_tradeoff_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_objective_tradeoff_report",
       artifact["source_objective_tradeoff_report"]},
      {"#{source}.objective_tradeoff_report", artifact["objective_tradeoff_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_objective_tradeoff_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_objective_tradeoff_rows(_artifact, _source), do: []

  defp candidate_refresh_contact_contention_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_contact_contention_report",
         artifact["source_contact_contention_report"]},
        {"candidate_refresh.contact_contention_report", artifact["contact_contention_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_contention_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_contact_contention_rows(artifact)
  end

  defp source_contact_contention_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_contention_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_contention_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    contact_contention_invalid_input_rows(
      Map.get(report, "invalid_contact_inputs", []),
      "#{source}.invalid_contact_inputs"
    ) ++
      contact_contention_group_rows(
        Map.get(report, "conflict_groups", []),
        "#{source}.conflict_groups"
      )
  end

  defp source_contact_contention_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_contact_contention_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_contention_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_contention_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_contention_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_contention_rows(
         %{"schema_contract" => "contact_contention_report.v1"} = report,
         source
       ) do
    source_contact_contention_report_rows(report, source)
  end

  defp result_artifact_contact_contention_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_contention_report",
       artifact["source_contact_contention_report"]},
      {"#{source}.contact_contention_report", artifact["contact_contention_report"]},
      {"#{source}.contact_allocation_report.contact_contention_report",
       get_in(artifact, ["contact_allocation_report", "contact_contention_report"])}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_contention_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_contact_contention_rows(_artifact, _source), do: []

  defp candidate_refresh_contact_contention_resolution_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_contention_resolution_report",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_contention_resolution_report"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_contention_resolution_report",
         get_in(artifact, ["accepted_planning_state", "contact_contention_resolution_report"])},
        {"candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_contention_resolution_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_contention_resolution_summary",
         get_in(artifact, ["accepted_planning_state", "contact_contention_resolution_summary"])},
        {"candidate_refresh.mission_state.source_contact_contention_resolution_report",
         get_in(artifact, ["mission_state", "source_contact_contention_resolution_report"])},
        {"candidate_refresh.mission_state.contact_contention_resolution_report",
         get_in(artifact, ["mission_state", "contact_contention_resolution_report"])},
        {"candidate_refresh.mission_state.source_contact_contention_resolution_summary",
         get_in(artifact, ["mission_state", "source_contact_contention_resolution_summary"])},
        {"candidate_refresh.mission_state.contact_contention_resolution_summary",
         get_in(artifact, ["mission_state", "contact_contention_resolution_summary"])},
        {"candidate_refresh.source_contact_contention_resolution_report",
         artifact["source_contact_contention_resolution_report"]},
        {"candidate_refresh.contact_contention_resolution_report",
         artifact["contact_contention_resolution_report"]},
        {"candidate_refresh.source_contact_contention_resolution_summary",
         artifact["source_contact_contention_resolution_summary"]},
        {"candidate_refresh.contact_contention_resolution_summary",
         artifact["contact_contention_resolution_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_contention_resolution_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_contact_contention_resolution_rows(artifact)
  end

  defp source_contact_contention_resolution_report_rows(reports, source)
       when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_contention_resolution_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_contention_resolution_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if contact_contention_resolution_summary?(report) do
      source_contact_contention_resolution_summary_rows(report, source)
    else
      report
      |> Map.get("recommendations", [])
      |> contact_contention_rows("#{source}.recommendations")
    end
  end

  defp source_contact_contention_resolution_report_rows(_report, _source), do: []

  defp source_contact_contention_resolution_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = contact_contention_resolution_summary_context(summary)

    summary
    |> contact_contention_resolution_summary_recommendation_rows()
    |> Enum.map(fn row ->
      row
      |> Map.put("source_contact_contention_resolution_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_summary_source", summary["source"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> contact_contention_rows("#{source}.summary_recommendations")
  end

  defp contact_contention_resolution_summary_recommendation_rows(%{"recommendations" => rows})
       when is_list(rows) and rows != [] do
    rows
    |> Enum.map(&stringify_keys/1)
  end

  defp contact_contention_resolution_summary_recommendation_rows(%{} = summary) do
    summary
    |> contact_contention_resolution_summary_group_ids()
    |> Enum.map(fn group_id ->
      selected_contact_ids =
        contact_contention_resolution_summary_group_ids(
          summary,
          group_id,
          "selected_contact_ids"
        )

      deferred_contact_ids =
        contact_contention_resolution_summary_group_ids(
          summary,
          group_id,
          "deferred_contact_ids"
        )

      review_contact_ids =
        contact_contention_resolution_summary_group_ids(
          summary,
          group_id,
          "review_contact_ids"
        )

      %{
        "group_id" => group_id,
        "ground_station_id" =>
          contact_contention_resolution_summary_group_value(
            summary,
            group_id,
            "ground_station_ids"
          ) ||
            contact_contention_resolution_summary_single_map_key(
              summary,
              "capacity_pack_required_capacity_fraction_by_ground_station_id"
            ),
        "resource_scope" =>
          contact_contention_resolution_summary_group_value(
            summary,
            group_id,
            "resource_scopes"
          ) ||
            contact_contention_resolution_summary_single_count_key(
              summary,
              "resource_scope_counts"
            ),
        "selected_contact_id" => List.first(selected_contact_ids),
        "selected_contact_ids" => selected_contact_ids,
        "deferred_contact_ids" => deferred_contact_ids,
        "review_contact_ids" => review_contact_ids,
        "candidate_count" =>
          Enum.count(
            Enum.uniq(selected_contact_ids ++ deferred_contact_ids ++ review_contact_ids)
          ),
        "selection_reason" =>
          contact_contention_resolution_summary_group_value(
            summary,
            group_id,
            "selection_reasons"
          ) ||
            contact_contention_resolution_summary_single_count_key(
              summary,
              "selection_reason_counts"
            ),
        "action" =>
          contact_contention_resolution_summary_group_value(summary, group_id, "actions") ||
            contact_contention_resolution_summary_single_count_key(summary, "action_counts") ||
            "recommend_preferred_contact_for_operator_review",
        "review_status" => "operator_review_required",
        "capacity_pack_required_capacity_fraction" =>
          contact_contention_resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_required_capacity_fraction"
          ),
        "capacity_pack_selected_required_capacity_fraction" =>
          contact_contention_resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_selected_required_capacity_fraction"
          ),
        "capacity_pack_deferred_required_capacity_fraction" =>
          contact_contention_resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_deferred_required_capacity_fraction"
          ),
        "capacity_pack_required_capacity_fraction_by_status" =>
          summary["capacity_pack_required_capacity_fraction_by_status"],
        "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
          summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
        "required_capacity_fraction_source_counts" =>
          summary["required_capacity_fraction_source_counts"]
      }
      |> compact_map()
    end)
  end

  defp contact_contention_resolution_summary_group_ids(%{} = summary) do
    keyed_group_ids =
      [
        "selected_contact_ids_by_group_id",
        "deferred_contact_ids_by_group_id",
        "review_contact_ids_by_group_id"
      ]
      |> Enum.flat_map(fn field ->
        case summary[field] do
          %{} = by_group -> Map.keys(by_group)
          _value -> []
        end
      end)

    [
      summary["recommendation_group_ids"],
      summary["review_group_ids"],
      keyed_group_ids
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp contact_contention_resolution_summary_group_ids(summary, group_id, field) do
    by_group_field = "#{field}_by_group_id"

    value =
      case summary[by_group_field] do
        %{} = by_group -> by_group[group_id]
        _value -> nil
      end

    (value || summary[field] || [])
    |> List.wrap()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp contact_contention_resolution_summary_group_value(summary, group_id, field) do
    by_group_field = "#{field}_by_group_id"

    case summary[by_group_field] do
      %{} = by_group ->
        by_group[group_id]
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> List.first()

      _value ->
        nil
    end
  end

  defp contact_contention_resolution_summary_group_number(summary, _group_id, field) do
    numeric_or_nil(summary[field])
  end

  defp contact_contention_resolution_summary_single_map_key(summary, field) do
    case summary[field] do
      %{} = values when map_size(values) == 1 ->
        values
        |> Map.keys()
        |> List.first()

      _value ->
        nil
    end
  end

  defp contact_contention_resolution_summary_single_count_key(summary, field) do
    case summary[field] do
      %{} = counts when map_size(counts) == 1 ->
        counts
        |> Map.keys()
        |> List.first()

      _value ->
        nil
    end
  end

  defp contact_contention_resolution_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "conflict_group_count" => summary["conflict_group_count"],
      "recommendation_count" => summary["recommendation_count"],
      "review_recommendation_count" => summary["review_recommendation_count"],
      "recommendation_group_ids" => summary["recommendation_group_ids"],
      "review_group_ids" => summary["review_group_ids"],
      "selected_contact_ids" => summary["selected_contact_ids"],
      "deferred_contact_ids" => summary["deferred_contact_ids"],
      "review_contact_ids" => summary["review_contact_ids"],
      "capacity_pack_required_capacity_fraction" =>
        summary["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        summary["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        summary["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        summary["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        summary["required_capacity_fraction_source_counts"],
      "action_counts" => summary["action_counts"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp contact_contention_resolution_summary?(%{
         "schema_contract" => "contact_contention_resolution_summary.v1"
       }),
       do: true

  defp contact_contention_resolution_summary?(%{
         "model" => "artifact_only_contact_contention_resolution_summary"
       }),
       do: true

  defp contact_contention_resolution_summary?(_summary), do: false

  defp candidate_refresh_result_artifact_contact_contention_resolution_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_contention_resolution_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_contention_resolution_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_contention_resolution_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_contention_resolution_rows(
         %{"schema_contract" => "contact_contention_resolution_report.v1"} = report,
         source
       ) do
    source_contact_contention_resolution_report_rows(report, source)
  end

  defp result_artifact_contact_contention_resolution_rows(
         %{"schema_contract" => "contact_contention_resolution_summary.v1"} = summary,
         source
       ) do
    source_contact_contention_resolution_report_rows(summary, source)
  end

  defp result_artifact_contact_contention_resolution_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_contention_resolution_report",
       artifact["source_contact_contention_resolution_report"]},
      {"#{source}.contact_contention_resolution_report",
       artifact["contact_contention_resolution_report"]},
      {"#{source}.source_contact_contention_resolution_summary",
       artifact["source_contact_contention_resolution_summary"]},
      {"#{source}.contact_contention_resolution_summary",
       artifact["contact_contention_resolution_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_contention_resolution_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_contact_contention_resolution_rows(_artifact, _source), do: []

  defp candidate_diff_rows(candidates, source, lineage_by_candidate_id \\ %{}) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      candidate_id =
        candidate["id"] || candidate["invalidated_candidate_id"] || "candidate_diff:#{index}"

      source_window_lineage = lineage_by_candidate_id[candidate_id]

      replacement_source_window_lineage =
        lineage_by_candidate_id[candidate["replacement_candidate_id"]]

      action = candidate["required_operator_action"] || "review_candidate_diff"

      reason =
        candidate["invalidated_reason"] || candidate["diff_reason"] ||
          "candidate refresh changed candidate"

      invalidated_candidate_id =
        candidate["invalidated_candidate_id"] ||
          if(candidate["invalidated_reason"], do: candidate_id)

      semantic_change_reasons = semantic_change_reasons(candidate)
      changed_fields = candidate_diff_changed_fields(candidate)

      %{
        "id" => review_id(["candidate_diff_review", candidate_id, index]),
        "review_type" => "candidate_diff_review",
        "source" => source,
        "subject_id" => candidate_id,
        "activity_id" => candidate_id,
        "activity_type" => candidate["type"] || candidate["activity_type"],
        "scenario_id" => candidate["scenario_id"],
        "target_id" => candidate["target_id"],
        "source_target_id" => candidate["source_target_id"],
        "source_target" => candidate["source_target"],
        "target_latitude_deg" => candidate["target_latitude_deg"],
        "target_longitude_deg" => candidate["target_longitude_deg"],
        "target_minimum_elevation_deg" => candidate["target_minimum_elevation_deg"],
        "target_priority" => candidate["target_priority"],
        "target_priority_source" => candidate["target_priority_source"],
        "target_priority_objective_ids" => candidate["target_priority_objective_ids"],
        "target_priority_objective_type" => candidate["target_priority_objective_type"],
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "source_window_id" => candidate["source_window_id"],
        "source_window_type" =>
          candidate["source_window_type"] || source_window_lineage_type(source_window_lineage),
        "source_window" => source_window_from_lineage(source_window_lineage),
        "source_window_lineage" => source_window_lineage,
        "replacement_source_window_id" =>
          replacement_source_window_id(candidate, replacement_source_window_lineage),
        "replacement_source_window_type" =>
          source_window_lineage_type(replacement_source_window_lineage),
        "replacement_source_window" =>
          source_window_from_lineage(replacement_source_window_lineage),
        "replacement_source_window_lineage" => replacement_source_window_lineage,
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "reason" => "candidate diff requires review: #{reason}",
        "operator_action_reason" => candidate["operator_action_reason"],
        "candidate_diff" => candidate,
        "invalidated_candidate_id" => invalidated_candidate_id,
        "invalidated_candidate_ids" => candidate["invalidated_candidate_ids"],
        "replacement_candidate_id" => candidate["replacement_candidate_id"],
        "invalidated_reason" => candidate["invalidated_reason"],
        "semantic_change_reasons" => semantic_change_reasons,
        "semantic_change_details" => candidate["semantic_change_details"],
        "changed_fields" => changed_fields,
        "candidate_diff_changed_fields" => changed_fields,
        "candidate_diff_changed_field_count" =>
          candidate_diff_changed_field_count(changed_fields),
        "candidate_diff_match_status" => candidate["candidate_diff_match_status"],
        "candidate_diff_match_count" => candidate["candidate_diff_match_count"],
        "semantic_match_status" => candidate["semantic_match_status"],
        "semantic_match_candidate_count" => candidate["semantic_match_candidate_count"],
        "semantic_match_candidate_ids" => candidate["semantic_match_candidate_ids"],
        "candidate_budget_match_status" => candidate["candidate_budget_match_status"],
        "candidate_budget_match_count" => candidate["candidate_budget_match_count"],
        "budget_dropped_candidate_ids" => candidate["budget_dropped_candidate_ids"],
        "invalid_prior_candidate_input" => candidate["invalid_prior_candidate_input"],
        "invalid_prior_candidate_input_reason" =>
          candidate["invalid_prior_candidate_input_reason"],
        "source_candidate" => candidate["source_candidate"],
        "source_candidate_diff" => candidate
      }
      |> Map.merge(candidate_diff_scoped_context(candidate))
      |> compact_map()
    end)
  end

  defp candidate_diff_scoped_context(candidate) do
    candidate
    |> Map.take(@candidate_diff_scoped_context_fields)
    |> compact_map()
  end

  defp candidate_diff_changed_fields(row) do
    row
    |> Map.get("candidate_diff_changed_fields", Map.get(row, "changed_fields"))
    |> List.wrap()
    |> Enum.concat(semantic_change_detail_fields(row["semantic_change_details"]))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp semantic_change_reasons(row) do
    detail_reasons = semantic_change_detail_reasons(row["semantic_change_details"])

    case detail_reasons do
      [] ->
        row
        |> Map.get("semantic_change_reasons")
        |> List.wrap()
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()

      reasons ->
        reasons
    end
  end

  defp semantic_change_detail_reasons(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "reason"))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp semantic_change_detail_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
  end

  defp candidate_diff_changed_field_count([]), do: nil
  defp candidate_diff_changed_field_count(fields), do: length(fields)

  defp replacement_source_window_id(candidate, nil), do: candidate["replacement_source_window_id"]

  defp replacement_source_window_id(candidate, lineage) do
    candidate["replacement_source_window_id"] || lineage["source_window_id"] ||
      get_in(lineage, ["source_window", "id"])
  end

  defp source_window_lineage_type(nil), do: nil

  defp source_window_lineage_type(lineage) do
    lineage["source_window_type"] || get_in(lineage, ["source_window", "type"])
  end

  defp source_window_from_lineage(nil), do: nil

  defp source_window_from_lineage(lineage), do: lineage["source_window"]

  defp candidate_refresh_freshness_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_freshness_report",
         get_in(artifact, ["accepted_planning_state", "source_freshness_report"])},
        {"candidate_refresh.accepted_planning_state.freshness_report",
         get_in(artifact, ["accepted_planning_state", "freshness_report"])},
        {"candidate_refresh.mission_state.source_freshness_report",
         get_in(artifact, ["mission_state", "source_freshness_report"])},
        {"candidate_refresh.mission_state.freshness_report",
         get_in(artifact, ["mission_state", "freshness_report"])},
        {"candidate_refresh.source_freshness_report", artifact["source_freshness_report"]},
        {"candidate_refresh.freshness_report", artifact["freshness_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_freshness_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_freshness_rows(artifact)
  end

  defp source_freshness_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_freshness_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_freshness_report_rows(%{} = report, source), do: freshness_rows(report, source)

  defp source_freshness_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_freshness_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_freshness_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_freshness_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_freshness_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_freshness_rows(
         %{"schema_contract" => "freshness_report.v1"} = report,
         source
       ) do
    source_freshness_report_rows(report, source)
  end

  defp result_artifact_freshness_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_freshness_report", artifact["source_freshness_report"]},
      {"#{source}.freshness_report", artifact["freshness_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_freshness_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_freshness_rows(_artifact, _source), do: []

  defp freshness_rows(nil, _source), do: []

  defp freshness_rows(%{} = report, source) do
    report = stringify_keys(report)
    status = Map.get(report, "status")

    if status in ["stale", "unknown"] do
      reason =
        report
        |> freshness_reasons()
        |> case do
          [] -> "candidate refresh freshness is #{status}"
          reasons -> "candidate refresh freshness is #{status}: #{Enum.join(reasons, ", ")}"
        end

      [
        %{
          "id" => review_id(["freshness_review", stable_id_fragment(source), status]),
          "review_type" => "freshness_review",
          "source" => source,
          "subject_id" => "freshness:#{status}",
          "action" => "review_refresh_freshness",
          "required_operator_action" => "review_refresh_freshness",
          "approval_status" => "operator_review_required",
          "reason" => reason,
          "freshness_status" => status,
          "model" => report["model"],
          "generated_at" => report["generated_at"],
          "accepted_at" => report["accepted_at"],
          "accepted_state_quality_level" => report["accepted_state_quality_level"],
          "allowed_state_quality_levels" => report["allowed_state_quality_levels"],
          "state_quality_status" => report["state_quality_status"],
          "current_epoch_s" => report["current_epoch_s"],
          "horizon_starts_at_s" => report["horizon_starts_at_s"],
          "accepted_snapshot_age_s" => report["accepted_snapshot_age_s"],
          "horizon_start_offset_s" => report["horizon_start_offset_s"],
          "max_snapshot_age_s" => report["max_snapshot_age_s"],
          "max_horizon_start_offset_s" => report["max_horizon_start_offset_s"],
          "stale_reasons" => Map.get(report, "stale_reasons", []),
          "unknown_reasons" => Map.get(report, "unknown_reasons", []),
          "source_freshness_report" => report
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp freshness_rows(_report, _source), do: []

  defp freshness_reasons(report) do
    Map.get(report, "stale_reasons", []) ++ Map.get(report, "unknown_reasons", [])
  end

  defp candidate_refresh_refresh_budget_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_refresh_budget_report",
         get_in(artifact, ["accepted_planning_state", "source_refresh_budget_report"])},
        {"candidate_refresh.accepted_planning_state.refresh_budget_report",
         get_in(artifact, ["accepted_planning_state", "refresh_budget_report"])},
        {"candidate_refresh.mission_state.source_refresh_budget_report",
         get_in(artifact, ["mission_state", "source_refresh_budget_report"])},
        {"candidate_refresh.mission_state.refresh_budget_report",
         get_in(artifact, ["mission_state", "refresh_budget_report"])},
        {"candidate_refresh.source_refresh_budget_report",
         artifact["source_refresh_budget_report"]},
        {"candidate_refresh.refresh_budget_report", artifact["refresh_budget_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_refresh_budget_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_refresh_budget_rows(artifact)
  end

  defp source_refresh_budget_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_refresh_budget_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_refresh_budget_report_rows(%{} = report, source),
    do: refresh_budget_rows(report, source)

  defp source_refresh_budget_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_refresh_budget_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_refresh_budget_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_refresh_budget_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_refresh_budget_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_refresh_budget_rows(
         %{"schema_contract" => "refresh_budget_report.v1"} = report,
         source
       ) do
    source_refresh_budget_report_rows(report, source)
  end

  defp result_artifact_refresh_budget_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_refresh_budget_report", artifact["source_refresh_budget_report"]},
      {"#{source}.refresh_budget_report", artifact["refresh_budget_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_refresh_budget_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_refresh_budget_rows(_artifact, _source), do: []

  defp refresh_budget_rows(%{} = report, source) do
    report = stringify_keys(report)
    dropped_count = Map.get(report, "dropped_candidate_count", 0)
    invalid_policy? = report["invalid_candidate_limit_policy"] == true

    if (is_number(dropped_count) and dropped_count > 0) or invalid_policy? do
      [
        %{
          "id" => review_id(["refresh_budget_review", stable_id_fragment(source)]),
          "review_type" => "refresh_budget_review",
          "source" => source,
          "subject_id" => "refresh_budget",
          "action" => "review_refresh_budget",
          "required_operator_action" => "review_refresh_budget",
          "approval_status" => "operator_review_required",
          "reason" => refresh_budget_review_reason(report, dropped_count, invalid_policy?),
          "model" => report["model"],
          "input_candidate_count" => report["input_candidate_count"],
          "kept_candidate_count" => report["kept_candidate_count"],
          "dropped_candidate_count" => dropped_count,
          "max_candidate_activities" => report["max_candidate_activities"],
          "invalid_candidate_limit_policy" => report["invalid_candidate_limit_policy"],
          "invalid_candidate_limit_policy_reason" =>
            report["invalid_candidate_limit_policy_reason"],
          "source_candidate_limit_policy" => report["source_candidate_limit_policy"],
          "selection_order" => report["selection_order"],
          "kept_candidate_ids" => Map.get(report, "kept_candidate_ids", []),
          "dropped_candidate_ids" => Map.get(report, "dropped_candidate_ids", []),
          "source_refresh_budget_report" => report
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp refresh_budget_rows(_report, _source), do: []

  defp candidate_refresh_model_acceptance_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_model_acceptance_report",
         get_in(artifact, ["accepted_planning_state", "source_model_acceptance_report"])},
        {"candidate_refresh.accepted_planning_state.model_acceptance_report",
         get_in(artifact, ["accepted_planning_state", "model_acceptance_report"])},
        {"candidate_refresh.mission_state.source_model_acceptance_report",
         get_in(artifact, ["mission_state", "source_model_acceptance_report"])},
        {"candidate_refresh.mission_state.model_acceptance_report",
         get_in(artifact, ["mission_state", "model_acceptance_report"])},
        {"candidate_refresh.source_model_acceptance_report",
         artifact["source_model_acceptance_report"]},
        {"candidate_refresh.model_acceptance_report", artifact["model_acceptance_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_model_acceptance_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_model_acceptance_rows(artifact)
  end

  defp source_model_acceptance_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_model_acceptance_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_model_acceptance_report_rows(%{} = report, source),
    do: model_acceptance_report_rows(report, "#{source}.rows")

  defp source_model_acceptance_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_model_acceptance_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_model_acceptance_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_model_acceptance_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_model_acceptance_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_model_acceptance_rows(
         %{"schema_contract" => "model_acceptance_report.v1"} = report,
         source
       ) do
    source_model_acceptance_report_rows(report, source)
  end

  defp result_artifact_model_acceptance_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_model_acceptance_report", artifact["source_model_acceptance_report"]},
      {"#{source}.model_acceptance_report", artifact["model_acceptance_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_model_acceptance_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_model_acceptance_rows(_artifact, _source), do: []

  defp model_acceptance_report_rows(report, source \\ "model_acceptance_report.rows") do
    report = stringify_keys(report)

    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&model_acceptance_reviewable_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      model_id = row["model_id"] || row["id"] || "model_acceptance"
      status = row["status"] || "review_required"

      %{
        "id" =>
          review_id([
            "model_acceptance_review",
            stable_id_fragment(source),
            model_id,
            index
          ]),
        "review_type" => "model_acceptance_review",
        "source" => source,
        "subject_id" => model_id,
        "action" => model_acceptance_action(status),
        "required_operator_action" => model_acceptance_action(status),
        "approval_status" => model_acceptance_approval_status(status),
        "reason" => row["reason"] || model_acceptance_reason(report, row, status),
        "model_acceptance_report_id" => report["report_id"],
        "model_acceptance_status" => status,
        "model_acceptance_intended_use" => report["intended_use"],
        "model_acceptance_validation_level" => row["validation_level"],
        "model_acceptance_model_id" => row["model_id"],
        "model_acceptance_implementation" => row["implementation"],
        "model_acceptance_model_count" => report["model_count"],
        "model_acceptance_accepted_count" => report["accepted_count"],
        "model_acceptance_review_required_count" => report["review_required_count"],
        "model_acceptance_blocked_count" => report["blocked_count"],
        "model_acceptance_unknown_model_count" => report["unknown_model_count"],
        "source_model_acceptance_row" => row,
        "source_model_acceptance_report" => model_acceptance_report_context(report)
      }
      |> compact_map()
    end)
  end

  defp model_acceptance_reviewable_row?(%{} = row),
    do: row["status"] not in [nil, "accepted", "accepted_for_use"]

  defp model_acceptance_reviewable_row?(_row), do: false

  defp model_acceptance_action("blocked"), do: "review_blocked_model_acceptance"
  defp model_acceptance_action(_status), do: "review_model_acceptance"

  defp model_acceptance_approval_status("blocked"), do: "blocked_by_policy"
  defp model_acceptance_approval_status(_status), do: "operator_review_required"

  defp model_acceptance_reason(report, row, status) do
    intended_use = report["intended_use"] || "intended use"
    model_id = row["model_id"] || "model"
    validation_level = row["validation_level"] || "unknown"

    "model #{model_id} is #{status} for #{intended_use} with #{validation_level} validation"
  end

  defp model_acceptance_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "schema_version",
      "model",
      "report_id",
      "intended_use",
      "status",
      "model_count",
      "accepted_count",
      "review_required_count",
      "blocked_count",
      "unknown_model_count",
      "status_counts",
      "validation_level_counts",
      "model_ids_by_status",
      "model_ids_by_validation_level",
      "model_ids_by_intended_use",
      "assumptions",
      "model_limits"
    ])
  end

  defp model_acceptance_report_id(report) do
    review_id([
      "model_acceptance_report",
      report["intended_use"],
      report["status"],
      report["model_count"]
    ])
  end

  defp candidate_refresh_validation_safety_case_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_validation_safety_case_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_validation_safety_case_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.validation_safety_case_summary",
         get_in(artifact, ["accepted_planning_state", "validation_safety_case_summary"])},
        {"candidate_refresh.mission_state.source_validation_safety_case_summary",
         get_in(artifact, ["mission_state", "source_validation_safety_case_summary"])},
        {"candidate_refresh.mission_state.validation_safety_case_summary",
         get_in(artifact, ["mission_state", "validation_safety_case_summary"])},
        {"candidate_refresh.source_validation_safety_case_summary",
         artifact["source_validation_safety_case_summary"]},
        {"candidate_refresh.validation_safety_case_summary",
         artifact["validation_safety_case_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_validation_safety_case_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_validation_safety_case_rows(artifact)
  end

  defp source_validation_safety_case_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_validation_safety_case_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_validation_safety_case_summary_rows(%{} = summary, source),
    do: validation_safety_case_summary_rows(summary, "#{source}.evidence")

  defp source_validation_safety_case_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_validation_safety_case_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_validation_safety_case_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_validation_safety_case_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_validation_safety_case_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_validation_safety_case_rows(
         %{"schema_contract" => "validation_safety_case_summary.v1"} = summary,
         source
       ) do
    source_validation_safety_case_summary_rows(summary, source)
  end

  defp result_artifact_validation_safety_case_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_validation_safety_case_summary",
       artifact["source_validation_safety_case_summary"]},
      {"#{source}.validation_safety_case_summary", artifact["validation_safety_case_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_validation_safety_case_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_validation_safety_case_rows(_artifact, _source), do: []

  defp validation_safety_case_summary_rows(
         summary,
         source \\ "validation_safety_case_summary.evidence"
       ) do
    summary = stringify_keys(summary)

    summary
    |> Map.get("evidence", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&validation_safety_case_reviewable_evidence?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {evidence, index} ->
      status = evidence["status"] || "review_required"

      evidence_ref =
        evidence["evidence_ref"] || "#{evidence["schema_contract"] || "evidence"}:#{index}"

      action = validation_safety_case_action(status)

      %{
        "id" =>
          review_id([
            "validation_safety_case_review",
            stable_id_fragment(source),
            stable_id_fragment(evidence_ref),
            index
          ]),
        "review_type" => "validation_safety_case_review",
        "source" => source,
        "subject_id" => stable_id_fragment(evidence_ref),
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => validation_safety_case_approval_status(status),
        "reason" => validation_safety_case_reason(summary, evidence, status, evidence_ref),
        "validation_safety_case_summary_id" => summary["summary_id"],
        "validation_safety_case_status" => summary["status"],
        "validation_safety_case_evidence_status" => status,
        "validation_safety_case_evidence_ref" => evidence_ref,
        "validation_safety_case_input_contract" => evidence["schema_contract"],
        "validation_safety_case_blocked_evidence_count" => summary["blocked_evidence_count"],
        "validation_safety_case_review_required_evidence_count" =>
          summary["review_required_evidence_count"],
        "validation_safety_case_schema_error_count" => summary["schema_error_count"],
        "validation_safety_case_schema_warning_count" => summary["schema_warning_count"],
        "validation_safety_case_model_blocked_count" => summary["model_blocked_count"],
        "validation_safety_case_model_review_required_count" =>
          summary["model_review_required_count"],
        "source_validation_safety_case_evidence" => evidence,
        "source_validation_safety_case_summary" => validation_safety_case_summary_context(summary)
      }
      |> compact_map()
    end)
  end

  defp validation_safety_case_reviewable_evidence?(%{} = evidence),
    do: evidence["status"] in ["blocked", "review_required"]

  defp validation_safety_case_reviewable_evidence?(_evidence), do: false

  defp validation_safety_case_action("blocked"), do: "review_blocked_validation_safety_case"
  defp validation_safety_case_action(_status), do: "review_validation_safety_case"

  defp validation_safety_case_approval_status("blocked"), do: "blocked_by_policy"
  defp validation_safety_case_approval_status(_status), do: "operator_review_required"

  defp validation_safety_case_reason(summary, evidence, status, evidence_ref) do
    case_id = summary["case_id"] || summary["summary_id"] || "validation safety case"
    contract = evidence["schema_contract"] || "evidence"

    "#{case_id} has #{status} #{contract} evidence at #{evidence_ref}"
  end

  defp validation_safety_case_summary_context(summary) do
    Map.take(summary, [
      "schema_contract",
      "schema_version",
      "model",
      "source",
      "summary_id",
      "case_id",
      "status",
      "evidence_count",
      "input_contracts",
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "blocked_evidence_count",
      "review_required_evidence_count",
      "accepted_evidence_count",
      "model_accepted_count",
      "model_review_required_count",
      "model_blocked_count",
      "unknown_model_count",
      "readiness_review_required_count",
      "readiness_blocked_count",
      "ready_for_import_count",
      "quality_gate_review_count",
      "quality_gate_blocked_count",
      "schema_error_count",
      "schema_warning_count",
      "schema_validation_report_count",
      "schema_validation_failed_report_count",
      "fixture_passed_count",
      "fixture_failed_count",
      "assumptions",
      "model_limits"
    ])
  end

  defp validation_safety_case_summary_id(summary) do
    review_id([
      "validation_safety_case_summary",
      summary["case_id"],
      summary["status"],
      summary["evidence_count"]
    ])
  end

  defp candidate_refresh_run_input_sources(%{"provenance" => %{"run_input_sources" => sources}})
       when is_map(sources) and map_size(sources) > 0,
       do: sources

  defp candidate_refresh_run_input_sources(%{"run_input_sources" => sources})
       when is_map(sources) and map_size(sources) > 0,
       do: sources

  defp candidate_refresh_run_input_sources(_artifact), do: nil

  defp put_candidate_refresh_run_input_sources(rows, nil), do: rows

  defp put_candidate_refresh_run_input_sources(rows, sources) do
    Enum.map(rows, &Map.put(&1, "run_input_sources", sources))
  end

  defp refresh_budget_review_reason(report, _dropped_count, true) do
    "candidate refresh budget policy is invalid: #{report["invalid_candidate_limit_policy_reason"]}"
  end

  defp refresh_budget_review_reason(_report, dropped_count, _invalid_policy?)
       when is_number(dropped_count) and dropped_count > 0 do
    "candidate refresh budget dropped #{dropped_count} candidates"
  end

  defp refresh_budget_review_reason(_report, _dropped_count, _invalid_policy?),
    do: "candidate refresh budget requires review"

  defp first_map(values) when is_list(values) do
    Enum.find(values, %{}, &is_map/1)
  end

  defp first_map(_values), do: %{}

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp resource_suppression_reason(%{"suppressed_reason" => reason}) when is_binary(reason),
    do: "resource filter suppressed candidate: #{reason}"

  defp resource_suppression_reason(_candidate), do: "resource filter suppressed candidate"

  defp feedback_rows(rows, source \\ "timeline_feedback_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      {action, approval_status, reason} = feedback_review_decision(row)

      %{
        "id" => review_id(["realized_feedback", row["activity_id"], index]),
        "review_type" => "realized_feedback",
        "source" => source,
        "subject_id" => row["activity_id"],
        "activity_id" => row["activity_id"],
        "activity_type" => row["planned_type"] || row["realized_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => approval_status,
        "reason" => reason,
        "feedback_status" => row["status"],
        "operational_feedback_excluded" => row["operational_feedback_excluded"],
        "operational_feedback_status" => row["operational_feedback_status"],
        "operational_feedback_exclusion_reason" => row["operational_feedback_exclusion_reason"],
        "match_strategy" => row["match_strategy"],
        "ambiguous_planned_timeline_id" => row["ambiguous_planned_timeline_id"],
        "ambiguous_planned_match_count" => row["ambiguous_planned_match_count"],
        "ambiguous_planned_activity_ids" => row["ambiguous_planned_activity_ids"],
        "ambiguous_planned_activities" => row["ambiguous_planned_activities"],
        "feedback_kind" => row["feedback_kind"],
        "realized_match_count" => row["realized_match_count"],
        "realized_activity_ids" => row["realized_activity_ids"],
        "realized_statuses" => row["realized_statuses"],
        "realized_match_strategies" => row["realized_match_strategies"],
        "realized_activities" => row["realized_activities"],
        "planned_timeline_id" => row["planned_timeline_id"],
        "timeline_identity" => row["timeline_identity"],
        "realized_timeline_id" => row["realized_timeline_id"],
        "realized_activity_id" => row["realized_activity_id"],
        "realized_source" => row["realized_source"],
        "realized_provider" => row["realized_provider"],
        "realized_source_quality" => row["realized_source_quality"],
        "realized_adapter" => row["realized_adapter"],
        "realized_adapter_version" => row["realized_adapter_version"],
        "realized_external_id" => row["realized_external_id"],
        "realized_schema_contract" => row["realized_schema_contract"],
        "realized_trust_boundary" => row["realized_trust_boundary"],
        "realized_received_at" => row["realized_received_at"],
        "realized_ingested_at" => row["realized_ingested_at"],
        "realized_provenance" => row["realized_provenance"],
        "planned_activity" => row["planned_activity"],
        "realized_activity" => row["realized_activity"],
        "invalid_realized_feedback_input" => row["invalid_realized_feedback_input"],
        "invalid_realized_feedback_input_reason" => row["invalid_realized_feedback_input_reason"],
        "invalid_realized_feedback_sections" => row["invalid_realized_feedback_sections"],
        "unsupported_realized_status" => row["unsupported_realized_status"],
        "invalid_cadence_import" => row["invalid_cadence_import"],
        "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
        "source_cadence_import" => row["source_cadence_import"],
        "source_activity_context" => row["source_activity_context"],
        "realized_activity_context" => row["realized_activity_context"],
        "planned_status" => row["planned_status"],
        "realized_status" => row["realized_status"],
        "status_transition" => row["status_transition"],
        "planned_protection_decision" => row["planned_protection_decision"],
        "planned_protection_category" => row["planned_protection_category"],
        "planned_protection_reason" => row["planned_protection_reason"],
        "source_protection_decision" => row["source_protection_decision"],
        "realized_type" => row["realized_type"],
        "direction" => row["direction"],
        "planned_direction" => row["planned_direction"],
        "realized_direction" => row["realized_direction"],
        "direction_match_status" => row["direction_match_status"],
        "ground_station_id" => row["ground_station_id"],
        "planned_ground_station_id" => row["planned_ground_station_id"],
        "realized_ground_station_id" => row["realized_ground_station_id"],
        "ground_station_match_status" => row["ground_station_match_status"],
        "spacecraft_id" => row["spacecraft_id"],
        "target_id" => row["target_id"],
        "planned_target_id" => row["planned_target_id"],
        "realized_target_id" => row["realized_target_id"],
        "target_match_status" => row["target_match_status"],
        "resource_id" => row["resource_id"],
        "planned_resource_id" => row["planned_resource_id"],
        "realized_resource_id" => row["realized_resource_id"],
        "resource_match_status" => row["resource_match_status"],
        "identity_match_status" => row["identity_match_status"],
        "identity_mismatch_fields" => row["identity_mismatch_fields"],
        "identity_mismatch_count" => row["identity_mismatch_count"],
        "collection_id" => row["collection_id"],
        "planned_collection_id" => row["planned_collection_id"],
        "realized_collection_id" => row["realized_collection_id"],
        "collection_match_status" => row["collection_match_status"],
        "product_id" => row["product_id"],
        "planned_product_id" => row["planned_product_id"],
        "realized_product_id" => row["realized_product_id"],
        "product_match_status" => row["product_match_status"],
        "product_ids" => row["product_ids"],
        "planned_product_ids" => row["planned_product_ids"],
        "realized_product_ids" => row["realized_product_ids"],
        "product_ids_match_status" => row["product_ids_match_status"],
        "payload_id" => row["payload_id"],
        "planned_payload_id" => row["planned_payload_id"],
        "realized_payload_id" => row["realized_payload_id"],
        "payload_match_status" => row["payload_match_status"],
        "instrument_id" => row["instrument_id"],
        "planned_instrument_id" => row["planned_instrument_id"],
        "realized_instrument_id" => row["realized_instrument_id"],
        "instrument_match_status" => row["instrument_match_status"],
        "pointing_target_id" => row["pointing_target_id"],
        "planned_pointing_target_id" => row["planned_pointing_target_id"],
        "realized_pointing_target_id" => row["realized_pointing_target_id"],
        "pointing_target_match_status" => row["pointing_target_match_status"],
        "pointing_mode" => row["pointing_mode"],
        "planned_pointing_mode" => row["planned_pointing_mode"],
        "realized_pointing_mode" => row["realized_pointing_mode"],
        "pointing_mode_match_status" => row["pointing_mode_match_status"],
        "boresight_axis" => row["boresight_axis"],
        "planned_off_nadir_angle_deg" => row["planned_off_nadir_angle_deg"],
        "realized_off_nadir_angle_deg" => row["realized_off_nadir_angle_deg"],
        "off_nadir_angle_delta_deg" => row["off_nadir_angle_delta_deg"],
        "planned_slew_angle_deg" => row["planned_slew_angle_deg"],
        "realized_slew_angle_deg" => row["realized_slew_angle_deg"],
        "slew_angle_delta_deg" => row["slew_angle_delta_deg"],
        "pointing_error_deg" => row["pointing_error_deg"],
        "pointing_status" => row["pointing_status"],
        "pointing_model" => row["pointing_model"],
        "pointing_source" => row["pointing_source"],
        "pointing_confidence" => row["pointing_confidence"],
        "attitude_target_id" => row["attitude_target_id"],
        "planned_attitude_target_id" => row["planned_attitude_target_id"],
        "realized_attitude_target_id" => row["realized_attitude_target_id"],
        "attitude_target_match_status" => row["attitude_target_match_status"],
        "attitude_mode" => row["attitude_mode"],
        "planned_attitude_mode" => row["planned_attitude_mode"],
        "realized_attitude_mode" => row["realized_attitude_mode"],
        "attitude_mode_match_status" => row["attitude_mode_match_status"],
        "planned_roll_deg" => row["planned_roll_deg"],
        "realized_roll_deg" => row["realized_roll_deg"],
        "roll_delta_deg" => row["roll_delta_deg"],
        "planned_pitch_deg" => row["planned_pitch_deg"],
        "realized_pitch_deg" => row["realized_pitch_deg"],
        "pitch_delta_deg" => row["pitch_delta_deg"],
        "planned_yaw_deg" => row["planned_yaw_deg"],
        "realized_yaw_deg" => row["realized_yaw_deg"],
        "yaw_delta_deg" => row["yaw_delta_deg"],
        "attitude_error_deg" => row["attitude_error_deg"],
        "attitude_status" => row["attitude_status"],
        "attitude_model" => row["attitude_model"],
        "attitude_source" => row["attitude_source"],
        "attitude_confidence" => row["attitude_confidence"],
        "link_protocol" => row["link_protocol"],
        "planned_link_protocol" => row["planned_link_protocol"],
        "realized_link_protocol" => row["realized_link_protocol"],
        "link_protocol_match_status" => row["link_protocol_match_status"],
        "frequency_band" => row["frequency_band"],
        "planned_frequency_band" => row["planned_frequency_band"],
        "realized_frequency_band" => row["realized_frequency_band"],
        "frequency_band_match_status" => row["frequency_band_match_status"],
        "modulation" => row["modulation"],
        "planned_modulation" => row["planned_modulation"],
        "realized_modulation" => row["realized_modulation"],
        "modulation_match_status" => row["modulation_match_status"],
        "coding_scheme" => row["coding_scheme"],
        "planned_coding_scheme" => row["planned_coding_scheme"],
        "realized_coding_scheme" => row["realized_coding_scheme"],
        "coding_scheme_match_status" => row["coding_scheme_match_status"],
        "polarization" => row["polarization"],
        "planned_polarization" => row["planned_polarization"],
        "realized_polarization" => row["realized_polarization"],
        "polarization_match_status" => row["polarization_match_status"],
        "data_rate_mbps" => row["data_rate_mbps"],
        "planned_data_rate_mbps" => row["planned_data_rate_mbps"],
        "realized_data_rate_mbps" => row["realized_data_rate_mbps"],
        "data_rate_delta_mbps" => row["data_rate_delta_mbps"],
        "link_margin_db" => row["link_margin_db"],
        "planned_link_margin_db" => row["planned_link_margin_db"],
        "realized_link_margin_db" => row["realized_link_margin_db"],
        "link_margin_delta_db" => row["link_margin_delta_db"],
        "snr_db" => row["snr_db"],
        "planned_snr_db" => row["planned_snr_db"],
        "realized_snr_db" => row["realized_snr_db"],
        "snr_delta_db" => row["snr_delta_db"],
        "eb_no_db" => row["eb_no_db"],
        "planned_eb_no_db" => row["planned_eb_no_db"],
        "realized_eb_no_db" => row["realized_eb_no_db"],
        "eb_no_delta_db" => row["eb_no_delta_db"],
        "bit_error_rate" => row["bit_error_rate"],
        "planned_bit_error_rate" => row["planned_bit_error_rate"],
        "realized_bit_error_rate" => row["realized_bit_error_rate"],
        "packet_loss_rate" => row["packet_loss_rate"],
        "planned_packet_loss_rate" => row["planned_packet_loss_rate"],
        "realized_packet_loss_rate" => row["realized_packet_loss_rate"],
        "frame_loss_rate" => row["frame_loss_rate"],
        "planned_frame_loss_rate" => row["planned_frame_loss_rate"],
        "realized_frame_loss_rate" => row["realized_frame_loss_rate"],
        "carrier_lock" => row["carrier_lock"],
        "planned_carrier_lock" => row["planned_carrier_lock"],
        "realized_carrier_lock" => row["realized_carrier_lock"],
        "symbol_lock" => row["symbol_lock"],
        "planned_symbol_lock" => row["planned_symbol_lock"],
        "realized_symbol_lock" => row["realized_symbol_lock"],
        "link_quality_status" => row["link_quality_status"],
        "planned_link_quality_status" => row["planned_link_quality_status"],
        "realized_link_quality_status" => row["realized_link_quality_status"],
        "eclipse_overlap_fraction" => row["eclipse_overlap_fraction"],
        "planned_eclipse_overlap_fraction" => row["planned_eclipse_overlap_fraction"],
        "realized_eclipse_overlap_fraction" => row["realized_eclipse_overlap_fraction"],
        "eclipse_overlap_s" => row["eclipse_overlap_s"],
        "planned_eclipse_overlap_s" => row["planned_eclipse_overlap_s"],
        "realized_eclipse_overlap_s" => row["realized_eclipse_overlap_s"],
        "lighting_condition" => row["lighting_condition"],
        "planned_lighting_condition" => row["planned_lighting_condition"],
        "realized_lighting_condition" => row["realized_lighting_condition"],
        "lighting_condition_match_status" => row["lighting_condition_match_status"],
        "lighting_condition_detail" => row["lighting_condition_detail"],
        "lighting_condition_model" => row["lighting_condition_model"],
        "lighting_detail_model" => row["lighting_detail_model"],
        "lighting_confidence" => row["lighting_confidence"],
        "image_quality_score" => row["image_quality_score"],
        "planned_image_quality_score" => row["planned_image_quality_score"],
        "realized_image_quality_score" => row["realized_image_quality_score"],
        "image_quality_score_delta" => row["image_quality_score_delta"],
        "image_quality_status" => row["image_quality_status"],
        "planned_image_quality_status" => row["planned_image_quality_status"],
        "realized_image_quality_status" => row["realized_image_quality_status"],
        "image_quality_status_match_status" => row["image_quality_status_match_status"],
        "image_quality_source" => row["image_quality_source"],
        "cloud_cover_fraction" => row["cloud_cover_fraction"],
        "planned_cloud_cover_fraction" => row["planned_cloud_cover_fraction"],
        "realized_cloud_cover_fraction" => row["realized_cloud_cover_fraction"],
        "cloud_cover_fraction_delta" => row["cloud_cover_fraction_delta"],
        "blur_score" => row["blur_score"],
        "planned_blur_score" => row["planned_blur_score"],
        "realized_blur_score" => row["realized_blur_score"],
        "blur_score_delta" => row["blur_score_delta"],
        "source_window_id" => row["source_window_id"],
        "planned_source_window_id" => row["planned_source_window_id"],
        "realized_source_window_id" => row["realized_source_window_id"],
        "source_window_match_status" => row["source_window_match_status"],
        "source_window_type" => row["source_window_type"],
        "dependency_activity_ids" => row["dependency_activity_ids"],
        "dependency_timeline_ids" => row["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "cadence_import_id" => row["cadence_import_id"],
        "cadence_import_contract" => row["cadence_import_contract"],
        "has_cadence_import" => row["has_cadence_import"],
        "planned_operator_action" => row["planned_operator_action"],
        "planned_operator_action_reason" => row["planned_operator_action_reason"],
        "superseded_planned_operator_action" => row["superseded_planned_operator_action"],
        "superseded_planned_operator_action_reason" =>
          row["superseded_planned_operator_action_reason"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
        "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
        "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          row["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          row["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => row["exclusivity_violation_group"],
        "planned_starts_at_s" => row["planned_starts_at_s"],
        "planned_ends_at_s" => row["planned_ends_at_s"],
        "actual_starts_at_s" => row["actual_starts_at_s"],
        "actual_ends_at_s" => row["actual_ends_at_s"],
        "start_delta_s" => row["start_delta_s"],
        "end_delta_s" => row["end_delta_s"],
        "max_timing_delta_s" => row["max_timing_delta_s"],
        "timing_variance_threshold_s" => row["timing_variance_threshold_s"],
        "timing_variance_status" => row["timing_variance_status"],
        "planned_estimated_throughput_mb" => row["planned_estimated_throughput_mb"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" => row["actual_data_rate_throughput_derivation"],
        "throughput_delta_mb" => row["throughput_delta_mb"],
        "throughput_completion_fraction" => row["throughput_completion_fraction"],
        "planned_data_volume_mb" => row["planned_data_volume_mb"],
        "actual_data_volume_mb" => row["actual_data_volume_mb"],
        "data_volume_delta_mb" => row["data_volume_delta_mb"],
        "data_volume_completion_fraction" => row["data_volume_completion_fraction"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "collection_ends_at_s" => row["collection_ends_at_s"],
        "planned_delivery_at_s" => row["planned_delivery_at_s"],
        "actual_delivery_at_s" => row["actual_delivery_at_s"],
        "max_latency_s" => row["max_latency_s"],
        "planned_latency_s" => row["planned_latency_s"],
        "actual_latency_s" => row["actual_latency_s"],
        "latency_delta_s" => row["latency_delta_s"],
        "latency_margin_s" => row["latency_margin_s"],
        "planned_delta_v_km_s" => row["planned_delta_v_km_s"],
        "realized_delta_v_km_s" => row["realized_delta_v_km_s"],
        "delta_v_delta_km_s" => row["delta_v_delta_km_s"],
        "planned_delta_v_magnitude_km_s" => row["planned_delta_v_magnitude_km_s"],
        "realized_delta_v_magnitude_km_s" => row["realized_delta_v_magnitude_km_s"],
        "delta_v_magnitude_delta_km_s" => row["delta_v_magnitude_delta_km_s"],
        "delta_v_match_status" => row["delta_v_match_status"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "command_authority_status" => row["command_authority_status"],
        "planned_command_authority_status" => row["planned_command_authority_status"],
        "realized_command_authority_status" => row["realized_command_authority_status"],
        "command_authority_status_match_status" => row["command_authority_status_match_status"],
        "required_authority" => row["required_authority"],
        "planned_required_authority" => row["planned_required_authority"],
        "realized_required_authority" => row["realized_required_authority"],
        "required_authority_match_status" => row["required_authority_match_status"],
        "command_safety_status" => row["command_safety_status"],
        "planned_command_safety_status" => row["planned_command_safety_status"],
        "realized_command_safety_status" => row["realized_command_safety_status"],
        "command_safety_status_match_status" => row["command_safety_status_match_status"],
        "command_authorized" => row["command_authorized"],
        "planned_command_authorized" => row["planned_command_authorized"],
        "realized_command_authorized" => row["realized_command_authorized"],
        "command_authorized_match_status" => row["command_authorized_match_status"],
        "command_safety_checked" => row["command_safety_checked"],
        "planned_command_safety_checked" => row["planned_command_safety_checked"],
        "realized_command_safety_checked" => row["realized_command_safety_checked"],
        "command_safety_checked_match_status" => row["command_safety_checked_match_status"],
        "observation_success" => row["observation_success"],
        "observation_result" => provider_result_artifact_value(row["observation_result"]),
        "observation_success_factor" => row["observation_success_factor"],
        "observation_success_factor_source" => row["observation_success_factor_source"],
        "feedback_weight" => row["feedback_weight"],
        "feedback_weight_source" => row["feedback_weight_source"],
        "maneuver_success_factor" => row["maneuver_success_factor"],
        "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
        "execution_uncertainty_status" => row["execution_uncertainty_status"],
        "execution_uncertainty" => row["execution_uncertainty"],
        "timing_3sigma_s" => row["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => row["execution_uncertainty_source"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "maneuver_success" => row["maneuver_success"],
        "maneuver_result" => provider_result_artifact_value(row["maneuver_result"]),
        "completed_fraction" => row["completed_fraction"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "resource_blocking_dimension" => row["resource_blocking_dimension"],
        "fuel_margin" => row["fuel_margin"],
        "thermal_zone_id" => row["thermal_zone_id"],
        "temperature_c" => row["temperature_c"],
        "planned_temperature_c" => row["planned_temperature_c"],
        "actual_temperature_c" => row["actual_temperature_c"],
        "temperature_delta_c" => row["temperature_delta_c"],
        "min_operating_temperature_c" => row["min_operating_temperature_c"],
        "max_operating_temperature_c" => row["max_operating_temperature_c"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "thermal_status" => row["thermal_status"],
        "thermal_model" => row["thermal_model"],
        "thermal_source" => row["thermal_source"],
        "thermal_confidence" => row["thermal_confidence"],
        "power_margin" => row["power_margin"],
        "storage_margin" => row["storage_margin"],
        "downlink_margin" => row["downlink_margin"],
        "battery_capacity_wh" => row["battery_capacity_wh"],
        "battery_energy_used_wh" => row["battery_energy_used_wh"],
        "battery_energy_generated_wh" => row["battery_energy_generated_wh"],
        "battery_state_of_charge" => row["battery_state_of_charge"],
        "spacecraft_available" => row["spacecraft_available"],
        "planned_spacecraft_available" => row["planned_spacecraft_available"],
        "realized_spacecraft_available" => row["realized_spacecraft_available"],
        "spacecraft_available_match_status" => row["spacecraft_available_match_status"],
        "payload_available" => row["payload_available"],
        "planned_payload_available" => row["planned_payload_available"],
        "realized_payload_available" => row["realized_payload_available"],
        "payload_available_match_status" => row["payload_available_match_status"],
        "antenna_available" => row["antenna_available"],
        "planned_antenna_available" => row["planned_antenna_available"],
        "realized_antenna_available" => row["realized_antenna_available"],
        "antenna_available_match_status" => row["antenna_available_match_status"],
        "degraded" => row["degraded"],
        "planned_degraded" => row["planned_degraded"],
        "realized_degraded" => row["realized_degraded"],
        "degraded_match_status" => row["degraded_match_status"],
        "mode" => row["mode"],
        "planned_mode" => row["planned_mode"],
        "realized_mode" => row["realized_mode"],
        "mode_match_status" => row["mode_match_status"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "station_availability" => row["station_availability"],
        "station_contention_status" => row["station_contention_status"],
        "capacity_fraction" => row["capacity_fraction"],
        "capacity_fraction_min" => row["capacity_fraction_min"],
        "capacity_fraction_max" => row["capacity_fraction_max"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          row["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "source_feedback" => row
      }
      |> compact_map()
    end)
  end

  defp repair_timeline_feedback_rows(artifact) do
    artifact
    |> get_in(["source_timeline_feedback_report", "rows"])
    |> realized_timeline_feedback_rows()
  end

  defp realized_timeline_feedback_rows(nil), do: []

  defp realized_timeline_feedback_rows(rows) when is_list(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["status"] == "planned_only"))
  end

  defp realized_timeline_feedback_rows(_rows), do: []

  defp feedback_review_decision(%{"realized_match_count" => count})
       when is_number(count) and count > 1 do
    {"review_duplicate_realized_feedback", "operator_review_required",
     "multiple realized feedback rows match the same planned activity"}
  end

  defp feedback_review_decision(%{"match_strategy" => "ambiguous_timeline_id"} = row) do
    {"review_ambiguous_realized_feedback", "operator_review_required",
     feedback_reason(row, "realized feedback timeline id matches multiple planned activities")}
  end

  defp feedback_review_decision(%{"invalid_activity_input" => true} = row) do
    {"review_invalid_activity_input", "operator_review_required",
     feedback_reason(
       row,
       "planned feedback input is invalid: #{row["invalid_activity_input_reason"]}"
     )}
  end

  defp feedback_review_decision(%{"invalid_realized_feedback_input" => true} = row) do
    {"review_invalid_realized_feedback_input", "operator_review_required",
     invalid_realized_feedback_reason(row)}
  end

  defp feedback_review_decision(%{"invalid_cadence_import" => true} = row) do
    {"review_invalid_cadence_import", "operator_review_required",
     feedback_reason(row, "realized feedback Cadence import context is invalid")}
  end

  defp feedback_review_decision(%{"timeline_integrity_status" => "review_required"} = row) do
    {"review_timeline_integrity", "operator_review_required",
     feedback_reason(row, "planned activity has dependency or exclusivity integrity issues")}
  end

  defp feedback_review_decision(%{"status" => "planned_only"}) do
    {"review_missing_realization", "operator_review_required",
     "planned activity has no realized feedback row"}
  end

  defp feedback_review_decision(%{"status" => "realized_only"} = row) do
    {"review_unplanned_realization", "operator_review_required",
     feedback_reason(row, "realized feedback row has no planned activity")}
  end

  defp feedback_review_decision(
         %{"status" => "matched", "planned_operator_action" => "resolve_blocked_activity"} = row
       ) do
    {"resolve_blocked_activity", "operator_review_required",
     feedback_reason(row, blocked_feedback_reason(row))}
  end

  defp feedback_review_decision(
         %{"status" => "matched", "planned_operator_action" => "resolve_rejected_activity"} = row
       ) do
    {"resolve_rejected_activity", "operator_review_required",
     feedback_reason(row, "realized feedback arrived for rejected planned activity")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_exception_statuses do
    {"review_contact_exception", "operator_review_required",
     feedback_reason(row, "realized contact ended with #{status} status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_variance_statuses do
    {"review_contact_variance", "operator_review_required",
     feedback_reason(row, "realized contact ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => "contact", "contact_success" => false} = row) do
    {"review_contact_exception", "operator_review_required",
     feedback_reason(row, "provider contact_success false despite completed status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_completion_statuses do
    cond do
      contact_throughput_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} below planned throughput")}

      completed_fraction_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} with partial completion fraction")}

      contact_link_quality_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} with link quality variance")}

      realized_activity_identity_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} with planned/realized identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} with planned/realized resource availability variance"
         )}

      timing_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} exceeded timing variance threshold")}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} but planned contact is missing Cadence import identity"
         )}

      true ->
        {"record_contact_completion", "not_required",
         feedback_reason(row, "realized contact #{status}")}
    end
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_exception_statuses do
    {"review_command_exception", "operator_review_required",
     feedback_reason(row, "realized command activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_variance_statuses do
    {"review_command_variance", "operator_review_required",
     feedback_reason(row, "realized command activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "command_success" => false} = row)
       when kind in ["command", "health_check"] do
    {"review_command_exception", "operator_review_required",
     feedback_reason(row, "provider command_success false despite completed status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "maneuver", "maneuver_success" => false} = row
       ) do
    {"review_maneuver_exception", "operator_review_required",
     feedback_reason(row, "provider maneuver_success false despite completed status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_completion_statuses do
    cond do
      realized_activity_identity_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with planned/realized contact identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with planned/realized resource availability variance"
         )}

      timing_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} exceeded timing variance threshold"
         )}

      completed_fraction_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with partial completion fraction"
         )}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} but planned command is missing Cadence import identity"
         )}

      true ->
        {"record_command_completion", "not_required",
         feedback_reason(row, "realized command activity #{status}")}
    end
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_exception_statuses do
    {"review_realized_exception", "operator_review_required",
     feedback_reason(row, "realized activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_variance_statuses do
    {"review_realized_variance", "operator_review_required",
     feedback_reason(row, "realized activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_completion_statuses do
    cond do
      completed_fraction_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(row, "realized activity #{status} with partial completion fraction")}

      realized_activity_identity_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} with planned/realized identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} with planned/realized resource availability variance"
         )}

      realized_maneuver_delta_v_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized maneuver activity #{status} with planned/realized delta-v variance"
         )}

      timing_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(row, "realized activity #{status} exceeded timing variance threshold")}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} but planned activity is missing Cadence import identity"
         )}

      true ->
        {"record_realized_completion", "not_required",
         feedback_reason(row, "realized activity #{status}")}
    end
  end

  defp feedback_review_decision(%{"status" => status} = row) do
    {"review_realized_feedback", "operator_review_required",
     feedback_reason(row, "realized feedback row has #{status} reconciliation status")}
  end

  defp blocked_feedback_reason(%{
         "planned_operator_action_reason" => "activity_status_blocked_by_policy"
       }) do
    "realized feedback arrived for status-blocked planned activity"
  end

  defp blocked_feedback_reason(_row) do
    "realized feedback arrived for policy-blocked planned activity"
  end

  defp contact_throughput_variance?(row) do
    case row["throughput_completion_fraction"] do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  defp completed_fraction_variance?(row) do
    case row["completed_fraction"] do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  defp timing_variance?(%{"timing_variance_status" => "exceeds_threshold"}), do: true
  defp timing_variance?(_row), do: false

  defp contact_link_quality_variance?(row) do
    row["realized_carrier_lock"] == false or
      row["realized_symbol_lock"] == false or
      negative_number?(row["realized_link_margin_db"]) or
      link_quality_failure_status?(row["realized_link_quality_status"])
  end

  defp link_quality_failure_status?(status) when is_binary(status) do
    status
    |> normalize_status()
    |> then(
      &(&1 in [
          "below_threshold",
          "degraded",
          "failed",
          "link_failed",
          "lock_lost",
          "low_margin",
          "no_lock",
          "poor",
          "unusable"
        ])
    )
  end

  defp link_quality_failure_status?(_status), do: false

  defp negative_number?(value), do: is_number(value) and value < 0.0

  defp normalize_status(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status(status) when is_atom(status),
    do: status |> Atom.to_string() |> normalize_status()

  defp normalize_status(_status), do: nil

  defp realized_contact_identity_variance?(row) do
    Enum.any?(
      [
        row["direction_match_status"],
        row["ground_station_match_status"],
        row["source_window_match_status"],
        row["link_protocol_match_status"],
        row["frequency_band_match_status"],
        row["modulation_match_status"],
        row["coding_scheme_match_status"],
        row["polarization_match_status"]
      ],
      &(&1 == "mismatch")
    )
  end

  defp realized_activity_identity_variance?(row) do
    realized_contact_identity_variance?(row) or
      Enum.any?(
        [
          row["target_match_status"],
          row["collection_match_status"],
          row["product_match_status"],
          row["product_ids_match_status"],
          row["payload_match_status"],
          row["instrument_match_status"]
        ],
        &(&1 == "mismatch")
      )
  end

  defp realized_resource_availability_variance?(row) do
    Enum.any?(
      [
        row["spacecraft_available_match_status"],
        row["payload_available_match_status"],
        row["antenna_available_match_status"],
        row["degraded_match_status"],
        row["mode_match_status"]
      ],
      &(&1 == "mismatch")
    )
  end

  defp realized_maneuver_delta_v_variance?(%{"feedback_kind" => "maneuver"} = row) do
    row["delta_v_match_status"] == "mismatch"
  end

  defp realized_maneuver_delta_v_variance?(_row), do: false

  defp missing_cadence_import?(row), do: row["cadence_import_status"] == "missing"

  defp invalid_realized_feedback_reason(%{
         "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
         "unsupported_realized_status" => status
       })
       when is_binary(status) and status != "" do
    "realized feedback input has unsupported status #{status}"
  end

  defp invalid_realized_feedback_reason(%{
         "invalid_realized_feedback_input_reason" => "missing_realized_status"
       }) do
    "realized feedback input is missing status"
  end

  defp invalid_realized_feedback_reason(row) do
    "realized feedback input is invalid: #{row["invalid_realized_feedback_input_reason"]}"
  end

  defp feedback_reason(%{"reason" => reason}, _fallback) when is_binary(reason) and reason != "",
    do: reason

  defp feedback_reason(_row, fallback), do: fallback

  defp command_window_rows(rows, source \\ "command_window_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["required_operator_action"] in no_command_window_review_actions()))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["command_window", row["activity_id"], index]),
        "review_type" => "command_window_review",
        "source" => source,
        "subject_id" => row["activity_id"],
        "activity_id" => row["activity_id"],
        "timeline_id" => row["timeline_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["activity_type"],
        "window_type" => row["window_type"],
        "direction" => row["direction"],
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "status" => row["status"],
        "approval_status" => operational_timeline_approval_status(row),
        "source_approval_status" => row["approval_status"],
        "locked" => row["locked"],
        "contact_success" => row["contact_success"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "provenance" => row["provenance"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["operator_action_reason"] || "command window requires operator review",
        "operator_action_reason" => row["operator_action_reason"],
        "superseded_required_operator_action" => row["superseded_required_operator_action"],
        "superseded_operator_action_reason" => row["superseded_operator_action_reason"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
        "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
        "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          row["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          row["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => row["exclusivity_violation_group"],
        "execution_boundary" => row["execution_boundary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "dependency_activity_ids" => row["dependency_activity_ids"],
        "dependency_timeline_ids" => row["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "has_source_window" => row["has_source_window"],
        "has_cadence_import" => row["has_cadence_import"],
        "timeline_identity" => row["timeline_identity"],
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "source_activity" => row["source_activity"],
        "source_activity_context" =>
          normalize_provider_result_artifact_fields(row["activity_context"]),
        "source_command_window" => row
      }
      |> compact_map()
    end)
  end

  defp no_command_window_review_actions do
    ["monitor_activity", "none_locked_activity", "none_terminal_activity"]
  end

  defp operational_timeline_rows(rows, source \\ "operational_timeline_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["required_operator_action"] in no_operational_timeline_review_actions()))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      row = sanitize_row_activity_context_cadence_import(row)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["operational_timeline", row["timeline_id"], row["activity_id"], index]),
        "review_type" => "operational_timeline_review",
        "source" => source,
        "subject_id" => row["timeline_id"] || row["activity_id"],
        "activity_id" => row["activity_id"],
        "timeline_id" => row["timeline_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["activity_type"],
        "operational_kind" => row["operational_kind"],
        "direction" => row["direction"],
        "spacecraft_id" => row["spacecraft_id"],
        "ground_station_id" => row["ground_station_id"],
        "target_id" => row["target_id"],
        "resource_id" => row["resource_id"],
        "collection_id" => row["collection_id"],
        "product_id" => row["product_id"],
        "product_ids" => row["product_ids"],
        "payload_id" => row["payload_id"],
        "instrument_id" => row["instrument_id"],
        "pointing_mode" => row_or_context_value(row, "pointing_mode"),
        "pointing_target_id" => row_or_context_value(row, "pointing_target_id"),
        "boresight_axis" => row_or_context_value(row, "boresight_axis"),
        "off_nadir_angle_deg" => row_or_context_value(row, "off_nadir_angle_deg"),
        "slew_angle_deg" => row_or_context_value(row, "slew_angle_deg"),
        "slew_rate_deg_s" => row_or_context_value(row, "slew_rate_deg_s"),
        "pointing_error_deg" => row_or_context_value(row, "pointing_error_deg"),
        "pointing_status" => row_or_context_value(row, "pointing_status"),
        "pointing_model" => row_or_context_value(row, "pointing_model"),
        "pointing_source" => row_or_context_value(row, "pointing_source"),
        "pointing_confidence" => row_or_context_value(row, "pointing_confidence"),
        "attitude_mode" => row_or_context_value(row, "attitude_mode"),
        "attitude_target_id" => row_or_context_value(row, "attitude_target_id"),
        "roll_deg" => row_or_context_value(row, "roll_deg"),
        "pitch_deg" => row_or_context_value(row, "pitch_deg"),
        "yaw_deg" => row_or_context_value(row, "yaw_deg"),
        "attitude_error_deg" => row_or_context_value(row, "attitude_error_deg"),
        "attitude_status" => row_or_context_value(row, "attitude_status"),
        "attitude_model" => row_or_context_value(row, "attitude_model"),
        "attitude_source" => row_or_context_value(row, "attitude_source"),
        "attitude_confidence" => row_or_context_value(row, "attitude_confidence"),
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "status" => row["status"],
        "approval_status" => operational_timeline_approval_status(row),
        "source_approval_status" => row["approval_status"],
        "locked" => row["locked"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["operator_action_reason"] || "operational timeline row requires review",
        "operator_action_reason" => row["operator_action_reason"],
        "precondition_status" => row["precondition_status"],
        "blocked_precondition_count" => row["blocked_precondition_count"],
        "review_precondition_count" => row["review_precondition_count"],
        "blocked_precondition_types" => row["blocked_precondition_types"],
        "review_precondition_types" => row["review_precondition_types"],
        "preconditions" => row["preconditions"],
        "execution_boundary" => row["execution_boundary"],
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "cadence_import_id" => row["cadence_import_id"],
        "cadence_import_contract" => row["cadence_import_contract"],
        "cadence_import_provider" =>
          row_or_cadence_import_value(row, "cadence_import_provider", "provider"),
        "cadence_import_adapter" =>
          row_or_cadence_import_value(row, "cadence_import_adapter", "adapter"),
        "cadence_import_adapter_version" =>
          row_or_cadence_import_value(row, "cadence_import_adapter_version", "adapter_version"),
        "cadence_import_trust_boundary" =>
          row_or_cadence_import_value(row, "cadence_import_trust_boundary", "trust_boundary") ||
            row_or_cadence_import_value(row, "cadence_import_trust_boundary", [
              "provenance",
              "trust_boundary"
            ]),
        "cadence_import_provenance" =>
          row_or_cadence_import_value(row, "cadence_import_provenance", "provenance"),
        "invalid_cadence_import" => row["invalid_cadence_import"],
        "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
        "source_cadence_import" => row["source_cadence_import"],
        "source_cadence_import_status" => row["source_cadence_import_status"],
        "replacement_cadence_import_status" => row["replacement_cadence_import_status"],
        "execution_uncertainty_status" => row["execution_uncertainty_status"],
        "execution_uncertainty" => row["execution_uncertainty"],
        "timing_3sigma_s" => row["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => row["execution_uncertainty_source"],
        "link_protocol" => row_or_context_value(row, "link_protocol"),
        "frequency_band" => row_or_context_value(row, "frequency_band"),
        "modulation" => row_or_context_value(row, "modulation"),
        "coding_scheme" => row_or_context_value(row, "coding_scheme"),
        "polarization" => row_or_context_value(row, "polarization"),
        "data_rate_mbps" => row_or_context_value(row, "data_rate_mbps"),
        "downlink_rate_mbps" => row_or_context_value(row, "downlink_rate_mbps"),
        "data_rate_mb_s" => row_or_context_value(row, "data_rate_mb_s"),
        "downlink_rate_mb_s" => row_or_context_value(row, "downlink_rate_mb_s"),
        "actual_data_rate_mbps" => row_or_context_value(row, "actual_data_rate_mbps"),
        "actual_downlink_rate_mbps" => row_or_context_value(row, "actual_downlink_rate_mbps"),
        "actual_data_rate_mb_s" => row_or_context_value(row, "actual_data_rate_mb_s"),
        "actual_downlink_rate_mb_s" => row_or_context_value(row, "actual_downlink_rate_mb_s"),
        "delivered_rate_mbps" => row_or_context_value(row, "delivered_rate_mbps"),
        "received_rate_mbps" => row_or_context_value(row, "received_rate_mbps"),
        "delivered_rate_mb_s" => row_or_context_value(row, "delivered_rate_mb_s"),
        "received_rate_mb_s" => row_or_context_value(row, "received_rate_mb_s"),
        "actual_duration_s" => row_or_context_value(row, "actual_duration_s"),
        "actual_contact_duration_s" => row_or_context_value(row, "actual_contact_duration_s"),
        "contact_duration_s" => row_or_context_value(row, "contact_duration_s"),
        "link_margin_db" => row_or_context_value(row, "link_margin_db"),
        "snr_db" => row_or_context_value(row, "snr_db"),
        "eb_no_db" => row_or_context_value(row, "eb_no_db"),
        "bit_error_rate" => row_or_context_value(row, "bit_error_rate"),
        "packet_loss_rate" => row_or_context_value(row, "packet_loss_rate"),
        "frame_loss_rate" => row_or_context_value(row, "frame_loss_rate"),
        "carrier_lock" => row_or_context_value(row, "carrier_lock"),
        "symbol_lock" => row_or_context_value(row, "symbol_lock"),
        "link_quality_status" => row_or_context_value(row, "link_quality_status"),
        "eclipse_overlap_fraction" => row_or_context_value(row, "eclipse_overlap_fraction"),
        "planned_eclipse_overlap_fraction" => row["planned_eclipse_overlap_fraction"],
        "realized_eclipse_overlap_fraction" => row["realized_eclipse_overlap_fraction"],
        "eclipse_overlap_s" => row_or_context_value(row, "eclipse_overlap_s"),
        "planned_eclipse_overlap_s" => row["planned_eclipse_overlap_s"],
        "realized_eclipse_overlap_s" => row["realized_eclipse_overlap_s"],
        "lighting_condition" => row_or_context_value(row, "lighting_condition"),
        "planned_lighting_condition" => row["planned_lighting_condition"],
        "realized_lighting_condition" => row["realized_lighting_condition"],
        "lighting_condition_match_status" => row["lighting_condition_match_status"],
        "lighting_condition_detail" => row_or_context_value(row, "lighting_condition_detail"),
        "lighting_condition_model" => row_or_context_value(row, "lighting_condition_model"),
        "lighting_detail_model" => row_or_context_value(row, "lighting_detail_model"),
        "lighting_confidence" => row_or_context_value(row, "lighting_confidence"),
        "planned_estimated_throughput_mb" => row["planned_estimated_throughput_mb"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" =>
          row_or_context_value(row, "actual_data_rate_throughput_derivation"),
        "throughput_delta_mb" => row["throughput_delta_mb"],
        "throughput_completion_fraction" => row["throughput_completion_fraction"],
        "data_volume_mb" => row["data_volume_mb"],
        "planned_data_volume_mb" => row["planned_data_volume_mb"],
        "actual_data_volume_mb" => row["actual_data_volume_mb"],
        "data_volume_delta_mb" => row["data_volume_delta_mb"],
        "data_volume_completion_fraction" => row["data_volume_completion_fraction"],
        "estimated_data_volume_mb" => row["estimated_data_volume_mb"],
        "estimated_storage_mb" => row["estimated_storage_mb"],
        "estimated_downlink_mb" => row["estimated_downlink_mb"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "collection_ends_at_s" => row["collection_ends_at_s"],
        "planned_delivery_at_s" => row["planned_delivery_at_s"],
        "actual_delivery_at_s" => row["actual_delivery_at_s"],
        "max_latency_s" => row["max_latency_s"],
        "planned_latency_s" => row["planned_latency_s"],
        "actual_latency_s" => row["actual_latency_s"],
        "latency_delta_s" => row["latency_delta_s"],
        "latency_margin_s" => row["latency_margin_s"],
        "resource_source_quality" => row_or_context_value(row, "resource_source_quality"),
        "resource_trust_boundary" => row_or_context_value(row, "resource_trust_boundary"),
        "resource_trust_boundary_status" =>
          row_or_context_value(row, "resource_trust_boundary_status"),
        "resource_provenance" => row_or_context_value(row, "resource_provenance"),
        "resource_blocking_dimension" => row_or_context_value(row, "resource_blocking_dimension"),
        "fuel_margin" => row_or_context_value(row, "fuel_margin"),
        "thermal_zone_id" => row_or_context_value(row, "thermal_zone_id"),
        "temperature_c" => row_or_context_value(row, "temperature_c"),
        "planned_temperature_c" => row_or_context_value(row, "planned_temperature_c"),
        "actual_temperature_c" => row_or_context_value(row, "actual_temperature_c"),
        "temperature_delta_c" => row_or_context_value(row, "temperature_delta_c"),
        "min_operating_temperature_c" => row_or_context_value(row, "min_operating_temperature_c"),
        "max_operating_temperature_c" => row_or_context_value(row, "max_operating_temperature_c"),
        "thermal_margin_c" => row_or_context_value(row, "thermal_margin_c"),
        "thermal_status" => row_or_context_value(row, "thermal_status"),
        "thermal_model" => row_or_context_value(row, "thermal_model"),
        "thermal_source" => row_or_context_value(row, "thermal_source"),
        "thermal_confidence" => row_or_context_value(row, "thermal_confidence"),
        "power_margin" => row_or_context_value(row, "power_margin"),
        "storage_margin" => row_or_context_value(row, "storage_margin"),
        "downlink_margin" => row_or_context_value(row, "downlink_margin"),
        "battery_capacity_wh" => row_or_context_value(row, "battery_capacity_wh"),
        "battery_energy_used_wh" => row_or_context_value(row, "battery_energy_used_wh"),
        "battery_energy_generated_wh" => row_or_context_value(row, "battery_energy_generated_wh"),
        "battery_state_of_charge" => row_or_context_value(row, "battery_state_of_charge"),
        "spacecraft_available" => row_or_context_value(row, "spacecraft_available"),
        "payload_available" => row_or_context_value(row, "payload_available"),
        "antenna_available" => row_or_context_value(row, "antenna_available"),
        "degraded" => row_or_context_value(row, "degraded"),
        "mode" => row_or_context_value(row, "mode"),
        "incompatible_activity_types" => row_or_context_value(row, "incompatible_activity_types"),
        "suppressed_activity_types" => row_or_context_value(row, "suppressed_activity_types"),
        "score" => row_or_context_value(row, "score"),
        "score_terms" => row_or_context_value(row, "score_terms"),
        "target_priority" => row_or_context_value(row, "target_priority"),
        "target_priority_source" => row_or_context_value(row, "target_priority_source"),
        "target_priority_objective_ids" =>
          row_or_context_value(row, "target_priority_objective_ids"),
        "target_priority_objective_type" =>
          row_or_context_value(row, "target_priority_objective_type"),
        "image_quality_score" => row_or_context_value(row, "image_quality_score"),
        "image_quality_status" => row_or_context_value(row, "image_quality_status"),
        "image_quality_source" => row_or_context_value(row, "image_quality_source"),
        "cloud_cover_fraction" => row_or_context_value(row, "cloud_cover_fraction"),
        "blur_score" => row_or_context_value(row, "blur_score"),
        "contact_success" => row_or_context_value(row, "contact_success"),
        "contact_success_factor" => row_or_context_value(row, "contact_success_factor"),
        "contact_success_factor_source" =>
          row_or_context_value(row, "contact_success_factor_source"),
        "command_success" => row_or_context_value(row, "command_success"),
        "contact_result" => row_or_context_provider_result_value(row, "contact_result"),
        "command_result" => row_or_context_provider_result_value(row, "command_result"),
        "command_authority_status" => row_or_context_value(row, "command_authority_status"),
        "command_safety_status" => row_or_context_value(row, "command_safety_status"),
        "command_authorized" => row_or_context_value(row, "command_authorized"),
        "command_safety_checked" => row_or_context_value(row, "command_safety_checked"),
        "command_success_factor" => row_or_context_value(row, "command_success_factor"),
        "command_success_factor_source" =>
          row_or_context_value(row, "command_success_factor_source"),
        "observation_success" => row_or_context_value(row, "observation_success"),
        "observation_result" => row_or_context_provider_result_value(row, "observation_result"),
        "observation_success_factor" => row_or_context_value(row, "observation_success_factor"),
        "observation_success_factor_source" =>
          row_or_context_value(row, "observation_success_factor_source"),
        "feedback_weight" => row_or_context_value(row, "feedback_weight"),
        "feedback_weight_source" => row_or_context_value(row, "feedback_weight_source"),
        "maneuver_success" => row_or_context_value(row, "maneuver_success"),
        "maneuver_result" => row_or_context_provider_result_value(row, "maneuver_result"),
        "maneuver_success_factor" => row_or_context_value(row, "maneuver_success_factor"),
        "maneuver_success_factor_source" =>
          row_or_context_value(row, "maneuver_success_factor_source"),
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "station_availability" => row_or_context_value(row, "station_availability"),
        "station_contention_status" => row_or_context_value(row, "station_contention_status"),
        "station_calendar_entry_id" => row_or_context_value(row, "station_calendar_entry_id"),
        "station_calendar_status" => row_or_context_value(row, "station_calendar_status"),
        "station_calendar_overlap_count" =>
          row_or_context_value(row, "station_calendar_overlap_count"),
        "station_calendar_overlap_entry_ids" =>
          row_or_context_value(row, "station_calendar_overlap_entry_ids"),
        "station_calendar_overlap_availabilities" =>
          row_or_context_value(row, "station_calendar_overlap_availabilities"),
        "station_calendar_entry_ambiguous" =>
          row_or_context_value(row, "station_calendar_entry_ambiguous"),
        "station_calendar_ambiguous_entry_count" =>
          row_or_context_value(row, "station_calendar_ambiguous_entry_count"),
        "station_calendar_ambiguous_entry_ids" =>
          row_or_context_value(row, "station_calendar_ambiguous_entry_ids"),
        "station_calendar_reservation_overlap_count" =>
          row_or_context_value(row, "station_calendar_reservation_overlap_count"),
        "station_calendar_reservation_ids" =>
          row_or_context_value(row, "station_calendar_reservation_ids"),
        "station_calendar_reserved_by" =>
          row_or_context_value(row, "station_calendar_reserved_by"),
        "station_calendar_reservation_statuses" =>
          row_or_context_value(row, "station_calendar_reservation_statuses"),
        "station_calendar_reservation_expires_at_s" =>
          row_or_context_value(row, "station_calendar_reservation_expires_at_s"),
        "station_calendar_trust_boundary_status" =>
          row_or_context_value(row, "station_calendar_trust_boundary_status"),
        "trust_boundary" => row_or_context_value(row, "trust_boundary"),
        "provenance" => row_or_context_value(row, "provenance"),
        "station_reservation_id" => row_or_context_value(row, "station_reservation_id"),
        "station_reservation_expires_at_s" =>
          row_or_context_value(row, "station_reservation_expires_at_s"),
        "station_reserved_by" => row_or_context_value(row, "station_reserved_by"),
        "station_reservation_status" => row_or_context_value(row, "station_reservation_status"),
        "station_reservation_match_status" =>
          row_or_context_value(row, "station_reservation_match_status"),
        "schedule_conflict_status" => row["schedule_conflict_status"],
        "exclusivity_group" => row["exclusivity_group"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
        "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
        "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          row["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          row["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => row["exclusivity_violation_group"],
        "timeline_identity_collision" => row["timeline_identity_collision"],
        "duplicate_timeline_identity_activity_count" =>
          row["duplicate_timeline_identity_activity_count"],
        "duplicate_timeline_identity_activity_ids" =>
          row["duplicate_timeline_identity_activity_ids"],
        "duplicate_timeline_identity_activities" => row["duplicate_timeline_identity_activities"],
        "superseded_required_operator_action" => row["superseded_required_operator_action"],
        "superseded_operator_action_reason" => row["superseded_operator_action_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          row_or_context_value(row, "required_authority") || requirement["required_authority"] ||
            rule_match["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "source_activity" => row["source_activity"],
        "dependency_activity_ids" => Map.get(row, "dependency_activity_ids", []),
        "dependency_timeline_ids" => Map.get(row, "dependency_timeline_ids", []),
        "exclusive_with_activity_ids" => Map.get(row, "exclusive_with_activity_ids", []),
        "exclusive_with_timeline_ids" => Map.get(row, "exclusive_with_timeline_ids", []),
        "has_source_window" => row["has_source_window"],
        "has_cadence_import" => row["has_cadence_import"],
        "timeline_identity" => row["timeline_identity"],
        "source_activity_context" =>
          normalize_provider_result_artifact_fields(row["activity_context"]),
        "source_station_calendar_entry" =>
          row_or_context_value(row, "source_station_calendar_entry"),
        "source_station_calendar_overlaps" =>
          row_or_context_value(row, "source_station_calendar_overlaps"),
        "source_operational_timeline" => row
      }
      |> compact_map()
    end)
  end

  defp no_operational_timeline_review_actions,
    do: ["monitor_activity", "none_locked_activity", "none_terminal_activity"]

  defp row_or_context_value(row, field) do
    case Map.fetch(row, field) do
      {:ok, nil} -> get_in(row, ["activity_context", field])
      {:ok, value} -> value
      :error -> get_in(row, ["activity_context", field])
    end
  end

  defp row_or_context_provider_result_value(row, field) do
    row
    |> row_or_context_value(field)
    |> provider_result_artifact_value()
  end

  defp normalize_provider_result_artifact_fields(%{} = map) do
    Enum.reduce(@provider_result_fields, map, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case provider_result_artifact_value(value) do
            nil -> Map.delete(acc, field)
            normalized -> Map.put(acc, field, normalized)
          end

        :error ->
          acc
      end
    end)
  end

  defp normalize_provider_result_artifact_fields(value), do: value

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp row_or_cadence_import_value(row, field, cadence_import_path) do
    case Map.fetch(row, field) do
      {:ok, value} ->
        value

      :error ->
        path = List.wrap(cadence_import_path)

        case row_activity_context_cadence_import(row) do
          %{} = cadence_import -> get_in(cadence_import, path)
          _cadence_import -> nil
        end
    end
  end

  defp sanitize_row_activity_context_cadence_import(
         %{"activity_context" => %{"cadence_import" => cadence_import} = context} = row
       )
       when not is_map(cadence_import) do
    source_cadence_import = %{"invalid_import_shape" => stringify_keys(cadence_import)}

    sanitized_context =
      context
      |> Map.delete("cadence_import")
      |> Map.put("invalid_cadence_import", true)
      |> Map.put("invalid_cadence_import_reason", "cadence_import_must_be_object")
      |> Map.put("source_cadence_import", source_cadence_import)

    row
    |> Map.put("activity_context", sanitized_context)
    |> Map.put("cadence_import_status", row["cadence_import_status"] || "invalid")
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("invalid_cadence_import_reason", "cadence_import_must_be_object")
    |> Map.put("source_cadence_import", source_cadence_import)
  end

  defp sanitize_row_activity_context_cadence_import(row), do: row

  defp row_activity_context_cadence_import(%{"activity_context" => %{} = context}),
    do: Map.get(context, "cadence_import")

  defp row_activity_context_cadence_import(_row), do: nil

  defp operational_timeline_approval_status(%{"required_operator_action" => action})
       when action in [
              "review_command_contact",
              "review_activity_approval",
              "resolve_rejected_activity",
              "resolve_contact_conflict",
              "review_terminal_activity_exception"
            ],
       do: "operator_review_required"

  defp operational_timeline_approval_status(row),
    do: Map.get(row, "approval_status", "operator_review_required")

  defp station_calendar_rows(rows, source \\ "station_calendar_report.affected_contacts") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&normalize_station_calendar_status_fields/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      action = row["required_operator_action"] || station_calendar_action(row)
      approval_status = row["approval_status"] || "operator_review_required"
      reason = row["operator_action_reason"] || station_calendar_reason(row)
      escalation = matched_policy_escalation(row)

      %{
        "id" =>
          review_id([
            "station_calendar",
            row["contact_id"],
            row["station_calendar_entry_id"],
            index
          ]),
        "review_type" => "station_calendar_review",
        "source" => source,
        "subject_id" => row["contact_id"],
        "contact_id" => row["contact_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["contact_type"],
        "direction" => row["direction"],
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          row["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "provider_counteroffer_id" => row["provider_counteroffer_id"],
        "provider_counteroffer_status" => row["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          row["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" =>
          row["provider_counteroffer_start_delta_s"] ||
            numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"]),
        "provider_counteroffer_end_delta_s" =>
          row["provider_counteroffer_end_delta_s"] ||
            numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"]),
        "provider_counteroffer_duration_delta_s" =>
          row["provider_counteroffer_duration_delta_s"] ||
            provider_counteroffer_duration_delta(row),
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "status" => row["status"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "station_reservation_hold_import_status" => row["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          row["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          row["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          row["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          row["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          row["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => row["station_reservation_hold_count"],
        "station_reservation_hold_ids" => row["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          row["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          row["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          row["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          row["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_import_status_counts" =>
          row["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          row["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          row["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          row["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" => row["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          row["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_import_readiness_summary" =>
          row["source_station_reservation_hold_import_readiness_summary"],
        "base_station_calendar_row_id" => row["base_station_calendar_row_id"],
        "duplicate_station_calendar_row_id_collision" =>
          row["duplicate_station_calendar_row_id_collision"],
        "duplicate_station_calendar_row_index" => row["duplicate_station_calendar_row_index"],
        "duplicate_station_calendar_row_count" => row["duplicate_station_calendar_row_count"],
        "invalid_feedback_confidence" => row["invalid_feedback_confidence"],
        "invalid_feedback_confidence_reason" => row["invalid_feedback_confidence_reason"],
        "source_contact_candidate" => row["source_contact_candidate"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => approval_status,
        "reason" => reason,
        "operator_action_reason" => row["operator_action_reason"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "source_station_calendar_review" => row
      }
      |> compact_map()
    end)
  end

  defp station_calendar_provider_contention_rows(
         groups,
         source \\ "station_calendar_report.provider_calendar_contention_groups"
       ) do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      escalation = matched_policy_escalation(group)

      %{
        "id" => review_id(["station_provider_contention", group["id"], index]),
        "review_type" => "station_calendar_review",
        "source" => source,
        "subject_id" => group["id"],
        "ground_station_id" => group["ground_station_id"],
        "starts_at_s" => group["starts_at_s"],
        "ends_at_s" => group["ends_at_s"],
        "overlap_duration_s" => group["overlap_duration_s"],
        "action" =>
          Map.get(group, "required_operator_action", "review_station_provider_contention"),
        "required_operator_action" =>
          Map.get(group, "required_operator_action", "review_station_provider_contention"),
        "approval_status" => Map.get(group, "approval_status", "operator_review_required"),
        "reason" => station_provider_contention_reason(group),
        "operator_action_reason" => group["operator_action_reason"],
        "approval_requirements" => group["approval_requirements"],
        "approval_rule_matches" => group["approval_rule_matches"],
        "source_policy_decision" => group["policy_decision"],
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "provider_calendar_contention_status" => group["provider_calendar_contention_status"],
        "provider_calendar_contention_group_id" => group["id"],
        "provider_calendar_contention_entry_count" => group["entry_count"],
        "provider_calendar_contention_entry_ids" => group["entry_ids"],
        "provider_calendar_contention_provider_ids" => group["provider_ids"],
        "provider_calendar_contention_provider_entry_ids" => group["provider_entry_ids"],
        "provider_calendar_contention_availabilities" => group["availabilities"],
        "provider_calendar_contention_directions" => group["directions"],
        "provider_calendar_contention_reservation_ids" => group["reservation_ids"],
        "provider_calendar_contention_reserved_by" => group["reserved_by"],
        "provider_calendar_contention_reservation_statuses" => group["reservation_statuses"],
        "provider_calendar_contention_reservation_expires_at_s" =>
          group["reservation_expires_at_s"],
        "station_reservation_hold_import_status" =>
          group["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          group["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          group["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          group["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          group["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          group["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => group["station_reservation_hold_count"],
        "station_reservation_hold_ids" => group["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          group["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          group["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          group["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          group["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_import_status_counts" =>
          group["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          group["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          group["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          group["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" =>
          group["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          group["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_import_readiness_summary" =>
          group["source_station_reservation_hold_import_readiness_summary"],
        "provider_calendar_contention_trust_boundary_statuses" =>
          group["trust_boundary_statuses"],
        "provider_calendar_contention_overlap_pairs" => group["overlap_pairs"],
        "source_station_calendar_provider_contention" => group
      }
      |> compact_map()
    end)
  end

  defp station_provider_contention_reason(%{
         "ground_station_id" => station_id,
         "entry_count" => entry_count
       }) do
    "review #{entry_count} overlapping provider calendar entries at #{station_id}"
  end

  defp station_provider_contention_reason(_group) do
    "review overlapping provider calendar entries"
  end

  defp station_calendar_precedence_summary?(%{} = summary) do
    model = summary["model"] || summary[:model]
    schema_contract = summary["schema_contract"] || summary[:schema_contract]

    model == "artifact_only_station_calendar_precedence_summary" or
      schema_contract == "station_calendar_precedence_summary.v1"
  end

  defp station_calendar_precedence_summary?(_summary), do: false

  defp station_calendar_precedence_summary_rows(summary, source) do
    summary = stringify_keys(summary)
    context = station_calendar_precedence_summary_context(summary)

    if station_calendar_precedence_reviewable_summary?(summary) do
      [
        %{
          "id" =>
            review_id([
              "station_calendar_precedence_summary",
              stable_id_fragment(source),
              summary["source"] || summary["source_artifact_type"]
            ]),
          "review_type" => "station_calendar_review",
          "source" => source,
          "subject_id" =>
            summary["source"] ||
              summary["source_artifact_type"] ||
              "station_calendar_precedence_summary",
          "source_artifact_type" => summary["source_artifact_type"],
          "action" => "review_station_calendar",
          "required_operator_action" => "review_station_calendar",
          "approval_status" => "operator_review_required",
          "reason" => "review station calendar precedence summary",
          "station_calendar_precedence_review_status" => summary["precedence_review_status"],
          "station_calendar_precedence_affected_contact_count" =>
            summary["affected_contact_count"],
          "station_calendar_precedence_applied_availability_counts" =>
            summary["applied_availability_counts"],
          "station_calendar_precedence_overlap_availability_counts" =>
            summary["overlap_availability_counts"],
          "station_calendar_precedence_affected_contact_ids_by_applied_availability" =>
            summary["affected_contact_ids_by_applied_availability"],
          "station_calendar_precedence_affected_contact_ids_by_overlap_availability" =>
            summary["affected_contact_ids_by_overlap_availability"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_count" =>
            summary["reserved_under_higher_precedence_contact_count"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_ids" =>
            summary["reserved_under_higher_precedence_contact_ids"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
            summary["reserved_under_higher_precedence_contact_ids_by_applied_availability"],
          "station_calendar_precedence_reserved_overlap_contact_ids" =>
            summary["reserved_overlap_contact_ids"],
          "station_calendar_precedence_reduced_capacity_contact_ids" =>
            summary["reduced_capacity_contact_ids"],
          "station_calendar_precedence_unavailable_contact_ids" =>
            summary["unavailable_contact_ids"],
          "station_calendar_precedence_model_limits" => summary["model_limits"],
          "source_station_calendar_precedence_summary" => context
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp station_calendar_precedence_reviewable_summary?(summary) do
    summary["precedence_review_status"] not in [nil, "passed", "importable"] or
      positive_report_count?(summary, "affected_contact_count") or
      positive_report_count?(summary, "reserved_under_higher_precedence_contact_count")
  end

  defp station_calendar_precedence_summary_context(summary) do
    summary
    |> Map.put_new("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put_new("source_summary_model", summary["model"])
  end

  defp station_reservation_rows(
         rows,
         source \\ "station_reservation_report.affected_contacts"
       ) do
    rows
    |> station_calendar_rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put(
        "id",
        review_id([
          "station_reservation",
          row["contact_id"] || row["subject_id"],
          row["station_reservation_id"]
        ])
      )
      |> Map.put("review_type", "station_reservation_review")
      |> Map.put("source", source)
      |> Map.put_new("required_operator_action", "review_station_reservation_overlap")
      |> Map.put_new("action", "review_station_reservation_overlap")
      |> Map.put("source_station_reservation", row["source_station_calendar_review"])
    end)
  end

  defp station_reservation_provider_contention_rows(
         groups,
         source \\ "station_reservation_report.provider_calendar_contention_groups"
       ) do
    groups
    |> station_calendar_provider_contention_rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put(
        "id",
        review_id(["station_reservation_provider_contention", row["subject_id"]])
      )
      |> Map.put("review_type", "station_reservation_review")
      |> Map.put("source", source)
      |> Map.put_new("required_operator_action", "review_station_provider_contention")
      |> Map.put_new("action", "review_station_provider_contention")
      |> Map.put("source_station_reservation", row["source_station_calendar_provider_contention"])
    end)
  end

  defp station_calendar_action(%{"provider_counteroffer_id" => id}) when is_binary(id),
    do: "review_provider_counteroffer"

  defp station_calendar_action(%{"provider_counteroffer_status" => status})
       when is_binary(status),
       do: "review_provider_counteroffer"

  defp station_calendar_action(%{"station_contention_status" => "reserved_overlap"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_calendar_reservation_overlap_count" => count})
       when is_number(count) and count > 0,
       do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reserved"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reduced_capacity"}),
    do: "review_reduced_station_capacity"

  defp station_calendar_action(_row), do: "review_station_availability"

  defp station_calendar_reason(%{
         "provider_counteroffer_id" => counteroffer_id,
         "ground_station_id" => station
       })
       when is_binary(counteroffer_id) and is_binary(station) do
    "station #{station} provider counteroffer #{counteroffer_id} requires operator review"
  end

  defp station_calendar_reason(%{"provider_counteroffer_id" => counteroffer_id})
       when is_binary(counteroffer_id),
       do: "provider counteroffer #{counteroffer_id} requires operator review"

  defp station_calendar_reason(%{
         "station_availability" => availability,
         "ground_station_id" => station
       })
       when is_binary(availability) and is_binary(station) do
    "station #{station} calendar reports #{availability}"
  end

  defp station_calendar_reason(%{"station_availability" => availability})
       when is_binary(availability),
       do: "station calendar reports #{availability}"

  defp station_calendar_reason(_row), do: "station calendar row requires operator review"

  defp normalize_station_calendar_status_fields(%{} = row) do
    row
    |> normalize_station_calendar_status_field("availability")
    |> normalize_station_calendar_status_field("status")
    |> normalize_station_calendar_status_field("station_availability")
    |> normalize_station_calendar_status_field("station_calendar_status")
    |> normalize_station_calendar_status_field("station_contention_status")
    |> normalize_station_calendar_status_field("reservation_status")
    |> normalize_station_calendar_status_field("station_reservation_status")
    |> normalize_station_calendar_status_field("reservation_match_status")
    |> normalize_station_calendar_status_field("station_reservation_match_status")
    |> normalize_station_calendar_status_field("station_calendar_overlap_availabilities")
    |> normalize_station_calendar_status_field("station_calendar_reservation_statuses")
    |> normalize_nested_station_calendar_status_field("source_station_calendar_entry")
    |> normalize_nested_station_calendar_status_field("source_station_calendar_overlaps")
  end

  defp normalize_station_calendar_status_fields(value), do: value

  defp normalize_nested_station_calendar_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} -> Map.put(row, field, normalize_station_calendar_status_value(value))
      :error -> row
    end
  end

  defp normalize_station_calendar_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} -> Map.put(row, field, normalize_station_calendar_status_value(value))
      :error -> row
    end
  end

  defp normalize_station_calendar_status_value(values) when is_list(values) do
    Enum.map(values, &normalize_station_calendar_status_value/1)
  end

  defp normalize_station_calendar_status_value(%{} = value) do
    normalize_station_calendar_status_fields(value)
  end

  defp normalize_station_calendar_status_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_station_calendar_status_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_station_calendar_status_value()
  end

  defp normalize_station_calendar_status_value(value), do: value

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  defp maneuver_review_rows(rows, source \\ "maneuver_review_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = preferred_maneuver_rule_match(row)
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["maneuver_review", row["scenario_id"], row["maneuver_id"], index]),
        "review_type" => "maneuver_review",
        "source" => source,
        "subject_id" => row["maneuver_id"],
        "maneuver_id" => row["maneuver_id"],
        "scenario_id" => row["scenario_id"],
        "maneuver_type" => row["maneuver_type"],
        "epoch_s" => row["epoch_s"],
        "epoch_scale" => row["epoch_scale"],
        "frame" => row["frame"],
        "delta_v_km_s" => row["delta_v_km_s"],
        "delta_v_magnitude_km_s" => row["delta_v_magnitude_km_s"],
        "maneuver_model" => row["maneuver_model"],
        "maneuver_success_factor" => row["maneuver_success_factor"],
        "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
        "approval_status" => row["approval_status"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["reason"],
        "execution_boundary" => row["execution_boundary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_recommendation" => row["source_recommendation"],
        "source_maneuver_review" => row
      }
      |> compact_map()
    end)
  end

  defp preferred_maneuver_rule_match(%{"required_operator_action" => action} = row)
       when action == "review_invalid_maneuver_recommendation" do
    row
    |> Map.get("approval_rule_matches", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(fn match -> match["rule_id"] == "invalid_maneuver_recommendation_review" end)
    |> case do
      nil -> row["approval_rule_matches"] |> first_map() |> stringify_keys()
      match -> match
    end
  end

  defp preferred_maneuver_rule_match(row) do
    row["approval_rule_matches"] |> first_map() |> stringify_keys()
  end

  defp timeline_diff_rows(rows, source \\ "timeline_diff_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&Map.get(&1, "requires_operator_review", false))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_diff_review_row(row, index, source)
    end)
  end

  defp timeline_diff_summary_rows(summary, source \\ "timeline_diff_summary.review_rows")

  defp timeline_diff_summary_rows(%{} = summary, source) do
    summary
    |> Map.get("review_rows", [])
    |> timeline_diff_rows(source)
    |> Enum.map(&put_timeline_diff_summary_context(&1, summary))
  end

  defp put_timeline_diff_summary_context(row, summary) do
    %{
      "source_artifact_type" => summary["source_artifact_type"],
      "source_timeline_diff_summary_source_activity_count" => summary["source_activity_count"],
      "source_timeline_diff_summary_replacement_activity_count" =>
        summary["replacement_activity_count"],
      "source_timeline_diff_summary_row_count" => summary["row_count"],
      "source_timeline_diff_summary_added_count" => summary["added_count"],
      "source_timeline_diff_summary_removed_count" => summary["removed_count"],
      "source_timeline_diff_summary_changed_count" => summary["changed_count"],
      "source_timeline_diff_summary_unchanged_count" => summary["unchanged_count"],
      "source_timeline_diff_summary_review_required_count" => summary["review_required_count"],
      "source_timeline_diff_summary_duplicate_timeline_identity_count" =>
        summary["duplicate_timeline_identity_count"],
      "source_timeline_diff_summary_invalid_source_activity_input_count" =>
        summary["invalid_source_activity_input_count"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_count" =>
        summary["invalid_replacement_activity_input_count"],
      "source_timeline_diff_summary_diff_status_counts" => summary["diff_status_counts"],
      "source_timeline_diff_summary_transition_decision_counts" =>
        summary["transition_decision_counts"],
      "source_timeline_diff_summary_required_operator_action_counts" =>
        summary["required_operator_action_counts"],
      "source_timeline_diff_summary_changed_field_counts" => summary["changed_field_counts"],
      "source_timeline_diff_summary_status_transition_category_counts" =>
        summary["status_transition_category_counts"],
      "source_timeline_diff_summary_approval_transition_category_counts" =>
        summary["approval_transition_category_counts"],
      "source_timeline_diff_summary_added_timeline_ids" => summary["added_timeline_ids"],
      "source_timeline_diff_summary_removed_timeline_ids" => summary["removed_timeline_ids"],
      "source_timeline_diff_summary_changed_timeline_ids" => summary["changed_timeline_ids"],
      "source_timeline_diff_summary_unchanged_timeline_ids" => summary["unchanged_timeline_ids"],
      "source_timeline_diff_summary_duplicate_timeline_identity_ids" =>
        summary["duplicate_timeline_identity_ids"],
      "source_timeline_diff_summary_invalid_source_activity_input_ids" =>
        summary["invalid_source_activity_input_ids"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_ids" =>
        summary["invalid_replacement_activity_input_ids"],
      "source_timeline_diff_summary_review_timeline_ids" => summary["review_timeline_ids"],
      "source_timeline_diff_summary_review_timeline_ids_by_required_operator_action" =>
        summary["review_timeline_ids_by_required_operator_action"],
      "source_timeline_diff_summary_review_timeline_ids_by_status_transition_category" =>
        summary["review_timeline_ids_by_status_transition_category"],
      "source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category" =>
        summary["review_timeline_ids_by_approval_transition_category"],
      "source_timeline_diff_summary_timeline_ids_by_changed_field" =>
        summary["timeline_ids_by_changed_field"],
      "source_timeline_diff_summary" => summary
    }
    |> compact_map()
    |> then(&Map.merge(row, &1))
  end

  defp timeline_transition_application_rows(
         rows,
         source,
         approval_policy
       ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&Map.get(&1, "requires_operator_review", false))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      source_diff =
        row
        |> Map.get("source_timeline_diff", %{})
        |> stringify_keys()
        |> Map.merge(
          Map.take(row, [
            "application_status",
            "selected_activity_source",
            "selected_activity",
            "requires_operator_review",
            "required_operator_action",
            "reason",
            "selected_timeline_integrity_status",
            "selected_timeline_integrity_issue_count",
            "selected_timeline_integrity_issue_types",
            "selected_timeline_integrity_issues",
            "selected_missing_dependency_activity_ids",
            "selected_missing_dependency_timeline_ids",
            "selected_self_dependency_activity_ids",
            "selected_self_dependency_timeline_ids",
            "selected_duplicate_dependency_activity_ids",
            "selected_duplicate_dependency_timeline_ids",
            "selected_duplicate_exclusivity_activity_ids",
            "selected_duplicate_exclusivity_timeline_ids",
            "selected_dependency_cycle_activity_ids",
            "selected_dependency_cycle_timeline_ids",
            "selected_dependency_order_violation_activity_ids",
            "selected_dependency_order_violation_timeline_ids",
            "selected_exclusivity_violation_activity_ids",
            "selected_exclusivity_violation_timeline_ids",
            "transition_application_provenance"
          ])
        )

      source_diff
      |> timeline_diff_review_row(index, source)
      |> Map.put("application_status", row["application_status"])
      |> Map.put("selected_activity_source", row["selected_activity_source"])
      |> Map.put("selected_activity", row["selected_activity"])
      |> Map.put("transition_application_provenance", row["transition_application_provenance"])
      |> Map.put("source_timeline_application", row)
      |> compact_map()
    end)
    |> apply_review_row_policy(
      approval_policy,
      "timeline_transition_application_policy_context"
    )
  end

  defp timeline_transition_application_summary_rows(
         summary,
         opts,
         source \\ "timeline_transition_application_summary.review_applications"
       )

  defp timeline_transition_application_summary_rows(%{} = summary, opts, source) do
    summary
    |> Map.get("review_applications", [])
    |> timeline_transition_application_rows(
      source,
      option(opts, :approval_policy) || option(opts, "approval_policy")
    )
    |> Enum.map(&put_transition_application_summary_context(&1, summary))
  end

  defp put_transition_application_summary_context(row, summary) do
    %{
      "source_artifact_type" => summary["source_artifact_type"],
      "source_transition_application_source_activity_count" => summary["source_activity_count"],
      "source_transition_application_replacement_activity_count" =>
        summary["replacement_activity_count"],
      "source_transition_application_count" => summary["application_count"],
      "source_transition_application_selected_activity_count" =>
        summary["selected_activity_count"],
      "source_transition_application_review_required_count" => summary["review_required_count"],
      "source_transition_application_preserved_source_count" => summary["preserved_source_count"],
      "source_transition_application_recorded_replacement_count" =>
        summary["recorded_replacement_count"],
      "source_transition_application_withheld_review_count" => summary["withheld_review_count"],
      "source_transition_application_selected_timeline_integrity_review_count" =>
        summary["selected_timeline_integrity_review_count"],
      "source_transition_application_selected_timeline_integrity_issue_count" =>
        summary["selected_timeline_integrity_issue_count"],
      "source_transition_application_selected_timeline_integrity_issue_types" =>
        summary["selected_timeline_integrity_issue_types"],
      "source_transition_application_status_counts" => summary["application_status_counts"],
      "source_transition_application_decision_counts" => summary["transition_decision_counts"],
      "source_transition_application_required_operator_action_counts" =>
        summary["required_operator_action_counts"],
      "source_transition_application_status_transition_category_counts" =>
        summary["status_transition_category_counts"],
      "source_transition_application_approval_transition_category_counts" =>
        summary["approval_transition_category_counts"],
      "source_transition_application_selected_activity_ids" => summary["selected_activity_ids"],
      "source_transition_application_selected_timeline_ids" => summary["selected_timeline_ids"],
      "source_transition_application_review_activity_ids" => summary["review_activity_ids"],
      "source_transition_application_review_timeline_ids" => summary["review_timeline_ids"],
      "source_transition_application_review_timeline_ids_by_required_operator_action" =>
        summary["review_timeline_ids_by_required_operator_action"],
      "source_transition_application_review_timeline_ids_by_status_transition_category" =>
        summary["review_timeline_ids_by_status_transition_category"],
      "source_transition_application_review_timeline_ids_by_approval_transition_category" =>
        summary["review_timeline_ids_by_approval_transition_category"],
      "source_transition_application_preserved_source_timeline_ids" =>
        summary["preserved_source_timeline_ids"],
      "source_transition_application_recorded_replacement_timeline_ids" =>
        summary["recorded_replacement_timeline_ids"],
      "source_transition_application_withheld_review_timeline_ids" =>
        summary["withheld_review_timeline_ids"],
      "source_timeline_transition_application_summary" => summary
    }
    |> compact_map()
    |> then(&Map.merge(row, &1))
  end

  defp apply_review_row_policy([], _approval_policy, _context_id), do: []
  defp apply_review_row_policy(rows, nil, _context_id), do: rows

  defp apply_review_row_policy(rows, approval_policy, context_id) do
    {_status, enriched_rows, rule_matches, policy_decision} =
      OrbitalDynamics.Policy.decide(
        rows,
        [],
        %{"id" => context_id, "events" => []},
        %{},
        approval_policy
      )

    if rule_matches == [] do
      rows
    else
      Enum.map(enriched_rows, fn row ->
        if Map.has_key?(row, "approval_rule_matches") do
          Map.put(row, "source_policy_decision", policy_decision)
        else
          row
        end
      end)
    end
  end

  defp option(opts, key) when is_list(opts) do
    case List.keyfind(opts, key, 0) do
      {_key, value} -> value
      nil -> nil
    end
  end

  defp option(%{} = opts, key), do: Map.get(opts, key)
  defp option(_opts, _key), do: nil

  defp timeline_diff_review_row(row, index, source) do
    %{
      "id" => review_id(["timeline_diff", row["timeline_id"], index]),
      "review_type" => "timeline_diff_review",
      "source" => source,
      "subject_id" => row["timeline_id"],
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "activity_id" => row["replacement_activity_id"] || row["source_activity_id"],
      "activity_type" => row["replacement_activity_type"] || row["source_activity_type"],
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_type" => row["source_activity_type"],
      "replacement_activity_type" => row["replacement_activity_type"],
      "source_spacecraft_id" => row["source_spacecraft_id"],
      "replacement_spacecraft_id" => row["replacement_spacecraft_id"],
      "source_ground_station_id" => row["source_ground_station_id"],
      "replacement_ground_station_id" => row["replacement_ground_station_id"],
      "source_target_id" => row["source_target_id"],
      "replacement_target_id" => row["replacement_target_id"],
      "source_source_window_id" => row["source_source_window_id"],
      "replacement_source_window_id" => row["replacement_source_window_id"],
      "action" => row["required_operator_action"],
      "required_operator_action" => row["required_operator_action"],
      "approval_status" => "operator_review_required",
      "reason" => row["reason"],
      "operator_action_reason" => row["operator_action_reason"] || row["reason"],
      "scenario_id" => row["scenario_id"],
      "source_starts_at_s" => row["source_starts_at_s"],
      "source_ends_at_s" => row["source_ends_at_s"],
      "replacement_starts_at_s" => row["replacement_starts_at_s"],
      "replacement_ends_at_s" => row["replacement_ends_at_s"],
      "start_delta_s" => row["start_delta_s"],
      "end_delta_s" => row["end_delta_s"],
      "source_status" => row["source_status"],
      "replacement_status" => row["replacement_status"],
      "source_approval_status" => row["source_approval_status"],
      "replacement_approval_status" => row["replacement_approval_status"],
      "source_locked" => row["source_locked"],
      "replacement_locked" => row["replacement_locked"],
      "source_protection_decision" => row["source_protection_decision"],
      "source_protection_category" => row["source_protection_category"],
      "source_protection_reason" => row["source_protection_reason"],
      "replacement_protection_decision" => row["replacement_protection_decision"],
      "replacement_protection_category" => row["replacement_protection_category"],
      "replacement_protection_reason" => row["replacement_protection_reason"],
      "source_timeline_integrity_status" => row["source_timeline_integrity_status"],
      "source_timeline_integrity_issue_count" => row["source_timeline_integrity_issue_count"],
      "source_timeline_integrity_issue_types" => row["source_timeline_integrity_issue_types"],
      "source_timeline_integrity_issues" => row["source_timeline_integrity_issues"],
      "source_missing_dependency_activity_ids" => row["source_missing_dependency_activity_ids"],
      "source_missing_dependency_timeline_ids" => row["source_missing_dependency_timeline_ids"],
      "source_self_dependency_activity_ids" => row["source_self_dependency_activity_ids"],
      "source_self_dependency_timeline_ids" => row["source_self_dependency_timeline_ids"],
      "source_dependency_cycle_activity_ids" => row["source_dependency_cycle_activity_ids"],
      "source_dependency_cycle_timeline_ids" => row["source_dependency_cycle_timeline_ids"],
      "replacement_timeline_integrity_status" => row["replacement_timeline_integrity_status"],
      "replacement_timeline_integrity_issue_count" =>
        row["replacement_timeline_integrity_issue_count"],
      "replacement_timeline_integrity_issue_types" =>
        row["replacement_timeline_integrity_issue_types"],
      "replacement_timeline_integrity_issues" => row["replacement_timeline_integrity_issues"],
      "replacement_missing_dependency_activity_ids" =>
        row["replacement_missing_dependency_activity_ids"],
      "replacement_missing_dependency_timeline_ids" =>
        row["replacement_missing_dependency_timeline_ids"],
      "replacement_self_dependency_activity_ids" =>
        row["replacement_self_dependency_activity_ids"],
      "replacement_self_dependency_timeline_ids" =>
        row["replacement_self_dependency_timeline_ids"],
      "replacement_dependency_cycle_activity_ids" =>
        row["replacement_dependency_cycle_activity_ids"],
      "replacement_dependency_cycle_timeline_ids" =>
        row["replacement_dependency_cycle_timeline_ids"],
      "status_transition" => row["status_transition"],
      "approval_transition" => row["approval_transition"],
      "changed_fields" => Map.get(row, "changed_fields", []),
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "duplicate_timeline_identity_scope" => row["duplicate_timeline_identity_scope"],
      "source_duplicate_activity_count" => row["source_duplicate_activity_count"],
      "replacement_duplicate_activity_count" => row["replacement_duplicate_activity_count"],
      "source_duplicate_activity_ids" => row["source_duplicate_activity_ids"],
      "replacement_duplicate_activity_ids" => row["replacement_duplicate_activity_ids"],
      "source_duplicate_activities" => row["source_duplicate_activities"],
      "replacement_duplicate_activities" => row["replacement_duplicate_activities"],
      "source_invalid_activity_input" => row["source_invalid_activity_input"],
      "source_invalid_activity_input_reason" => row["source_invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "replacement_invalid_activity_input" => row["replacement_invalid_activity_input"],
      "replacement_invalid_activity_input_reason" =>
        row["replacement_invalid_activity_input_reason"],
      "replacement_activity" => row["replacement_activity"],
      "transition_decision" => row["transition_decision"],
      "transition_decision_reason" => row["transition_decision_reason"],
      "requires_operator_review" => row["requires_operator_review"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "source_activity_context" => row["source_activity_context"],
      "replacement_activity_context" => row["replacement_activity_context"],
      "application_status" => row["application_status"],
      "selected_activity_source" => row["selected_activity_source"],
      "selected_activity" => row["selected_activity"],
      "selected_timeline_integrity_status" => row["selected_timeline_integrity_status"],
      "selected_timeline_integrity_issue_count" => row["selected_timeline_integrity_issue_count"],
      "selected_timeline_integrity_issue_types" => row["selected_timeline_integrity_issue_types"],
      "selected_timeline_integrity_issues" => row["selected_timeline_integrity_issues"],
      "selected_missing_dependency_activity_ids" =>
        row["selected_missing_dependency_activity_ids"],
      "selected_missing_dependency_timeline_ids" =>
        row["selected_missing_dependency_timeline_ids"],
      "selected_self_dependency_activity_ids" => row["selected_self_dependency_activity_ids"],
      "selected_self_dependency_timeline_ids" => row["selected_self_dependency_timeline_ids"],
      "selected_duplicate_dependency_activity_ids" =>
        row["selected_duplicate_dependency_activity_ids"],
      "selected_duplicate_dependency_timeline_ids" =>
        row["selected_duplicate_dependency_timeline_ids"],
      "selected_duplicate_exclusivity_activity_ids" =>
        row["selected_duplicate_exclusivity_activity_ids"],
      "selected_duplicate_exclusivity_timeline_ids" =>
        row["selected_duplicate_exclusivity_timeline_ids"],
      "selected_dependency_cycle_activity_ids" => row["selected_dependency_cycle_activity_ids"],
      "selected_dependency_cycle_timeline_ids" => row["selected_dependency_cycle_timeline_ids"],
      "selected_dependency_order_violation_activity_ids" =>
        row["selected_dependency_order_violation_activity_ids"],
      "selected_dependency_order_violation_timeline_ids" =>
        row["selected_dependency_order_violation_timeline_ids"],
      "selected_exclusivity_violation_activity_ids" =>
        row["selected_exclusivity_violation_activity_ids"],
      "selected_exclusivity_violation_timeline_ids" =>
        row["selected_exclusivity_violation_timeline_ids"],
      "source_timeline_diff" => row
    }
    |> compact_map()
  end

  defp timeline_dependency_impact_rows(summary),
    do: timeline_dependency_impact_rows(summary, "timeline_dependency_impact_summary.rows")

  defp timeline_dependency_impact_rows(%{} = summary, source) do
    summary
    |> Map.get("dependency_impact_rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["dependency_impact_status"] == "clear"))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_dependency_impact_review_row(row, index, source, summary)
    end)
  end

  defp timeline_dependency_impact_rows(_summary, _source), do: []

  defp timeline_dependency_impact_review_row(row, index, source, summary) do
    %{
      "id" => review_id(["timeline_dependency_impact", row["id"] || row["timeline_id"], index]),
      "review_type" => "timeline_dependency_impact_review",
      "source" => source,
      "subject_id" => row["timeline_id"] || row["activity_id"],
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "dependency_impact_scope" => row["scope"],
      "dependency_impact_status" => row["dependency_impact_status"] || "review_required",
      "action" => row["required_operator_action"],
      "required_operator_action" => row["required_operator_action"],
      "approval_status" => "operator_review_required",
      "reason" => row["operator_action_reason"],
      "operator_action_reason" => row["operator_action_reason"],
      "status" => row["status"],
      "source_activity_count" => summary["source_activity_count"],
      "replacement_activity_count" => summary["replacement_activity_count"],
      "changed_source_activity_count" => summary["changed_source_activity_count"],
      "changed_source_timeline_count" => summary["changed_source_timeline_count"],
      "dependent_activity_count" => summary["dependent_activity_count"],
      "source_dependent_activity_count" => summary["source_dependent_activity_count"],
      "replacement_dependent_activity_count" => summary["replacement_dependent_activity_count"],
      "impacted_source_activity_ids" => summary["impacted_source_activity_ids"],
      "impacted_source_timeline_ids" => summary["impacted_source_timeline_ids"],
      "dependent_activity_ids" => summary["dependent_activity_ids"],
      "dependent_timeline_ids" => summary["dependent_timeline_ids"],
      "source_dependent_activity_ids" => summary["source_dependent_activity_ids"],
      "source_dependent_timeline_ids" => summary["source_dependent_timeline_ids"],
      "replacement_dependent_activity_ids" => summary["replacement_dependent_activity_ids"],
      "replacement_dependent_timeline_ids" => summary["replacement_dependent_timeline_ids"],
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "impacted_dependency_activity_ids" => row["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => row["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" => row["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" => row["impacted_exclusive_with_timeline_ids"],
      "source_timeline_dependency_impact" => row
    }
    |> compact_map()
  end

  defp timeline_publication_rows(summary),
    do: timeline_publication_rows(summary, "timeline_publication_summary")

  defp timeline_publication_rows(%{} = summary, source) do
    [
      %{
        "id" =>
          review_id([
            "timeline_publication",
            summary["publication_id"] || summary["source_artifact_id"] || "summary",
            summary["publication_sequence"] || 0
          ]),
        "review_type" => "timeline_publication_review",
        "source" => source,
        "subject_id" => summary["publication_id"] || summary["source_artifact_id"],
        "publication_id" => summary["publication_id"],
        "publication_sequence" => summary["publication_sequence"],
        "publication_status" => summary["publication_status"],
        "publication_authority" => summary["publication_authority"],
        "source_artifact_id" => summary["source_artifact_id"],
        "source_artifact_type" => summary["source_artifact_type"],
        "supersedes_artifact_ids" => summary["supersedes_artifact_ids"],
        "downstream_product_ids" => summary["downstream_product_ids"],
        "invalidated_downstream_product_ids" => summary["invalidated_downstream_product_ids"],
        "dependency_impact_status" => summary["dependency_impact_status"],
        "dependency_impact_row_count" => summary["dependency_impact_row_count"],
        "impacted_dependency_activity_ids" => summary["impacted_dependency_activity_ids"],
        "impacted_dependency_timeline_ids" => summary["impacted_dependency_timeline_ids"],
        "impacted_exclusive_with_activity_ids" => summary["impacted_exclusive_with_activity_ids"],
        "impacted_exclusive_with_timeline_ids" => summary["impacted_exclusive_with_timeline_ids"],
        "timeline_diff_row_count" => summary["timeline_diff_row_count"],
        "timeline_diff_changed_count" => summary["timeline_diff_changed_count"],
        "timeline_diff_review_required_count" => summary["timeline_diff_review_required_count"],
        "changed_field_counts" => summary["changed_field_counts"],
        "changed_timeline_ids" => summary["changed_timeline_ids"],
        "review_timeline_ids" => summary["review_timeline_ids"],
        "timeline_ids_by_changed_field" => summary["timeline_ids_by_changed_field"],
        "action" => "review_timeline_publication",
        "required_operator_action" => "review_timeline_publication",
        "approval_status" => "operator_review_required",
        "reason" => timeline_publication_review_reason(summary),
        "operator_action_reason" => timeline_publication_operator_action_reason(summary),
        "source_timeline_publication_summary" => summary
      }
      |> compact_map()
    ]
  end

  defp timeline_publication_rows(_summary, _source), do: []

  defp timeline_publication_review_reason(%{} = summary) do
    "review publication #{summary["publication_id"] || summary["source_artifact_id"]} before downstream handoff"
  end

  defp timeline_publication_operator_action_reason(%{
         "publication_status" => "published_with_downstream_invalidations"
       }),
       do: "publication_invalidates_downstream_products"

  defp timeline_publication_operator_action_reason(%{
         "dependency_impact_status" => "review_required"
       }),
       do: "publication_dependency_impact_review_required"

  defp timeline_publication_operator_action_reason(%{
         "timeline_diff_review_required_count" => count
       })
       when is_integer(count) and count > 0,
       do: "publication_timeline_diff_review_required"

  defp timeline_publication_operator_action_reason(_summary),
    do: "publication_metadata_review_required"

  defp timeline_lifecycle_state_rows(summary),
    do: timeline_lifecycle_state_rows(summary, "timeline_lifecycle_state_summary.review_rows")

  defp timeline_lifecycle_state_rows(%{} = summary, source) do
    summary
    |> Map.get("review_rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_lifecycle_state_review_row(row, index, source, summary)
    end)
  end

  defp timeline_lifecycle_state_rows(_summary, _source), do: []

  defp timeline_activity_precondition_rows(
         %{} = summary,
         source \\ "timeline_activity_precondition_summary.summary"
       ) do
    summary = stringify_keys(summary)
    [timeline_activity_precondition_review_row(summary, 1, source)]
  end

  defp timeline_activity_precondition_review_row(summary, index, source) do
    subject_id = summary["timeline_id"] || summary["activity_id"]
    required_operator_action = activity_precondition_required_operator_action(summary)
    reason = activity_precondition_reason(summary)

    %{
      "id" => review_id(["timeline_activity_precondition", subject_id, index]),
      "review_type" => "timeline_activity_precondition_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => summary["timeline_id"],
      "activity_id" => summary["activity_id"],
      "activity_type" => summary["activity_type"],
      "precondition_status" => summary["precondition_status"],
      "blocked_precondition_count" => summary["blocked_precondition_count"],
      "review_precondition_count" => summary["review_precondition_count"],
      "blocked_precondition_types" => summary["blocked_precondition_types"],
      "review_precondition_types" => summary["review_precondition_types"],
      "preconditions" => summary["preconditions"],
      "dependency_activity_ids" => summary["dependency_activity_ids"],
      "dependency_timeline_ids" => summary["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => summary["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => summary["exclusive_with_timeline_ids"],
      "allow_overlap" => summary["allow_overlap"],
      "invalid_activity_input" => summary["invalid_activity_input"],
      "invalid_activity_input_reason" => summary["invalid_activity_input_reason"],
      "timeline_identity" => summary["timeline_identity"],
      "action" => required_operator_action,
      "required_operator_action" => required_operator_action,
      "approval_status" => activity_precondition_approval_status(summary),
      "reason" => reason,
      "operator_action_reason" => reason,
      "source_timeline_activity_precondition_summary" => summary
    }
    |> compact_map()
  end

  defp activity_precondition_required_operator_action(%{"invalid_activity_input" => true}),
    do: "review_invalid_activity_input"

  defp activity_precondition_required_operator_action(%{"precondition_status" => "blocked"}),
    do: "review_blocked_activity_precondition"

  defp activity_precondition_required_operator_action(%{
         "precondition_status" => "review_required"
       }),
       do: "review_activity_precondition"

  defp activity_precondition_required_operator_action(%{"precondition_status" => "clear"}),
    do: "record_activity_precondition"

  defp activity_precondition_required_operator_action(_summary),
    do: "review_activity_precondition"

  defp activity_precondition_approval_status(%{"precondition_status" => "clear"}),
    do: "not_required"

  defp activity_precondition_approval_status(_summary), do: "operator_review_required"

  defp activity_precondition_reason(%{"invalid_activity_input" => true} = summary) do
    summary["invalid_activity_input_reason"] || "invalid_activity_input"
  end

  defp activity_precondition_reason(%{"precondition_status" => "blocked"}),
    do: "blocked_activity_precondition"

  defp activity_precondition_reason(%{"precondition_status" => "review_required"}),
    do: "activity_precondition_review_required"

  defp activity_precondition_reason(%{"precondition_status" => "clear"}),
    do: "activity_precondition_clear"

  defp activity_precondition_reason(_summary), do: "activity_precondition_review_required"

  defp timeline_activity_state_rows(%{} = state, source) do
    [
      timeline_lifecycle_state_review_row(
        state,
        1,
        source,
        timeline_activity_state_summary(state)
      )
    ]
  end

  defp timeline_activity_state_summary(%{} = state) do
    if state["review_required"] do
      %{
        "planned_activity_count" => 1,
        "realized_activity_count" => 1,
        "review_required_count" => 1
      }
    else
      %{
        "planned_activity_count" => 1,
        "realized_activity_count" => 1,
        "review_required_count" => 0
      }
    end
  end

  defp timeline_activity_state_source_id(state, fallback) do
    Map.get(state, "id") || Map.get(state, "source") || Map.get(state, "timeline_id") ||
      Map.get(state, "activity_id") || fallback
  end

  defp timeline_lifecycle_state_review_row(row, index, source, summary) do
    subject_id = row["timeline_id"] || row["activity_id"]
    required_operator_action = lifecycle_state_required_operator_action(row)

    %{
      "id" => review_id(["timeline_lifecycle_state", subject_id, index]),
      "review_type" => "timeline_lifecycle_state_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "planned_activity_id" => row["planned_activity_id"],
      "realized_activity_id" => row["realized_activity_id"],
      "planned_activity_ids" => row["planned_activity_ids"],
      "realized_activity_ids" => row["realized_activity_ids"],
      "timeline_lifecycle_state_status" => "review_required",
      "transition_decision" => row["transition_decision"] || "review",
      "status_transition_decision" => row["status_transition_decision"],
      "approval_transition_decision" => row["approval_transition_decision"],
      "action" => required_operator_action,
      "required_operator_action" => required_operator_action,
      "approval_status" => lifecycle_state_approval_status(row),
      "reason" => lifecycle_state_reason(row),
      "operator_action_reason" => lifecycle_state_reason(row),
      "required_operator_actions" => row["required_operator_actions"],
      "operator_action_reasons" => row["operator_action_reasons"],
      "import_action" => row["import_action"],
      "status_transition" => row["status_transition"],
      "approval_transition" => row["approval_transition"],
      "planned_status" => row["planned_status"],
      "realized_status" => row["realized_status"],
      "planned_status_category" => row["planned_status_category"],
      "realized_status_category" => row["realized_status_category"],
      "planned_approval_status" => row["planned_approval_status"],
      "realized_approval_status" => row["realized_approval_status"],
      "planned_approval_category" => row["planned_approval_category"],
      "realized_approval_category" => row["realized_approval_category"],
      "planned_locked" => row["planned_locked"],
      "realized_locked" => row["realized_locked"],
      "planned_executed" => row["planned_executed"],
      "realized_executed" => row["realized_executed"],
      "planned_protection_decision" =>
        protection_decision_status(row["planned_protection_decision"]),
      "realized_protection_decision" =>
        protection_decision_status(row["realized_protection_decision"]),
      "planned_protection_context" => row["planned_protection_decision"],
      "realized_protection_context" => row["realized_protection_decision"],
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_count" => row["invalid_activity_input_count"],
      "invalid_activity_input_reasons" => row["invalid_activity_input_reasons"],
      "source_planned_activity_count" => summary["planned_activity_count"],
      "source_realized_activity_count" => summary["realized_activity_count"],
      "source_lifecycle_state_review_required_count" => summary["review_required_count"],
      "planned_activity_context" => row["planned_activity_context"],
      "realized_activity_context" => row["realized_activity_context"]
    }
    |> maybe_put_candidate_refresh_timeline_activity_state_lifecycle_source(row, source)
    |> Map.put(timeline_activity_state_source_field(row), row)
    |> compact_map()
  end

  defp maybe_put_candidate_refresh_timeline_activity_state_lifecycle_source(
         review_row,
         row,
         "candidate_refresh." <> _source
       ) do
    Map.put_new(
      review_row,
      "source_timeline_lifecycle_state",
      timeline_activity_state_lifecycle_source(row)
    )
  end

  defp maybe_put_candidate_refresh_timeline_activity_state_lifecycle_source(
         review_row,
         _row,
         _source
       ),
       do: review_row

  defp timeline_activity_state_lifecycle_source(%{} = row) do
    row
    |> Map.put_new("schema_contract", timeline_activity_state_source_contract(row))
    |> compact_map()
  end

  defp timeline_activity_state_source_contract(%{"schema_contract" => contract})
       when is_binary(contract),
       do: contract

  defp timeline_activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_state"
       }),
       do: "timeline_activity_state.v1"

  defp timeline_activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_status_state"
       }),
       do: "timeline_activity_status_state.v1"

  defp timeline_activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_approval_state"
       }),
       do: "timeline_activity_approval_state.v1"

  defp timeline_activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_lifecycle_state"
       }),
       do: "timeline_activity_lifecycle_state.v1"

  defp timeline_activity_state_source_contract(_row), do: nil

  defp timeline_activity_state_source_field(%{"schema_contract" => "timeline_activity_state.v1"}),
    do: "source_timeline_activity_state"

  defp timeline_activity_state_source_field(%{
         "model" => "artifact_only_timeline_activity_state"
       }),
       do: "source_timeline_activity_state"

  defp timeline_activity_state_source_field(_row), do: "source_timeline_lifecycle_state"

  defp lifecycle_state_approval_status(%{"review_required" => false}), do: "not_required"
  defp lifecycle_state_approval_status(_row), do: "operator_review_required"

  defp lifecycle_state_required_operator_action(%{"required_operator_action" => action})
       when is_binary(action),
       do: action

  defp lifecycle_state_required_operator_action(%{"required_operator_actions" => [action | _]})
       when is_binary(action),
       do: action

  defp lifecycle_state_required_operator_action(%{"review_required" => false}),
    do: "record_timeline_change"

  defp lifecycle_state_required_operator_action(%{
         "approval_transition_decision" => "review"
       }),
       do: "review_activity_approval"

  defp lifecycle_state_required_operator_action(%{
         "status_transition_decision" => "review"
       }),
       do: "review_activity_transition"

  defp lifecycle_state_required_operator_action(_row), do: "review_timeline_lifecycle_state"

  defp lifecycle_state_reason(%{"operator_action_reasons" => [reason | _]}), do: reason

  defp lifecycle_state_reason(%{"operator_action_reason" => reason}) when is_binary(reason),
    do: reason

  defp lifecycle_state_reason(%{"required_operator_action" => action}) when is_binary(action),
    do: action

  defp lifecycle_state_reason(_row), do: "timeline_lifecycle_state_requires_review"

  defp timeline_preservation_report_rows(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_preservation_review_row(
        row,
        index,
        "timeline_preservation_report.rows",
        report,
        row
      )
    end)
  end

  defp timeline_preservation_status_rows(%{} = status, source) do
    [timeline_preservation_review_row(status, 1, source, status, status)]
  end

  defp timeline_preservation_review_row(row, index, source, summary, source_state) do
    subject_id = row["timeline_id"] || row["activity_id"]
    preservation_status = timeline_preservation_status(row, summary)
    protection_decision = row["protection_decision"]
    protection_category = row["protection_category"]
    protection_reason = row["protection_reason"] || row["reason"]

    %{
      "id" => review_id(["timeline_preservation", subject_id, index]),
      "review_type" => "timeline_preservation_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "timeline_preservation_status" => preservation_status,
      "requires_preservation" => timeline_preservation_requires_preservation?(row),
      "requires_operator_review" => timeline_preservation_requires_review?(row),
      "action" => timeline_preservation_required_operator_action(row),
      "required_operator_action" => timeline_preservation_required_operator_action(row),
      "approval_status" => timeline_preservation_approval_status(row),
      "reason" => protection_reason,
      "operator_action_reason" => protection_reason,
      "timeline_preservation_protection_decision" => protection_decision,
      "timeline_preservation_protection_category" => protection_category,
      "timeline_preservation_protection_reason" => protection_reason,
      "locked" => row["locked"],
      "approved" => row["approved"],
      "executed" => row["executed"],
      "status" => row["status"],
      "approval_status_value" => row["approval_status"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity_count" => summary["activity_count"],
      "preserve_activity_count" => summary["preserve_activity_count"],
      "review_change_activity_count" => summary["review_change_activity_count"],
      "mutable_activity_count" => summary["mutable_activity_count"],
      "preservation_sensitive_activity_count" => summary["preservation_sensitive_activity_count"],
      "preserve_activity_ids" => summary["preserve_activity_ids"],
      "preserve_timeline_ids" => summary["preserve_timeline_ids"],
      "review_change_activity_ids" => summary["review_change_activity_ids"],
      "review_change_timeline_ids" => summary["review_change_timeline_ids"],
      "preservation_sensitive_activity_ids" => summary["preservation_sensitive_activity_ids"],
      "preservation_sensitive_timeline_ids" => summary["preservation_sensitive_timeline_ids"],
      "source_timeline_preservation" => source_state
    }
    |> compact_map()
  end

  defp timeline_preservation_source_id(status, fallback) do
    Map.get(status, "id") || Map.get(status, "source") || Map.get(status, "timeline_id") ||
      Map.get(status, "activity_id") || fallback
  end

  defp timeline_integrity_report_rows(%{} = report) do
    timeline_integrity_report_rows(report, "timeline_integrity_report.rows")
  end

  defp timeline_integrity_report_rows(%{} = report, source) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      timeline_integrity_review_row(row, index, report, source)
    end)
  end

  defp timeline_integrity_review_row(row, index, summary, source) do
    subject_id = row["timeline_id"] || row["activity_id"]
    required_action = row["required_operator_action"] || "review_timeline_integrity"
    reason = row["operator_action_reason"] || row["reason"] || "timeline_integrity_issue"

    %{
      "id" => review_id(["timeline_integrity", subject_id, index]),
      "review_type" => "timeline_integrity_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "timeline_identity" => row["timeline_identity"],
      "timeline_integrity_status" => row["timeline_integrity_status"] || "review_required",
      "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => row["timeline_integrity_issues"],
      "action" => required_action,
      "required_operator_action" => required_action,
      "approval_status" => "operator_review_required",
      "reason" => reason,
      "operator_action_reason" => reason,
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
      "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
      "duplicate_dependency_activity_ids" => row["duplicate_dependency_activity_ids"],
      "duplicate_dependency_timeline_ids" => row["duplicate_dependency_timeline_ids"],
      "duplicate_exclusivity_activity_ids" => row["duplicate_exclusivity_activity_ids"],
      "duplicate_exclusivity_timeline_ids" => row["duplicate_exclusivity_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity_count" => summary["activity_count"],
      "source_valid_activity_count" => summary["valid_activity_count"],
      "source_invalid_activity_input_count" => summary["invalid_activity_input_count"],
      "source_timeline_integrity_review_count" => summary["timeline_integrity_review_count"],
      "source_timeline_integrity_issue_count" => summary["timeline_integrity_issue_count"],
      "source_timeline_integrity_issue_types" => summary["timeline_integrity_issue_types"],
      "source_timeline_integrity_issue_type_counts" =>
        summary["timeline_integrity_issue_type_counts"],
      "source_dependency_issue_count" => summary["dependency_issue_count"],
      "source_exclusivity_issue_count" => summary["exclusivity_issue_count"],
      "review_activity_ids" => summary["review_activity_ids"],
      "review_timeline_ids" => summary["review_timeline_ids"],
      "dependency_review_activity_ids" => summary["dependency_review_activity_ids"],
      "dependency_review_timeline_ids" => summary["dependency_review_timeline_ids"],
      "exclusivity_review_activity_ids" => summary["exclusivity_review_activity_ids"],
      "exclusivity_review_timeline_ids" => summary["exclusivity_review_timeline_ids"],
      "invalid_activity_input_ids" => summary["invalid_activity_input_ids"],
      "source_timeline_integrity" => row
    }
    |> compact_map()
  end

  defp timeline_preservation_status(%{"timeline_preservation_status" => status}, _summary),
    do: status

  defp timeline_preservation_status(%{"protection_decision" => "review_change"}, _summary),
    do: "review_required"

  defp timeline_preservation_status(%{"protection_decision" => "preserve"}, _summary),
    do: "preservation_required"

  defp timeline_preservation_status(_row, %{"timeline_preservation_status" => status}), do: status
  defp timeline_preservation_status(_row, _summary), do: "clear"

  defp timeline_preservation_requires_preservation?(%{"requires_preservation" => value})
       when is_boolean(value),
       do: value

  defp timeline_preservation_requires_preservation?(%{"protection_decision" => "preserve"}),
    do: true

  defp timeline_preservation_requires_preservation?(_row), do: false

  defp timeline_preservation_requires_review?(%{"requires_operator_review" => value})
       when is_boolean(value),
       do: value

  defp timeline_preservation_requires_review?(%{"protection_decision" => "review_change"}),
    do: true

  defp timeline_preservation_requires_review?(_row), do: false

  defp timeline_preservation_required_operator_action(%{"required_operator_action" => action})
       when is_binary(action),
       do: action

  defp timeline_preservation_required_operator_action(%{"requires_operator_review" => true}),
    do: "review_timeline_preservation"

  defp timeline_preservation_required_operator_action(%{
         "protection_decision" => "review_change"
       }),
       do: "review_timeline_preservation"

  defp timeline_preservation_required_operator_action(%{"requires_preservation" => true}),
    do: "record_timeline_preservation"

  defp timeline_preservation_required_operator_action(%{"protection_decision" => "preserve"}),
    do: "record_timeline_preservation"

  defp timeline_preservation_required_operator_action(_row), do: "record_timeline_preservation"

  defp timeline_preservation_approval_status(row) do
    if timeline_preservation_requires_review?(row),
      do: "operator_review_required",
      else: "not_required"
  end

  defp protection_decision_status(%{"protection_decision" => decision}) when is_binary(decision),
    do: decision

  defp protection_decision_status(decision) when is_binary(decision), do: decision
  defp protection_decision_status(_decision), do: nil

  defp approval_rows(requirements, source) do
    requirements
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {requirement, index} ->
      rule_match =
        requirement["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(requirement["policy_decision"] || %{})
      policy_escalation = requirement |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id([
            "approval",
            source,
            requirement["activity_id"],
            requirement["action"],
            index
          ]),
        "review_type" => "approval_requirement",
        "source" => source,
        "subject_id" => requirement["activity_id"],
        "activity_id" => requirement["activity_id"],
        "activity_type" => requirement["activity_type"],
        "action" => requirement["action"],
        "required_operator_action" => requirement["action"],
        "approval_status" => requirement["policy_classification"] || "operator_review_required",
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "reason" => requirement["reason"],
        "approval_rule_matches" => requirement["approval_rule_matches"],
        "activity_context" => requirement["activity_context"],
        "candidate_diff" => requirement["candidate_diff"],
        "source_policy_decision" => requirement["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_requirement" => requirement
      }
      |> put_candidate_diff_fields(requirement["candidate_diff"])
      |> compact_map()
    end)
  end

  defp put_candidate_diff_fields(row, nil), do: row

  defp put_candidate_diff_fields(row, %{} = candidate_diff) do
    row
    |> Map.put("invalidated_candidate_id", candidate_diff["invalidated_candidate_id"])
    |> Map.put("invalidated_candidate_ids", candidate_diff["invalidated_candidate_ids"])
    |> Map.put("replacement_candidate_id", candidate_diff["replacement_candidate_id"])
    |> Map.put("invalidated_reason", candidate_diff["invalidated_reason"])
    |> Map.put("semantic_change_reasons", candidate_diff["semantic_change_reasons"])
    |> Map.put("candidate_diff_match_status", candidate_diff["candidate_diff_match_status"])
    |> Map.put("candidate_diff_match_count", candidate_diff["candidate_diff_match_count"])
    |> Map.put("semantic_match_status", candidate_diff["semantic_match_status"])
    |> Map.put("semantic_match_candidate_count", candidate_diff["semantic_match_candidate_count"])
    |> Map.put("semantic_match_candidate_ids", candidate_diff["semantic_match_candidate_ids"])
    |> Map.put("candidate_budget_match_status", candidate_diff["candidate_budget_match_status"])
    |> Map.put("candidate_budget_match_count", candidate_diff["candidate_budget_match_count"])
    |> Map.put("budget_dropped_candidate_ids", candidate_diff["budget_dropped_candidate_ids"])
  end

  defp policy_escalation_rows(nil, _source), do: []

  defp policy_escalation_rows(%{} = decision, source) do
    decision = stringify_keys(decision)

    decision
    |> Map.get("escalations", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {escalation, index} ->
      rule_id = Map.get(escalation, "rule_id", "policy_escalation")

      %{
        "id" => review_id(["policy_escalation", source, rule_id, index]),
        "review_type" => "policy_escalation",
        "source" => source,
        "subject_id" => rule_id,
        "action" => "review_policy_escalation",
        "required_operator_action" => "review_policy_escalation",
        "approval_status" => Map.get(escalation, "classification", decision["classification"]),
        "reason" => policy_escalation_reason(escalation),
        "policy_bundle_id" => decision["policy_bundle_id"],
        "policy_bundle_provenance" => decision["policy_bundle_provenance"],
        "policy_bundle_provenance_source" =>
          get_in(decision, ["policy_bundle_provenance", "source"]),
        "policy_bundle_adapter" => get_in(decision, ["policy_bundle_provenance", "adapter"]),
        "policy_bundle_organization_id" =>
          get_in(decision, ["policy_bundle_provenance", "organization_id"]),
        "policy_bundle_policy_source" =>
          get_in(decision, ["policy_bundle_provenance", "policy_source"]),
        "rule_id" => rule_id,
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "source_policy_decision" => decision
      }
      |> compact_map()
    end)
  end

  defp policy_escalation_rows(_decision, _source), do: []

  defp policy_escalation_reason(%{"required_authority" => authority}) when is_binary(authority),
    do: "policy escalation requires #{authority}"

  defp policy_escalation_reason(%{"escalation_role" => role}) when is_binary(role),
    do: "policy escalation requires #{role}"

  defp policy_escalation_reason(_escalation), do: "policy escalation requires operator review"

  defp schema_validation_batch_report_rows(entry) do
    entry = stringify_keys(entry)

    entry
    |> Map.get("report", %{})
    |> stringify_keys()
    |> Map.put_new("artifact_path", entry["path"])
    |> Map.put("batch_entry_path", entry["path"])
    |> schema_validation_rows("schema_validation_batch_report.reports.report")
  end

  defp constraint_rows(rows, source \\ "constraint_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.reject(fn {row, _index} -> Map.get(row, "status") == "pass" end)
    |> Enum.map(fn {row, index} ->
      constraint_id = row["constraint_id"]
      scenario_id = row["scenario_id"]
      status = row["status"] || "unknown"

      %{
        "id" => review_id(["constraint", constraint_id, scenario_id, index]),
        "review_type" => "constraint_review",
        "source" => source,
        "subject_id" => scenario_id || constraint_id || "constraint_report",
        "scenario_id" => scenario_id,
        "constraint_id" => constraint_id,
        "metric" => row["metric"],
        "operator" => row["operator"],
        "threshold" => row["threshold"],
        "value" => row["value"],
        "score" => row["score"],
        "violation_severity" => row["violation_severity"],
        "constraint_status" => status,
        "action" => "review_constraint",
        "required_operator_action" => "review_constraint",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => constraint_reason(row),
        "source_constraint_row" => row
      }
      |> compact_map()
    end)
  end

  defp constraint_reason(row) do
    status = row["status"] || "unknown"
    constraint_id = row["constraint_id"] || "constraint"
    subject = row["scenario_id"] || row["subject_id"] || "artifact"
    metric = row["metric"] || "metric"
    operator = row["operator"] || "operator"
    threshold = row["threshold"] || "threshold"

    "review #{status} constraint #{constraint_id} for #{subject}: #{metric} #{operator} #{threshold}"
  end

  defp constraint_report_id(report) do
    review_id([
      "constraint_report",
      Map.get(report, "id") || get_in(report, ["assumptions", "source"]) || report["status"]
    ])
  end

  defp objective_satisfaction_rows(rows, source \\ "objective_satisfaction_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.reject(fn {row, _index} -> objective_satisfaction_pass_status?(row["status"]) end)
    |> Enum.map(fn {row, index} ->
      objective = row["objective"]
      target_id = row["target_id"]
      row_id = row["id"]

      %{
        "id" => review_id(["objective_satisfaction", objective, target_id || row_id, index]),
        "review_type" => "objective_satisfaction_review",
        "source" => source,
        "subject_id" => target_id || row_id || objective || "objective_satisfaction",
        "objective" => objective,
        "objective_status" => row["status"],
        "target_id" => target_id,
        "required_count" => row["required_count"],
        "candidate_count" => row["candidate_count"],
        "selected_count" => row["selected_count"],
        "satisfied_count" => row["satisfied_count"],
        "candidate_target_ids" => row["candidate_target_ids"],
        "selected_target_ids" => row["selected_target_ids"],
        "selected_activity_ids" => row["selected_activity_ids"],
        "selected_contact_ids" => row["selected_contact_ids"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "candidate_downlink_mb" => row["candidate_downlink_mb"],
        "selected_downlink_mb" => row["selected_downlink_mb"],
        "satisfied_downlink_mb" => row["satisfied_downlink_mb"],
        "action" => "review_objective_satisfaction",
        "required_operator_action" => "review_objective_satisfaction",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => objective_satisfaction_reason(row),
        "source_objective_satisfaction" => row
      }
      |> compact_map()
    end)
  end

  defp objective_satisfaction_pass_status?(status)
       when status in ["met", "selected", "no_requirement"],
       do: true

  defp objective_satisfaction_pass_status?(_status), do: false

  defp objective_satisfaction_reason(row) do
    status = row["status"] || "unknown"
    objective = row["objective"] || "objective"
    subject = row["target_id"] || row["id"] || "objective_satisfaction"

    "review #{status} objective #{objective} for #{subject}"
  end

  defp schema_validation_rows(report, source_prefix \\ "schema_validation_report") do
    issues =
      report
      |> Map.get("errors", [])
      |> Enum.map(&schema_validation_issue_row(&1, source_prefix <> ".errors"))
      |> Kernel.++(
        report
        |> Map.get("warnings", [])
        |> Enum.map(&schema_validation_issue_row(&1, source_prefix <> ".warnings"))
      )

    if issues == [] do
      []
    else
      remediation_by_path =
        report
        |> Map.get("remediation", [])
        |> Enum.map(&stringify_keys/1)
        |> Map.new(&{&1["path"], &1})

      issues
      |> Enum.with_index(1)
      |> Enum.map(fn {issue, index} ->
        remediation = Map.get(remediation_by_path, issue["path"])
        severity = Map.get(issue, "severity", "error")

        %{
          "id" =>
            review_id([
              "schema_validation",
              report["validated_contract"],
              report["validation_mode"],
              stable_id_fragment(report["batch_entry_path"]),
              stable_id_fragment(issue["path"]),
              index
            ]),
          "review_type" => "schema_validation_review",
          "source" => issue["source"],
          "subject_id" => report["validated_contract"] || "schema_validation_report",
          "action" => schema_validation_action(severity),
          "required_operator_action" => "review_schema_validation",
          "approval_status" => "operator_review_required",
          "reason" => schema_validation_reason(report, issue),
          "validation_status" => report["status"],
          "validation_mode" => report["validation_mode"],
          "validated_contract" => report["validated_contract"],
          "validated_artifact_family" => report["validated_artifact_family"],
          "artifact_path" => report["artifact_path"],
          "issue_severity" => severity,
          "issue_path" => issue["path"],
          "issue_message" => issue["message"],
          "error_count" => report["error_count"],
          "warning_count" => report["warning_count"],
          "remediation_count" => report["remediation_count"],
          "remediation_category" => remediation && remediation["category"],
          "remediation_action" => remediation && remediation["action"],
          "source_validation_issue" => Map.delete(issue, "source"),
          "source_validation_remediation" => remediation,
          "source_schema_validation_report" => report
        }
        |> compact_map()
      end)
    end
  end

  defp schema_validation_issue_row(issue, source) do
    issue
    |> stringify_keys()
    |> Map.put("source", source)
  end

  defp schema_validation_action("warning"), do: "review_schema_validation_warning"
  defp schema_validation_action(_severity), do: "review_schema_validation_failure"

  defp schema_validation_reason(report, issue) do
    contract = report["validated_contract"] || "artifact"
    severity = issue["severity"] || "error"
    path = issue["path"] || "$"
    message = issue["message"] || "schema validation issue"

    "#{contract} #{severity} at #{path}: #{message}"
  end

  defp schema_validation_report_id(report) do
    review_id([
      "schema_validation",
      report["validated_contract"],
      report["validation_mode"],
      report["status"]
    ])
  end

  defp schema_validation_batch_report_id(report) do
    review_id([
      "schema_validation_batch",
      report["validation_mode"],
      stable_id_fragment(report["input_dir"]),
      report["status"]
    ])
  end

  defp result_artifact_execution_rows(artifact) do
    case Map.get(artifact, "execution_report") do
      %{} = report ->
        report
        |> stringify_keys()
        |> Map.put_new("study_id", Map.get(artifact, "study_id"))
        |> Map.put_new("run_id", get_in(artifact, ["run", "id"]))
        |> execution_report_rows("result_artifact.execution_report.failed_scenarios")

      _value ->
        []
    end
  end

  defp result_artifact_constraint_rows(artifact) do
    artifact
    |> get_in(["constraint_report", "rows"])
    |> List.wrap()
    |> constraint_rows("result_artifact.constraint_report.rows")
  end

  defp result_artifact_maneuver_review_rows(artifact) do
    artifact
    |> get_in(["maneuver_review_report", "rows"])
    |> List.wrap()
    |> maneuver_review_rows("result_artifact.maneuver_review_report.rows")
  end

  defp result_artifact_maneuver_recommendation_rows(artifact) do
    recommendations = Map.get(artifact, "maneuver_recommendations", [])

    if recommendations == [] do
      []
    else
      recommendations
      |> OrbitalDynamics.ManeuverReview.report(
        source: "result_artifact.maneuver_recommendations",
        source_artifact_id: result_artifact_id(artifact)
      )
      |> Map.get("rows", [])
      |> maneuver_review_rows("result_artifact.maneuver_recommendations")
    end
  end

  defp result_artifact_maneuver_rows(artifact) do
    review_rows = result_artifact_maneuver_review_rows(artifact)
    recommendation_rows = result_artifact_maneuver_recommendation_rows(artifact)
    review_keys = MapSet.new(review_rows, &maneuver_review_identity/1)

    review_rows ++
      Enum.reject(recommendation_rows, fn row ->
        MapSet.member?(review_keys, maneuver_review_identity(row))
      end)
  end

  defp maneuver_review_identity(row) do
    [
      row["review_type"],
      row["maneuver_id"] || row["subject_id"],
      row["scenario_id"],
      row["epoch_s"],
      row["delta_v_km_s"],
      row["required_operator_action"] || row["action"]
    ]
    |> encode_value()
  end

  defp result_artifact_id(artifact) do
    review_id([
      "result_artifact",
      artifact["study_id"],
      get_in(artifact, ["run", "id"]) || get_in(artifact, ["execution_report", "run_id"])
    ])
  end

  defp execution_report_rows(report, source \\ "execution_report.failed_scenarios") do
    report
    |> Map.get("failed_scenarios", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {failure, index} ->
      scenario_id = failure["scenario_id"] || "unknown_scenario"
      stage = failure["stage"] || "unknown_stage"

      %{
        "id" => review_id(["execution", scenario_id, stage, index]),
        "review_type" => "execution_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "scenario_index" => failure["scenario_index"],
        "action" => "review_execution_failure",
        "required_operator_action" => "review_execution_failure",
        "approval_status" => "operator_review_required",
        "reason" => "review execution failure for scenario #{scenario_id} during #{stage}",
        "execution_status" => report["status"],
        "execution_mode" => report["execution_mode"],
        "execution_stage" => stage,
        "execution_error" => failure["error"],
        "resumability" => failure["resumability"],
        "retry_recommendation" => failure["retry_recommendation"],
        "study_id" => report["study_id"],
        "run_id" => report["run_id"],
        "failed_scenario_count" => report["failed_scenario_count"],
        "completed_scenario_count" => report["completed_scenario_count"],
        "scenario_count" => report["scenario_count"],
        "source_execution_failure" => failure,
        "source_execution_report" => execution_report_context(report)
      }
      |> compact_map()
    end)
  end

  defp execution_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "study_id",
      "run_id",
      "status",
      "execution_mode",
      "scenario_count",
      "completed_scenario_count",
      "failed_scenario_count",
      "event_result_count",
      "model_limits",
      "execution_plan",
      "assumptions"
    ])
  end

  defp quality_gate_rows(report, source \\ "quality_gate_report.rows") do
    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&quality_gate_reviewable_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      gate_id = row["gate_id"] || "quality_gate"
      gate_status = row["status"] || "review_required"
      classification = row["classification"] || "review_only"
      action = quality_gate_action(classification)
      row_id = row["id"] || review_id(["quality_gate", gate_id, index])

      %{
        "id" => review_id(["quality_gate_review", row_id]),
        "review_type" => "quality_gate_review",
        "source" => source,
        "subject_id" => row_id,
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => quality_gate_approval_status(classification),
        "cadence_import_status" => quality_gate_cadence_import_status(classification),
        "reason" => row["reason"] || "quality gate #{gate_id} requires review",
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => report["readiness_level"],
        "import_classification" => classification,
        "quality_gate_report_id" => report["report_id"],
        "quality_gate_id" => gate_id,
        "quality_gate_status" => gate_status,
        "quality_gate_classification" => classification,
        "quality_gate_reason" => row["reason"],
        "readiness_gate_id" => gate_id,
        "readiness_gate_status" => gate_status,
        "readiness_gate_classification" => classification,
        "readiness_gate_reason" => row["reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "source_quality_gate_row" => row,
        "source_quality_gate_report" => quality_gate_report_context(report)
      }
      |> Map.merge(quality_gate_row_import_readiness_context(row))
      |> Map.merge(quality_gate_row_resource_context(row))
      |> Map.merge(quality_gate_row_operator_training_context(row))
      |> compact_map()
    end)
  end

  defp quality_gate_import_readiness_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_import_readiness_summary.v1"] and
      model == "artifact_only_quality_gate_import_readiness_summary"
  end

  defp quality_gate_import_readiness_summary?(_summary), do: false

  defp quality_gate_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_summary.v1"] and
      model == "artifact_only_quality_gate_summary"
  end

  defp quality_gate_summary?(_summary), do: false

  defp quality_gate_unavailable_resource_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_unavailable_resource_summary.v1"] and
      model == "artifact_only_quality_gate_unavailable_resource_summary"
  end

  defp quality_gate_unavailable_resource_summary?(_summary), do: false

  defp quality_gate_operator_training_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_operator_training_summary.v1"] and
      model == "artifact_only_quality_gate_operator_training_summary"
  end

  defp quality_gate_operator_training_summary?(_summary), do: false

  defp quality_gate_schema_validation_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_schema_validation_summary.v1"] and
      model == "artifact_only_quality_gate_schema_validation_summary"
  end

  defp quality_gate_schema_validation_summary?(_summary), do: false

  defp quality_gate_report_from_quality_gate_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    gate_ids_by_status = Map.get(summary, "gate_ids_by_status") || %{}

    status =
      summary["status"] || quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)

    classification =
      summary["import_classification"] || quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:operational_quality_gate_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_quality_gate_report_id" => summary["source_quality_gate_report_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" =>
        summary["readiness_level"] || quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        summary["gate_count"] ||
          quality_gate_import_readiness_row_count(summary, row_ids_by_status),
      "passed_gate_count" =>
        summary["passed_gate_count"] ||
          length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        summary["review_gate_count"] ||
          length(
            quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
          ),
      "analysis_gate_count" =>
        summary["analysis_gate_count"] ||
          length(
            quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")
          ),
      "blocked_gate_count" =>
        summary["blocked_gate_count"] ||
          length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" =>
        summary["gate_status_counts"] ||
          quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        summary["gate_classification_counts"] ||
          quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "gate_ids_by_status" => gate_ids_by_status,
      "gate_ids_by_classification" => summary["gate_ids_by_classification"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        summary["quality_gate_row_ids_by_classification"],
      "passed_gate_ids" =>
        summary["passed_gate_ids"] || quality_gate_summary_values(gate_ids_by_status, "passed"),
      "review_required_gate_ids" =>
        summary["review_required_gate_ids"] ||
          quality_gate_summary_values(gate_ids_by_status, "review_required"),
      "analysis_only_gate_ids" =>
        summary["analysis_only_gate_ids"] ||
          quality_gate_summary_values(gate_ids_by_status, "analysis_only"),
      "blocked_gate_ids" =>
        summary["blocked_gate_ids"] || quality_gate_summary_values(gate_ids_by_status, "blocked"),
      "non_passed_quality_gate_row_ids" => summary["non_passed_quality_gate_row_ids"],
      "non_passed_gate_ids" => summary["non_passed_gate_ids"],
      "non_passed_gate_count" => summary["non_passed_gate_count"],
      "non_passed_rows" => summary["non_passed_rows"],
      "trust_boundary" => summary["trust_boundary"],
      "trust_boundaries" => summary["trust_boundaries"],
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_summary_rows(summary)
    }
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp quality_gate_summary_rows(summary) do
    rows = summary["rows"] || summary["non_passed_rows"] || []

    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      row
      |> Map.put_new("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put_new("source_summary_model", summary["model"])
    end)
  end

  defp quality_gate_report_from_schema_validation_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_schema_validation_status(summary, row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_schema_validation_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:schema_validation_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["schema_validation_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "schema_validation_row_count" => summary["schema_validation_row_count"],
      "schema_validation_pass_count" => summary["schema_validation_pass_count"],
      "schema_validation_fail_count" => summary["schema_validation_fail_count"],
      "schema_validation_error_count" => summary["schema_validation_error_count"],
      "schema_validation_warning_count" => summary["schema_validation_warning_count"],
      "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
      "schema_validation_status_counts" => summary["schema_validation_status_counts"],
      "schema_validation_status_ids" => summary["schema_validation_status_ids"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_schema_validation_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_schema_validation_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["schema_validation_gate_ids"] || []) ||
            "cadence_import"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_schema_validation_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "schema_validation_pass_count" => summary["schema_validation_pass_count"],
          "schema_validation_fail_count" => summary["schema_validation_fail_count"],
          "schema_validation_error_count" => summary["schema_validation_error_count"],
          "schema_validation_warning_count" => summary["schema_validation_warning_count"],
          "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
          "schema_validation_status_counts" => summary["schema_validation_status_counts"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_schema_validation_status(summary, row_ids_by_status) do
    cond do
      quality_gate_summary_values(row_ids_by_status, "blocked") != [] or
          summary["schema_validation_import_blocked"] == true ->
        "blocked"

      quality_gate_summary_values(row_ids_by_status, "analysis_only") != [] ->
        "analysis_only"

      quality_gate_summary_values(row_ids_by_status, "review_required") != [] ->
        "review_required"

      true ->
        "passed"
    end
  end

  defp quality_gate_schema_validation_reason("blocked"),
    do: "schema validation quality gate is blocked"

  defp quality_gate_schema_validation_reason("analysis_only"),
    do: "schema validation quality gate is analysis-only"

  defp quality_gate_schema_validation_reason(_status),
    do: "schema validation quality gate requires review"

  defp quality_gate_report_from_operator_training_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_operator_training_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:operator_training_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["operator_training_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "operator_training_row_count" => summary["operator_training_row_count"],
      "operator_training_requirement_count" => summary["operator_training_requirement_count"],
      "operator_training_requirement_counts" => summary["operator_training_requirement_counts"],
      "operator_training_requirement_ids" => summary["operator_training_requirement_ids"],
      "required_operator_roles" => summary["required_operator_roles"],
      "required_training_ids" => summary["required_training_ids"],
      "required_certification_ids" => summary["required_certification_ids"],
      "required_qualification_ids" => summary["required_qualification_ids"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        summary["quality_gate_row_ids_by_classification"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "quality_gate_ids_by_classification" => summary["quality_gate_ids_by_classification"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_operator_training_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_operator_training_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["operator_training_gate_ids"] || []) ||
            "operator_training"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_operator_training_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "operator_training_requirement_count" => summary["operator_training_requirement_count"],
          "operator_training_requirement_counts" =>
            summary["operator_training_requirement_counts"],
          "operator_training_requirement_ids" => summary["operator_training_requirement_ids"],
          "required_operator_roles" => summary["required_operator_roles"],
          "required_training_ids" => summary["required_training_ids"],
          "required_certification_ids" => summary["required_certification_ids"],
          "required_qualification_ids" => summary["required_qualification_ids"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_operator_training_reason("blocked"),
    do: "operator training quality gate is blocked"

  defp quality_gate_operator_training_reason("analysis_only"),
    do: "operator training quality gate is analysis-only"

  defp quality_gate_operator_training_reason(_status),
    do: "operator training quality gate requires review"

  defp quality_gate_report_from_unavailable_resource_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)
    reason_counts = quality_gate_unavailable_resource_reason_counts(summary)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_unavailable_resource_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:unavailable_resource_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["resource_availability_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "resource_availability_pressure_count" =>
        quality_gate_unavailable_resource_pressure_count(reason_counts),
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" => Map.keys(reason_counts) |> Enum.sort(),
      "station_availability_reason_counts" => summary["station_availability_reason_counts"],
      "station_availability_reason_ids" => summary["station_availability_reason_ids"],
      "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
      "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        summary["blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        summary["blocked_contact_ids_by_spacecraft_id"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_unavailable_resource_rows(summary, row_ids_by_status, reason_counts)
    }
    |> compact_map()
  end

  defp quality_gate_unavailable_resource_rows(summary, row_ids_by_status, reason_counts) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["resource_availability_gate_ids"] || []) ||
            "resource_availability"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_unavailable_resource_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "resource_availability_pressure_count" =>
            quality_gate_unavailable_resource_pressure_count(reason_counts),
          "resource_availability_reason_counts" => reason_counts,
          "resource_availability_reason_ids" => Map.keys(reason_counts) |> Enum.sort(),
          "station_availability_reason_counts" => summary["station_availability_reason_counts"],
          "station_availability_reason_ids" => summary["station_availability_reason_ids"],
          "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
          "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
          "resource_blocked_contact_ids_by_blocking_dimension" =>
            summary["blocked_contact_ids_by_blocking_dimension"],
          "resource_blocked_contact_ids_by_spacecraft_id" =>
            summary["blocked_contact_ids_by_spacecraft_id"],
          "resource_blocked_contact_ids_by_status" => summary["blocked_contact_ids_by_status"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_unavailable_resource_reason_counts(summary) do
    [
      summary["unavailable_resource_reason_counts"],
      summary["station_availability_reason_counts"]
    ]
    |> Enum.reduce(%{}, fn
      %{} = counts, acc ->
        Enum.reduce(counts, acc, fn {reason, count}, reason_counts ->
          Map.update(reason_counts, reason, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp quality_gate_unavailable_resource_pressure_count(reason_counts) do
    reason_counts
    |> Map.values()
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp quality_gate_unavailable_resource_reason("blocked"),
    do: "resource availability quality gate is blocked"

  defp quality_gate_unavailable_resource_reason("analysis_only"),
    do: "resource availability quality gate is analysis-only"

  defp quality_gate_unavailable_resource_reason(_status),
    do: "resource availability quality gate requires review"

  defp quality_gate_report_from_import_readiness_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status(summary)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_import_readiness_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:import_readiness_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" => quality_gate_import_readiness_row_count(summary, row_ids_by_status),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_import_readiness_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_import_readiness_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) || List.first(summary["import_readiness_gate_ids"] || [])

        gate_id = gate_id || "cadence_import"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_import_readiness_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"]
        }
        |> Map.merge(quality_gate_import_readiness_row_context(summary, gate_id))
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_import_readiness_row_context(summary, "cadence_import") do
    Map.take(summary, [
      "ready_for_import_count",
      "manifest_review_required_count",
      "blocked_import_count",
      "missing_import_count",
      "invalid_cadence_import_count",
      "current_freshness_count",
      "stale_freshness_count",
      "unknown_freshness_count",
      "freshness_status_counts",
      "schema_validation_pass_count",
      "schema_validation_fail_count",
      "schema_validation_error_count",
      "schema_validation_warning_count",
      "schema_validation_remediation_count",
      "schema_validation_status_counts",
      "import_status_counts",
      "cadence_import_status_counts"
    ])
  end

  defp quality_gate_import_readiness_row_context(_summary, _gate_id), do: %{}

  defp quality_gate_import_readiness_status(%{} = summary) do
    case quality_gate_import_readiness_status_from_row_ids(
           summary["quality_gate_row_ids_by_status"]
         ) do
      nil -> quality_gate_import_readiness_status_from_summary(summary)
      status -> status
    end
  end

  defp quality_gate_import_readiness_status_from_summary(%{} = summary) do
    cond do
      quality_gate_import_readiness_values(summary["blocked_quality_gate_row_ids"]) != [] or
        positive_report_count?(summary, "blocked_import_count") or
          positive_report_count?(summary, "invalid_cadence_import_count") ->
        "blocked"

      quality_gate_import_readiness_values(summary["analysis_only_quality_gate_row_ids"]) != [] ->
        "analysis_only"

      quality_gate_import_readiness_values(summary["review_required_quality_gate_row_ids"]) != [] or
        quality_gate_import_readiness_values(
          summary["stale_or_unknown_freshness_quality_gate_row_ids"]
        ) != [] or
        quality_gate_import_readiness_values(summary["import_preparation_quality_gate_row_ids"]) !=
          [] or
        positive_report_count?(summary, "manifest_review_required_count") or
        positive_report_count?(summary, "stale_freshness_count") or
          positive_report_count?(summary, "unknown_freshness_count") ->
        "review_required"

      true ->
        "passed"
    end
  end

  defp quality_gate_import_readiness_status_from_row_ids(%{} = row_ids_by_status) do
    cond do
      quality_gate_summary_values(row_ids_by_status, "blocked") != [] -> "blocked"
      quality_gate_summary_values(row_ids_by_status, "analysis_only") != [] -> "analysis_only"
      quality_gate_summary_values(row_ids_by_status, "review_required") != [] -> "review_required"
      true -> "passed"
    end
  end

  defp quality_gate_import_readiness_status_from_row_ids(_row_ids_by_status), do: nil

  defp quality_gate_import_readiness_row_ids(%{} = row_ids_by_status, _summary, status) do
    quality_gate_summary_values(row_ids_by_status, status)
  end

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "passed"),
    do: quality_gate_import_readiness_values(summary["ready_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "review_required"),
    do: quality_gate_import_readiness_values(summary["review_required_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "analysis_only"),
    do: quality_gate_import_readiness_values(summary["analysis_only_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "blocked"),
    do: quality_gate_import_readiness_values(summary["blocked_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_count(_summary, %{} = row_ids_by_status) do
    row_ids_by_status
    |> Map.values()
    |> Enum.flat_map(&quality_gate_import_readiness_values/1)
    |> length()
  end

  defp quality_gate_import_readiness_row_count(summary, _row_ids_by_status),
    do: summary["import_readiness_row_count"] || summary["gate_count"]

  defp quality_gate_import_readiness_gate_ids(summary, status) do
    case quality_gate_summary_values(summary["quality_gate_ids_by_status"], status) do
      [] ->
        if quality_gate_import_readiness_row_ids(
             summary["quality_gate_row_ids_by_status"],
             summary,
             status
           ) == [] do
          []
        else
          summary["import_readiness_gate_ids"] || []
        end

      gate_ids ->
        gate_ids
    end
  end

  defp quality_gate_import_readiness_status_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.map(fn {status, row_ids} ->
      {to_string(status), length(quality_gate_import_readiness_values(row_ids))}
    end)
    |> Enum.reject(fn {_status, count} -> count == 0 end)
    |> Map.new()
  end

  defp quality_gate_import_readiness_status_counts(_row_ids_by_status), do: %{}

  defp quality_gate_import_readiness_classification_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.reduce(%{}, fn {status, row_ids}, counts ->
      classification = quality_gate_import_readiness_classification(to_string(status))
      count = length(quality_gate_import_readiness_values(row_ids))
      Map.update(counts, classification, count, &(&1 + count))
    end)
    |> Enum.reject(fn {_classification, count} -> count == 0 end)
    |> Map.new()
  end

  defp quality_gate_import_readiness_classification_counts(_row_ids_by_status), do: %{}

  defp quality_gate_import_readiness_classification("blocked"), do: "blocked"
  defp quality_gate_import_readiness_classification("analysis_only"), do: "analysis_only"
  defp quality_gate_import_readiness_classification("review_required"), do: "review_only"
  defp quality_gate_import_readiness_classification(_status), do: "importable"

  defp quality_gate_import_readiness_level("blocked"), do: "blocked"
  defp quality_gate_import_readiness_level("analysis_only"), do: "analysis_only"
  defp quality_gate_import_readiness_level("review_only"), do: "operator_review"
  defp quality_gate_import_readiness_level(_classification), do: "import_eligible"

  defp quality_gate_import_readiness_reason("blocked"),
    do: "quality gate import readiness is blocked"

  defp quality_gate_import_readiness_reason("analysis_only"),
    do: "quality gate import readiness is analysis-only"

  defp quality_gate_import_readiness_reason(_status),
    do: "quality gate import readiness requires review"

  defp quality_gate_summary_values(%{} = values_by_key, key) do
    values_by_key
    |> Map.get(key, Map.get(values_by_key, String.to_atom(key), []))
    |> quality_gate_import_readiness_values()
  end

  defp quality_gate_summary_values(_values_by_key, _key), do: []

  defp quality_gate_import_readiness_values(values) when is_list(values), do: values
  defp quality_gate_import_readiness_values(_values), do: []

  defp positive_report_count?(summary, field) do
    case numeric_or_nil(summary[field]) do
      nil -> false
      value -> value > 0
    end
  end

  defp quality_gate_reviewable_row?(%{} = row),
    do: (row["status"] || row["classification"]) not in [nil, "passed", "importable"]

  defp quality_gate_reviewable_row?(_row), do: false

  defp quality_gate_action("analysis_only"), do: "record_quality_gate_analysis_only"
  defp quality_gate_action("blocked"), do: "review_blocked_quality_gate"
  defp quality_gate_action(_classification), do: "review_quality_gate"

  defp quality_gate_approval_status("analysis_only"), do: "not_required"
  defp quality_gate_approval_status("blocked"), do: "blocked_by_policy"
  defp quality_gate_approval_status(_classification), do: "operator_review_required"

  defp quality_gate_cadence_import_status("analysis_only"), do: "not_applicable"
  defp quality_gate_cadence_import_status(_classification), do: "present"

  defp quality_gate_row_import_readiness_context(%{"gate_id" => "cadence_import"} = row) do
    Map.take(row, [
      "ready_for_import_count",
      "manifest_review_required_count",
      "blocked_import_count",
      "missing_import_count",
      "invalid_cadence_import_count",
      "current_freshness_count",
      "stale_freshness_count",
      "unknown_freshness_count",
      "freshness_status_counts",
      "schema_validation_pass_count",
      "schema_validation_fail_count",
      "schema_validation_error_count",
      "schema_validation_warning_count",
      "schema_validation_remediation_count",
      "schema_validation_status_counts",
      "import_status_counts",
      "cadence_import_status_counts"
    ])
  end

  defp quality_gate_row_import_readiness_context(_row), do: %{}

  defp quality_gate_row_resource_context(row) do
    reason_counts = Map.get(row, "resource_availability_reason_counts") || %{}

    %{
      "resource_availability_pressure_count" => row["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" =>
        row["resource_availability_reason_ids"] ||
          operational_readiness_non_empty_list(operational_readiness_count_keys(reason_counts)),
      "station_availability_reason_ids" =>
        row["station_availability_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_station_reason_ids(reason_counts)
          ),
      "station_availability_reason_counts" =>
        row["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        row["unavailable_resource_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_unavailable_reason_ids(reason_counts)
          ),
      "resource_blocking_dimension_counts" => row["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        row["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        row["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => row["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => row["resource_trust_boundary_status_counts"]
    }
  end

  defp quality_gate_row_operator_training_context(%{"gate_id" => "operator_training"} = row) do
    Map.take(row, [
      "operator_training_requirement_count",
      "operator_training_requirement_counts",
      "operator_training_requirement_ids",
      "required_operator_roles",
      "required_training_ids",
      "required_certification_ids",
      "required_qualification_ids"
    ])
  end

  defp quality_gate_row_operator_training_context(_row), do: %{}

  defp quality_gate_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "report_id",
      "source_summary_model",
      "source_summary_schema_contract",
      "source_artifact_type",
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id",
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gate_status_counts",
      "gate_classification_counts",
      "gate_ids_by_status",
      "gate_ids_by_classification",
      "quality_gate_row_ids_by_status",
      "quality_gate_row_ids_by_classification",
      "passed_gate_ids",
      "review_required_gate_ids",
      "analysis_only_gate_ids",
      "blocked_gate_ids",
      "non_passed_quality_gate_row_ids",
      "non_passed_gate_ids",
      "non_passed_gate_count",
      "model_limits",
      "assumptions"
    ])
  end

  defp put_quality_gate_report_summary(package, report) do
    Map.merge(package, quality_gate_report_summary_context(report))
  end

  defp quality_gate_report_summary_context(report) do
    Map.take(report, [
      "source_readiness_report_id",
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gate_status_counts",
      "gate_classification_counts",
      "gate_ids_by_status",
      "gate_ids_by_classification",
      "quality_gate_row_ids_by_status",
      "quality_gate_row_ids_by_classification",
      "passed_gate_ids",
      "review_required_gate_ids",
      "analysis_only_gate_ids",
      "blocked_gate_ids"
    ])
  end

  defp operational_readiness_rows(report, source \\ "operational_readiness_report") do
    classification = report["import_classification"] || "review_only"
    action = operational_readiness_action(classification)

    summary_row =
      %{
        "id" => review_id(["operational_readiness", report["report_id"] || classification]),
        "review_type" => "operational_readiness_review",
        "source" => source,
        "subject_id" =>
          report["report_id"] || report["source_artifact_id"] || "operational_readiness",
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => operational_readiness_approval_status(classification),
        "cadence_import_status" => operational_readiness_cadence_import_status(classification),
        "reason" => operational_readiness_reason(report, classification),
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => report["readiness_level"],
        "import_classification" => classification,
        "operational_readiness_status" => report["status"],
        "gate_count" => report["gate_count"],
        "passed_gate_count" => report["passed_gate_count"],
        "review_gate_count" => report["review_gate_count"],
        "analysis_gate_count" => report["analysis_gate_count"],
        "blocked_gate_count" => report["blocked_gate_count"],
        "gates" => report["gates"],
        "evidence" => report["evidence"],
        "source_operational_readiness_report" => operational_readiness_report_context(report)
      }
      |> Map.merge(operational_readiness_report_resource_context(report))
      |> compact_map()

    [summary_row | operational_readiness_gate_rows(report, source)]
  end

  defp put_operational_readiness_report_summary(package, report) do
    Map.merge(package, operational_readiness_report_summary_context(report))
  end

  defp operational_readiness_report_summary_context(report) do
    report
    |> Map.take([
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count"
    ])
    |> Map.put("source_readiness_report_id", report["report_id"])
    |> compact_map()
  end

  defp operational_readiness_gate_rows(report, source) do
    report
    |> Map.get("gates", [])
    |> Enum.filter(&operational_readiness_reviewable_gate?/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn gate ->
      gate_id = gate["id"] || "operational_gate"
      gate_status = gate["status"] || "review_required"
      classification = gate["classification"] || "review_only"
      action = operational_readiness_gate_action(gate)

      %{
        "id" =>
          review_id([
            "operational_readiness_gate",
            report["report_id"] || report["source_artifact_id"] || "operational_readiness",
            gate_id
          ]),
        "review_type" => "operational_readiness_review",
        "source" => "#{source}.gates",
        "subject_id" =>
          [
            report["report_id"] || report["source_artifact_id"] || "operational_readiness",
            gate_id
          ]
          |> Enum.map(&encode_value/1)
          |> Enum.join(":"),
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => operational_readiness_gate_approval_status(gate),
        "cadence_import_status" => operational_readiness_cadence_import_status(classification),
        "reason" => gate["reason"],
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => readiness_level(classification),
        "import_classification" => classification,
        "operational_readiness_status" => gate_status,
        "readiness_gate_id" => gate_id,
        "readiness_gate_status" => gate_status,
        "readiness_gate_classification" => classification,
        "readiness_gate_reason" => gate["reason"],
        "analysis_mode" => gate["analysis_mode"],
        "analysis_mode_source" => gate["analysis_mode_source"],
        "source_operational_readiness_gate" => gate,
        "source_operational_readiness_report" => operational_readiness_report_context(report)
      }
      |> Map.merge(operational_readiness_gate_context(gate))
      |> compact_map()
    end)
  end

  defp operational_readiness_gate_context(%{"id" => "resource_availability"} = gate) do
    reason_counts = Map.get(gate, "resource_availability_reason_counts") || %{}

    %{
      "resource_availability_pressure_count" => gate["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" =>
        gate["resource_availability_reason_ids"] ||
          operational_readiness_count_keys(reason_counts),
      "station_availability_reason_ids" =>
        gate["station_availability_reason_ids"] ||
          operational_readiness_station_reason_ids(reason_counts),
      "station_availability_reason_counts" =>
        gate["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        gate["unavailable_resource_reason_ids"] ||
          operational_readiness_unavailable_reason_ids(reason_counts),
      "resource_blocking_dimension_counts" => gate["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        gate["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        gate["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => gate["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => gate["resource_trust_boundary_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "cadence_import"} = gate) do
    %{
      "ready_for_import_count" => gate["ready_for_import_count"],
      "manifest_review_required_count" => gate["manifest_review_required_count"],
      "blocked_import_count" => gate["blocked_import_count"],
      "missing_import_count" => gate["missing_import_count"],
      "invalid_cadence_import_count" => gate["invalid_cadence_import_count"],
      "current_freshness_count" => gate["current_freshness_count"],
      "stale_freshness_count" => gate["stale_freshness_count"],
      "unknown_freshness_count" => gate["unknown_freshness_count"],
      "freshness_status_counts" => gate["freshness_status_counts"],
      "schema_validation_pass_count" => gate["schema_validation_pass_count"],
      "schema_validation_fail_count" => gate["schema_validation_fail_count"],
      "schema_validation_error_count" => gate["schema_validation_error_count"],
      "schema_validation_warning_count" => gate["schema_validation_warning_count"],
      "schema_validation_remediation_count" => gate["schema_validation_remediation_count"],
      "schema_validation_status_counts" => gate["schema_validation_status_counts"],
      "import_status_counts" => gate["import_status_counts"],
      "cadence_import_status_counts" => gate["cadence_import_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "adapter_boundary"} = gate) do
    %{
      "adapter_context_count" => gate["adapter_context_count"],
      "adapter_trust_boundary_declared_count" => gate["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" => gate["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" => gate["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" => gate["adapter_boundary_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "operator_training"} = gate) do
    %{
      "operator_training_requirement_count" => gate["operator_training_requirement_count"],
      "operator_training_requirement_counts" => gate["operator_training_requirement_counts"],
      "required_operator_roles" => gate["required_operator_roles"],
      "required_training_ids" => gate["required_training_ids"],
      "required_certification_ids" => gate["required_certification_ids"],
      "required_qualification_ids" => gate["required_qualification_ids"]
    }
  end

  defp operational_readiness_gate_context(_gate), do: %{}

  defp operational_readiness_report_resource_context(report) do
    evidence = Map.get(report, "evidence") || %{}

    reason_counts =
      report["resource_availability_reason_counts"] ||
        evidence["resource_availability_reason_counts"] ||
        %{}

    %{
      "resource_availability_pressure_count" =>
        report["resource_availability_pressure_count"] ||
          evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => non_empty_map(reason_counts),
      "resource_availability_reason_ids" =>
        report["resource_availability_reason_ids"] ||
          evidence["resource_availability_reason_ids"] ||
          operational_readiness_non_empty_list(operational_readiness_count_keys(reason_counts)),
      "station_availability_reason_ids" =>
        report["station_availability_reason_ids"] ||
          evidence["station_availability_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_station_reason_ids(reason_counts)
          ),
      "station_availability_reason_counts" =>
        report["station_availability_reason_counts"] ||
          evidence["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        report["unavailable_resource_reason_ids"] ||
          evidence["unavailable_resource_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_unavailable_reason_ids(reason_counts)
          ),
      "resource_blocking_dimension_counts" =>
        report["resource_blocking_dimension_counts"] ||
          evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        report["resource_blocked_contact_ids_by_blocking_dimension"] ||
          evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        report["resource_blocked_contact_ids_by_spacecraft_id"] ||
          evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" =>
        report["resource_source_quality_counts"] || evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" =>
        report["resource_trust_boundary_status_counts"] ||
          evidence["resource_trust_boundary_status_counts"]
    }
  end

  defp operational_readiness_non_empty_list([_ | _] = values), do: values
  defp operational_readiness_non_empty_list(_values), do: nil

  defp operational_readiness_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.sort()
  end

  defp operational_readiness_count_keys(_counts), do: nil

  defp operational_readiness_unavailable_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in operational_readiness_unavailable_reasons()))
    |> Enum.sort()
  end

  defp operational_readiness_unavailable_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in operational_readiness_station_reasons()))
    |> Enum.sort()
  end

  defp operational_readiness_station_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_counts(counts) when is_map(counts) do
    counts
    |> Enum.filter(fn {reason, count} ->
      reason in operational_readiness_station_reasons() and is_integer(count) and count > 0
    end)
    |> Map.new()
  end

  defp operational_readiness_station_reason_counts(_counts), do: %{}

  defp operational_readiness_unavailable_reasons do
    ~w(
      antenna_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp operational_readiness_station_reasons do
    ~w(
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
    )
  end

  defp operational_readiness_reviewable_gate?(%{} = gate),
    do: (gate["status"] || gate[:status]) not in [nil, "passed"]

  defp operational_readiness_reviewable_gate?(_gate), do: false

  defp operational_readiness_gate_action(%{"classification" => classification}),
    do: operational_readiness_action(classification)

  defp operational_readiness_gate_action(_gate), do: operational_readiness_action("review_only")

  defp operational_readiness_gate_approval_status(%{"classification" => classification}),
    do: operational_readiness_approval_status(classification)

  defp operational_readiness_gate_approval_status(_gate),
    do: operational_readiness_approval_status("review_only")

  defp candidate_refresh_schema_validation_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_schema_validation_report",
         get_in(artifact, ["accepted_planning_state", "source_schema_validation_report"])},
        {"candidate_refresh.accepted_planning_state.schema_validation_report",
         get_in(artifact, ["accepted_planning_state", "schema_validation_report"])},
        {"candidate_refresh.accepted_planning_state.source_schema_validation_batch_report",
         get_in(artifact, ["accepted_planning_state", "source_schema_validation_batch_report"])},
        {"candidate_refresh.accepted_planning_state.schema_validation_batch_report",
         get_in(artifact, ["accepted_planning_state", "schema_validation_batch_report"])},
        {"candidate_refresh.mission_state.source_schema_validation_report",
         get_in(artifact, ["mission_state", "source_schema_validation_report"])},
        {"candidate_refresh.mission_state.schema_validation_report",
         get_in(artifact, ["mission_state", "schema_validation_report"])},
        {"candidate_refresh.mission_state.source_schema_validation_batch_report",
         get_in(artifact, ["mission_state", "source_schema_validation_batch_report"])},
        {"candidate_refresh.mission_state.schema_validation_batch_report",
         get_in(artifact, ["mission_state", "schema_validation_batch_report"])},
        {"candidate_refresh.source_schema_validation_report",
         artifact["source_schema_validation_report"]},
        {"candidate_refresh.schema_validation_report", artifact["schema_validation_report"]},
        {"candidate_refresh.source_schema_validation_batch_report",
         artifact["source_schema_validation_batch_report"]},
        {"candidate_refresh.schema_validation_batch_report",
         artifact["schema_validation_batch_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_schema_validation_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_schema_validation_container_rows(artifact)
  end

  defp source_schema_validation_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_schema_validation_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_schema_validation_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    case report["schema_contract"] do
      "schema_validation_batch_report.v1" ->
        source_schema_validation_batch_report_rows(report, source)

      _contract ->
        schema_validation_rows(report, source)
    end
  end

  defp source_schema_validation_report_rows(_report, _source), do: []

  defp source_schema_validation_batch_report_rows(report, source) do
    report
    |> Map.get("reports", [])
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.flat_map(fn {entry, index} ->
      entry = stringify_keys(entry)

      entry
      |> Map.get("report", %{})
      |> stringify_keys()
      |> Map.put_new("artifact_path", entry["path"])
      |> Map.put("batch_entry_path", entry["path"])
      |> schema_validation_rows("#{source}.reports[#{index}].report")
    end)
  end

  defp candidate_refresh_schema_validation_container_rows(artifact) do
    [
      {:operator_review_package, "candidate_refresh.source_operator_review_package",
       artifact["source_operator_review_package"]},
      {:operator_review_package, "candidate_refresh.operator_review_package",
       artifact["operator_review_package"]},
      {:cadence_import_manifest, "candidate_refresh.source_cadence_import_manifest",
       artifact["source_cadence_import_manifest"]},
      {:cadence_import_manifest, "candidate_refresh.cadence_import_manifest",
       artifact["cadence_import_manifest"]}
    ]
    |> Enum.flat_map(fn {kind, source, package_or_manifest} ->
      schema_validation_container_rows(kind, package_or_manifest, source)
    end)
    |> Kernel.++(candidate_refresh_result_artifact_schema_validation_rows(artifact))
  end

  defp candidate_refresh_result_artifact_schema_validation_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_schema_validation_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_schema_validation_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_schema_validation_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_schema_validation_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_schema_validation_report", artifact["source_schema_validation_report"]},
      {"#{source}.schema_validation_report", artifact["schema_validation_report"]},
      {"#{source}.source_schema_validation_batch_report",
       artifact["source_schema_validation_batch_report"]},
      {"#{source}.schema_validation_batch_report", artifact["schema_validation_batch_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_schema_validation_report_rows(report_or_reports, report_source)
    end)
    |> Kernel.++(
      schema_validation_container_rows(
        :operator_review_package,
        artifact["operator_review_package"],
        "#{source}.operator_review_package"
      )
    )
    |> Kernel.++(
      schema_validation_container_rows(
        :cadence_import_manifest,
        artifact["cadence_import_manifest"],
        "#{source}.cadence_import_manifest"
      )
    )
  end

  defp result_artifact_schema_validation_rows(_artifact, _source), do: []

  defp schema_validation_container_rows(kind, containers, source) when is_list(containers) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      schema_validation_container_rows(kind, container, "#{source}[#{index}]")
    end)
  end

  defp schema_validation_container_rows(:operator_review_package, %{} = package, source) do
    package = stringify_keys(package)

    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "schema_validation_review"))
    |> schema_validation_rows_from_review_or_import_rows(source, package)
  end

  defp schema_validation_container_rows(:cadence_import_manifest, %{} = manifest, source) do
    manifest = stringify_keys(manifest)

    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "schema_validation_review" or
        row["import_action"] == "review_schema_validation"
    end)
    |> schema_validation_rows_from_review_or_import_rows(source, manifest)
  end

  defp schema_validation_container_rows(_kind, _container, _source), do: []

  defp schema_validation_rows_from_review_or_import_rows([], _source, _artifact), do: []

  defp schema_validation_rows_from_review_or_import_rows(rows, source, artifact) do
    report_source = "#{source}.rows.source_schema_validation_report"

    rows
    |> schema_validation_report_from_review_or_import_rows(artifact)
    |> source_schema_validation_report_rows(report_source)
  end

  defp schema_validation_report_from_review_or_import_rows(rows, artifact) do
    report =
      rows
      |> Enum.map(&embedded_schema_validation_report/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [embedded_report | _reports] ->
          stringify_keys(embedded_report)

        [] ->
          schema_validation_report_from_review_or_import_rows(rows)
      end

    artifact = stringify_keys(artifact)

    report
    |> Map.put("source", "preserved_schema_validation_review_rows")
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> compact_map()
  end

  defp schema_validation_report_from_review_or_import_rows(rows) do
    errors =
      rows
      |> Enum.filter(&schema_validation_error_row?/1)
      |> Enum.map(&schema_validation_issue_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    warnings =
      rows
      |> Enum.filter(&schema_validation_warning_row?/1)
      |> Enum.map(&schema_validation_issue_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    remediation =
      rows
      |> Enum.map(&schema_validation_remediation_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "preserved_schema_validation_review_rows",
      "validation_mode" => schema_validation_row_value(rows, ["validation_mode"]),
      "validated_contract" =>
        schema_validation_row_value(rows, ["validated_contract", "subject_id"]),
      "validated_artifact_family" =>
        schema_validation_row_value(rows, ["validated_artifact_family"]),
      "status" => schema_validation_report_status_from_rows(rows),
      "error_count" => length(errors),
      "warning_count" => length(warnings),
      "errors" => errors,
      "warnings" => warnings,
      "artifact_path" => schema_validation_row_value(rows, ["artifact_path"]),
      "remediation_count" => length(remediation),
      "remediation" => remediation
    }
    |> compact_map()
  end

  defp embedded_schema_validation_report(%{} = row) do
    cond do
      is_map(get_in(row, ["source_review_row", "source_schema_validation_report"])) ->
        get_in(row, ["source_review_row", "source_schema_validation_report"])

      is_map(row["source_schema_validation_report"]) ->
        row["source_schema_validation_report"]

      true ->
        nil
    end
  end

  defp schema_validation_report_status_from_rows(rows) do
    cond do
      Enum.any?(rows, &schema_validation_error_row?/1) ->
        "fail"

      status =
          schema_validation_row_value(rows, ["validation_status", "schema_validation_gate_status"]) ->
        status

      true ->
        "fail"
    end
  end

  defp schema_validation_error_row?(row) do
    row["issue_severity"] in [nil, "", "error"] and
      (row["validation_status"] == "fail" or row["schema_validation_gate_status"] == "fail" or
         row["issue_path"] not in [nil, ""] or is_map(row["source_validation_issue"]))
  end

  defp schema_validation_warning_row?(row), do: row["issue_severity"] == "warning"

  defp schema_validation_issue_from_row(row) do
    issue =
      case row["source_validation_issue"] do
        %{} = issue -> stringify_keys(issue)
        _issue -> %{}
      end

    %{
      "path" => issue["path"] || row["issue_path"],
      "message" => issue["message"] || row["issue_message"],
      "severity" => issue["severity"] || row["issue_severity"]
    }
    |> compact_map()
  end

  defp schema_validation_remediation_from_row(row) do
    remediation =
      case row["source_validation_remediation"] do
        %{} = remediation -> stringify_keys(remediation)
        _remediation -> %{}
      end

    %{
      "path" => remediation["path"] || row["issue_path"],
      "category" => remediation["category"] || row["remediation_category"],
      "action" => remediation["action"] || row["remediation_action"]
    }
    |> compact_map()
  end

  defp schema_validation_row_value(rows, keys) do
    rows
    |> Enum.find_value(fn row ->
      Enum.find_value(keys, fn key ->
        value = row[key]
        if value not in [nil, "", []], do: value
      end)
    end)
  end

  defp candidate_refresh_contact_allocation_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_report",
         get_in(artifact, ["accepted_planning_state", "source_contact_allocation_report"])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_report",
         get_in(artifact, ["accepted_planning_state", "contact_allocation_report"])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_summary",
         get_in(artifact, ["accepted_planning_state", "source_contact_allocation_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_summary",
         get_in(artifact, ["accepted_planning_state", "contact_allocation_summary"])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_capacity_pack_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_capacity_pack_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_capacity_pack_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_capacity_pack_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.mission_state.source_contact_allocation_report",
         get_in(artifact, ["mission_state", "source_contact_allocation_report"])},
        {"candidate_refresh.mission_state.contact_allocation_report",
         get_in(artifact, ["mission_state", "contact_allocation_report"])},
        {"candidate_refresh.mission_state.source_contact_allocation_summary",
         get_in(artifact, ["mission_state", "source_contact_allocation_summary"])},
        {"candidate_refresh.mission_state.contact_allocation_summary",
         get_in(artifact, ["mission_state", "contact_allocation_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_station_pressure_summary",
         get_in(artifact, ["mission_state", "contact_allocation_station_pressure_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "mission_state",
           "contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.mission_state.source_contact_allocation_capacity_pack_summary",
         get_in(artifact, ["mission_state", "source_contact_allocation_capacity_pack_summary"])},
        {"candidate_refresh.mission_state.contact_allocation_capacity_pack_summary",
         get_in(artifact, ["mission_state", "contact_allocation_capacity_pack_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "mission_state",
           "contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.source_contact_allocation_report",
         artifact["source_contact_allocation_report"]},
        {"candidate_refresh.contact_allocation_report", artifact["contact_allocation_report"]},
        {"candidate_refresh.source_contact_allocation_summary",
         artifact["source_contact_allocation_summary"]},
        {"candidate_refresh.contact_allocation_summary", artifact["contact_allocation_summary"]},
        {"candidate_refresh.source_contact_allocation_station_pressure_summary",
         artifact["source_contact_allocation_station_pressure_summary"]},
        {"candidate_refresh.contact_allocation_station_pressure_summary",
         artifact["contact_allocation_station_pressure_summary"]},
        {"candidate_refresh.source_contact_allocation_reservation_conflict_summary",
         artifact["source_contact_allocation_reservation_conflict_summary"]},
        {"candidate_refresh.contact_allocation_reservation_conflict_summary",
         artifact["contact_allocation_reservation_conflict_summary"]},
        {"candidate_refresh.source_contact_allocation_capacity_pack_summary",
         artifact["source_contact_allocation_capacity_pack_summary"]},
        {"candidate_refresh.contact_allocation_capacity_pack_summary",
         artifact["contact_allocation_capacity_pack_summary"]},
        {"candidate_refresh.source_contact_allocation_provider_reservation_request_summary",
         artifact["source_contact_allocation_provider_reservation_request_summary"]},
        {"candidate_refresh.contact_allocation_provider_reservation_request_summary",
         artifact["contact_allocation_provider_reservation_request_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_allocation_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_contact_allocation_rows(artifact)
  end

  defp source_contact_allocation_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_allocation_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_allocation_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    cond do
      contact_allocation_review_summary?(report) ->
        contact_allocation_summary_review_rows(report, source)

      provider_reservation_request_summary?(report) ->
        report
        |> source_contact_allocation_report_rows_from_provider_reservation_summary()
        |> contact_allocation_rows("#{source}.provider_reservation_request_rows")

      true ->
        contact_allocation_rows(Map.get(report, "rows", []), "#{source}.rows") ++
          contact_allocation_capacity_pack_rows(
            Map.get(report, "reduced_capacity_pack_groups", []),
            "#{source}.reduced_capacity_pack_groups"
          ) ++
          contact_allocation_station_calendar_provider_contention_rows(report, source)
    end
  end

  defp source_contact_allocation_report_rows(_report, _source), do: []

  defp contact_allocation_summary_review_rows(%{} = summary, source) do
    summary = stringify_keys(summary)

    contact_allocation_summary_contact_review_rows(summary, source) ++
      contact_allocation_summary_capacity_pack_rows(summary, source)
  end

  defp contact_allocation_summary_contact_review_rows(%{} = summary, source) do
    summary_context = contact_allocation_summary_context(summary)
    {rows, row_source} = contact_allocation_summary_review_row_source(summary, source)

    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&put_contact_allocation_summary_context(&1, summary, summary_context))
    |> contact_allocation_rows(row_source)
  end

  defp contact_allocation_summary_capacity_pack_rows(
         %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"} = summary,
         source
       ) do
    summary_context = contact_allocation_summary_context(summary)

    summary
    |> Map.get("reduced_capacity_pack_groups", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn group ->
      group
      |> Map.put("source_contact_allocation_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("source", summary["source"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> contact_allocation_capacity_pack_rows("#{source}.reduced_capacity_pack_groups")
  end

  defp contact_allocation_summary_capacity_pack_rows(_summary, _source), do: []

  defp contact_allocation_summary_review_row_source(
         %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"} = summary,
         source
       ) do
    first_contact_allocation_summary_rows(summary, [
      {"reservation_review_rows", "#{source}.reservation_review_rows"},
      {"reservation_conflict_rows", "#{source}.reservation_conflict_rows"},
      {"review_rows", "#{source}.review_rows"},
      {"rows", "#{source}.rows"}
    ])
  end

  defp contact_allocation_summary_review_row_source(summary, source) do
    first_contact_allocation_summary_rows(summary, [
      {"review_rows", "#{source}.review_rows"},
      {"rows", "#{source}.rows"}
    ])
  end

  defp first_contact_allocation_summary_rows(summary, row_sources) do
    Enum.find_value(row_sources, {[], "contact_allocation_summary.rows"}, fn {field, source} ->
      rows = Map.get(summary, field, [])

      if is_list(rows) and rows != [] do
        {rows, source}
      end
    end)
  end

  defp put_contact_allocation_summary_context(row, summary, summary_context) do
    row
    |> Map.put("source_contact_allocation_summary", summary_context)
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("source", summary["source"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp contact_allocation_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "input_contact_count" => summary["input_contact_count"],
      "allocated_contact_count" => summary["allocated_contact_count"],
      "returned_allocated_contact_count" => summary["returned_allocated_contact_count"],
      "deferred_contact_count" => summary["deferred_contact_count"],
      "blocked_contact_count" => summary["blocked_contact_count"],
      "review_contact_ids" => summary["review_contact_ids"],
      "station_pressure_review_contact_ids" => summary["station_pressure_review_contact_ids"],
      "reservation_review_contact_ids" => summary["reservation_review_contact_ids"],
      "capacity_pack_review_status" => summary["capacity_pack_review_status"],
      "reduced_capacity_pack_group_count" => summary["reduced_capacity_pack_group_count"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp contact_allocation_review_summary?(%{
         "schema_contract" => schema_contract
       })
       when schema_contract in [
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1"
            ],
       do: true

  defp contact_allocation_review_summary?(_summary), do: false

  defp source_contact_allocation_report_rows_from_provider_reservation_summary(%{} = summary) do
    summary = stringify_keys(summary)
    assumptions = stringify_keys(Map.get(summary, "assumptions", %{}))

    summary_context =
      %{
        "model" => summary["model"],
        "schema_contract" => summary["schema_contract"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "provider_reservation_candidate_contact_count" =>
          summary["provider_reservation_candidate_contact_count"],
        "provider_reservation_request_contact_count" =>
          summary["provider_reservation_request_contact_count"],
        "provider_reservation_review_contact_count" =>
          summary["provider_reservation_review_contact_count"],
        "provider_reservation_no_request_contact_count" =>
          summary["provider_reservation_no_request_contact_count"],
        "provider_reservation_request_status" => summary["provider_reservation_request_status"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    request_rows =
      provider_reservation_summary_rows(
        summary["provider_reservation_request_rows"],
        "request_ready",
        summary,
        assumptions,
        summary_context
      )

    review_rows =
      provider_reservation_summary_rows(
        summary["provider_reservation_review_rows"],
        "review_required",
        summary,
        assumptions,
        summary_context
      )

    request_rows ++ review_rows
  end

  defp source_contact_allocation_report_rows_from_provider_reservation_summary(_summary), do: []

  defp provider_reservation_summary_rows(rows, status, summary, assumptions, summary_context) do
    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      row
      |> Map.put("provider_reservation_request_status", status)
      |> Map.put("provider_reservation_request_summary_model", summary["model"])
      |> Map.put(
        "provider_reservation_request_summary_schema_contract",
        summary["schema_contract"]
      )
      |> Map.put(
        "provider_reservation_request_source_artifact_type",
        summary["source_artifact_type"]
      )
      |> Map.put("provider_reservation_request_source", summary["source"])
      |> Map.put(
        "provider_reservation_request_execution_boundary",
        assumptions["execution_boundary"]
      )
      |> Map.put("provider_reservation_execution", assumptions["provider_reservation_execution"])
      |> Map.put("source_provider_reservation_request_summary", summary_context)
      |> compact_map()
    end)
  end

  defp provider_reservation_request_summary?(%{
         "model" => "artifact_only_contact_allocation_provider_reservation_request_summary"
       }),
       do: true

  defp provider_reservation_request_summary?(_summary), do: false

  defp candidate_refresh_result_artifact_contact_allocation_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_allocation_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_allocation_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_allocation_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_allocation_rows(
         %{"schema_contract" => "contact_allocation_report.v1"} = report,
         source
       ) do
    source_contact_allocation_report_rows(report, source)
  end

  defp result_artifact_contact_allocation_rows(
         %{"schema_contract" => schema_contract} = summary,
         source
       )
       when schema_contract in [
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1",
              "contact_allocation_provider_reservation_request_summary.v1"
            ] do
    source_contact_allocation_report_rows(summary, source)
  end

  defp result_artifact_contact_allocation_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_allocation_report",
       artifact["source_contact_allocation_report"]},
      {"#{source}.contact_allocation_report", artifact["contact_allocation_report"]},
      {"#{source}.source_contact_allocation_summary",
       artifact["source_contact_allocation_summary"]},
      {"#{source}.contact_allocation_summary", artifact["contact_allocation_summary"]},
      {"#{source}.source_contact_allocation_station_pressure_summary",
       artifact["source_contact_allocation_station_pressure_summary"]},
      {"#{source}.contact_allocation_station_pressure_summary",
       artifact["contact_allocation_station_pressure_summary"]},
      {"#{source}.source_contact_allocation_reservation_conflict_summary",
       artifact["source_contact_allocation_reservation_conflict_summary"]},
      {"#{source}.contact_allocation_reservation_conflict_summary",
       artifact["contact_allocation_reservation_conflict_summary"]},
      {"#{source}.source_contact_allocation_capacity_pack_summary",
       artifact["source_contact_allocation_capacity_pack_summary"]},
      {"#{source}.contact_allocation_capacity_pack_summary",
       artifact["contact_allocation_capacity_pack_summary"]},
      {"#{source}.source_contact_allocation_provider_reservation_request_summary",
       artifact["source_contact_allocation_provider_reservation_request_summary"]},
      {"#{source}.contact_allocation_provider_reservation_request_summary",
       artifact["contact_allocation_provider_reservation_request_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_allocation_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_contact_allocation_rows(_artifact, _source), do: []

  defp candidate_refresh_link_capacity_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_link_capacity_report",
         get_in(artifact, ["accepted_planning_state", "source_link_capacity_report"])},
        {"candidate_refresh.accepted_planning_state.link_capacity_report",
         get_in(artifact, ["accepted_planning_state", "link_capacity_report"])},
        {"candidate_refresh.accepted_planning_state.source_link_capacity_summary",
         get_in(artifact, ["accepted_planning_state", "source_link_capacity_summary"])},
        {"candidate_refresh.accepted_planning_state.link_capacity_summary",
         get_in(artifact, ["accepted_planning_state", "link_capacity_summary"])},
        {"candidate_refresh.accepted_planning_state.source_relay_data_path_summary",
         get_in(artifact, ["accepted_planning_state", "source_relay_data_path_summary"])},
        {"candidate_refresh.accepted_planning_state.relay_data_path_summary",
         get_in(artifact, ["accepted_planning_state", "relay_data_path_summary"])},
        {"candidate_refresh.mission_state.source_link_capacity_report",
         get_in(artifact, ["mission_state", "source_link_capacity_report"])},
        {"candidate_refresh.mission_state.link_capacity_report",
         get_in(artifact, ["mission_state", "link_capacity_report"])},
        {"candidate_refresh.mission_state.source_link_capacity_summary",
         get_in(artifact, ["mission_state", "source_link_capacity_summary"])},
        {"candidate_refresh.mission_state.link_capacity_summary",
         get_in(artifact, ["mission_state", "link_capacity_summary"])},
        {"candidate_refresh.mission_state.source_relay_data_path_summary",
         get_in(artifact, ["mission_state", "source_relay_data_path_summary"])},
        {"candidate_refresh.mission_state.relay_data_path_summary",
         get_in(artifact, ["mission_state", "relay_data_path_summary"])},
        {"candidate_refresh.source_link_capacity_report",
         artifact["source_link_capacity_report"]},
        {"candidate_refresh.link_capacity_report", artifact["link_capacity_report"]},
        {"candidate_refresh.source_link_capacity_summary",
         artifact["source_link_capacity_summary"]},
        {"candidate_refresh.link_capacity_summary", artifact["link_capacity_summary"]},
        {"candidate_refresh.source_relay_data_path_summary",
         artifact["source_relay_data_path_summary"]},
        {"candidate_refresh.relay_data_path_summary", artifact["relay_data_path_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_link_capacity_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_link_capacity_rows(artifact)
  end

  defp source_link_capacity_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_link_capacity_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_link_capacity_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if link_capacity_summary?(report) or relay_data_path_summary?(report) do
      source_link_capacity_summary_rows(report, source)
    else
      link_capacity_report_rows(report, source)
    end
  end

  defp source_link_capacity_report_rows(_report, _source), do: []

  defp source_link_capacity_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = link_capacity_summary_context(summary)

    summary
    |> link_capacity_summary_review_rows()
    |> Enum.map(fn row ->
      row
      |> Map.put("source_link_capacity_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> link_capacity_rows("#{source}.rows")
  end

  defp link_capacity_summary_review_rows(%{"rows" => rows}) when is_list(rows) and rows != [] do
    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp link_capacity_summary_review_rows(%{} = summary) do
    summary
    |> Map.get("ground_station_ids", [])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.map(fn station_id ->
      selected_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "selected_contact_ids")

      actual_throughput_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "actual_throughput_contact_ids")

      required_downlink_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "required_downlink_contact_ids")

      contact_ids =
        [selected_contact_ids, actual_throughput_contact_ids, required_downlink_contact_ids]
        |> List.flatten()
        |> Enum.uniq()

      %{
        "ground_station_id" => station_id,
        "contact_count" => length(contact_ids),
        "contact_ids" => contact_ids,
        "selected_contact_count" => length(selected_contact_ids),
        "selected_contact_ids" => selected_contact_ids,
        "actual_throughput_contact_count" => length(actual_throughput_contact_ids),
        "actual_throughput_contact_ids" => actual_throughput_contact_ids,
        "required_downlink_contact_count" => length(required_downlink_contact_ids),
        "required_downlink_contact_ids" => required_downlink_contact_ids,
        "selected_downlink_shortfall_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "selected_downlink_shortfall_mb"
          ),
        "actual_downlink_shortfall_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "actual_downlink_shortfall_mb"
          ),
        "capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "capacity_adjusted_throughput_mb"
          ),
        "selected_capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "selected_capacity_adjusted_throughput_mb"
          ),
        "unused_capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "unused_capacity_adjusted_throughput_mb"
          ),
        "downlink_requirement_status" =>
          link_capacity_summary_shortfall_status(
            summary,
            station_id,
            "shortfall_ground_station_ids"
          ),
        "actual_downlink_requirement_status" =>
          link_capacity_summary_shortfall_status(
            summary,
            station_id,
            "actual_shortfall_ground_station_ids"
          ),
        "station_calendar_entry_ids" =>
          link_capacity_summary_station_ids(summary, station_id, "station_calendar_entry_ids"),
        "station_calendar_provider_entry_ids" =>
          link_capacity_summary_station_ids(
            summary,
            station_id,
            "station_calendar_provider_entry_ids"
          ),
        "station_reservation_ids" =>
          link_capacity_summary_station_ids(summary, station_id, "station_reservation_ids")
      }
      |> compact_map()
    end)
  end

  defp link_capacity_summary_station_ids(summary, station_id, field) do
    map_field = "#{field}_by_ground_station_id"

    summary
    |> Map.get(map_field, %{})
    |> Map.get(station_id, [])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp link_capacity_summary_station_number(summary, station_id, field) do
    map_field = "#{field}_by_ground_station_id"

    summary
    |> Map.get(map_field, %{})
    |> Map.get(station_id)
  end

  defp link_capacity_summary_shortfall_status(summary, station_id, field) do
    if station_id in Map.get(summary, field, []) do
      "shortfall"
    end
  end

  defp link_capacity_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "route_count" => summary["route_count"],
      "relay_route_count" => summary["relay_route_count"],
      "direct_downlink_route_count" => summary["direct_downlink_route_count"],
      "route_ids" => summary["route_ids"],
      "route_ids_by_ground_station_id" => summary["route_ids_by_ground_station_id"],
      "route_ids_by_latency_status" => summary["route_ids_by_latency_status"],
      "route_ids_by_risk_status" => summary["route_ids_by_risk_status"],
      "route_ids_by_custody_status" => summary["route_ids_by_custody_status"],
      "source_spacecraft_ids" => summary["source_spacecraft_ids"],
      "relay_spacecraft_ids" => summary["relay_spacecraft_ids"],
      "ground_downlink_contact_ids" => summary["ground_downlink_contact_ids"],
      "custody_status_counts" => summary["custody_status_counts"],
      "latency_status_counts" => summary["latency_status_counts"],
      "risk_status_counts" => summary["risk_status_counts"],
      "station_count" => summary["station_count"],
      "contact_count" => summary["contact_count"],
      "selected_contact_count" => summary["selected_contact_count"],
      "selected_downlink_shortfall_mb" => summary["selected_downlink_shortfall_mb"],
      "actual_downlink_shortfall_mb" => summary["actual_downlink_shortfall_mb"],
      "capacity_adjusted_throughput_mb" => summary["capacity_adjusted_throughput_mb"],
      "selected_capacity_adjusted_throughput_mb" =>
        summary["selected_capacity_adjusted_throughput_mb"],
      "unused_capacity_adjusted_throughput_mb" =>
        summary["unused_capacity_adjusted_throughput_mb"],
      "selected_contact_ids" => summary["selected_contact_ids"],
      "actual_throughput_contact_ids" => summary["actual_throughput_contact_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp link_capacity_summary?(%{"schema_contract" => "link_capacity_summary.v1"}), do: true
  defp link_capacity_summary?(_report), do: false

  defp relay_data_path_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["route_count"]) and
      (summary["model"] == "artifact_only_relay_data_path_summary" or
         summary["schema_contract"] == "relay_data_path_summary.v1")
  end

  defp candidate_refresh_result_artifact_link_capacity_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_link_capacity_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_link_capacity_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_link_capacity_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_link_capacity_rows(
         %{"schema_contract" => "link_capacity_report.v1"} = report,
         source
       ) do
    source_link_capacity_report_rows(report, source)
  end

  defp result_artifact_link_capacity_rows(
         %{"schema_contract" => "link_capacity_summary.v1"} = summary,
         source
       ) do
    source_link_capacity_report_rows(summary, source)
  end

  defp result_artifact_link_capacity_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_link_capacity_report", artifact["source_link_capacity_report"]},
      {"#{source}.link_capacity_report", artifact["link_capacity_report"]},
      {"#{source}.source_link_capacity_summary", artifact["source_link_capacity_summary"]},
      {"#{source}.link_capacity_summary", artifact["link_capacity_summary"]},
      {"#{source}.source_relay_data_path_summary", artifact["source_relay_data_path_summary"]},
      {"#{source}.relay_data_path_summary", artifact["relay_data_path_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_link_capacity_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_link_capacity_rows(_artifact, _source), do: []

  defp candidate_refresh_contact_filter_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_contact_filter_report",
         artifact["source_contact_filter_report"]},
        {"candidate_refresh.contact_filter_report", artifact["contact_filter_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_filter_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_contact_filter_rows(artifact)
  end

  defp source_contact_filter_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_filter_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_filter_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("suppressed_candidates", [])
    |> contact_suppression_rows("#{source}.suppressed_candidates")
  end

  defp source_contact_filter_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_contact_filter_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_filter_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_filter_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_filter_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_filter_rows(
         %{"schema_contract" => "contact_filter_report.v1"} = report,
         source
       ) do
    source_contact_filter_report_rows(report, source)
  end

  defp result_artifact_contact_filter_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_filter_report", artifact["source_contact_filter_report"]},
      {"#{source}.contact_filter_report", artifact["contact_filter_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_filter_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_contact_filter_rows(_artifact, _source), do: []

  defp candidate_refresh_resource_filter_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_resource_filter_report",
         artifact["source_resource_filter_report"]},
        {"candidate_refresh.resource_filter_report", artifact["resource_filter_report"]},
        {"candidate_refresh.source_resource_filter_summary",
         artifact["source_resource_filter_summary"]},
        {"candidate_refresh.resource_filter_summary", artifact["resource_filter_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_resource_filter_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_resource_filter_rows(artifact)
  end

  defp source_resource_filter_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_resource_filter_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_resource_filter_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if resource_filter_summary?(report) do
      source_resource_filter_summary_rows(report, source)
    else
      resource_filter_invalid_summary_rows(
        Map.get(report, "invalid_resource_summary_inputs", []),
        "#{source}.invalid_resource_summary_inputs"
      ) ++
        resource_suppression_rows(
          Map.get(report, "suppressed_candidates", []),
          "#{source}.suppressed_candidates"
        )
    end
  end

  defp source_resource_filter_report_rows(_report, _source), do: []

  defp source_resource_filter_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = resource_filter_summary_context(summary)

    invalid_summary_rows =
      summary
      |> Map.get("invalid_resource_summary_inputs", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&put_resource_filter_summary_context(&1, summary, summary_context))
      |> resource_filter_invalid_summary_rows("#{source}.invalid_resource_summary_inputs")

    suppression_rows =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&put_resource_filter_summary_context(&1, summary, summary_context))
      |> resource_suppression_rows("#{source}.review_rows")

    invalid_summary_rows ++ suppression_rows
  end

  defp resource_filter_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "input_candidate_count" => summary["input_candidate_count"],
      "kept_candidate_count" => summary["kept_candidate_count"],
      "suppressed_candidate_count" => summary["suppressed_candidate_count"],
      "invalid_resource_summary_input_count" => summary["invalid_resource_summary_input_count"],
      "suppression_review_status" => summary["suppression_review_status"],
      "suppressed_candidate_ids" => summary["suppressed_candidate_ids"],
      "invalid_resource_summary_input_ids" => summary["invalid_resource_summary_input_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp put_resource_filter_summary_context(row, summary, summary_context) do
    row
    |> Map.put("source_resource_filter_summary", summary_context)
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp resource_filter_summary?(%{"schema_contract" => "resource_filter_summary.v1"}),
    do: true

  defp resource_filter_summary?(_report), do: false

  defp candidate_refresh_result_artifact_resource_filter_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_resource_filter_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_resource_filter_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_resource_filter_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_resource_filter_rows(
         %{"schema_contract" => "resource_filter_report.v1"} = report,
         source
       ) do
    source_resource_filter_report_rows(report, source)
  end

  defp result_artifact_resource_filter_rows(
         %{"schema_contract" => "resource_filter_summary.v1"} = summary,
         source
       ) do
    source_resource_filter_report_rows(summary, source)
  end

  defp result_artifact_resource_filter_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_resource_filter_report", artifact["source_resource_filter_report"]},
      {"#{source}.resource_filter_report", artifact["resource_filter_report"]},
      {"#{source}.source_resource_filter_summary", artifact["source_resource_filter_summary"]},
      {"#{source}.resource_filter_summary", artifact["resource_filter_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_resource_filter_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_resource_filter_rows(_artifact, _source), do: []

  defp candidate_refresh_resource_projection_rows(artifact) do
    report_rows =
      [
        {"candidate_refresh.source_resource_projection_report",
         artifact["source_resource_projection_report"]},
        {"candidate_refresh.resource_projection_report", artifact["resource_projection_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_resource_projection_report_rows(report_or_reports, source)
      end)

    flow_summary_rows =
      [
        {"candidate_refresh.source_resource_projection_flow_summary",
         artifact["source_resource_projection_flow_summary"]},
        {"candidate_refresh.resource_projection_flow_summary",
         artifact["resource_projection_flow_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_resource_projection_flow_summary_rows(summary_or_summaries, source)
      end)

    report_rows ++
      flow_summary_rows ++ candidate_refresh_result_artifact_resource_projection_rows(artifact)
  end

  defp source_resource_projection_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_resource_projection_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_resource_projection_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    resource_projection_invalid_activity_rows(
      Map.get(report, "invalid_activity_inputs", []),
      "#{source}.invalid_activity_inputs"
    ) ++
      resource_projection_invalid_summary_rows(
        Map.get(report, "invalid_resource_summary_inputs", []),
        "#{source}.invalid_resource_summary_inputs"
      ) ++
      resource_projection_rows(
        Map.get(report, "projected_resources", []),
        "#{source}.projected_resources"
      )
  end

  defp source_resource_projection_report_rows(_report, _source), do: []

  defp source_resource_projection_flow_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_resource_projection_flow_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_resource_projection_flow_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> resource_projection_flow_summary_rows("#{source}.projected_resources")
  end

  defp source_resource_projection_flow_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_resource_projection_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_resource_projection_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_resource_projection_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_resource_projection_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_resource_projection_rows(
         %{"schema_contract" => "resource_projection_report.v1"} = report,
         source
       ) do
    source_resource_projection_report_rows(report, source)
  end

  defp result_artifact_resource_projection_rows(
         %{"schema_contract" => "resource_projection_flow_summary.v1"} = summary,
         source
       ) do
    source_resource_projection_flow_summary_rows(summary, source)
  end

  defp result_artifact_resource_projection_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {:report, "#{source}.source_resource_projection_report",
       artifact["source_resource_projection_report"]},
      {:report, "#{source}.resource_projection_report", artifact["resource_projection_report"]},
      {:flow_summary, "#{source}.source_resource_projection_flow_summary",
       artifact["source_resource_projection_flow_summary"]},
      {:flow_summary, "#{source}.resource_projection_flow_summary",
       artifact["resource_projection_flow_summary"]}
    ]
    |> Enum.flat_map(fn
      {:report, report_source, report_or_reports} ->
        source_resource_projection_report_rows(report_or_reports, report_source)

      {:flow_summary, summary_source, summary_or_summaries} ->
        source_resource_projection_flow_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_resource_projection_rows(_artifact, _source), do: []

  defp candidate_refresh_provider_counteroffer_rows(artifact) do
    report_rows =
      [
        {"candidate_refresh.source_provider_counteroffer_report",
         artifact["source_provider_counteroffer_report"]},
        {"candidate_refresh.provider_counteroffer_report",
         artifact["provider_counteroffer_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_provider_counteroffer_report_rows(report_or_reports, source)
      end)

    plan_impact_rows =
      [
        {"candidate_refresh.source_provider_counteroffer_review_summary",
         artifact["source_provider_counteroffer_review_summary"], "review_rows"},
        {"candidate_refresh.provider_counteroffer_review_summary",
         artifact["provider_counteroffer_review_summary"], "review_rows"},
        {"candidate_refresh.source_provider_counteroffer_import_readiness_summary",
         artifact["source_provider_counteroffer_import_readiness_summary"],
         "import_readiness_rows"},
        {"candidate_refresh.provider_counteroffer_import_readiness_summary",
         artifact["provider_counteroffer_import_readiness_summary"], "import_readiness_rows"},
        {"candidate_refresh.source_provider_counteroffer_plan_impact_summary",
         artifact["source_provider_counteroffer_plan_impact_summary"], "impact_rows"},
        {"candidate_refresh.provider_counteroffer_plan_impact_summary",
         artifact["provider_counteroffer_plan_impact_summary"], "impact_rows"}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries, row_key} ->
        source_provider_counteroffer_summary_rows(summary_or_summaries, source, row_key)
      end)

    report_rows ++
      plan_impact_rows ++ candidate_refresh_result_artifact_provider_counteroffer_rows(artifact)
  end

  defp source_provider_counteroffer_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_provider_counteroffer_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_provider_counteroffer_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> provider_counteroffer_rows("#{source}.rows")
  end

  defp source_provider_counteroffer_report_rows(_report, _source), do: []

  defp source_provider_counteroffer_summary_rows(summaries, source, row_key)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_provider_counteroffer_summary_rows(summary, "#{source}[#{index}]", row_key)
    end)
  end

  defp source_provider_counteroffer_summary_rows(%{} = summary, source, row_key) do
    summary = stringify_keys(summary)

    summary
    |> Map.get(row_key, [])
    |> Enum.map(&provider_counteroffer_summary_row(&1, summary))
    |> provider_counteroffer_rows("#{source}.#{row_key}")
  end

  defp source_provider_counteroffer_summary_rows(_summary, _source, _row_key), do: []

  defp provider_counteroffer_summary_row(%{} = row, %{} = summary) do
    row
    |> stringify_keys()
    |> Map.put(
      "source_provider_counteroffer_summary",
      provider_counteroffer_summary_context(summary)
    )
  end

  defp provider_counteroffer_summary_row(row, _summary), do: row

  defp provider_counteroffer_summary_context(%{} = summary) do
    summary
    |> Map.take([
      "model",
      "schema_contract",
      "source",
      "source_artifact_type",
      "source_artifact_id",
      "counteroffer_count",
      "reviewable_count",
      "review_counteroffer_ids",
      "counteroffer_review_status",
      "import_readiness_status",
      "import_classification",
      "provider_counteroffer_import_status_counts",
      "required_import_action_counts",
      "plan_impact_status",
      "counteroffer_lock_deadline_status_counts",
      "counteroffer_ids_by_lock_deadline_status",
      "assumptions"
    ])
    |> compact_map()
  end

  defp candidate_refresh_result_artifact_provider_counteroffer_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_provider_counteroffer_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_provider_counteroffer_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_provider_counteroffer_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_provider_counteroffer_rows(
         %{"schema_contract" => "provider_counteroffer_report.v1"} = report,
         source
       ) do
    source_provider_counteroffer_report_rows(report, source)
  end

  defp result_artifact_provider_counteroffer_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {:report, "#{source}.source_provider_counteroffer_report",
       artifact["source_provider_counteroffer_report"]},
      {:report, "#{source}.provider_counteroffer_report",
       artifact["provider_counteroffer_report"]},
      {:summary, "#{source}.source_provider_counteroffer_review_summary",
       artifact["source_provider_counteroffer_review_summary"], "review_rows"},
      {:summary, "#{source}.provider_counteroffer_review_summary",
       artifact["provider_counteroffer_review_summary"], "review_rows"},
      {:summary, "#{source}.source_provider_counteroffer_import_readiness_summary",
       artifact["source_provider_counteroffer_import_readiness_summary"],
       "import_readiness_rows"},
      {:summary, "#{source}.provider_counteroffer_import_readiness_summary",
       artifact["provider_counteroffer_import_readiness_summary"], "import_readiness_rows"},
      {:summary, "#{source}.source_provider_counteroffer_plan_impact_summary",
       artifact["source_provider_counteroffer_plan_impact_summary"], "impact_rows"},
      {:summary, "#{source}.provider_counteroffer_plan_impact_summary",
       artifact["provider_counteroffer_plan_impact_summary"], "impact_rows"}
    ]
    |> Enum.flat_map(fn
      {:report, report_source, report_or_reports} ->
        source_provider_counteroffer_report_rows(report_or_reports, report_source)

      {:summary, summary_source, summary_or_summaries, row_key} ->
        source_provider_counteroffer_summary_rows(
          summary_or_summaries,
          summary_source,
          row_key
        )
    end)
  end

  defp result_artifact_provider_counteroffer_rows(_artifact, _source), do: []

  defp candidate_refresh_station_calendar_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_station_calendar_report",
         artifact["source_station_calendar_report"]},
        {"candidate_refresh.station_calendar_report", artifact["station_calendar_report"]},
        {"candidate_refresh.accepted_planning_state.source_station_calendar_precedence_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.station_calendar_precedence_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.mission_state.source_station_calendar_precedence_summary",
         get_in(artifact, [
           "mission_state",
           "source_station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.mission_state.station_calendar_precedence_summary",
         get_in(artifact, [
           "mission_state",
           "station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.source_station_calendar_precedence_summary",
         artifact["source_station_calendar_precedence_summary"]},
        {"candidate_refresh.station_calendar_precedence_summary",
         artifact["station_calendar_precedence_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_station_calendar_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_station_calendar_rows(artifact)
  end

  defp source_station_calendar_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_station_calendar_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_station_calendar_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if station_calendar_precedence_summary?(report) do
      station_calendar_precedence_summary_rows(report, source)
    else
      station_calendar_rows(
        Map.get(report, "affected_contacts", []),
        "#{source}.affected_contacts"
      ) ++
        station_calendar_provider_contention_rows(
          Map.get(report, "provider_calendar_contention_groups", []),
          "#{source}.provider_calendar_contention_groups"
        )
    end
  end

  defp source_station_calendar_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_station_calendar_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_station_calendar_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_station_calendar_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_station_calendar_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_station_calendar_rows(
         %{"schema_contract" => "station_calendar_report.v1"} = report,
         source
       ) do
    source_station_calendar_report_rows(report, source)
  end

  defp result_artifact_station_calendar_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_station_calendar_report", artifact["source_station_calendar_report"]},
      {"#{source}.station_calendar_report", artifact["station_calendar_report"]},
      {"#{source}.source_station_calendar_precedence_summary",
       artifact["source_station_calendar_precedence_summary"]},
      {"#{source}.station_calendar_precedence_summary",
       artifact["station_calendar_precedence_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_station_calendar_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_station_calendar_rows(_artifact, _source), do: []

  defp candidate_refresh_station_reservation_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_station_reservation_report",
         artifact["source_station_reservation_report"]},
        {"candidate_refresh.station_reservation_report", artifact["station_reservation_report"]},
        {"candidate_refresh.source_station_reservation_review_summary",
         artifact["source_station_reservation_review_summary"]},
        {"candidate_refresh.station_reservation_review_summary",
         artifact["station_reservation_review_summary"]},
        {"candidate_refresh.source_station_reservation_hold_summary",
         artifact["source_station_reservation_hold_summary"]},
        {"candidate_refresh.station_reservation_hold_summary",
         artifact["station_reservation_hold_summary"]},
        {"candidate_refresh.source_station_reservation_hold_import_readiness_summary",
         artifact["source_station_reservation_hold_import_readiness_summary"]},
        {"candidate_refresh.station_reservation_hold_import_readiness_summary",
         artifact["station_reservation_hold_import_readiness_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_station_reservation_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_station_reservation_rows(artifact)
  end

  defp source_station_reservation_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_station_reservation_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_station_reservation_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    cond do
      station_reservation_review_summary?(report) ->
        source_station_reservation_report_rows_from_summary(report, source)

      station_reservation_hold_summary?(report) ->
        source_station_reservation_report_rows_from_summary(report, source)

      station_reservation_hold_import_readiness_summary?(report) ->
        source_station_reservation_report_rows_from_hold_import_readiness_summary(report, source)

      station_reservation_report?(report) ->
        station_reservation_rows(
          Map.get(report, "affected_contacts", []),
          "#{source}.affected_contacts"
        ) ++
          station_reservation_provider_contention_rows(
            Map.get(report, "provider_calendar_contention_groups", []),
            "#{source}.provider_calendar_contention_groups"
          )

      true ->
        []
    end
  end

  defp source_station_reservation_report_rows(_report, _source), do: []

  defp source_station_reservation_report_rows_from_summary(%{} = summary, source) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&station_reservation_summary_row(&1, summary))
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    station_reservation_rows(
      affected_rows,
      "#{source}.review_rows.affected_contacts"
    ) ++
      station_reservation_provider_contention_rows(
        provider_rows,
        "#{source}.review_rows.provider_calendar_contention_groups"
      )
  end

  defp station_reservation_summary_row(%{} = row, %{} = summary) do
    reservation_ids = Map.get(row, "reservation_ids", [])
    reservation_statuses = Map.get(row, "reservation_statuses", [])
    reserved_by = Map.get(row, "reserved_by", [])
    reservation_expires_at_s = Map.get(row, "reservation_expires_at_s", [])

    summary_context =
      %{
        "model" => summary["model"],
        "schema_contract" => summary["schema_contract"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "reservation_review_status" => summary["reservation_review_status"],
        "reservation_hold_count" => summary["reservation_hold_count"],
        "reservation_hold_review_status" => summary["reservation_hold_review_status"],
        "reservation_hold_expiration_count" => summary["reservation_hold_expiration_count"],
        "earliest_reservation_hold_expires_at_s" =>
          summary["earliest_reservation_hold_expires_at_s"],
        "reservation_hold_expiration_status_counts" =>
          summary["reservation_hold_expiration_status_counts"],
        "reservation_hold_status_counts" => summary["reservation_hold_status_counts"],
        "reservation_hold_ids" => summary["reservation_hold_ids"],
        "reservation_hold_ids_by_expiration_status" =>
          summary["reservation_hold_ids_by_expiration_status"],
        "reservation_hold_ids_by_status" => summary["reservation_hold_ids_by_status"],
        "reservation_hold_ids_by_reserved_by" => summary["reservation_hold_ids_by_reserved_by"],
        "reservation_hold_ids_by_row_type" => summary["reservation_hold_ids_by_row_type"],
        "reservation_hold_contact_ids_by_expiration_status" =>
          summary["reservation_hold_contact_ids_by_expiration_status"],
        "review_contact_ids" => summary["review_contact_ids"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    row
    |> Map.put_new("id", station_reservation_summary_row_id(row))
    |> Map.put_new("station_calendar_reservation_ids", reservation_ids)
    |> Map.put_new("station_calendar_reservation_statuses", reservation_statuses)
    |> Map.put_new("station_calendar_reserved_by", reserved_by)
    |> Map.put_new("station_calendar_reservation_expires_at_s", reservation_expires_at_s)
    |> Map.put_new("station_calendar_reservation_overlap_count", length(reservation_ids))
    |> Map.put_new("station_reservation_id", List.first(reservation_ids))
    |> Map.put_new("station_reserved_by", List.first(reserved_by))
    |> Map.put_new("station_reservation_status", List.first(reservation_statuses))
    |> Map.put_new("station_reservation_expires_at_s", List.first(reservation_expires_at_s))
    |> Map.put("station_reservation_summary_model", summary["model"])
    |> Map.put("station_reservation_summary_schema_contract", summary["schema_contract"])
    |> Map.put("station_reservation_summary_source", summary["source"])
    |> Map.put(
      "station_reservation_summary_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> Map.put("station_reservation_hold_count", summary["reservation_hold_count"])
    |> Map.put("station_reservation_hold_ids", summary["reservation_hold_ids"])
    |> Map.put(
      "station_reservation_hold_contact_ids_by_expiration_status",
      summary["reservation_hold_contact_ids_by_expiration_status"]
    )
    |> Map.put("source_station_reservation_summary", summary_context)
    |> compact_map()
  end

  defp station_reservation_summary_row_id(%{} = row) do
    review_id([
      "station_reservation_summary",
      row["reservation_review_row_type"],
      row["contact_id"] || row["ground_station_id"],
      List.first(List.wrap(row["reservation_ids"]))
    ])
  end

  defp source_station_reservation_report_rows_from_hold_import_readiness_summary(
         %{} = summary,
         source
       ) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("import_readiness_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&station_reservation_hold_import_readiness_row(&1, summary))
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    station_reservation_rows(
      affected_rows,
      "#{source}.import_readiness_rows.affected_contacts"
    ) ++
      station_reservation_provider_contention_rows(
        provider_rows,
        "#{source}.import_readiness_rows.provider_calendar_contention_groups"
      )
  end

  defp station_reservation_hold_import_readiness_row(%{} = row, %{} = summary) do
    assumptions = stringify_keys(Map.get(summary, "assumptions", %{}))
    reservation_ids = Map.get(row, "reservation_ids", [])
    reservation_statuses = Map.get(row, "reservation_statuses", [])
    reserved_by = Map.get(row, "reserved_by", [])

    summary_context =
      %{
        "model" => summary["model"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "reservation_hold_count" => summary["reservation_hold_count"],
        "import_readiness_status" => summary["import_readiness_status"],
        "import_classification" => summary["import_classification"],
        "ready_for_import_count" => summary["ready_for_import_count"],
        "review_required_before_import_count" => summary["review_required_before_import_count"],
        "no_import_required_count" => summary["no_import_required_count"],
        "reservation_hold_import_status_counts" =>
          summary["reservation_hold_import_status_counts"],
        "required_import_action_counts" => summary["required_import_action_counts"],
        "reservation_hold_ids" => summary["reservation_hold_ids"],
        "reservation_hold_ids_by_import_status" =>
          summary["reservation_hold_ids_by_import_status"],
        "reservation_hold_ids_by_required_import_action" =>
          summary["reservation_hold_ids_by_required_import_action"],
        "reservation_hold_contact_ids_by_import_status" =>
          summary["reservation_hold_contact_ids_by_import_status"],
        "reservation_hold_contact_ids_by_expiration_status" =>
          summary["reservation_hold_contact_ids_by_expiration_status"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    row
    |> Map.put_new("id", station_reservation_hold_import_readiness_row_id(row))
    |> Map.put_new("station_calendar_reservation_ids", reservation_ids)
    |> Map.put_new("station_calendar_reservation_statuses", reservation_statuses)
    |> Map.put_new("station_calendar_reserved_by", reserved_by)
    |> Map.put_new("station_calendar_reservation_overlap_count", length(reservation_ids))
    |> Map.put_new("station_reservation_id", List.first(reservation_ids))
    |> Map.put_new("station_reserved_by", List.first(reserved_by))
    |> Map.put_new("station_reservation_status", List.first(reservation_statuses))
    |> Map.put("station_reservation_hold_import_readiness_summary_model", summary["model"])
    |> Map.put("station_reservation_hold_import_readiness_source", summary["source"])
    |> Map.put(
      "station_reservation_hold_import_readiness_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> Map.put(
      "station_reservation_hold_import_readiness_status",
      summary["import_readiness_status"]
    )
    |> Map.put(
      "station_reservation_hold_import_classification",
      summary["import_classification"]
    )
    |> Map.put("station_reservation_hold_count", summary["reservation_hold_count"])
    |> Map.put("station_reservation_hold_ids", summary["reservation_hold_ids"])
    |> Map.put(
      "station_reservation_hold_ids_by_import_status",
      summary["reservation_hold_ids_by_import_status"]
    )
    |> Map.put(
      "station_reservation_hold_ids_by_required_import_action",
      summary["reservation_hold_ids_by_required_import_action"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_import_status",
      summary["reservation_hold_contact_ids_by_import_status"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_expiration_status",
      summary["reservation_hold_contact_ids_by_expiration_status"]
    )
    |> Map.put(
      "station_reservation_hold_import_status_counts",
      summary["reservation_hold_import_status_counts"]
    )
    |> Map.put(
      "station_reservation_hold_required_import_action_counts",
      summary["required_import_action_counts"]
    )
    |> Map.put(
      "station_reservation_hold_import_execution_boundary",
      assumptions["execution_boundary"]
    )
    |> Map.put("station_reservation_hold_provider_write", assumptions["provider_write"])
    |> Map.put("station_reservation_hold_cadence_write", assumptions["cadence_write"])
    |> Map.put(
      "station_reservation_hold_reservation_acceptance",
      assumptions["reservation_acceptance"]
    )
    |> Map.put("source_station_reservation_hold_import_readiness_summary", summary_context)
    |> compact_map()
  end

  defp station_reservation_hold_import_readiness_row_id(%{} = row) do
    review_id([
      "station_reservation_hold_import_readiness",
      row["reservation_review_row_type"],
      row["contact_id"],
      List.first(List.wrap(row["reservation_ids"]))
    ])
  end

  defp station_reservation_hold_import_readiness_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_import_readiness_summary" and
      is_list(summary["import_readiness_rows"])
  end

  defp station_reservation_hold_import_readiness_summary?(_summary), do: false

  defp station_reservation_report?(%{} = report) do
    report = stringify_keys(report)

    report["schema_contract"] in [nil, "station_reservation_report.v1"] and
      (is_list(report["affected_contacts"]) or
         is_list(report["provider_calendar_contention_groups"]))
  end

  defp station_reservation_review_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_review_summary" and
      summary["schema_contract"] in [nil, "station_reservation_review_summary.v1"] and
      is_list(summary["review_rows"])
  end

  defp station_reservation_review_summary?(_summary), do: false

  defp station_reservation_hold_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_summary" and
      summary["schema_contract"] in [nil, "station_reservation_hold_summary.v1"] and
      is_list(summary["review_rows"])
  end

  defp station_reservation_hold_summary?(_summary), do: false

  defp candidate_refresh_result_artifact_station_reservation_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_station_reservation_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_station_reservation_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_station_reservation_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_station_reservation_rows(
         %{"schema_contract" => "station_reservation_report.v1"} = report,
         source
       ) do
    source_station_reservation_report_rows(report, source)
  end

  defp result_artifact_station_reservation_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_station_reservation_report",
       artifact["source_station_reservation_report"]},
      {"#{source}.station_reservation_report", artifact["station_reservation_report"]},
      {"#{source}.source_station_reservation_review_summary",
       artifact["source_station_reservation_review_summary"]},
      {"#{source}.station_reservation_review_summary",
       artifact["station_reservation_review_summary"]},
      {"#{source}.source_station_reservation_hold_summary",
       artifact["source_station_reservation_hold_summary"]},
      {"#{source}.station_reservation_hold_summary",
       artifact["station_reservation_hold_summary"]},
      {"#{source}.source_station_reservation_hold_import_readiness_summary",
       artifact["source_station_reservation_hold_import_readiness_summary"]},
      {"#{source}.station_reservation_hold_import_readiness_summary",
       artifact["station_reservation_hold_import_readiness_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_station_reservation_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_station_reservation_rows(_artifact, _source), do: []

  defp candidate_refresh_quality_gate_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_quality_gate_report",
         get_in(artifact, ["accepted_planning_state", "source_quality_gate_report"])},
        {"candidate_refresh.accepted_planning_state.quality_gate_report",
         get_in(artifact, ["accepted_planning_state", "quality_gate_report"])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.mission_state.source_quality_gate_report",
         get_in(artifact, ["mission_state", "source_quality_gate_report"])},
        {"candidate_refresh.mission_state.quality_gate_report",
         get_in(artifact, ["mission_state", "quality_gate_report"])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.source_quality_gate_report", artifact["source_quality_gate_report"]},
        {"candidate_refresh.quality_gate_report", artifact["quality_gate_report"]},
        {"candidate_refresh.source_operational_quality_gate_import_readiness_summary",
         artifact["source_operational_quality_gate_import_readiness_summary"]},
        {"candidate_refresh.operational_quality_gate_import_readiness_summary",
         artifact["operational_quality_gate_import_readiness_summary"]},
        {"candidate_refresh.source_operational_quality_gate_summary",
         artifact["source_operational_quality_gate_summary"]},
        {"candidate_refresh.operational_quality_gate_summary",
         artifact["operational_quality_gate_summary"]},
        {"candidate_refresh.source_operational_quality_gate_unavailable_resource_summary",
         artifact["source_operational_quality_gate_unavailable_resource_summary"]},
        {"candidate_refresh.operational_quality_gate_unavailable_resource_summary",
         artifact["operational_quality_gate_unavailable_resource_summary"]},
        {"candidate_refresh.source_operational_quality_gate_operator_training_summary",
         artifact["source_operational_quality_gate_operator_training_summary"]},
        {"candidate_refresh.operational_quality_gate_operator_training_summary",
         artifact["operational_quality_gate_operator_training_summary"]},
        {"candidate_refresh.source_operational_quality_gate_schema_validation_summary",
         artifact["source_operational_quality_gate_schema_validation_summary"]},
        {"candidate_refresh.operational_quality_gate_schema_validation_summary",
         artifact["operational_quality_gate_schema_validation_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_quality_gate_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_quality_gate_rows(artifact)
  end

  defp source_quality_gate_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_quality_gate_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_quality_gate_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    cond do
      quality_gate_import_readiness_summary?(report) ->
        report
        |> quality_gate_report_from_import_readiness_summary()
        |> quality_gate_rows(source)

      quality_gate_summary?(report) ->
        report
        |> quality_gate_report_from_quality_gate_summary()
        |> quality_gate_rows("#{source}.rows")

      quality_gate_unavailable_resource_summary?(report) ->
        report
        |> quality_gate_report_from_unavailable_resource_summary()
        |> quality_gate_rows(source)

      quality_gate_operator_training_summary?(report) ->
        report
        |> quality_gate_report_from_operator_training_summary()
        |> quality_gate_rows(source)

      quality_gate_schema_validation_summary?(report) ->
        report
        |> quality_gate_report_from_schema_validation_summary()
        |> quality_gate_rows(source)

      true ->
        quality_gate_rows(report, "#{source}.rows")
    end
  end

  defp source_quality_gate_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_quality_gate_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_quality_gate_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_quality_gate_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_quality_gate_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_quality_gate_rows(
         %{"schema_contract" => "quality_gate_report.v1"} = report,
         source
       ) do
    source_quality_gate_report_rows(report, source)
  end

  defp result_artifact_quality_gate_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_quality_gate_report", artifact["source_quality_gate_report"]},
      {"#{source}.quality_gate_report", artifact["quality_gate_report"]},
      {"#{source}.source_operational_quality_gate_import_readiness_summary",
       artifact["source_operational_quality_gate_import_readiness_summary"]},
      {"#{source}.operational_quality_gate_import_readiness_summary",
       artifact["operational_quality_gate_import_readiness_summary"]},
      {"#{source}.source_operational_quality_gate_summary",
       artifact["source_operational_quality_gate_summary"]},
      {"#{source}.operational_quality_gate_summary",
       artifact["operational_quality_gate_summary"]},
      {"#{source}.source_operational_quality_gate_unavailable_resource_summary",
       artifact["source_operational_quality_gate_unavailable_resource_summary"]},
      {"#{source}.operational_quality_gate_unavailable_resource_summary",
       artifact["operational_quality_gate_unavailable_resource_summary"]},
      {"#{source}.source_operational_quality_gate_operator_training_summary",
       artifact["source_operational_quality_gate_operator_training_summary"]},
      {"#{source}.operational_quality_gate_operator_training_summary",
       artifact["operational_quality_gate_operator_training_summary"]},
      {"#{source}.source_operational_quality_gate_schema_validation_summary",
       artifact["source_operational_quality_gate_schema_validation_summary"]},
      {"#{source}.operational_quality_gate_schema_validation_summary",
       artifact["operational_quality_gate_schema_validation_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_quality_gate_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_quality_gate_rows(_artifact, _source), do: []

  defp candidate_refresh_timeline_feedback_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_timeline_feedback_report",
         artifact["source_timeline_feedback_report"]},
        {"candidate_refresh.timeline_feedback_report", artifact["timeline_feedback_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_timeline_feedback_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_timeline_feedback_rows(artifact)
  end

  defp source_timeline_feedback_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_timeline_feedback_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_timeline_feedback_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> realized_timeline_feedback_rows()
    |> feedback_rows("#{source}.rows")
  end

  defp source_timeline_feedback_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_timeline_feedback_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_timeline_feedback_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_timeline_feedback_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_timeline_feedback_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_timeline_feedback_rows(
         %{"schema_contract" => "timeline_feedback_report.v1"} = report,
         source
       ) do
    source_timeline_feedback_report_rows(report, source)
  end

  defp result_artifact_timeline_feedback_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_feedback_report", artifact["source_timeline_feedback_report"]},
      {"#{source}.timeline_feedback_report", artifact["timeline_feedback_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_timeline_feedback_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_timeline_feedback_rows(_artifact, _source), do: []

  defp candidate_refresh_operational_timeline_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_operational_timeline_report",
         artifact["source_operational_timeline_report"]},
        {"candidate_refresh.operational_timeline_report", artifact["operational_timeline_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_operational_timeline_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_operational_timeline_rows(artifact)
  end

  defp source_operational_timeline_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_operational_timeline_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_operational_timeline_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> operational_timeline_rows("#{source}.rows")
  end

  defp source_operational_timeline_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_operational_timeline_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_operational_timeline_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_operational_timeline_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_operational_timeline_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_operational_timeline_rows(
         %{"schema_contract" => "operational_timeline_report.v1"} = report,
         source
       ) do
    source_operational_timeline_report_rows(report, source)
  end

  defp result_artifact_operational_timeline_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_operational_timeline_report",
       artifact["source_operational_timeline_report"]},
      {"#{source}.operational_timeline_report", artifact["operational_timeline_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_operational_timeline_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_operational_timeline_rows(_artifact, _source), do: []

  defp candidate_refresh_operational_readiness_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_operational_readiness_report",
         artifact["source_operational_readiness_report"]},
        {"candidate_refresh.operational_readiness_report",
         artifact["operational_readiness_report"]},
        {"candidate_refresh.source_operational_import_eligibility_summary",
         artifact["source_operational_import_eligibility_summary"]},
        {"candidate_refresh.operational_import_eligibility_summary",
         artifact["operational_import_eligibility_summary"]},
        {"candidate_refresh.source_operational_readiness_gate_summary",
         artifact["source_operational_readiness_gate_summary"]},
        {"candidate_refresh.operational_readiness_gate_summary",
         artifact["operational_readiness_gate_summary"]},
        {"candidate_refresh.source_operational_execution_boundary_summary",
         artifact["source_operational_execution_boundary_summary"]},
        {"candidate_refresh.operational_execution_boundary_summary",
         artifact["operational_execution_boundary_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_operational_readiness_report_rows(report_or_reports, source)
      end)

    direct_rows ++
      candidate_refresh_result_artifact_operational_readiness_rows(artifact) ++
      candidate_refresh_operational_readiness_summary_rows(artifact)
  end

  defp source_operational_readiness_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_operational_readiness_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_operational_readiness_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> operational_readiness_report_from_source()
    |> operational_readiness_rows(source)
  end

  defp source_operational_readiness_report_rows(_report, _source), do: []

  defp operational_readiness_report_from_source(%{} = report) do
    cond do
      operational_import_eligibility_summary?(report) ->
        operational_readiness_report_from_summary(report)

      operational_readiness_gate_summary?(report) ->
        operational_readiness_report_from_summary(report)

      operational_execution_boundary_summary?(report) ->
        operational_readiness_report_from_summary(report)

      true ->
        report
    end
  end

  defp operational_readiness_report_from_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
  end

  defp operational_import_eligibility_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_import_eligibility_summary" or
         summary["schema_contract"] == "operational_import_eligibility_summary.v1")
  end

  defp operational_readiness_gate_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_operational_readiness_gate_summary" or
         summary["schema_contract"] == "operational_readiness_gate_summary.v1")
  end

  defp operational_execution_boundary_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_operational_execution_boundary_summary" or
         summary["schema_contract"] == "operational_execution_boundary_summary.v1")
  end

  defp candidate_refresh_result_artifact_operational_readiness_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_operational_readiness_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_operational_readiness_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_operational_readiness_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_operational_readiness_rows(
         %{"schema_contract" => "operational_readiness_report.v1"} = report,
         source
       ) do
    source_operational_readiness_report_rows(report, source)
  end

  defp result_artifact_operational_readiness_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_operational_readiness_report",
       artifact["source_operational_readiness_report"]},
      {"#{source}.operational_readiness_report", artifact["operational_readiness_report"]},
      {"#{source}.source_operational_import_eligibility_summary",
       artifact["source_operational_import_eligibility_summary"]},
      {"#{source}.operational_import_eligibility_summary",
       artifact["operational_import_eligibility_summary"]},
      {"#{source}.source_operational_readiness_gate_summary",
       artifact["source_operational_readiness_gate_summary"]},
      {"#{source}.operational_readiness_gate_summary",
       artifact["operational_readiness_gate_summary"]},
      {"#{source}.source_operational_execution_boundary_summary",
       artifact["source_operational_execution_boundary_summary"]},
      {"#{source}.operational_execution_boundary_summary",
       artifact["operational_execution_boundary_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_operational_readiness_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_operational_readiness_rows(_artifact, _source), do: []

  defp candidate_refresh_operational_readiness_summary_rows(artifact) do
    summary = get_in(artifact, ["provenance", "source_reports", "operational_readiness_report"])

    case summary do
      %{} = summary when map_size(summary) > 0 ->
        summary = stringify_keys(summary)
        classification = operational_readiness_summary_classification(summary)
        action = operational_readiness_action(classification)
        report_id = "candidate_refresh.operational_readiness_source_reports"
        evidence = operational_readiness_summary_evidence(summary)
        resource_context = operational_readiness_summary_resource_context(summary)

        [
          %{
            "id" => review_id(["operational_readiness", report_id]),
            "review_type" => "operational_readiness_review",
            "source" =>
              "candidate_refresh.provenance.source_reports.operational_readiness_report",
            "subject_id" => report_id,
            "action" => action,
            "required_operator_action" => action,
            "approval_status" => operational_readiness_approval_status(classification),
            "cadence_import_status" =>
              operational_readiness_cadence_import_status(classification),
            "reason" =>
              "candidate refresh included #{summary["count"] || 0} operational readiness source report(s) classified #{classification}",
            "source_artifact_type" => "operational_readiness_report.v1",
            "source_artifact_id" => report_id,
            "readiness_level" => operational_readiness_summary_readiness_level(summary),
            "import_classification" => classification,
            "operational_readiness_status" => operational_readiness_summary_status(summary),
            "gate_count" => summary["gate_count"],
            "passed_gate_count" => summary["passed_gate_count"],
            "review_gate_count" => summary["review_gate_count"],
            "analysis_gate_count" => summary["analysis_gate_count"],
            "blocked_gate_count" => summary["blocked_gate_count"],
            "evidence" => evidence,
            "source_operational_readiness_report" =>
              Map.merge(summary, %{
                "schema_contract" => "operational_readiness_report.v1",
                "summary_source" =>
                  "candidate_refresh.provenance.source_reports.operational_readiness_report"
              })
          }
          |> Map.merge(resource_context)
          |> compact_map()
        ]

      _summary ->
        []
    end
  end

  defp operational_readiness_summary_classification(summary) do
    counts = summary["import_classification_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) or positive_count?(summary["blocked_gate_count"]) ->
        "blocked"

      positive_count?(counts["review_only"]) or positive_count?(summary["review_gate_count"]) ->
        "review_only"

      positive_count?(counts["analysis_only"]) or positive_count?(summary["analysis_gate_count"]) ->
        "analysis_only"

      positive_count?(counts["importable"]) ->
        "importable"

      true ->
        "review_only"
    end
  end

  defp operational_readiness_summary_readiness_level(summary) do
    counts = summary["readiness_level_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) -> "blocked"
      positive_count?(counts["operator_review"]) -> "operator_review"
      positive_count?(counts["analysis_only"]) -> "analysis_only"
      positive_count?(counts["import_eligible"]) -> "import_eligible"
      true -> readiness_level(operational_readiness_summary_classification(summary))
    end
  end

  defp operational_readiness_summary_status(summary) do
    counts = summary["status_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) -> "blocked"
      positive_count?(counts["review_required"]) -> "review_required"
      positive_count?(counts["analysis_only"]) -> "analysis_only"
      positive_count?(counts["passed"]) -> "passed"
      true -> nil
    end
  end

  defp operational_readiness_summary_evidence(summary) do
    [
      "ready_for_import_count",
      "review_required_count",
      "schema_validation_fail_count",
      "stale_freshness_count",
      "source_model_limit_count",
      "resource_availability_pressure_count",
      "resource_availability_reason_counts",
      "resource_availability_reason_ids",
      "station_availability_reason_ids",
      "station_availability_reason_counts",
      "unavailable_resource_reason_ids",
      "resource_blocking_dimension_counts"
    ]
    |> operational_readiness_summary_keys(summary)
    |> non_empty_map()
  end

  defp operational_readiness_summary_resource_context(summary) do
    [
      "resource_availability_pressure_count",
      "resource_availability_reason_counts",
      "resource_availability_reason_ids",
      "station_availability_reason_ids",
      "station_availability_reason_counts",
      "unavailable_resource_reason_ids",
      "resource_blocking_dimension_counts"
    ]
    |> operational_readiness_summary_keys(summary)
  end

  defp operational_readiness_summary_keys(keys, summary) do
    keys
    |> Enum.reduce(%{}, fn key, evidence ->
      case summary[key] do
        value when value in [nil, 0] -> evidence
        value -> Map.put(evidence, key, value)
      end
    end)
  end

  defp operational_readiness_action("importable"), do: "record_operational_readiness_importable"

  defp operational_readiness_action("analysis_only"),
    do: "record_operational_readiness_analysis_only"

  defp operational_readiness_action("blocked"), do: "review_blocked_operational_readiness"
  defp operational_readiness_action(_classification), do: "review_operational_readiness"

  defp operational_readiness_approval_status("importable"), do: "auto_approvable"
  defp operational_readiness_approval_status("analysis_only"), do: "not_required"
  defp operational_readiness_approval_status("blocked"), do: "blocked_by_policy"
  defp operational_readiness_approval_status(_classification), do: "operator_review_required"

  defp operational_readiness_cadence_import_status("analysis_only"), do: "not_applicable"
  defp operational_readiness_cadence_import_status(_classification), do: "present"

  defp readiness_level("importable"), do: "import_eligible"
  defp readiness_level("review_only"), do: "operator_review"
  defp readiness_level("analysis_only"), do: "analysis_only"
  defp readiness_level("blocked"), do: "blocked"
  defp readiness_level(_classification), do: "operator_review"

  defp positive_count?(value) when is_integer(value), do: value > 0
  defp positive_count?(value) when is_float(value), do: value > 0.0
  defp positive_count?(_value), do: false

  defp operational_readiness_reason(report, classification) do
    source_type = report["source_artifact_type"] || "artifact"
    source_id = report["source_artifact_id"] || "unknown"

    "operational readiness classified #{source_type} #{source_id} as #{classification}"
  end

  defp operational_readiness_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "report_id",
      "source_summary_model",
      "source_summary_schema_contract",
      "source_artifact_type",
      "source_artifact_id",
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gates",
      "evidence",
      "model_limits",
      "assumptions"
    ])
  end

  defp execution_report_id(report) do
    review_id([
      "execution",
      report["study_id"],
      report["run_id"] || report["status"]
    ])
  end

  defp plan_delta_rows(deltas, source) do
    deltas
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {delta, index} ->
      repair_action = Map.get(delta, "repair_action", "unknown")
      action = plan_delta_operator_action(repair_action)
      source_import_context = plan_delta_import_context(delta, "source")
      replacement_import_context = plan_delta_import_context(delta, "replacement")

      source_activity_context =
        plan_delta_activity_context(delta["source_activity_context"], source_import_context)

      replacement_activity_context =
        plan_delta_activity_context(
          delta["replacement_activity_context"],
          replacement_import_context
        )

      %{
        "id" => review_id(["plan_delta", delta["activity_id"], repair_action, index]),
        "review_type" => "plan_delta_review",
        "source" => source,
        "subject_id" => delta["activity_id"],
        "activity_id" => delta["activity_id"],
        "activity_type" => delta["activity_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => plan_delta_approval_status(delta),
        "repair_action" => repair_action,
        "reason" => Map.get(delta, "reason", "review #{repair_action} repair delta"),
        "source_timeline_id" => delta["source_timeline_id"],
        "replacement_activity_id" => delta["replacement_activity_id"],
        "replacement_timeline_id" => delta["replacement_timeline_id"],
        "timeline_link" => delta["timeline_link"],
        "source_activity_context" => source_activity_context,
        "replacement_activity_context" => replacement_activity_context,
        "source_timeline_identity" => plan_delta_source_timeline_identity(delta),
        "replacement_timeline_identity" => plan_delta_replacement_timeline_identity(delta),
        "source_cadence_import_status" => source_import_context["cadence_import_status"],
        "source_cadence_import_type" => source_import_context["cadence_import_type"],
        "source_cadence_import_id" => source_import_context["cadence_import_id"],
        "source_cadence_import_contract" => source_import_context["cadence_import_contract"],
        "source_has_cadence_import" => source_import_context["has_cadence_import"],
        "replacement_cadence_import_status" =>
          replacement_import_context["cadence_import_status"],
        "replacement_cadence_import_type" => replacement_import_context["cadence_import_type"],
        "replacement_cadence_import_id" => replacement_import_context["cadence_import_id"],
        "replacement_cadence_import_contract" =>
          replacement_import_context["cadence_import_contract"],
        "replacement_has_cadence_import" => replacement_import_context["has_cadence_import"],
        "invalid_cadence_import" =>
          source_import_context["invalid_cadence_import"] ||
            replacement_import_context["invalid_cadence_import"],
        "invalid_cadence_import_reason" =>
          source_import_context["invalid_cadence_import_reason"] ||
            replacement_import_context["invalid_cadence_import_reason"],
        "source_cadence_import" =>
          plan_delta_invalid_cadence_import_evidence(
            source_import_context,
            replacement_import_context
          ),
        "source_delta" => delta
      }
      |> compact_map()
    end)
  end

  defp plan_delta_operator_action("preserved"), do: "record_preserved_timeline_item"
  defp plan_delta_operator_action("preserved_executed"), do: "record_preserved_executed_item"
  defp plan_delta_operator_action("moved"), do: "review_moved_timeline_item"
  defp plan_delta_operator_action("replaced"), do: "review_replaced_timeline_item"
  defp plan_delta_operator_action("suppressed"), do: "review_suppressed_timeline_item"
  defp plan_delta_operator_action("canceled"), do: "review_canceled_timeline_item"
  defp plan_delta_operator_action("review_realized_feedback"), do: "review_realized_feedback"
  defp plan_delta_operator_action(_action), do: "review_plan_delta"

  defp plan_delta_approval_status(%{"requires_approval" => false}), do: "not_required"
  defp plan_delta_approval_status(_delta), do: "operator_review_required"

  defp plan_delta_source_timeline_identity(delta) do
    get_in(delta, ["source_activity_context", "timeline_identity"]) ||
      get_in(delta, ["planned", "timeline_identity"])
  end

  defp plan_delta_replacement_timeline_identity(delta) do
    get_in(delta, ["replacement_activity_context", "timeline_identity"])
  end

  defp plan_delta_import_context(delta, side) do
    context = Map.get(delta, "#{side}_activity_context", %{}) || %{}
    context = if is_map(context), do: context, else: %{}
    raw_cadence_import = Map.get(context, "cadence_import")
    cadence_import = if is_map(raw_cadence_import), do: raw_cadence_import, else: %{}
    activity_type = plan_delta_context_activity_type(delta, side, context)
    has_import? = is_map(raw_cadence_import)
    invalid_import? = Map.has_key?(context, "cadence_import") and not has_import?

    %{
      "cadence_import_status" =>
        if(invalid_import?,
          do: "invalid",
          else: plan_delta_cadence_import_status(has_import?, activity_type, context)
        ),
      "cadence_import_type" => get_in(cadence_import, ["activity_type"]),
      "cadence_import_id" => get_in(cadence_import, ["external_id"]),
      "cadence_import_contract" => get_in(cadence_import, ["schema_contract"]),
      "has_cadence_import" => has_import?,
      "invalid_cadence_import" => if(invalid_import?, do: true),
      "invalid_cadence_import_reason" => if(invalid_import?, do: "cadence_import_must_be_object"),
      "source_cadence_import" =>
        if(invalid_import?,
          do: %{"invalid_import_shape" => stringify_keys(raw_cadence_import)}
        )
    }
  end

  defp plan_delta_activity_context(
         %{} = context,
         %{"invalid_cadence_import" => true} = import_context
       ) do
    context
    |> Map.delete("cadence_import")
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("invalid_cadence_import_reason", import_context["invalid_cadence_import_reason"])
    |> Map.put("source_cadence_import", import_context["source_cadence_import"])
  end

  defp plan_delta_activity_context(%{} = context, _import_context), do: context
  defp plan_delta_activity_context(_context, _import_context), do: nil

  defp plan_delta_invalid_cadence_import_evidence(source_context, replacement_context) do
    %{
      "source" => source_context["source_cadence_import"],
      "replacement" => replacement_context["source_cadence_import"]
    }
    |> compact_map()
    |> empty_to_nil()
  end

  defp plan_delta_context_activity_type(delta, "source", context) do
    get_in(context, ["timeline_identity", "activity_type"]) || delta["activity_type"]
  end

  defp plan_delta_context_activity_type(_delta, "replacement", context) do
    get_in(context, ["timeline_identity", "activity_type"])
  end

  defp plan_delta_cadence_import_status(true, _activity_type, _context), do: "present"

  defp plan_delta_cadence_import_status(false, activity_type, context) do
    cond do
      activity_type in ["downlink", "planned_contact", "tracking", "command", "health_check"] ->
        "missing"

      context["direction"] == "command" ->
        "missing"

      is_binary(context["ground_station_id"]) and context["ground_station_id"] != "" ->
        "missing"

      true ->
        "not_applicable"
    end
  end

  defp timeline_protection_rows(nil, _source), do: []

  defp timeline_protection_rows(%{} = protection, source) do
    protection = stringify_keys(protection)

    [
      {"preserved_locked_or_approved", "preserved", "preserved_locked_or_approved_activity_ids",
       "record_protected_timeline_preservation",
       "locked or approved activity preserved by repair policy", "not_required"},
      {"preserved_executed", "preserved", "preserved_executed_activity_ids",
       "record_executed_timeline_preservation", "executed activity preserved by repair policy",
       "not_required"},
      {"changed_locked_or_approved", "changed", "changed_locked_or_approved_activity_ids",
       "review_changed_protected_timeline_item", "locked or approved activity changed by repair",
       "operator_review_required"},
      {"changed_executed", "changed", "changed_executed_activity_ids",
       "review_changed_executed_timeline_item", "executed activity changed by repair",
       "operator_review_required"}
    ]
    |> Enum.flat_map(fn {category, decision, id_field, action, reason, approval_status} ->
      protection
      |> Map.get(id_field, [])
      |> Enum.map(&encode_value/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {activity_id, index} ->
        %{
          "id" => review_id(["timeline_protection", category, activity_id, index]),
          "review_type" => "timeline_protection",
          "source" => source,
          "subject_id" => activity_id,
          "activity_id" => activity_id,
          "action" => action,
          "required_operator_action" => action,
          "approval_status" => approval_status,
          "reason" => reason,
          "protection_category" => category,
          "protection_decision" => decision,
          "source_timeline_protection" => protection
        }
      end)
    end)
  end

  defp warning_rows(warnings, source) do
    warnings
    |> Enum.map(&encode_value/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {warning, index} ->
      %{
        "id" => review_id(["warning", source, index]),
        "review_type" => "warning",
        "source" => source,
        "subject_id" => "warning:#{index}",
        "action" => "review_warning",
        "required_operator_action" => "review_warning",
        "approval_status" => "operator_review_required",
        "reason" => warning,
        "severity" => "warning"
      }
    end)
  end

  defp candidate_refresh_warning_rows(artifact) do
    rows = warning_rows(Map.get(artifact, "warnings", []), "candidate_refresh.warnings")

    case get_in(artifact, ["provenance", "operational_feedback"]) do
      %{} = feedback_provenance ->
        context = operational_feedback_warning_context(feedback_provenance)
        Enum.map(rows, &Map.merge(&1, context))

      _feedback_provenance ->
        rows
    end
  end

  defp operational_feedback_warning_context(feedback_provenance) do
    %{
      "operational_feedback_trust_boundary_status" =>
        feedback_provenance["trust_boundary_status"],
      "operational_feedback_trust_boundary" => feedback_provenance["trust_boundary"],
      "operational_feedback_trust_boundaries" =>
        operational_feedback_trust_boundaries(feedback_provenance),
      "operational_feedback_field_trust_boundaries" =>
        operational_feedback_field_trust_boundaries(feedback_provenance),
      "operational_feedback_input_keys" => feedback_provenance["input_keys"],
      "source_operational_feedback" => feedback_provenance["source_operational_feedback"],
      "source_operational_feedback_provenance" => feedback_provenance
    }
    |> compact_map()
  end

  defp risk_rows(risks, source) do
    risks
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {risk, index} ->
      risk_type = Map.get(risk, "type", "risk")

      %{
        "id" => review_id(["risk", source, risk_type, index]),
        "review_type" => "risk_explanation",
        "source" => source,
        "subject_id" => risk_type,
        "action" => "review_risk",
        "required_operator_action" => "review_risk",
        "approval_status" => "operator_review_required",
        "risk_type" => risk_type,
        "severity" => Map.get(risk, "severity"),
        "reason" => Map.get(risk, "reason", risk_type),
        "value" => Map.get(risk, "value"),
        "branch_id" => risk["branch_id"],
        "scenario_id" => risk["scenario_id"],
        "activity_id" => risk["activity_id"] || risk["first_resource_pressure_activity_id"],
        "activity_type" => risk["activity_type"] || risk["first_resource_pressure_activity_type"],
        "ground_station_id" =>
          risk["ground_station_id"] || risk["first_resource_pressure_ground_station_id"],
        "spacecraft_id" => risk["spacecraft_id"],
        "target_id" => risk["target_id"],
        "collection_id" => risk["collection_id"],
        "product_id" => risk["product_id"],
        "product_ids" => risk["product_ids"],
        "payload_id" => risk["payload_id"],
        "instrument_id" => risk["instrument_id"],
        "objective_id" => risk["objective_id"],
        "objective_type" => risk["objective_type"],
        "objective_status" => risk["objective_status"],
        "source_objective_status" => risk["source_objective_status"],
        "latency_objective" => risk["latency_objective"],
        "max_latency_s" => risk["max_latency_s"],
        "planned_latency_s" => risk["planned_latency_s"],
        "required_contacts" => risk["required_contacts"],
        "planned_contacts" => risk["planned_contacts"],
        "required_downlink_mb" => risk["required_downlink_mb"],
        "planned_downlink_mb" => risk["planned_downlink_mb"],
        "contact_result" => risk["contact_result"],
        "realized_status" => risk["realized_status"],
        "source_activity_id" => risk["source_activity_id"],
        "source_activity_ids" => risk["source_activity_ids"],
        "missed_downlink_activity_id" => risk["missed_downlink_activity_id"],
        "missed_downlink_activity_ids" => risk["missed_downlink_activity_ids"],
        "feedback_source" => risk["feedback_source"],
        "feedback_scope" => risk["feedback_scope"],
        "trust_boundary" => risk["trust_boundary"],
        "derivation_reasons" => risk["derivation_reasons"],
        "direction" => risk["direction"] || risk["first_resource_pressure_direction"],
        "station_calendar_entry_id" =>
          risk["station_calendar_entry_id"] ||
            risk["first_resource_pressure_station_calendar_entry_id"],
        "station_calendar_provider_id" =>
          risk["station_calendar_provider_id"] ||
            risk["first_resource_pressure_station_calendar_provider_id"],
        "station_calendar_provider_entry_id" =>
          risk["station_calendar_provider_entry_id"] ||
            risk["first_resource_pressure_station_calendar_provider_entry_id"],
        "station_calendar_directions" =>
          risk["station_calendar_directions"] ||
            risk["first_resource_pressure_station_calendar_directions"],
        "first_resource_pressure_activity_id" => risk["first_resource_pressure_activity_id"],
        "first_resource_pressure_activity_type" => risk["first_resource_pressure_activity_type"],
        "first_resource_pressure_kind" => risk["first_resource_pressure_kind"],
        "first_resource_pressure_starts_at_s" => risk["first_resource_pressure_starts_at_s"],
        "first_resource_pressure_direction" => risk["first_resource_pressure_direction"],
        "first_resource_pressure_ground_station_id" =>
          risk["first_resource_pressure_ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          risk["first_resource_pressure_station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          risk["first_resource_pressure_station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          risk["first_resource_pressure_station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          risk["first_resource_pressure_station_calendar_directions"],
        "first_resource_pressure_capacity_fraction" =>
          risk["first_resource_pressure_capacity_fraction"],
        "first_resource_pressure_source_window_id" =>
          risk["first_resource_pressure_source_window_id"],
        "first_resource_pressure_source_window_type" =>
          risk["first_resource_pressure_source_window_type"],
        "first_resource_pressure_source_window" => risk["first_resource_pressure_source_window"],
        "source_window_id" =>
          risk["source_window_id"] || risk["first_resource_pressure_source_window_id"],
        "source_window_type" =>
          risk["source_window_type"] || risk["first_resource_pressure_source_window_type"],
        "source_window" => risk["source_window"] || risk["first_resource_pressure_source_window"],
        "source_risk" => risk
      }
      |> compact_map()
    end)
  end

  defp strategy_recommendation_rows(%{} = recommendation, operational_feedback_context) do
    case Map.get(recommendation, "recommended_branch_id") do
      nil ->
        []

      branch_id ->
        [
          %{
            "id" => review_id(["strategy", "recommendation", branch_id]),
            "review_type" => "strategy_recommendation",
            "source" => "campaign_strategy.recommendation",
            "subject_id" => branch_id,
            "branch_id" => branch_id,
            "recommended_branch_id" => recommendation["recommended_branch_id"],
            "ranked_branch_ids" => Map.get(recommendation, "ranked_branch_ids", []),
            "action" => "review_strategy_recommendation",
            "required_operator_action" => "review_strategy_recommendation",
            "approval_status" => Map.get(recommendation, "approval_status"),
            "reason" => Map.get(recommendation, "reason"),
            "tradeoff_count" => length(Map.get(recommendation, "tradeoffs", [])),
            "risk_count" => length(Map.get(recommendation, "risks_remaining", [])),
            "approval_requirement_count" =>
              length(Map.get(recommendation, "requires_approval", [])),
            "source_recommendation" => recommendation
          }
          |> Map.merge(strategy_recommendation_branch_event_context(recommendation))
          |> merge_strategy_recommendation_context(
            strategy_recommendation_risk_context(recommendation)
          )
          |> merge_strategy_recommendation_context(
            strategy_recommendation_resource_pressure_context(recommendation)
          )
          |> Map.merge(operational_feedback_context)
          |> compact_map()
        ]
    end
  end

  defp strategy_recommendation_branch_event_context(%{"explanation" => explanation})
       when is_list(explanation) do
    explanation
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(&(&1["type"] == "branch_event_summary"))
    |> case do
      nil ->
        %{}

      summary ->
        Map.take(summary, [
          "branch_event_count",
          "branch_event_types",
          "branch_event_trust_boundary_status_counts",
          "combined_source_branch_ids",
          "branch_ground_station_ids",
          "branch_scenario_ids",
          "branch_target_ids",
          "branch_collection_ids",
          "branch_product_ids",
          "branch_payload_ids",
          "branch_instrument_ids",
          "branch_objective_ids",
          "branch_objective_types",
          "branch_objective_statuses",
          "branch_source_objective_statuses",
          "branch_feedback_sources",
          "branch_feedback_scopes",
          "branch_contact_results",
          "branch_realized_statuses",
          "branch_transition_types",
          "branch_transition_categories",
          "branch_transition_reasons",
          "branch_requires_operator_review",
          "branch_requires_operator_review_count",
          "branch_missed_downlink_activity_ids",
          "branch_maneuver_execution_uncertainty_activity_ids",
          "branch_maneuver_execution_uncertainty_timeline_ids",
          "branch_maneuver_execution_uncertainty_maneuver_ids",
          "branch_maneuver_execution_uncertainty_statuses",
          "branch_maneuver_execution_uncertainty_sources",
          "branch_maneuver_execution_uncertainty_max_timing_3sigma_s",
          "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s",
          "branch_timeline_integrity_activity_ids",
          "branch_timeline_integrity_timeline_ids",
          "branch_missing_dependency_activity_ids",
          "branch_missing_dependency_timeline_ids",
          "branch_dependency_cycle_activity_ids",
          "branch_dependency_cycle_timeline_ids",
          "branch_dependency_order_violation_activity_ids",
          "branch_dependency_order_violation_timeline_ids",
          "branch_exclusivity_violation_activity_ids",
          "branch_exclusivity_violation_timeline_ids",
          "branch_exclusivity_violation_groups",
          "branch_source_activity_ids",
          "branch_directions",
          "branch_station_availabilities",
          "branch_station_contention_statuses",
          "branch_station_calendar_entry_ids",
          "branch_station_calendar_provider_ids",
          "branch_station_calendar_provider_entry_ids",
          "branch_station_calendar_directions",
          "branch_station_calendar_statuses",
          "branch_station_calendar_trust_boundary_statuses",
          "branch_station_reservation_ids",
          "branch_station_reserved_by",
          "branch_station_reservation_statuses",
          "branch_station_reservation_match_statuses",
          "branch_image_quality_min_score",
          "branch_image_quality_statuses",
          "branch_image_quality_sources",
          "branch_cloud_cover_max_fraction",
          "branch_blur_max_score",
          "branch_max_latency_s",
          "branch_planned_latency_s",
          "branch_required_contacts",
          "branch_planned_contacts",
          "branch_required_downlink_mb",
          "branch_planned_downlink_mb",
          "capacity_pack_group_ids",
          "capacity_pack_statuses",
          "capacity_pack_min_capacity_fraction",
          "capacity_pack_max_used_fraction",
          "capacity_pack_max_required_capacity_fraction",
          "capacity_pack_total_required_capacity_fraction",
          "capacity_pack_required_capacity_sources"
        ])
    end
  end

  defp strategy_recommendation_branch_event_context(_recommendation), do: %{}

  defp strategy_recommendation_resource_pressure_context(%{"explanation" => explanation})
       when is_list(explanation) do
    rows =
      explanation
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["type"] == "resource_pressure"))

    %{
      "activity_ids" =>
        risk_context_values(rows, ["activity_id", "first_resource_pressure_activity_id"]),
      "scenario_ids" => risk_context_values(rows, "scenario_id"),
      "ground_station_ids" =>
        risk_context_values(rows, [
          "ground_station_id",
          "first_resource_pressure_ground_station_id"
        ]),
      "spacecraft_ids" => risk_context_values(rows, "spacecraft_id"),
      "directions" =>
        risk_context_values(rows, ["direction", "first_resource_pressure_direction"]),
      "station_calendar_entry_ids" =>
        risk_context_values(rows, [
          "station_calendar_entry_id",
          "first_resource_pressure_station_calendar_entry_id"
        ]),
      "station_calendar_provider_ids" =>
        risk_context_values(rows, [
          "station_calendar_provider_id",
          "first_resource_pressure_station_calendar_provider_id"
        ]),
      "station_calendar_provider_entry_ids" =>
        risk_context_values(rows, [
          "station_calendar_provider_entry_id",
          "first_resource_pressure_station_calendar_provider_entry_id"
        ]),
      "station_calendar_directions" =>
        risk_context_values(rows, [
          "station_calendar_directions",
          "first_resource_pressure_station_calendar_directions"
        ]),
      "source_window_ids" =>
        risk_context_values(rows, [
          "source_window_id",
          "first_resource_pressure_source_window_id"
        ]),
      "source_window_types" =>
        risk_context_values(rows, [
          "source_window_type",
          "first_resource_pressure_source_window_type"
        ]),
      "resource_pressure_statuses" => risk_context_values(rows, "resource_pressure_status"),
      "resource_pressure_types" => risk_context_values(rows, ["resource_pressure_types"]),
      "first_resource_pressure_kinds" =>
        risk_context_values(rows, ["pressure_kind", "first_resource_pressure_kind"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  defp strategy_recommendation_resource_pressure_context(_recommendation), do: %{}

  defp strategy_recommendation_risk_context(%{"risks_remaining" => risks}) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    %{
      "risk_types" => risk_context_values(risks, "type"),
      "activity_ids" =>
        risk_context_values(risks, ["activity_id", "first_resource_pressure_activity_id"]),
      "scenario_ids" => risk_context_values(risks, "scenario_id"),
      "ground_station_ids" =>
        risk_context_values(risks, [
          "ground_station_id",
          "first_resource_pressure_ground_station_id"
        ]),
      "spacecraft_ids" => risk_context_values(risks, "spacecraft_id"),
      "target_ids" => risk_context_values(risks, "target_id"),
      "collection_ids" => risk_context_values(risks, "collection_id"),
      "product_ids" => risk_context_values(risks, ["product_id", "product_ids"]),
      "payload_ids" => risk_context_values(risks, "payload_id"),
      "instrument_ids" => risk_context_values(risks, "instrument_id"),
      "objective_ids" => risk_context_values(risks, "objective_id"),
      "objective_types" => risk_context_values(risks, "objective_type"),
      "feedback_sources" => risk_context_values(risks, "feedback_source"),
      "feedback_scopes" => risk_context_values(risks, "feedback_scope"),
      "source_activity_ids" =>
        risk_context_values(risks, ["source_activity_id", "source_activity_ids"]),
      "timeline_ids" => risk_context_values(risks, "timeline_id"),
      "maneuver_ids" => risk_context_values(risks, "maneuver_id"),
      "maneuver_execution_uncertainty_statuses" =>
        risk_context_values(risks, "execution_uncertainty_status"),
      "maneuver_execution_uncertainty_sources" =>
        risk_context_values(risks, "execution_uncertainty_source"),
      "maneuver_execution_uncertainty_timing_3sigma_s" =>
        risk_context_values(risks, "timing_3sigma_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_km_s" =>
        risk_context_values(risks, "delta_v_3sigma_magnitude_km_s"),
      "missing_dependency_activity_ids" =>
        risk_context_values(risks, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        risk_context_values(risks, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" =>
        risk_context_values(risks, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" =>
        risk_context_values(risks, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        risk_context_values(risks, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        risk_context_values(risks, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        risk_context_values(risks, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        risk_context_values(risks, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_groups" => risk_context_values(risks, "exclusivity_violation_group"),
      "missed_downlink_activity_ids" =>
        risk_context_values(risks, [
          "missed_downlink_activity_id",
          "missed_downlink_activity_ids"
        ]),
      "directions" =>
        risk_context_values(risks, ["direction", "first_resource_pressure_direction"]),
      "station_calendar_entry_ids" =>
        risk_context_values(risks, [
          "station_calendar_entry_id",
          "first_resource_pressure_station_calendar_entry_id"
        ]),
      "station_calendar_provider_ids" =>
        risk_context_values(risks, [
          "station_calendar_provider_id",
          "first_resource_pressure_station_calendar_provider_id"
        ]),
      "station_calendar_provider_entry_ids" =>
        risk_context_values(risks, [
          "station_calendar_provider_entry_id",
          "first_resource_pressure_station_calendar_provider_entry_id"
        ]),
      "station_calendar_directions" =>
        risk_context_values(risks, [
          "station_calendar_directions",
          "first_resource_pressure_station_calendar_directions"
        ]),
      "source_window_ids" =>
        risk_context_values(risks, [
          "source_window_id",
          "first_resource_pressure_source_window_id"
        ]),
      "source_window_types" =>
        risk_context_values(risks, [
          "source_window_type",
          "first_resource_pressure_source_window_type"
        ]),
      "resource_pressure_statuses" => risk_context_values(risks, "resource_pressure_status"),
      "resource_pressure_types" => risk_context_values(risks, ["resource_pressure_types"]),
      "first_resource_pressure_kinds" =>
        risk_context_values(risks, "first_resource_pressure_kind")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  defp strategy_recommendation_risk_context(_recommendation), do: %{}

  defp merge_strategy_recommendation_context(row, context) when is_map(context) do
    Enum.reduce(context, row, fn
      {key, values}, acc when is_list(values) ->
        merged =
          acc
          |> Map.get(key, [])
          |> List.wrap()
          |> Kernel.++(values)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        if merged == [] do
          acc
        else
          Map.put(acc, key, merged)
        end

      {_key, nil}, acc ->
        acc

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end

  defp merge_strategy_recommendation_context(row, _context), do: row

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

  defp operational_feedback_review_context(%{} = provenance) do
    %{
      "operational_feedback_trust_boundary_status" =>
        operational_feedback_trust_boundary_status(provenance),
      "operational_feedback_trust_boundary" => operational_feedback_trust_boundary(provenance),
      "operational_feedback_trust_boundaries" =>
        operational_feedback_trust_boundaries(provenance),
      "operational_feedback_field_trust_boundaries" =>
        operational_feedback_field_trust_boundaries(provenance),
      "operational_feedback_input_keys" => provenance["input_keys"],
      "source_operational_feedback" => provenance["source_operational_feedback"],
      "source_operational_feedback_provenance" => provenance
    }
    |> compact_map()
  end

  defp operational_feedback_review_context(_provenance), do: %{}

  defp operational_feedback_trust_boundary_status(%{"sources" => sources})
       when is_list(sources) do
    statuses =
      sources
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(& &1["trust_boundary_status"])
      |> Enum.reject(&is_nil/1)

    cond do
      "missing" in statuses -> "missing"
      operational_feedback_trust_boundaries(%{"sources" => sources}) != [] -> "declared"
      "declared" in statuses -> "declared"
      true -> nil
    end
  end

  defp operational_feedback_trust_boundary_status(_provenance), do: nil

  defp operational_feedback_trust_boundary(%{} = provenance) do
    provenance
    |> operational_feedback_trust_boundaries()
    |> case do
      [boundary] -> boundary
      _boundaries -> nil
    end
  end

  defp operational_feedback_trust_boundaries(%{} = provenance) do
    provenance = stringify_keys(provenance)

    direct_boundaries = [
      provenance["trust_boundary"],
      provenance["trust_boundaries"]
    ]

    source_boundaries =
      provenance
      |> Map.get("sources", [])
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = source ->
          source = stringify_keys(source)

          [
            source["trust_boundary"],
            source["trust_boundaries"]
          ]

        _source ->
          []
      end)

    (direct_boundaries ++ source_boundaries)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_field_trust_boundaries(%{} = provenance) do
    provenance
    |> stringify_keys()
    |> Map.get("sources", [])
    |> List.wrap()
    |> Enum.reduce(%{}, fn
      %{} = source, field_boundaries ->
        source = stringify_keys(source)

        field_boundaries
        |> merge_feedback_field_trust_boundaries(source["feedback_trust_boundaries"])
        |> merge_feedback_field_trust_boundaries(
          get_in(source, ["source_operational_feedback_provenance", "feedback_trust_boundaries"])
        )

      _source, field_boundaries ->
        field_boundaries
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp merge_feedback_field_trust_boundaries(field_boundaries, %{} = incoming) do
    incoming
    |> stringify_keys()
    |> Enum.reduce(field_boundaries, fn {field, key_boundaries}, field_boundaries ->
      if is_map(key_boundaries) do
        normalized =
          key_boundaries
          |> stringify_keys()
          |> Enum.reduce(%{}, fn {key, trust_boundaries}, normalized ->
            trust_boundaries =
              trust_boundaries
              |> List.wrap()
              |> Enum.map(&encode_value/1)
              |> Enum.reject(&(&1 in [nil, ""]))
              |> Enum.uniq()
              |> Enum.sort()

            if trust_boundaries == [] do
              normalized
            else
              Map.put(normalized, key, trust_boundaries)
            end
          end)

        Map.update(field_boundaries, field, normalized, fn existing ->
          Map.merge(existing, normalized, fn _key, left, right ->
            (left ++ right) |> Enum.uniq() |> Enum.sort()
          end)
        end)
      else
        field_boundaries
      end
    end)
  end

  defp merge_feedback_field_trust_boundaries(field_boundaries, _incoming), do: field_boundaries

  defp strategy_tradeoff_rows(%{} = recommendation) do
    branch_id = Map.get(recommendation, "recommended_branch_id")
    approval_status = Map.get(recommendation, "approval_status")

    recommendation
    |> Map.get("tradeoffs", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {tradeoff, index} ->
      dimension = Map.get(tradeoff, "dimension", "tradeoff")

      %{
        "id" => review_id(["strategy", "tradeoff", branch_id, dimension, index]),
        "review_type" => "strategy_tradeoff",
        "source" => "campaign_strategy.recommendation.tradeoffs",
        "subject_id" => dimension,
        "branch_id" => branch_id,
        "action" => "review_strategy_tradeoff",
        "required_operator_action" => "review_strategy_tradeoff",
        "approval_status" => approval_status,
        "reason" => strategy_tradeoff_reason(tradeoff),
        "dimension" => dimension,
        "baseline" => Map.get(tradeoff, "baseline"),
        "recommended" => Map.get(tradeoff, "recommended"),
        "delta" => Map.get(tradeoff, "delta"),
        "source_tradeoff" => tradeoff
      }
      |> compact_map()
    end)
  end

  defp strategy_tradeoff_reason(%{} = tradeoff) do
    dimension = Map.get(tradeoff, "dimension", "tradeoff")
    delta = Map.get(tradeoff, "delta")

    "#{dimension} recommendation tradeoff delta #{encode_value(delta)}"
  end

  defp strategy_warning_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch
      |> Map.get("warnings", [])
      |> Enum.map(&encode_value/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {warning, index} ->
        branch_id = Map.get(branch, "branch_id")

        %{
          "id" => review_id(["warning", "campaign_strategy.branch", branch_id, index]),
          "review_type" => "warning",
          "source" => "campaign_strategy.branches.warnings",
          "subject_id" => branch_id,
          "branch_id" => branch_id,
          "action" => "review_branch_warning",
          "required_operator_action" => "review_branch_warning",
          "approval_status" => "operator_review_required",
          "reason" => warning,
          "severity" => "warning"
        }
        |> compact_map()
      end)
    end)
  end

  defp strategy_resource_suppression_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_resource_filter_report", "suppressed_candidates"])
      |> List.wrap()
      |> resource_suppression_rows(
        "campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_constraint_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "constraint_report", "rows"])
      |> List.wrap()
      |> constraint_rows("campaign_strategy.branches.repair_result.constraint_report.rows")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_operational_timeline_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "operational_timeline_report", "rows"])
      |> List.wrap()
      |> operational_timeline_rows(
        "campaign_strategy.branches.repair_result.operational_timeline_report.rows"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_resource_projection_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["resource_projection_report", "projected_resources"])
      |> List.wrap()
      |> resource_projection_rows(
        "campaign_strategy.branches.resource_projection_report.projected_resources"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_refresh_budget_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_refresh_budget_report"])
      |> refresh_budget_rows(
        "campaign_strategy.branches.repair_result.source_refresh_budget_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_freshness_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_freshness_report"])
      |> freshness_rows("campaign_strategy.branches.repair_result.source_freshness_report")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_candidate_diff_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_candidate_diff_report"])
      |> candidate_diff_report_rows(
        "campaign_strategy.branches.repair_result.source_candidate_diff_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_suppression_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_contact_filter_report", "suppressed_candidates"])
      |> List.wrap()
      |> contact_suppression_rows(
        "campaign_strategy.branches.repair_result.source_contact_filter_report.suppressed_candidates"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_station_calendar_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_station_calendar_report", "affected_contacts"])
      |> List.wrap()
      |> station_calendar_rows(
        "campaign_strategy.branches.repair_result.source_station_calendar_report.affected_contacts"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_link_capacity_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "link_capacity_report"])
      |> link_capacity_report_rows(
        "campaign_strategy.branches.repair_result.link_capacity_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_score_term_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "score_term_report", "rows"])
      |> List.wrap()
      |> score_term_rows("campaign_strategy.branches.repair_result.score_term_report.rows")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_objective_tradeoff_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "objective_tradeoff_report", "tradeoffs"])
      |> List.wrap()
      |> objective_tradeoff_rows(
        "campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_allocation_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      rows =
        branch
        |> get_in(["repair_result", "source_contact_allocation_report", "rows"])
        |> List.wrap()
        |> contact_allocation_rows(
          "campaign_strategy.branches.repair_result.source_contact_allocation_report.rows"
        )

      pack_rows =
        branch
        |> get_in([
          "repair_result",
          "source_contact_allocation_report",
          "reduced_capacity_pack_groups"
        ])
        |> List.wrap()
        |> contact_allocation_capacity_pack_rows(
          "campaign_strategy.branches.repair_result.source_contact_allocation_report.reduced_capacity_pack_groups"
        )

      (rows ++ pack_rows)
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_contact_allocation_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      rows =
        branch
        |> get_in(["repair_result", "contact_allocation_report", "rows"])
        |> List.wrap()
        |> contact_allocation_rows(
          "campaign_strategy.branches.repair_result.contact_allocation_report.rows"
        )

      pack_rows =
        branch
        |> get_in(["repair_result", "contact_allocation_report", "reduced_capacity_pack_groups"])
        |> List.wrap()
        |> contact_allocation_capacity_pack_rows(
          "campaign_strategy.branches.repair_result.contact_allocation_report.reduced_capacity_pack_groups"
        )

      (rows ++ pack_rows)
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_intent_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_contact_intents"])
      |> List.wrap()
      |> contact_intent_rows("campaign_strategy.branches.repair_result.source_contact_intents")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_timeline_feedback_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_timeline_feedback_report", "rows"])
      |> realized_timeline_feedback_rows()
      |> feedback_rows(
        "campaign_strategy.branches.repair_result.source_timeline_feedback_report.rows"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_command_window_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "command_window_report", "rows"])
      |> List.wrap()
      |> command_window_rows()
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp station_calendar_context_fields do
    [
      "station_availability",
      "station_calendar_status",
      "capacity_fraction",
      "capacity_fraction_min",
      "capacity_fraction_max",
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_directions",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_trust_boundary_statuses",
      "station_reservation_ids",
      "station_reservation_expires_at_s",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses"
    ]
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp put_contact_allocation_count_map(package, artifact, paths) do
    reports = Enum.map(paths, &get_in(artifact, &1))

    put_contact_allocation_summaries(package, reports)
  end

  defp put_candidate_refresh_contact_allocation_count_map(package, artifact) do
    reports =
      [
        artifact["source_contact_allocation_report"],
        artifact["contact_allocation_report"],
        artifact["source_contact_allocation_summary"],
        artifact["contact_allocation_summary"],
        artifact["source_contact_allocation_station_pressure_summary"],
        artifact["contact_allocation_station_pressure_summary"],
        artifact["source_contact_allocation_reservation_conflict_summary"],
        artifact["contact_allocation_reservation_conflict_summary"],
        artifact["source_contact_allocation_capacity_pack_summary"],
        artifact["contact_allocation_capacity_pack_summary"],
        artifact["source_contact_allocation_provider_reservation_request_summary"],
        artifact["contact_allocation_provider_reservation_request_summary"]
      ] ++
        result_artifact_contact_allocation_summary_reports(artifact["source_result_artifact"]) ++
        result_artifact_contact_allocation_summary_reports(artifact["result_artifact"])

    put_contact_allocation_summaries(package, reports)
  end

  defp result_artifact_contact_allocation_summary_reports(artifacts) when is_list(artifacts) do
    Enum.flat_map(artifacts, &result_artifact_contact_allocation_summary_reports/1)
  end

  defp result_artifact_contact_allocation_summary_reports(%{} = artifact) do
    artifact = stringify_keys(artifact)

    direct_reports =
      if result_artifact_contact_allocation_summary?(artifact), do: [artifact], else: []

    nested_reports =
      [
        artifact["source_contact_allocation_report"],
        artifact["contact_allocation_report"],
        artifact["source_contact_allocation_summary"],
        artifact["contact_allocation_summary"],
        artifact["source_contact_allocation_station_pressure_summary"],
        artifact["contact_allocation_station_pressure_summary"],
        artifact["source_contact_allocation_reservation_conflict_summary"],
        artifact["contact_allocation_reservation_conflict_summary"],
        artifact["source_contact_allocation_capacity_pack_summary"],
        artifact["contact_allocation_capacity_pack_summary"],
        artifact["source_contact_allocation_provider_reservation_request_summary"],
        artifact["contact_allocation_provider_reservation_request_summary"]
      ]

    direct_reports ++ nested_reports
  end

  defp result_artifact_contact_allocation_summary_reports(_artifact), do: []

  defp result_artifact_contact_allocation_summary?(%{"schema_contract" => schema_contract})
       when schema_contract in [
              "contact_allocation_report.v1",
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1",
              "contact_allocation_provider_reservation_request_summary.v1"
            ],
       do: true

  defp result_artifact_contact_allocation_summary?(_artifact), do: false

  defp put_strategy_contact_allocation_count_map(package, artifact) do
    reports =
      artifact
      |> Map.get("branches", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(fn branch ->
        [
          get_in(branch, ["repair_result", "source_contact_allocation_report"]),
          get_in(branch, ["repair_result", "contact_allocation_report"]),
          get_in(branch, [
            "repair_result",
            "source_contact_allocation_provider_reservation_request_summary"
          ]),
          get_in(branch, [
            "repair_result",
            "contact_allocation_provider_reservation_request_summary"
          ])
        ]
      end)

    put_contact_allocation_summaries(package, reports)
  end

  defp put_contact_allocation_summaries(package, reports) do
    reports =
      reports
      |> Enum.flat_map(&contact_allocation_summary_reports/1)

    package
    |> put_contact_allocation_count_summary(
      reports,
      "calendar_entry_trust_boundary_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_reservation_match_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_reservation_expiration_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "resource_blocking_dimension_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_ground_station_id"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_availability"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_precedence_availability"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_precedence_rank"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_pressure_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_pressure_review_contact_count"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_required_capacity_fraction"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_required_capacity_fraction_by_status"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "required_capacity_fraction_source_counts"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_candidate_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_request_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_review_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_no_request_contact_count"
    )
    |> put_contact_allocation_status_count_summary(
      reports,
      "provider_reservation_request_status",
      "provider_reservation_request_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "reduced_capacity_pack_status_counts"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "reduced_capacity_pack_group_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_reservation_declared_expiration_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_reservation_missing_expiration_contact_count"
    )
    |> put_contact_allocation_min_number_summary(
      reports,
      "earliest_station_reservation_expires_at_s"
    )
    |> put_contact_allocation_list_summary(reports, "station_reservation_ids")
    |> put_contact_allocation_list_summary(reports, "station_reservation_expires_at_s")
    |> put_contact_allocation_list_summary(reports, "station_reserved_bys")
    |> put_contact_allocation_list_summary(reports, "station_reservation_statuses")
    |> put_contact_allocation_list_summary(reports, "capacity_pack_group_ids")
    |> put_contact_allocation_list_summary(reports, "reduced_capacity_packed_contact_ids")
    |> put_contact_allocation_list_summary(reports, "reduced_capacity_deferred_contact_ids")
    |> put_contact_allocation_list_summary(reports, "station_pressure_review_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_request_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_review_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_no_request_contact_ids")
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_reserved_by"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_reserved_by"
    )
    |> put_contact_allocation_id_map_summary(reports, "capacity_pack_contact_ids_by_status")
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "required_capacity_fraction_contact_ids_by_source"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_group_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_expiration_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_availability"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_precedence_availability"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_precedence_rank"
    )
  end

  defp contact_allocation_summary_reports(%{} = report), do: [stringify_keys(report)]

  defp contact_allocation_summary_reports(reports) when is_list(reports) do
    Enum.flat_map(reports, &contact_allocation_summary_reports/1)
  end

  defp contact_allocation_summary_reports(_report), do: []

  defp put_contact_allocation_count_summary(package, reports, field) do
    counts =
      reports
      |> contact_allocation_count_maps(field)
      |> merge_count_maps()

    put_merged_count_map(package, field, counts)
  end

  defp put_contact_allocation_scalar_count_summary(package, reports, field) do
    counts =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_integer/1)

    case counts do
      [] -> package
      counts -> Map.put(package, field, Enum.sum(counts))
    end
  end

  defp put_contact_allocation_number_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> package
      values -> Map.put(package, field, Enum.sum(values))
    end
  end

  defp put_contact_allocation_number_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_number_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_contact_allocation_status_count_summary(package, reports, source_field, target_field) do
    counts =
      reports
      |> Enum.map(&Map.get(&1, source_field))
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.frequencies()

    put_merged_count_map(package, target_field, counts)
  end

  defp put_contact_allocation_min_number_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> package
      values -> Map.put(package, field, Enum.min(values))
    end
  end

  defp put_contact_allocation_list_summary(package, reports, field) do
    values =
      reports
      |> Enum.flat_map(fn report ->
        case Map.get(report, field) do
          values when is_list(values) -> values
          _values -> []
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case values do
      [] -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_contact_allocation_id_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_string_list_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_contact_allocation_nested_id_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_nested_string_list_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp contact_allocation_count_maps(reports, field) do
    reports
    |> Enum.map(fn
      %{} = report -> Map.get(report, field)
      _report -> nil
    end)
    |> Enum.filter(&is_map/1)
  end

  defp merge_count_maps(count_maps) do
    Enum.reduce(count_maps, %{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, key, value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
  end

  defp merge_number_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, value}, acc ->
        if is_number(value), do: Map.update(acc, key, value, &(&1 + value)), else: acc
      end)
    end)
  end

  defp put_merged_count_map(package, _field, counts) when counts == %{}, do: package
  defp put_merged_count_map(package, field, counts), do: Map.put(package, field, counts)

  defp merge_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, values}, acc ->
        values = if is_list(values), do: values, else: []

        Map.update(acc, key, values, fn current ->
          (current ++ values)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      end)
    end)
  end

  defp merge_nested_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {outer_key, inner_map}, acc ->
        inner_values = if is_map(inner_map), do: merge_string_list_maps([inner_map]), else: %{}

        Map.update(acc, outer_key, inner_values, fn current ->
          merge_string_list_maps([current, inner_values])
        end)
      end)
    end)
  end

  defp empty_to_nil(map) when map == %{}, do: nil
  defp empty_to_nil(map), do: map
end
