defmodule OrbitalDynamics.CadenceImport do
  @moduledoc """
  Builds artifact-only Cadence import manifests.

  The manifest is an adapter boundary: it names the repaired timeline changes
  that are ready, blocked, or still waiting on review before a downstream
  Cadence-side importer decides what to schedule. This module does not call
  Cadence APIs or mutate schedules.
  """

  alias OrbitalDynamics.OperatorReview

  @schema_contract "cadence_import_manifest.v1"
  @schema_version 1
  @import_statuses ~w(
    blocked_missing_cadence_import
    not_applicable
    ready_for_import
    review_required_before_import
  )
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

  @doc """
  Declares the artifact-only import-manifest model and known limits.
  """
  def capability do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_cadence_import_manifest,
      supported_sources: [
        "campaign_plan.v1",
        "campaign_repair.v2",
        "campaign_strategy.v3",
        "candidate_refresh.v1",
        "proposed_contact.v1",
        "planned_activity.v1",
        "realized_activity.v1",
        "realized_state_snapshot.v1",
        "result_artifact.v1",
        "timeline_feedback_report.v1",
        "operational_timeline_report.v1",
        "contact_contention_report.v1",
        "contact_contention_resolution_report.v1",
        "command_window_report.v1",
        "station_calendar_report.v1",
        "station_reservation_report.v1",
        "link_capacity_report.v1",
        "contact_allocation_report.v1",
        "contact_allocation_capacity_pack_summary.v1",
        "contact_allocation_reservation_conflict_summary.v1",
        "resource_projection_report.v1",
        "resource_projection_flow_summary.v1",
        "contact_intent.v1",
        "contact_filter_report.v1",
        "candidate_rejection_report.v1",
        "provider_counteroffer_report.v1",
        "candidate_diff_report.v1",
        "invalidated_candidate.v1",
        "resource_filter_report.v1",
        "freshness_report.v1",
        "refresh_budget_report.v1",
        "constraint_report.v1",
        "objective_satisfaction_report.v1",
        "maneuver_recommendation.v1",
        "maneuver_execution_delta.v1",
        "maneuver_review_report.v1",
        "timeline_diff_report.v1",
        "timeline_diff_summary.v1",
        "timeline_dependency_impact_summary.v1",
        "timeline_publication_summary.v1",
        "timeline_activity_precondition_summary.v1",
        "timeline_activity_state.v1",
        "timeline_activity_status_state.v1",
        "timeline_activity_approval_state.v1",
        "timeline_activity_lifecycle_state.v1",
        "timeline_lifecycle_state_summary.v1",
        "timeline_preservation_report.v1",
        "timeline_preservation_status.v1",
        "timeline_integrity_report.v1",
        "timeline_transition_application_summary.v1",
        "timeline_transition_application_report.v1",
        "approval_requirement.v1",
        "policy_decision.v1",
        "branch_comparison_report.v1",
        "ranking_comparison_report.v1",
        "score_term_report.v1",
        "objective_tradeoff_report.v1",
        "pareto_frontier_report.v1",
        "schema_validation_report.v1",
        "schema_validation_batch_report.v1",
        "execution_report.v1",
        "operational_readiness_report.v1",
        "quality_gate_report.v1",
        "operator_review_package.v1"
      ],
      import_actions: [
        "import_proposed_contact",
        "import_strategy_recommendation",
        "review_strategy_branch_alternative",
        "record_realized_feedback",
        "review_realized_feedback",
        "review_operational_timeline",
        "review_contact_contention",
        "review_contact_contention_resolution",
        "review_command_window",
        "review_station_calendar",
        "review_station_reservation",
        "review_link_capacity",
        "review_contact_allocation",
        "review_contact_allocation_capacity_pack",
        "review_provider_reservation_request",
        "review_contact_intent",
        "review_candidate_rejection",
        "review_provider_counteroffer",
        "review_candidate_diff",
        "review_refresh_freshness",
        "review_refresh_budget",
        "review_constraint",
        "review_objective_satisfaction",
        "review_resource_projection",
        "review_contact_suppression",
        "review_resource_suppression",
        "review_maneuver",
        "review_timeline_diff",
        "review_timeline_dependency_impact",
        "review_timeline_publication",
        "review_timeline_precondition",
        "review_timeline_lifecycle_state",
        "review_timeline_preservation",
        "review_timeline_integrity",
        "review_approval_requirement",
        "review_policy_escalation",
        "review_timeline_protection",
        "review_warning",
        "review_risk",
        "review_strategy_recommendation",
        "review_strategy_tradeoff",
        "review_score_term",
        "review_objective_tradeoff",
        "review_ranking_comparison",
        "review_pareto_frontier",
        "review_schema_validation",
        "review_execution",
        "review_operational_readiness",
        "review_quality_gate",
        "review_operator_row",
        "import_replacement_activity",
        "cancel_source_activity",
        "suppress_source_activity",
        "record_preserved_executed_activity",
        "record_preserved_activity",
        "review_plan_delta"
      ],
      source_review_types: source_review_types(),
      import_statuses: @import_statuses,
      cadence_import_statuses: @cadence_import_statuses,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      handoff_row_semantics: [
        :schema_validation_import_rows,
        :schema_validation_issue_context,
        :schema_validation_batch_nested_report_context,
        :operational_readiness_import_rows,
        :operational_readiness_gate_rows,
        :operational_readiness_resource_summary_context,
        :operational_readiness_resource_gate_context,
        :operational_readiness_adapter_boundary_context,
        :operational_readiness_cadence_import_gate_context,
        :quality_gate_import_rows,
        :quality_gate_resource_row_context,
        :timeline_diff_summary_import_rows,
        :timeline_diff_summary_source_handoff_consistency,
        :timeline_dependency_impact_import_rows,
        :timeline_dependency_impact_source_handoff_consistency,
        :timeline_publication_import_rows,
        :timeline_publication_source_handoff_consistency,
        :timeline_lifecycle_state_import_rows,
        :timeline_lifecycle_state_source_handoff_consistency,
        :timeline_activity_precondition_import_rows,
        :timeline_activity_precondition_source_handoff_consistency,
        :timeline_preservation_import_rows,
        :timeline_preservation_source_handoff_consistency,
        :timeline_integrity_import_rows,
        :timeline_integrity_source_handoff_consistency,
        :timeline_transition_application_summary_import_rows,
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
        :suppression_source_handoff_consistency,
        :review_package_passthrough_rows
      ],
      known_limits: [
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_resolve_schedule_conflicts,
        :review_rows_are_adapter_handoff_not_operator_approval
      ]
    }
  end

  @doc """
  Returns the import-manifest capability metadata using the common plural API.
  """
  def capabilities, do: capability()

  defp source_review_types do
    OperatorReview.capabilities().review_types ++
      [
        "proposed_contact",
        "strategy_branch_comparison"
      ]
  end

  @doc """
  Builds a `cadence_import_manifest.v1` from a supported artifact.
  """
  def manifest(artifact, opts \\ [])

  def manifest(%{"schema_contract" => "cadence_import_manifest.v1"} = manifest, _opts),
    do: manifest

  def manifest(%{schema_contract: "cadence_import_manifest.v1"} = manifest, _opts),
    do: stringify_keys(manifest)

  def manifest(%{"campaign_plan" => %{} = artifact}, opts),
    do: from_campaign_artifact(artifact, opts)

  def manifest(%{campaign_plan: %{} = artifact}, opts),
    do: artifact |> stringify_keys() |> from_campaign_artifact(opts)

  def manifest(%{"candidate_refresh" => %{} = artifact}, opts),
    do: from_candidate_refresh_artifact(artifact, opts)

  def manifest(%{candidate_refresh: %{} = artifact}, opts),
    do: artifact |> stringify_keys() |> from_candidate_refresh_artifact(opts)

  def manifest(%{"schema_contract" => "timeline_diff_summary.v1"} = summary, opts),
    do: from_timeline_diff_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_diff_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_diff_summary(opts)

  def manifest(%{"model" => "artifact_only_timeline_diff_summary"} = summary, opts)
      when not is_map_key(summary, "schema_contract") do
    from_timeline_diff_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_diff_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_diff_summary(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_dependency_impact_summary"} = summary, opts)
      when not is_map_key(summary, "schema_contract") do
    from_timeline_dependency_impact_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_dependency_impact_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_dependency_impact_summary(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_publication_summary"} = summary, opts)
      when not is_map_key(summary, "schema_contract") do
    from_timeline_publication_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_publication_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_publication_summary(opts)
  end

  def manifest(
        %{"model" => "artifact_only_timeline_activity_precondition_summary"} = summary,
        opts
      )
      when not is_map_key(summary, "schema_contract") do
    from_timeline_activity_precondition_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_activity_precondition_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_activity_precondition_summary(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_lifecycle_state_summary"} = summary, opts)
      when not is_map_key(summary, "schema_contract") do
    from_timeline_lifecycle_state_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_lifecycle_state_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_lifecycle_state_summary(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_activity_state"} = state, opts)
      when not is_map_key(state, "schema_contract") do
    from_timeline_activity_state(state, opts)
  end

  def manifest(%{model: "artifact_only_timeline_activity_state"} = state, opts)
      when not is_map_key(state, :schema_contract) do
    state |> stringify_keys() |> from_timeline_activity_state(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_activity_status_state"} = state, opts)
      when not is_map_key(state, "schema_contract") do
    from_timeline_activity_status_state(state, opts)
  end

  def manifest(%{model: "artifact_only_timeline_activity_status_state"} = state, opts)
      when not is_map_key(state, :schema_contract) do
    state |> stringify_keys() |> from_timeline_activity_status_state(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_activity_approval_state"} = state, opts)
      when not is_map_key(state, "schema_contract") do
    from_timeline_activity_approval_state(state, opts)
  end

  def manifest(%{model: "artifact_only_timeline_activity_approval_state"} = state, opts)
      when not is_map_key(state, :schema_contract) do
    state |> stringify_keys() |> from_timeline_activity_approval_state(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_activity_lifecycle_state"} = state, opts)
      when not is_map_key(state, "schema_contract") do
    from_timeline_activity_lifecycle_state(state, opts)
  end

  def manifest(%{model: "artifact_only_timeline_activity_lifecycle_state"} = state, opts)
      when not is_map_key(state, :schema_contract) do
    state |> stringify_keys() |> from_timeline_activity_lifecycle_state(opts)
  end

  def manifest(%{"model" => "artifact_only_lifecycle_preservation_summary"} = report, opts)
      when not is_map_key(report, "schema_contract") do
    from_timeline_preservation_report(report, opts)
  end

  def manifest(%{model: "artifact_only_lifecycle_preservation_summary"} = report, opts)
      when not is_map_key(report, :schema_contract) do
    report |> stringify_keys() |> from_timeline_preservation_report(opts)
  end

  def manifest(%{"model" => "artifact_only_lifecycle_preservation_status"} = status, opts)
      when not is_map_key(status, "schema_contract") do
    from_timeline_preservation_status(status, opts)
  end

  def manifest(%{model: "artifact_only_lifecycle_preservation_status"} = status, opts)
      when not is_map_key(status, :schema_contract) do
    status |> stringify_keys() |> from_timeline_preservation_status(opts)
  end

  def manifest(%{"schema_contract" => "timeline_integrity_report.v1"} = report, opts),
    do: from_timeline_integrity_report(report, opts)

  def manifest(%{schema_contract: "timeline_integrity_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_timeline_integrity_report(opts)

  def manifest(%{"model" => "artifact_only_timeline_integrity_summary"} = report, opts)
      when not is_map_key(report, "schema_contract") do
    from_timeline_integrity_report(report, opts)
  end

  def manifest(%{model: "artifact_only_timeline_integrity_summary"} = report, opts)
      when not is_map_key(report, :schema_contract) do
    report |> stringify_keys() |> from_timeline_integrity_report(opts)
  end

  def manifest(
        %{"schema_contract" => "timeline_transition_application_summary.v1"} = summary,
        opts
      ),
      do: from_timeline_transition_application_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_transition_application_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_transition_application_summary(opts)

  def manifest(
        %{"model" => "artifact_only_timeline_transition_application_summary"} = summary,
        opts
      )
      when not is_map_key(summary, "schema_contract") do
    from_timeline_transition_application_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_transition_application_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_transition_application_summary(opts)
  end

  def manifest(%{"schema_version" => 2} = artifact, opts)
      when not is_map_key(artifact, "schema_contract") do
    from_repair_artifact(artifact, opts)
  end

  def manifest(%{"schema_version" => 1, "run" => %{}, "execution_report" => %{}} = artifact, opts)
      when not is_map_key(artifact, "schema_contract") do
    from_result_artifact(artifact, opts)
  end

  def manifest(%{"schema_version" => 3} = artifact, opts)
      when not is_map_key(artifact, "schema_contract") do
    from_strategy_artifact(artifact, opts)
  end

  def manifest(%{"schema_version" => 1} = artifact, opts)
      when not is_map_key(artifact, "schema_contract") do
    from_campaign_artifact(artifact, opts)
  end

  def manifest(%{"schema_contract" => "campaign_repair.v2"} = artifact, opts),
    do: from_repair_artifact(artifact, opts)

  def manifest(%{"schema_contract" => "campaign_strategy.v3"} = artifact, opts),
    do: from_strategy_artifact(artifact, opts)

  def manifest(%{"schema_contract" => "campaign_plan.v1"} = artifact, opts),
    do: from_campaign_artifact(artifact, opts)

  def manifest(%{"schema_contract" => "candidate_refresh.v1"} = artifact, opts),
    do: from_candidate_refresh_artifact(artifact, opts)

  def manifest(%{"schema_contract" => "result_artifact.v1"} = artifact, opts),
    do: from_result_artifact(artifact, opts)

  def manifest(%{schema_version: 2} = artifact, opts)
      when not is_map_key(artifact, :schema_contract) do
    artifact |> stringify_keys() |> from_repair_artifact(opts)
  end

  def manifest(%{schema_version: 1, run: %{}, execution_report: %{}} = artifact, opts)
      when not is_map_key(artifact, :schema_contract) do
    artifact |> stringify_keys() |> from_result_artifact(opts)
  end

  def manifest(%{schema_version: 3} = artifact, opts)
      when not is_map_key(artifact, :schema_contract) do
    artifact |> stringify_keys() |> from_strategy_artifact(opts)
  end

  def manifest(%{schema_version: 1} = artifact, opts)
      when not is_map_key(artifact, :schema_contract) do
    artifact |> stringify_keys() |> from_campaign_artifact(opts)
  end

  def manifest(%{schema_contract: "campaign_repair.v2"} = artifact, opts),
    do: artifact |> stringify_keys() |> from_repair_artifact(opts)

  def manifest(%{schema_contract: "campaign_strategy.v3"} = artifact, opts),
    do: artifact |> stringify_keys() |> from_strategy_artifact(opts)

  def manifest(%{schema_contract: "campaign_plan.v1"} = artifact, opts),
    do: artifact |> stringify_keys() |> from_campaign_artifact(opts)

  def manifest(%{schema_contract: "candidate_refresh.v1"} = artifact, opts),
    do: artifact |> stringify_keys() |> from_candidate_refresh_artifact(opts)

  def manifest(%{schema_contract: "result_artifact.v1"} = artifact, opts),
    do: artifact |> stringify_keys() |> from_result_artifact(opts)

  def manifest(
        %{"cadence_import" => %{"schema_contract" => "proposed_contact.v1"}} = contact,
        opts
      )
      when not is_map_key(contact, "schema_contract"),
      do: from_proposed_contact(contact, opts)

  def manifest(%{cadence_import: %{schema_contract: "proposed_contact.v1"}} = contact, opts)
      when not is_map_key(contact, :schema_contract),
      do: contact |> stringify_keys() |> from_proposed_contact(opts)

  def manifest(%{"schema_contract" => "proposed_contact.v1"} = contact, opts),
    do: from_proposed_contact(contact, opts)

  def manifest(%{schema_contract: "proposed_contact.v1"} = contact, opts),
    do: contact |> stringify_keys() |> from_proposed_contact(opts)

  def manifest(%{"schema_contract" => "planned_activity.v1"} = activity, opts),
    do: from_planned_activity(activity, opts)

  def manifest(%{schema_contract: "planned_activity.v1"} = activity, opts),
    do: activity |> stringify_keys() |> from_planned_activity(opts)

  def manifest(%{"schema_contract" => "realized_activity.v1"} = activity, opts),
    do: from_realized_activity(activity, opts)

  def manifest(%{schema_contract: "realized_activity.v1"} = activity, opts),
    do: activity |> stringify_keys() |> from_realized_activity(opts)

  def manifest(%{"schema_contract" => "realized_state_snapshot.v1"} = snapshot, opts),
    do: from_realized_state_snapshot(snapshot, opts)

  def manifest(%{schema_contract: "realized_state_snapshot.v1"} = snapshot, opts),
    do: snapshot |> stringify_keys() |> from_realized_state_snapshot(opts)

  def manifest(%{"schema_contract" => "operator_review_package.v1"} = package, opts),
    do: from_operator_review_package(package, opts)

  def manifest(%{schema_contract: "operator_review_package.v1"} = package, opts),
    do: package |> stringify_keys() |> from_operator_review_package(opts)

  def manifest(%{"schema_contract" => "timeline_feedback_report.v1"} = report, opts),
    do: from_timeline_feedback_report(report, opts)

  def manifest(%{schema_contract: "timeline_feedback_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_timeline_feedback_report(opts)

  def manifest(%{"schema_contract" => "operational_timeline_report.v1"} = report, opts),
    do: from_operational_timeline_report(report, opts)

  def manifest(%{schema_contract: "operational_timeline_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_operational_timeline_report(opts)

  def manifest(%{"schema_contract" => "contact_contention_report.v1"} = report, opts),
    do: from_contact_contention_report(report, opts)

  def manifest(%{schema_contract: "contact_contention_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_contact_contention_report(opts)

  def manifest(%{"schema_contract" => "contact_contention_resolution_report.v1"} = report, opts),
    do: from_contact_contention_resolution_report(report, opts)

  def manifest(%{schema_contract: "contact_contention_resolution_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_contact_contention_resolution_report(opts)

  def manifest(%{"schema_contract" => "command_window_report.v1"} = report, opts),
    do: from_command_window_report(report, opts)

  def manifest(%{schema_contract: "command_window_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_command_window_report(opts)

  def manifest(%{"schema_contract" => "station_calendar_report.v1"} = report, opts),
    do: from_station_calendar_report(report, opts)

  def manifest(%{schema_contract: "station_calendar_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_station_calendar_report(opts)

  def manifest(%{"schema_contract" => "station_reservation_report.v1"} = report, opts),
    do: from_station_reservation_report(report, opts)

  def manifest(%{schema_contract: "station_reservation_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_station_reservation_report(opts)

  def manifest(%{"schema_contract" => "link_capacity_report.v1"} = report, opts),
    do: from_link_capacity_report(report, opts)

  def manifest(%{schema_contract: "link_capacity_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_link_capacity_report(opts)

  def manifest(%{"schema_contract" => "contact_allocation_report.v1"} = report, opts),
    do: from_contact_allocation_report(report, opts)

  def manifest(%{schema_contract: "contact_allocation_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_contact_allocation_report(opts)

  def manifest(
        %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"} = summary,
        opts
      ),
      do: from_contact_allocation_capacity_pack_summary(summary, opts)

  def manifest(%{schema_contract: "contact_allocation_capacity_pack_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_contact_allocation_capacity_pack_summary(opts)

  def manifest(
        %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"} = summary,
        opts
      ),
      do: from_contact_allocation_reservation_conflict_summary(summary, opts)

  def manifest(
        %{schema_contract: "contact_allocation_reservation_conflict_summary.v1"} = summary,
        opts
      ),
      do:
        summary |> stringify_keys() |> from_contact_allocation_reservation_conflict_summary(opts)

  def manifest(%{"schema_contract" => "contact_intent.v1"} = intent, opts),
    do: from_contact_intent(intent, opts)

  def manifest(%{schema_contract: "contact_intent.v1"} = intent, opts),
    do: intent |> stringify_keys() |> from_contact_intent(opts)

  def manifest(%{"schema_contract" => "resource_projection_report.v1"} = report, opts),
    do: from_resource_projection_report(report, opts)

  def manifest(%{schema_contract: "resource_projection_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_resource_projection_report(opts)

  def manifest(%{"schema_contract" => "resource_projection_flow_summary.v1"} = summary, opts),
    do: from_resource_projection_flow_summary(summary, opts)

  def manifest(%{schema_contract: "resource_projection_flow_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_resource_projection_flow_summary(opts)

  def manifest(%{"schema_contract" => "contact_filter_report.v1"} = report, opts),
    do: from_contact_filter_report(report, opts)

  def manifest(%{schema_contract: "contact_filter_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_contact_filter_report(opts)

  def manifest(%{"schema_contract" => "candidate_diff_report.v1"} = report, opts),
    do: from_candidate_diff_report(report, opts)

  def manifest(%{schema_contract: "candidate_diff_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_candidate_diff_report(opts)

  def manifest(%{"schema_contract" => "candidate_rejection_report.v1"} = report, opts),
    do: from_candidate_rejection_report(report, opts)

  def manifest(%{schema_contract: "candidate_rejection_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_candidate_rejection_report(opts)

  def manifest(%{"schema_contract" => "provider_counteroffer_report.v1"} = report, opts),
    do: from_provider_counteroffer_report(report, opts)

  def manifest(%{schema_contract: "provider_counteroffer_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_provider_counteroffer_report(opts)

  def manifest(%{"schema_contract" => "invalidated_candidate.v1"} = candidate, opts),
    do: from_invalidated_candidate(candidate, opts)

  def manifest(%{schema_contract: "invalidated_candidate.v1"} = candidate, opts),
    do: candidate |> stringify_keys() |> from_invalidated_candidate(opts)

  def manifest(%{"schema_contract" => "resource_filter_report.v1"} = report, opts),
    do: from_resource_filter_report(report, opts)

  def manifest(%{schema_contract: "resource_filter_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_resource_filter_report(opts)

  def manifest(%{"schema_contract" => "freshness_report.v1"} = report, opts),
    do: from_freshness_report(report, opts)

  def manifest(%{schema_contract: "freshness_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_freshness_report(opts)

  def manifest(%{"schema_contract" => "refresh_budget_report.v1"} = report, opts),
    do: from_refresh_budget_report(report, opts)

  def manifest(%{schema_contract: "refresh_budget_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_refresh_budget_report(opts)

  def manifest(%{"schema_contract" => "constraint_report.v1"} = report, opts),
    do: from_constraint_report(report, opts)

  def manifest(%{schema_contract: "constraint_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_constraint_report(opts)

  def manifest(%{"schema_contract" => "objective_satisfaction_report.v1"} = report, opts),
    do: from_objective_satisfaction_report(report, opts)

  def manifest(%{schema_contract: "objective_satisfaction_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_objective_satisfaction_report(opts)

  def manifest(%{"schema_contract" => "maneuver_recommendation.v1"} = recommendation, opts),
    do: from_maneuver_recommendation(recommendation, opts)

  def manifest(%{schema_contract: "maneuver_recommendation.v1"} = recommendation, opts),
    do: recommendation |> stringify_keys() |> from_maneuver_recommendation(opts)

  def manifest(%{"schema_contract" => "maneuver_execution_delta.v1"} = delta, opts),
    do: from_maneuver_execution_delta(delta, opts)

  def manifest(%{schema_contract: "maneuver_execution_delta.v1"} = delta, opts),
    do: delta |> stringify_keys() |> from_maneuver_execution_delta(opts)

  def manifest(%{"schema_contract" => "maneuver_review_report.v1"} = report, opts),
    do: from_maneuver_review_report(report, opts)

  def manifest(%{schema_contract: "maneuver_review_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_maneuver_review_report(opts)

  def manifest(%{"schema_contract" => "timeline_diff_report.v1"} = report, opts),
    do: from_timeline_diff_report(report, opts)

  def manifest(%{schema_contract: "timeline_diff_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_timeline_diff_report(opts)

  def manifest(%{"schema_contract" => "timeline_dependency_impact_summary.v1"} = summary, opts),
    do: from_timeline_dependency_impact_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_dependency_impact_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_dependency_impact_summary(opts)

  def manifest(%{"schema_contract" => "timeline_publication_summary.v1"} = summary, opts),
    do: from_timeline_publication_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_publication_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_publication_summary(opts)

  def manifest(
        %{"schema_contract" => "timeline_activity_precondition_summary.v1"} = summary,
        opts
      ),
      do: from_timeline_activity_precondition_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_activity_precondition_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_activity_precondition_summary(opts)

  def manifest(%{"schema_contract" => "timeline_lifecycle_state_summary.v1"} = summary, opts),
    do: from_timeline_lifecycle_state_summary(summary, opts)

  def manifest(%{schema_contract: "timeline_lifecycle_state_summary.v1"} = summary, opts),
    do: summary |> stringify_keys() |> from_timeline_lifecycle_state_summary(opts)

  def manifest(%{"schema_contract" => "timeline_activity_state.v1"} = state, opts),
    do: from_timeline_activity_state(state, opts)

  def manifest(%{schema_contract: "timeline_activity_state.v1"} = state, opts),
    do: state |> stringify_keys() |> from_timeline_activity_state(opts)

  def manifest(%{"schema_contract" => "timeline_activity_status_state.v1"} = state, opts),
    do: from_timeline_activity_status_state(state, opts)

  def manifest(%{schema_contract: "timeline_activity_status_state.v1"} = state, opts),
    do: state |> stringify_keys() |> from_timeline_activity_status_state(opts)

  def manifest(%{"schema_contract" => "timeline_activity_approval_state.v1"} = state, opts),
    do: from_timeline_activity_approval_state(state, opts)

  def manifest(%{schema_contract: "timeline_activity_approval_state.v1"} = state, opts),
    do: state |> stringify_keys() |> from_timeline_activity_approval_state(opts)

  def manifest(%{"schema_contract" => "timeline_activity_lifecycle_state.v1"} = state, opts),
    do: from_timeline_activity_lifecycle_state(state, opts)

  def manifest(%{schema_contract: "timeline_activity_lifecycle_state.v1"} = state, opts),
    do: state |> stringify_keys() |> from_timeline_activity_lifecycle_state(opts)

  def manifest(%{"schema_contract" => "timeline_preservation_report.v1"} = report, opts),
    do: from_timeline_preservation_report(report, opts)

  def manifest(%{schema_contract: "timeline_preservation_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_timeline_preservation_report(opts)

  def manifest(%{"schema_contract" => "timeline_preservation_status.v1"} = status, opts),
    do: from_timeline_preservation_status(status, opts)

  def manifest(%{schema_contract: "timeline_preservation_status.v1"} = status, opts),
    do: status |> stringify_keys() |> from_timeline_preservation_status(opts)

  def manifest(%{"model" => "artifact_only_timeline_diff_summary"} = summary, opts)
      when not is_map_key(summary, "schema_contract") do
    from_timeline_diff_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_diff_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_diff_summary(opts)
  end

  def manifest(%{"model" => "artifact_only_timeline_integrity_summary"} = report, opts)
      when not is_map_key(report, "schema_contract") do
    from_timeline_integrity_report(report, opts)
  end

  def manifest(%{model: "artifact_only_timeline_integrity_summary"} = report, opts)
      when not is_map_key(report, :schema_contract) do
    report |> stringify_keys() |> from_timeline_integrity_report(opts)
  end

  def manifest(
        %{"model" => "artifact_only_timeline_transition_application_summary"} = summary,
        opts
      )
      when not is_map_key(summary, "schema_contract") do
    from_timeline_transition_application_summary(summary, opts)
  end

  def manifest(%{model: "artifact_only_timeline_transition_application_summary"} = summary, opts)
      when not is_map_key(summary, :schema_contract) do
    summary |> stringify_keys() |> from_timeline_transition_application_summary(opts)
  end

  def manifest(
        %{"schema_contract" => "timeline_transition_application_report.v1"} = report,
        opts
      ),
      do: from_timeline_transition_application_report(report, opts)

  def manifest(%{schema_contract: "timeline_transition_application_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_timeline_transition_application_report(opts)

  def manifest(%{"schema_contract" => "approval_requirement.v1"} = requirement, opts),
    do: from_approval_requirement(requirement, opts)

  def manifest(%{schema_contract: "approval_requirement.v1"} = requirement, opts),
    do: requirement |> stringify_keys() |> from_approval_requirement(opts)

  def manifest(%{"schema_contract" => "policy_decision.v1"} = decision, opts),
    do: from_policy_decision(decision, opts)

  def manifest(%{schema_contract: "policy_decision.v1"} = decision, opts),
    do: decision |> stringify_keys() |> from_policy_decision(opts)

  def manifest(%{"schema_contract" => "branch_comparison_report.v1"} = report, opts),
    do: from_branch_comparison_report(report, opts)

  def manifest(%{schema_contract: "branch_comparison_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_branch_comparison_report(opts)

  def manifest(%{"schema_contract" => "ranking_comparison_report.v1"} = report, opts),
    do: from_ranking_comparison_report(report, opts)

  def manifest(%{schema_contract: "ranking_comparison_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_ranking_comparison_report(opts)

  def manifest(%{"schema_contract" => "score_term_report.v1"} = report, opts),
    do: from_score_term_report(report, opts)

  def manifest(%{schema_contract: "score_term_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_score_term_report(opts)

  def manifest(%{"schema_contract" => "objective_tradeoff_report.v1"} = report, opts),
    do: from_objective_tradeoff_report(report, opts)

  def manifest(%{schema_contract: "objective_tradeoff_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_objective_tradeoff_report(opts)

  def manifest(%{"schema_contract" => "pareto_frontier_report.v1"} = report, opts),
    do: from_pareto_frontier_report(report, opts)

  def manifest(%{schema_contract: "pareto_frontier_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_pareto_frontier_report(opts)

  def manifest(%{"schema_contract" => "schema_validation_report.v1"} = report, opts),
    do: from_schema_validation_report(report, opts)

  def manifest(%{schema_contract: "schema_validation_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_schema_validation_report(opts)

  def manifest(%{"schema_contract" => "schema_validation_batch_report.v1"} = report, opts),
    do: from_schema_validation_batch_report(report, opts)

  def manifest(%{schema_contract: "schema_validation_batch_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_schema_validation_batch_report(opts)

  def manifest(%{"schema_contract" => "execution_report.v1"} = report, opts),
    do: from_execution_report(report, opts)

  def manifest(%{schema_contract: "execution_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_execution_report(opts)

  def manifest(%{"schema_contract" => "operational_readiness_report.v1"} = report, opts),
    do: from_operational_readiness_report(report, opts)

  def manifest(%{schema_contract: "operational_readiness_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_operational_readiness_report(opts)

  def manifest(%{"schema_contract" => "quality_gate_report.v1"} = report, opts),
    do: from_quality_gate_report(report, opts)

  def manifest(%{schema_contract: "quality_gate_report.v1"} = report, opts),
    do: report |> stringify_keys() |> from_quality_gate_report(opts)

  def manifest(%{} = artifact, _opts) do
    contract = unsupported_manifest_contract(artifact)

    raise ArgumentError,
          "unsupported Cadence import artifact contract #{inspect(contract)}; " <>
            "supported contracts: #{supported_manifest_contracts()}"
  end

  def manifest(_artifact, _opts) do
    raise ArgumentError, "Cadence import artifact must be a map"
  end

  @doc """
  Builds an import manifest from a V1 campaign plan artifact.
  """
  def from_campaign_artifact(%{} = artifact, opts \\ []) do
    artifact = stringify_keys(artifact)
    source_artifact_id = option(opts, :source_artifact_id, artifact["plan_id"])
    review_package = OperatorReview.from_campaign_artifact(artifact)

    rows =
      artifact
      |> Map.get("proposed_contacts", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.sort_by(&{Map.get(&1, "starts_at_s", 0.0), Map.get(&1, "id", "")})
      |> Enum.with_index(1)
      |> Enum.map(fn {contact, rank} -> proposed_contact_manifest_row(contact, rank) end)

    review_rows =
      review_package
      |> Map.get("rows", [])
      |> Enum.filter(
        &(&1["review_type"] in [
            "contact_contention_recommendation",
            "contact_contention_review",
            "operational_timeline_review",
            "timeline_integrity_review",
            "command_window_review",
            "station_calendar_review",
            "link_capacity_review",
            "resource_projection_review",
            "timeline_activity_precondition_review",
            "objective_satisfaction_review",
            "score_term_review",
            "objective_tradeoff_review",
            "contact_allocation_review",
            "contact_intent_review",
            "constraint_review"
          ])
      )
      |> Enum.with_index(length(rows) + 1)
      |> Enum.map(fn {row, rank} -> review_manifest_row(row, rank) end)

    rows = rows ++ review_rows

    build_manifest(
      rows,
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_campaign_artifact",
        "source_artifact_type" => "campaign_plan.v1",
        "source_artifact_id" => source_artifact_id,
        "source_plan_id" => artifact["plan_id"],
        "source_proposed_contact_count" => length(Map.get(artifact, "proposed_contacts", []))
      }
      |> Map.merge(review_summary_context(review_package)),
      %{
        "source_artifact_type" => "campaign_plan.v1",
        "source_artifact_id" => source_artifact_id,
        "row_source" =>
          "campaign_plan.proposed_contacts_contact_contention_groups_recommendations_operational_timeline_integrity_activity_precondition_command_window_station_calendar_link_capacity_resource_projection_objective_satisfaction_score_term_objective_tradeoff_and_contact_allocation_rows",
        "deterministic_ordering" =>
          "proposed_contacts_starts_at_s_then_contact_id_then_operator_review_row_order"
      }
      |> Map.merge(review_summary_context(review_package))
    )
  end

  @doc """
  Builds an import manifest from a standalone proposed-contact row.
  """
  def from_proposed_contact(%{} = contact, opts \\ []) do
    contact = stringify_keys(contact)
    source_artifact_id = option(opts, :source_artifact_id, contact["id"])

    build_manifest(
      [proposed_contact_manifest_row(contact, 1)],
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_proposed_contact",
        "source_artifact_type" => "proposed_contact.v1",
        "source_artifact_id" => source_artifact_id
      },
      %{
        "source_artifact_type" => "proposed_contact.v1",
        "source_artifact_id" => source_artifact_id || "proposed_contact",
        "row_source" => "proposed_contact",
        "deterministic_ordering" => "single proposed contact"
      }
    )
  end

  @doc """
  Builds an import manifest from a standalone planned-activity row.
  """
  def from_planned_activity(%{} = activity, opts \\ []) do
    activity = stringify_keys(activity)

    source_artifact_id =
      option(opts, :source_artifact_id, activity["id"] || activity["activity_id"])

    from_review_report(
      OperatorReview.from_planned_activity(activity),
      opts,
      "planned_activity.v1",
      source_artifact_id || "planned_activity"
    )
  end

  @doc """
  Builds an import manifest from a standalone realized-activity row.
  """
  def from_realized_activity(%{} = activity, opts \\ []) do
    activity = stringify_keys(activity)

    source_artifact_id =
      option(opts, :source_artifact_id, activity["id"] || activity["realized_activity_id"])

    from_review_report(
      OperatorReview.from_realized_activity(activity),
      opts,
      "realized_activity.v1",
      source_artifact_id || "realized_activity"
    )
  end

  @doc """
  Builds an import manifest from a realized-state snapshot.
  """
  def from_realized_state_snapshot(%{} = snapshot, opts \\ []) do
    snapshot = stringify_keys(snapshot)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        snapshot["snapshot_id"] || get_in(snapshot, ["metadata", "snapshot_id"])
      )

    from_review_report(
      OperatorReview.from_realized_state_snapshot(snapshot),
      opts,
      "realized_state_snapshot.v1",
      source_artifact_id || "realized_state_snapshot"
    )
  end

  @doc """
  Builds an import manifest from a top-level study result artifact.
  """
  def from_result_artifact(%{} = artifact, opts \\ []) do
    artifact = stringify_keys(artifact)

    source_artifact_id =
      option(opts, :source_artifact_id, result_artifact_source_id(artifact))

    from_review_report(
      OperatorReview.from_result_artifact(artifact),
      opts,
      "result_artifact.v1",
      source_artifact_id || "result_artifact"
    )
  end

  @doc """
  Builds an import manifest from a candidate refresh artifact.
  """
  def from_candidate_refresh_artifact(%{} = artifact, opts \\ []) do
    artifact = stringify_keys(artifact)

    review_package =
      Map.get(artifact, "operator_review_package") ||
        OperatorReview.from_candidate_refresh_artifact(artifact)

    source_artifact_id = option(opts, :source_artifact_id, Map.get(artifact, "refresh_id"))

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "candidate_refresh.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from a V3 strategy artifact.
  """
  def from_strategy_artifact(%{} = artifact, opts \\ []) do
    artifact = stringify_keys(artifact)

    source_artifact_id =
      option(opts, :source_artifact_id, get_in(artifact, ["strategy_metadata", "strategy_id"]))

    recommendation = Map.get(artifact, "recommendation", %{})
    comparison_rows = get_in(artifact, ["branch_comparison_report", "rows"]) || []
    review_package = strategy_review_package(artifact)

    operational_feedback_context =
      operational_feedback_manifest_context(Map.get(artifact, "operational_feedback_provenance"))

    rows =
      comparison_rows
      |> Enum.map(&stringify_keys/1)
      |> Enum.sort_by(&{Map.get(&1, "rank", 0), Map.get(&1, "branch_id", "")})
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        strategy_manifest_row(row, recommendation, rank, operational_feedback_context)
      end)

    review_rows = strategy_review_manifest_rows(review_package, length(rows) + 1)
    rows = rows ++ review_rows

    build_manifest(
      rows,
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_strategy_artifact",
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => source_artifact_id,
        "source_plan_id" => artifact["source_plan_id"],
        "source_repair_id" => artifact["source_repair_id"],
        "recommended_branch_id" => recommendation["recommended_branch_id"],
        "source_branch_count" => length(comparison_rows),
        "source_review_count" => strategy_review_count(review_package),
        "operator_review_package_source" =>
          if(Map.has_key?(artifact, "operator_review_package"), do: "embedded", else: "derived")
      }
      |> Map.merge(review_summary_context(review_package)),
      %{
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => source_artifact_id,
        "row_source" =>
          "campaign_strategy.branch_comparison_report.rows_and_operator_review_package.rows",
        "deterministic_ordering" => "branch_comparison_rank_then_branch_id"
      }
      |> Map.merge(review_summary_context(review_package))
    )
  end

  @doc """
  Builds an import manifest from a V2 repair artifact.
  """
  def from_repair_artifact(%{} = artifact, opts \\ []) do
    artifact = stringify_keys(artifact)

    review_package =
      Map.get(artifact, "operator_review_package") ||
        OperatorReview.from_repair_artifact(artifact)

    source_artifact_id =
      get_in(artifact, ["repair_metadata", "repair_id"]) ||
        Map.get(artifact, "source_plan_id", "campaign_repair")

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "campaign_repair.v2",
        source_artifact_id: source_artifact_id,
        source_repair_id: source_artifact_id,
        source_plan_id: Map.get(artifact, "source_plan_id")
      )
    )
  end

  @doc """
  Builds an import manifest from a realized timeline feedback report.
  """
  def from_timeline_feedback_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    review_package =
      Map.get(report, "operator_review_package") ||
        OperatorReview.from_timeline_feedback_report(report)

    source_artifact_id =
      option(opts, :source_artifact_id, Map.get(report, "id") || "timeline_feedback_report")

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "timeline_feedback_report.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from an operational timeline report.
  """
  def from_operational_timeline_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_operational_timeline_report(report),
      opts,
      "operational_timeline_report.v1",
      source_artifact_id || "operational_timeline_report"
    )
  end

  @doc """
  Builds an import manifest from a contact-contention report.
  """
  def from_contact_contention_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    review_package =
      Map.get(report, "operator_review_package") ||
        OperatorReview.from_contact_contention_report(report)

    source_artifact_id =
      option(opts, :source_artifact_id, Map.get(report, "id") || "contact_contention_report")

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "contact_contention_report.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from a contact-contention resolution report.
  """
  def from_contact_contention_resolution_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    review_package =
      Map.get(report, "operator_review_package") ||
        OperatorReview.from_contact_contention_resolution_report(report)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        Map.get(report, "id") || "contact_contention_resolution_report"
      )

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "contact_contention_resolution_report.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from a command-window report.
  """
  def from_command_window_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    review_package =
      Map.get(report, "operator_review_package") ||
        OperatorReview.from_command_window_report(report)

    source_artifact_id =
      option(opts, :source_artifact_id, Map.get(report, "id") || Map.get(report, "source")) ||
        "command_window_report"

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "command_window_report.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from a station-calendar report.
  """
  def from_station_calendar_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    review_package =
      Map.get(report, "operator_review_package") ||
        OperatorReview.from_station_calendar_report(report)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        Map.get(report, "id") || get_in(report, ["assumptions", "source"])
      ) || "station_calendar_report"

    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "station_calendar_report.v1",
        source_artifact_id: source_artifact_id
      )
    )
  end

  @doc """
  Builds an import manifest from a station-reservation report.
  """
  def from_station_reservation_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_station_reservation_report(report),
      opts,
      "station_reservation_report.v1",
      source_artifact_id || "station_reservation_report"
    )
  end

  @doc """
  Builds an import manifest from a link-capacity report.
  """
  def from_link_capacity_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_link_capacity_report(report),
      opts,
      "link_capacity_report.v1",
      source_artifact_id || "link_capacity_report"
    )
  end

  @doc """
  Builds an import manifest from a contact-allocation report.
  """
  def from_contact_allocation_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_contact_allocation_report(report),
      opts,
      "contact_allocation_report.v1",
      source_artifact_id || "contact_allocation_report"
    )
  end

  @doc """
  Builds an import manifest from a contact-allocation capacity-pack summary.
  """
  def from_contact_allocation_capacity_pack_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_contact_allocation_capacity_pack_summary(summary),
      opts,
      "contact_allocation_capacity_pack_summary.v1",
      source_artifact_id || "contact_allocation_capacity_pack_summary"
    )
  end

  @doc """
  Builds an import manifest from a contact-allocation reservation-conflict summary.
  """
  def from_contact_allocation_reservation_conflict_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_contact_allocation_reservation_conflict_summary(summary),
      opts,
      "contact_allocation_reservation_conflict_summary.v1",
      source_artifact_id || "contact_allocation_reservation_conflict_summary"
    )
  end

  @doc """
  Builds an import manifest from a standalone contact-intent row.
  """
  def from_contact_intent(%{} = intent, opts \\ []) do
    intent = stringify_keys(intent)
    source_artifact_id = option(opts, :source_artifact_id, intent["id"] || intent["activity_id"])

    from_review_report(
      OperatorReview.from_contact_intent(intent),
      opts,
      "contact_intent.v1",
      source_artifact_id || "contact_intent"
    )
  end

  @doc """
  Builds an import manifest from a resource-projection report.
  """
  def from_resource_projection_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, report["id"] || get_in(report, ["assumptions", "source"]))

    from_review_report(
      OperatorReview.from_resource_projection_report(report),
      opts,
      "resource_projection_report.v1",
      source_artifact_id || "resource_projection_report"
    )
  end

  @doc """
  Builds an import manifest from a resource-projection flow summary.
  """
  def from_resource_projection_flow_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        summary["id"] || summary["source"] || get_in(summary, ["assumptions", "source"])
      )

    from_review_report(
      OperatorReview.from_resource_projection_flow_summary(summary),
      opts,
      "resource_projection_flow_summary.v1",
      source_artifact_id || "resource_projection_flow_summary"
    )
  end

  @doc """
  Builds an import manifest from a contact-filter report.
  """
  def from_contact_filter_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_contact_filter_report(report),
      opts,
      "contact_filter_report.v1",
      source_artifact_id || "contact_filter_report"
    )
  end

  @doc """
  Builds an import manifest from a candidate-diff report.
  """
  def from_candidate_diff_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_candidate_diff_report(report),
      opts,
      "candidate_diff_report.v1",
      source_artifact_id || "candidate_diff_report"
    )
  end

  @doc """
  Builds an import manifest from a candidate-rejection report.
  """
  def from_candidate_rejection_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_candidate_rejection_report(report),
      opts,
      "candidate_rejection_report.v1",
      source_artifact_id || "candidate_rejection_report"
    )
  end

  @doc """
  Builds an import manifest from a provider-counteroffer report.
  """
  def from_provider_counteroffer_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_provider_counteroffer_report(report),
      opts,
      "provider_counteroffer_report.v1",
      source_artifact_id || "provider_counteroffer_report"
    )
  end

  @doc """
  Builds an import manifest from a standalone invalidated-candidate row.
  """
  def from_invalidated_candidate(%{} = candidate, opts \\ []) do
    candidate = stringify_keys(candidate)

    source_artifact_id =
      option(opts, :source_artifact_id, candidate["id"] || candidate["invalidated_candidate_id"])

    from_review_report(
      OperatorReview.from_invalidated_candidate(candidate),
      opts,
      "invalidated_candidate.v1",
      source_artifact_id || "invalidated_candidate"
    )
  end

  @doc """
  Builds an import manifest from a resource-filter report.
  """
  def from_resource_filter_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_resource_filter_report(report),
      opts,
      "resource_filter_report.v1",
      source_artifact_id || "resource_filter_report"
    )
  end

  @doc """
  Builds an import manifest from a freshness report.
  """
  def from_freshness_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_freshness_report(report),
      opts,
      "freshness_report.v1",
      source_artifact_id || "freshness_report"
    )
  end

  @doc """
  Builds an import manifest from a refresh-budget report.
  """
  def from_refresh_budget_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_refresh_budget_report(report),
      opts,
      "refresh_budget_report.v1",
      source_artifact_id || "refresh_budget_report"
    )
  end

  @doc """
  Builds an import manifest from a constraint report.
  """
  def from_constraint_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, report["id"] || get_in(report, ["assumptions", "source"]))

    from_review_report(
      OperatorReview.from_constraint_report(report),
      opts,
      "constraint_report.v1",
      source_artifact_id || "constraint_report"
    )
  end

  @doc """
  Builds an import manifest from an objective-satisfaction report.
  """
  def from_objective_satisfaction_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_objective_satisfaction_report(report),
      opts,
      "objective_satisfaction_report.v1",
      source_artifact_id || "objective_satisfaction_report"
    )
  end

  @doc """
  Builds an import manifest from a standalone maneuver recommendation.
  """
  def from_maneuver_recommendation(%{} = recommendation, opts \\ []) do
    recommendation = stringify_keys(recommendation)

    source_artifact_id =
      option(opts, :source_artifact_id, recommendation["id"] || recommendation["maneuver_id"])

    from_review_report(
      OperatorReview.from_maneuver_recommendation(recommendation),
      opts,
      "maneuver_recommendation.v1",
      source_artifact_id || "maneuver_recommendation"
    )
  end

  @doc """
  Builds an import manifest from a standalone maneuver execution delta.
  """
  def from_maneuver_execution_delta(%{} = delta, opts \\ []) do
    delta = stringify_keys(delta)
    source_artifact_id = option(opts, :source_artifact_id, delta["id"] || delta["activity_id"])

    from_review_report(
      OperatorReview.from_maneuver_execution_delta(delta),
      opts,
      "maneuver_execution_delta.v1",
      source_artifact_id || "maneuver_execution_delta"
    )
  end

  @doc """
  Builds an import manifest from a maneuver-review report.
  """
  def from_maneuver_review_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        report["id"] || report["source_artifact_id"] || report["source"]
      )

    from_review_report(
      OperatorReview.from_maneuver_review_report(report),
      opts,
      "maneuver_review_report.v1",
      source_artifact_id || "maneuver_review_report"
    )
  end

  @doc """
  Builds an import manifest from a timeline-diff report.
  """
  def from_timeline_diff_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_timeline_diff_report(report),
      opts,
      "timeline_diff_report.v1",
      source_artifact_id || "timeline_diff_report"
    )
  end

  @doc """
  Builds an import manifest from a model-only timeline diff summary.
  """
  def from_timeline_diff_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_timeline_diff_summary(summary),
      opts,
      "timeline_diff_summary.v1",
      source_artifact_id || "timeline_diff_summary"
    )
  end

  @doc """
  Builds an import manifest from a timeline dependency-impact summary.
  """
  def from_timeline_dependency_impact_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_timeline_dependency_impact_summary(summary),
      opts,
      "timeline_dependency_impact_summary.v1",
      source_artifact_id || "timeline_dependency_impact_summary"
    )
  end

  @doc """
  Builds an import manifest from a timeline publication summary.
  """
  def from_timeline_publication_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        summary["publication_id"] || summary["source_artifact_id"]
      )

    from_review_report(
      OperatorReview.from_timeline_publication_summary(summary),
      opts,
      "timeline_publication_summary.v1",
      source_artifact_id || "timeline_publication_summary"
    )
  end

  @doc """
  Builds an import manifest from a timeline activity precondition summary.
  """
  def from_timeline_activity_precondition_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)

    source_artifact_id =
      option(
        opts,
        :source_artifact_id,
        summary["id"] || summary["source"] || summary["timeline_id"]
      )

    from_review_report(
      OperatorReview.from_timeline_activity_precondition_summary(summary),
      opts,
      "timeline_activity_precondition_summary.v1",
      source_artifact_id || summary["activity_id"] || "timeline_activity_precondition_summary"
    )
  end

  @doc """
  Builds an import manifest from a timeline lifecycle-state summary.
  """
  def from_timeline_lifecycle_state_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_timeline_lifecycle_state_summary(summary),
      opts,
      "timeline_lifecycle_state_summary.v1",
      source_artifact_id || "timeline_lifecycle_state_summary"
    )
  end

  @doc """
  Builds an import manifest from a compact activity-state artifact.
  """
  def from_timeline_activity_state(%{} = state, opts \\ []) do
    state = stringify_keys(state)
    source_artifact_id = timeline_activity_state_source_id(state, opts, "timeline_activity_state")

    from_review_report(
      OperatorReview.from_timeline_activity_state(state),
      opts,
      "timeline_activity_state.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a single activity status-state artifact.
  """
  def from_timeline_activity_status_state(%{} = state, opts \\ []) do
    state = stringify_keys(state)

    source_artifact_id =
      timeline_activity_state_source_id(state, opts, "timeline_activity_status_state")

    from_review_report(
      OperatorReview.from_timeline_activity_status_state(state),
      opts,
      "timeline_activity_status_state.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a single activity approval-state artifact.
  """
  def from_timeline_activity_approval_state(%{} = state, opts \\ []) do
    state = stringify_keys(state)

    source_artifact_id =
      timeline_activity_state_source_id(state, opts, "timeline_activity_approval_state")

    from_review_report(
      OperatorReview.from_timeline_activity_approval_state(state),
      opts,
      "timeline_activity_approval_state.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a single activity lifecycle-state artifact.
  """
  def from_timeline_activity_lifecycle_state(%{} = state, opts \\ []) do
    state = stringify_keys(state)

    source_artifact_id =
      timeline_activity_state_source_id(state, opts, "timeline_activity_lifecycle_state")

    from_review_report(
      OperatorReview.from_timeline_activity_lifecycle_state(state),
      opts,
      "timeline_activity_lifecycle_state.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a timeline preservation report.
  """
  def from_timeline_preservation_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_timeline_preservation_report(report),
      opts,
      "timeline_preservation_report.v1",
      source_artifact_id || "timeline_preservation_report"
    )
  end

  @doc """
  Builds an import manifest from a single timeline preservation status artifact.
  """
  def from_timeline_preservation_status(%{} = status, opts \\ []) do
    status = stringify_keys(status)

    source_artifact_id =
      timeline_preservation_source_id(status, opts, "timeline_preservation_status")

    from_review_report(
      OperatorReview.from_timeline_preservation_status(status),
      opts,
      "timeline_preservation_status.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a model-only timeline integrity report.
  """
  def from_timeline_integrity_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_timeline_integrity_report(report),
      opts,
      "timeline_integrity_report.v1",
      source_artifact_id || "timeline_integrity_report"
    )
  end

  @doc """
  Builds an import manifest from a model-only timeline transition-application summary.
  """
  def from_timeline_transition_application_summary(%{} = summary, opts \\ []) do
    summary = stringify_keys(summary)
    source_artifact_id = option(opts, :source_artifact_id, summary["id"] || summary["source"])

    from_review_report(
      OperatorReview.from_timeline_transition_application_summary(summary,
        approval_policy: option(opts, :approval_policy)
      ),
      opts,
      "timeline_transition_application_summary.v1",
      source_artifact_id || "timeline_transition_application_summary"
    )
  end

  @doc """
  Builds an import manifest from a timeline transition application report.
  """
  def from_timeline_transition_application_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_timeline_transition_application_report(report,
        approval_policy: option(opts, :approval_policy)
      ),
      opts,
      "timeline_transition_application_report.v1",
      source_artifact_id || "timeline_transition_application_report"
    )
  end

  @doc """
  Builds an import manifest from a standalone approval requirement.
  """
  def from_approval_requirement(%{} = requirement, opts \\ []) do
    requirement = stringify_keys(requirement)

    source_artifact_id =
      option(opts, :source_artifact_id, requirement["id"] || requirement["activity_id"])

    from_review_report(
      OperatorReview.from_approval_requirement(requirement),
      opts,
      "approval_requirement.v1",
      source_artifact_id || "approval_requirement"
    )
  end

  @doc """
  Builds an import manifest from a policy-decision artifact.
  """
  def from_policy_decision(%{} = decision, opts \\ []) do
    decision = stringify_keys(decision)

    source_artifact_id =
      option(opts, :source_artifact_id, decision["id"] || decision["policy_bundle_id"])

    from_review_report(
      OperatorReview.from_policy_decision(decision),
      opts,
      "policy_decision.v1",
      source_artifact_id || "policy_decision"
    )
  end

  @doc """
  Builds an import manifest from a branch-comparison report.
  """
  def from_branch_comparison_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_branch_comparison_report(report),
      opts,
      "branch_comparison_report.v1",
      source_artifact_id || "branch_comparison_report"
    )
  end

  @doc """
  Builds an import manifest from a ranking-comparison report.
  """
  def from_ranking_comparison_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_ranking_comparison_report(report),
      opts,
      "ranking_comparison_report.v1",
      source_artifact_id || "ranking_comparison_report"
    )
  end

  @doc """
  Builds an import manifest from a score-term report.
  """
  def from_score_term_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_score_term_report(report),
      opts,
      "score_term_report.v1",
      source_artifact_id || "score_term_report"
    )
  end

  @doc """
  Builds an import manifest from an objective-tradeoff report.
  """
  def from_objective_tradeoff_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_objective_tradeoff_report(report),
      opts,
      "objective_tradeoff_report.v1",
      source_artifact_id || "objective_tradeoff_report"
    )
  end

  @doc """
  Builds an import manifest from a Pareto-frontier report.
  """
  def from_pareto_frontier_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)
    source_artifact_id = option(opts, :source_artifact_id, report["id"] || report["source"])

    from_review_report(
      OperatorReview.from_pareto_frontier_report(report),
      opts,
      "pareto_frontier_report.v1",
      source_artifact_id || "pareto_frontier_report"
    )
  end

  @doc """
  Builds an import manifest from a schema-validation report.
  """
  def from_schema_validation_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, schema_validation_report_source_id(report))

    from_review_report(
      OperatorReview.from_schema_validation_report(report),
      opts,
      "schema_validation_report.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a schema-validation batch report.
  """
  def from_schema_validation_batch_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, schema_validation_batch_report_source_id(report))

    from_review_report(
      OperatorReview.from_schema_validation_batch_report(report),
      opts,
      "schema_validation_batch_report.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from an execution report.
  """
  def from_execution_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, execution_report_source_id(report))

    from_review_report(
      OperatorReview.from_execution_report(report),
      opts,
      "execution_report.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from an operational-readiness report.
  """
  def from_operational_readiness_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, report["report_id"] || "operational_readiness_report")

    from_review_report(
      OperatorReview.from_operational_readiness_report(report),
      opts,
      "operational_readiness_report.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from a quality-gate report.
  """
  def from_quality_gate_report(%{} = report, opts \\ []) do
    report = stringify_keys(report)

    source_artifact_id =
      option(opts, :source_artifact_id, report["report_id"] || "quality_gate_report")

    from_review_report(
      OperatorReview.from_quality_gate_report(report),
      opts,
      "quality_gate_report.v1",
      source_artifact_id
    )
  end

  @doc """
  Builds an import manifest from an operator-review package.
  """
  def from_operator_review_package(%{} = package, opts \\ []) do
    package = stringify_keys(package)
    source_artifact_type = option(opts, :source_artifact_type, package["source_artifact_type"])
    source_artifact_id = option(opts, :source_artifact_id, package["source_artifact_id"])

    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&import_manifest_review_row?/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        row
        |> review_manifest_row(rank)
        |> put_run_input_sources(row)
        |> put_source_review_queue(row)
      end)

    build_manifest(
      rows,
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_operator_review_package",
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_review_count" => package["review_count"],
        "source_repair_id" => option(opts, :source_repair_id),
        "source_plan_id" => option(opts, :source_plan_id)
      }
      |> Map.merge(review_summary_context(package)),
      %{
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "row_source" => review_package_row_source(source_artifact_type),
        "deterministic_ordering" => "source review row order"
      }
      |> Map.merge(review_summary_context(package))
    )
  end

  defp from_review_report(review_package, opts, source_artifact_type, source_artifact_id) do
    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: source_artifact_type,
        source_artifact_id: source_artifact_id
      )
    )
  end

  defp timeline_activity_state_source_id(state, opts, fallback) do
    option(opts, :source_artifact_id) || state["id"] || state["source"] || state["timeline_id"] ||
      state["activity_id"] || fallback
  end

  defp timeline_preservation_source_id(status, opts, fallback) do
    option(opts, :source_artifact_id) || status["id"] || status["source"] || status["timeline_id"] ||
      status["activity_id"] || fallback
  end

  defp build_manifest(rows, provenance, context) do
    rows = Enum.map(rows, &normalize_import_row/1)

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_cadence_import_manifest",
      "manifest_id" => manifest_id(context["source_artifact_id"]),
      "source_artifact_type" => context["source_artifact_type"],
      "source_artifact_id" => context["source_artifact_id"],
      "row_count" => length(rows),
      "ready_count" => Enum.count(rows, &(&1["import_status"] == "ready_for_import")),
      "review_required_count" =>
        Enum.count(rows, &(&1["import_status"] == "review_required_before_import")),
      "blocked_count" =>
        Enum.count(rows, &(&1["import_status"] == "blocked_missing_cadence_import")),
      "missing_import_count" => Enum.count(rows, &(&1["cadence_import_status"] == "missing")),
      "import_action_counts" => count_by(rows, "import_action"),
      "import_status_counts" => count_by(rows, "import_status"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "source_review_type_counts" => count_by(rows, "source_review_type"),
      "source_review_action_counts" => count_by(rows, "source_review_action"),
      "source_review_queue_counts" => count_by(rows, "source_review_queue_key"),
      "source_readiness_report_id" => context["source_readiness_report_id"],
      "readiness_level" => context["readiness_level"],
      "import_classification" => context["import_classification"],
      "status" => context["status"],
      "gate_count" => context["gate_count"],
      "passed_gate_count" => context["passed_gate_count"],
      "review_gate_count" => context["review_gate_count"],
      "analysis_gate_count" => context["analysis_gate_count"],
      "blocked_gate_count" => context["blocked_gate_count"],
      "gate_status_counts" => context["gate_status_counts"],
      "gate_classification_counts" => context["gate_classification_counts"],
      "gate_ids_by_status" => context["gate_ids_by_status"],
      "gate_ids_by_classification" => context["gate_ids_by_classification"],
      "quality_gate_row_ids_by_status" => context["quality_gate_row_ids_by_status"],
      "quality_gate_row_ids_by_classification" =>
        context["quality_gate_row_ids_by_classification"],
      "passed_gate_ids" => context["passed_gate_ids"],
      "review_required_gate_ids" => context["review_required_gate_ids"],
      "analysis_only_gate_ids" => context["analysis_only_gate_ids"],
      "blocked_gate_ids" => context["blocked_gate_ids"],
      "calendar_entry_trust_boundary_status_counts" =>
        context["calendar_entry_trust_boundary_status_counts"],
      "station_reservation_ids" => context["station_reservation_ids"],
      "station_reservation_expires_at_s" => context["station_reservation_expires_at_s"],
      "station_reservation_expiration_status_counts" =>
        context["station_reservation_expiration_status_counts"],
      "resource_blocking_dimension_counts" => context["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        context["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        context["resource_blocked_contact_ids_by_spacecraft_id"],
      "station_pressure_contact_count" => context["station_pressure_contact_count"],
      "station_pressure_review_contact_count" => context["station_pressure_review_contact_count"],
      "station_pressure_review_contact_ids" => context["station_pressure_review_contact_ids"],
      "station_pressure_contact_counts_by_ground_station_id" =>
        context["station_pressure_contact_counts_by_ground_station_id"],
      "station_pressure_contact_ids_by_ground_station_id" =>
        context["station_pressure_contact_ids_by_ground_station_id"],
      "station_pressure_contact_counts_by_availability" =>
        context["station_pressure_contact_counts_by_availability"],
      "station_pressure_contact_ids_by_availability" =>
        context["station_pressure_contact_ids_by_availability"],
      "station_pressure_contact_counts_by_precedence_availability" =>
        context["station_pressure_contact_counts_by_precedence_availability"],
      "station_pressure_contact_ids_by_precedence_availability" =>
        context["station_pressure_contact_ids_by_precedence_availability"],
      "station_pressure_contact_counts_by_precedence_rank" =>
        context["station_pressure_contact_counts_by_precedence_rank"],
      "station_pressure_contact_ids_by_precedence_rank" =>
        context["station_pressure_contact_ids_by_precedence_rank"],
      "station_pressure_contact_counts_by_status" =>
        context["station_pressure_contact_counts_by_status"],
      "station_pressure_contact_ids_by_status" =>
        context["station_pressure_contact_ids_by_status"],
      "station_pressure_contact_ids_by_direction" =>
        context["station_pressure_contact_ids_by_direction"],
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        context["station_pressure_contact_ids_by_direction_and_ground_station_id"],
      "capacity_pack_required_capacity_fraction" =>
        context["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        context["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        context["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        context["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_contact_ids_by_status" => context["capacity_pack_contact_ids_by_status"],
      "capacity_pack_contact_ids_by_direction" =>
        context["capacity_pack_contact_ids_by_direction"],
      "capacity_pack_selected_contact_ids_by_direction" =>
        context["capacity_pack_selected_contact_ids_by_direction"],
      "capacity_pack_deferred_contact_ids_by_direction" =>
        context["capacity_pack_deferred_contact_ids_by_direction"],
      "capacity_pack_contact_ids_by_ground_station_id" =>
        context["capacity_pack_contact_ids_by_ground_station_id"],
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        context["capacity_pack_selected_contact_ids_by_ground_station_id"],
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        context["capacity_pack_deferred_contact_ids_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        context["required_capacity_fraction_source_counts"],
      "required_capacity_fraction_contact_ids_by_source" =>
        context["required_capacity_fraction_contact_ids_by_source"],
      "provider_reservation_candidate_contact_count" =>
        context["provider_reservation_candidate_contact_count"],
      "provider_reservation_request_contact_count" =>
        context["provider_reservation_request_contact_count"],
      "provider_reservation_review_contact_count" =>
        context["provider_reservation_review_contact_count"],
      "provider_reservation_no_request_contact_count" =>
        context["provider_reservation_no_request_contact_count"],
      "provider_reservation_request_status_counts" =>
        context["provider_reservation_request_status_counts"],
      "provider_reservation_request_contact_ids" =>
        context["provider_reservation_request_contact_ids"],
      "provider_reservation_review_contact_ids" =>
        context["provider_reservation_review_contact_ids"],
      "provider_reservation_no_request_contact_ids" =>
        context["provider_reservation_no_request_contact_ids"],
      "provider_reservation_request_contact_ids_by_ground_station_id" =>
        context["provider_reservation_request_contact_ids_by_ground_station_id"],
      "provider_reservation_review_contact_ids_by_ground_station_id" =>
        context["provider_reservation_review_contact_ids_by_ground_station_id"],
      "provider_reservation_no_request_contact_ids_by_direction" =>
        context["provider_reservation_no_request_contact_ids_by_direction"],
      "provider_reservation_request_contact_ids_by_direction" =>
        context["provider_reservation_request_contact_ids_by_direction"],
      "provider_reservation_review_contact_ids_by_direction" =>
        context["provider_reservation_review_contact_ids_by_direction"],
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_request_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_review_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_request_contact_ids_by_match_status" =>
        context["provider_reservation_request_contact_ids_by_match_status"],
      "provider_reservation_review_contact_ids_by_match_status" =>
        context["provider_reservation_review_contact_ids_by_match_status"],
      "provider_reservation_request_ids_by_match_status" =>
        context["provider_reservation_request_ids_by_match_status"],
      "provider_reservation_review_ids_by_match_status" =>
        context["provider_reservation_review_ids_by_match_status"],
      "reservation_conflict_contact_ids_by_direction" =>
        context["reservation_conflict_contact_ids_by_direction"],
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        context["reservation_conflict_contact_ids_by_direction_and_ground_station_id"],
      "reduced_capacity_pack_group_count" => context["reduced_capacity_pack_group_count"],
      "reduced_capacity_pack_status_counts" => context["reduced_capacity_pack_status_counts"],
      "capacity_pack_group_ids" => context["capacity_pack_group_ids"],
      "capacity_pack_group_ids_by_status" => context["capacity_pack_group_ids_by_status"],
      "reduced_capacity_packed_contact_ids" => context["reduced_capacity_packed_contact_ids"],
      "reduced_capacity_deferred_contact_ids" => context["reduced_capacity_deferred_contact_ids"],
      "station_reservation_declared_expiration_contact_count" =>
        context["station_reservation_declared_expiration_contact_count"],
      "station_reservation_missing_expiration_contact_count" =>
        context["station_reservation_missing_expiration_contact_count"],
      "earliest_station_reservation_expires_at_s" =>
        context["earliest_station_reservation_expires_at_s"],
      "station_reservation_contact_ids_by_expiration_status" =>
        context["station_reservation_contact_ids_by_expiration_status"],
      "station_reservation_ids_by_expiration_status" =>
        context["station_reservation_ids_by_expiration_status"],
      "station_reservation_contact_ids_by_match_status" =>
        context["station_reservation_contact_ids_by_match_status"],
      "station_reservation_contact_ids_by_status" =>
        context["station_reservation_contact_ids_by_status"],
      "station_reservation_contact_ids_by_reserved_by" =>
        context["station_reservation_contact_ids_by_reserved_by"],
      "station_reservation_ids_by_match_status" =>
        context["station_reservation_ids_by_match_status"],
      "station_reservation_ids_by_status" => context["station_reservation_ids_by_status"],
      "station_reservation_ids_by_reserved_by" =>
        context["station_reservation_ids_by_reserved_by"],
      "station_reserved_bys" => context["station_reserved_bys"],
      "station_reservation_statuses" => context["station_reservation_statuses"],
      "station_reservation_match_status_counts" =>
        context["station_reservation_match_status_counts"],
      "rows" => rows,
      "provenance" => compact_map(provenance),
      "model_limits" => model_limits(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "row_source" => context["row_source"],
        "deterministic_ordering" => context["deterministic_ordering"]
      }
    }
    |> compact_map()
  end

  defp review_summary_context(%{} = package) do
    package
    |> Map.take([
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
      "calendar_entry_trust_boundary_status_counts",
      "station_reservation_ids",
      "station_reservation_expires_at_s",
      "station_reservation_expiration_status_counts",
      "resource_blocking_dimension_counts",
      "resource_blocked_contact_ids_by_blocking_dimension",
      "resource_blocked_contact_ids_by_spacecraft_id",
      "station_pressure_contact_count",
      "station_pressure_review_contact_count",
      "station_pressure_review_contact_ids",
      "station_pressure_contact_counts_by_ground_station_id",
      "station_pressure_contact_ids_by_ground_station_id",
      "station_pressure_contact_counts_by_availability",
      "station_pressure_contact_ids_by_availability",
      "station_pressure_contact_counts_by_precedence_availability",
      "station_pressure_contact_ids_by_precedence_availability",
      "station_pressure_contact_counts_by_precedence_rank",
      "station_pressure_contact_ids_by_precedence_rank",
      "station_pressure_contact_counts_by_status",
      "station_pressure_contact_ids_by_status",
      "station_pressure_contact_ids_by_direction",
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      "capacity_pack_required_capacity_fraction",
      "capacity_pack_selected_required_capacity_fraction",
      "capacity_pack_deferred_required_capacity_fraction",
      "capacity_pack_required_capacity_fraction_by_status",
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_contact_ids_by_status",
      "capacity_pack_contact_ids_by_direction",
      "capacity_pack_selected_contact_ids_by_direction",
      "capacity_pack_deferred_contact_ids_by_direction",
      "capacity_pack_contact_ids_by_ground_station_id",
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      "required_capacity_fraction_source_counts",
      "required_capacity_fraction_contact_ids_by_source",
      "provider_reservation_candidate_contact_count",
      "provider_reservation_request_contact_count",
      "provider_reservation_review_contact_count",
      "provider_reservation_no_request_contact_count",
      "provider_reservation_request_status_counts",
      "provider_reservation_request_contact_ids",
      "provider_reservation_review_contact_ids",
      "provider_reservation_no_request_contact_ids",
      "provider_reservation_request_contact_ids_by_ground_station_id",
      "provider_reservation_review_contact_ids_by_ground_station_id",
      "provider_reservation_no_request_contact_ids_by_direction",
      "provider_reservation_request_contact_ids_by_direction",
      "provider_reservation_review_contact_ids_by_direction",
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      "provider_reservation_request_contact_ids_by_match_status",
      "provider_reservation_review_contact_ids_by_match_status",
      "provider_reservation_request_ids_by_match_status",
      "provider_reservation_review_ids_by_match_status",
      "reservation_conflict_contact_ids_by_direction",
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      "reduced_capacity_pack_group_count",
      "reduced_capacity_pack_status_counts",
      "capacity_pack_group_ids",
      "capacity_pack_group_ids_by_status",
      "reduced_capacity_packed_contact_ids",
      "reduced_capacity_deferred_contact_ids",
      "station_reservation_declared_expiration_contact_count",
      "station_reservation_missing_expiration_contact_count",
      "earliest_station_reservation_expires_at_s",
      "station_reservation_contact_ids_by_expiration_status",
      "station_reservation_ids_by_expiration_status",
      "station_reservation_contact_ids_by_match_status",
      "station_reservation_contact_ids_by_status",
      "station_reservation_contact_ids_by_reserved_by",
      "station_reservation_ids_by_match_status",
      "station_reservation_ids_by_status",
      "station_reservation_ids_by_reserved_by",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_status_counts"
    ])
    |> maybe_put_run_input_sources(package)
    |> compact_map()
  end

  defp maybe_put_run_input_sources(context, %{
         "provenance" => %{"run_input_sources" => sources}
       })
       when is_map(sources) and map_size(sources) > 0,
       do: Map.put(context, "run_input_sources", sources)

  defp maybe_put_run_input_sources(context, _package), do: context

  defp normalize_import_row(%{} = row) do
    case Map.fetch(row, "cadence_import_status") do
      {:ok, status} ->
        normalize_import_row_status(row, status)

      :error ->
        row
    end
  end

  defp put_run_input_sources(row, %{"run_input_sources" => sources})
       when is_map(sources) and map_size(sources) > 0,
       do: Map.put(row, "run_input_sources", sources)

  defp put_run_input_sources(row, _source_row), do: row

  defp normalize_import_row_status(row, status) do
    normalized_status = encode_json_value(status)

    if normalized_status in @cadence_import_statuses do
      Map.put(row, "cadence_import_status", normalized_status)
    else
      row
      |> Map.put("cadence_import_status", "invalid")
      |> Map.put("import_status", "review_required_before_import")
      |> Map.put("has_cadence_import", false)
      |> Map.put("invalid_cadence_import", true)
      |> Map.put_new("invalid_cadence_import_reason", "unsupported_cadence_import_status")
      |> Map.put("unsupported_cadence_import_status", encode_json_value(status))
    end
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp model_limits do
    capability()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp source_review_action(row), do: row["action"] || row["required_operator_action"]

  defp put_source_review_queue(manifest_row, source_row) do
    manifest_row
    |> maybe_put_source_review_queue("source_review_queue", source_row["review_queue"])
    |> maybe_put_source_review_queue("source_review_queue_key", source_row["review_queue_key"])
  end

  defp maybe_put_source_review_queue(row, _field, value) when value in [nil, ""], do: row
  defp maybe_put_source_review_queue(row, field, value), do: Map.put(row, field, value)

  defp proposed_contact_manifest_row(contact, rank) do
    raw_cadence_import = Map.get(contact, "cadence_import")
    cadence_import = if is_map(raw_cadence_import), do: raw_cadence_import, else: %{}
    has_import? = is_map(raw_cadence_import)
    invalid_import? = Map.has_key?(contact, "cadence_import") and not has_import?
    cadence_import_status = proposed_contact_cadence_import_status(has_import?, invalid_import?)

    %{
      "id" => "cadence_import:proposed_contact:#{contact["id"] || rank}",
      "rank" => rank,
      "import_action" => "import_proposed_contact",
      "import_status" => proposed_contact_import_status(cadence_import_status),
      "import_side" => "source",
      "source_review_row_id" => "proposed_contact:#{contact["id"] || rank}",
      "source_review_type" => "proposed_contact",
      "source_review_action" => "import_proposed_contact",
      "subject_id" => contact["id"],
      "activity_id" => contact["id"],
      "activity_type" => contact["type"] || "downlink",
      "direction" => contact["direction"],
      "ground_station_id" => contact["ground_station_id"],
      "scenario_id" => contact["scenario_id"],
      "source_window_id" => contact["source_window_id"],
      "starts_at_s" => contact["starts_at_s"],
      "ends_at_s" => contact["ends_at_s"],
      "estimated_throughput_mb" => contact["estimated_throughput_mb"],
      "capacity_adjusted_throughput_mb" => contact["capacity_adjusted_throughput_mb"],
      "station_availability" => contact["station_availability"],
      "station_contention_status" => contact["station_contention_status"],
      "station_calendar_entry_id" => contact["station_calendar_entry_id"],
      "station_calendar_status" => contact["station_calendar_status"],
      "station_calendar_overlap_count" => contact["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => contact["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        contact["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_trust_boundary_status" =>
        contact["station_calendar_trust_boundary_status"],
      "trust_boundary" => contact["trust_boundary"],
      "provenance" => contact["provenance"],
      "source_station_calendar_entry" => contact["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => contact["source_station_calendar_overlaps"],
      "cadence_import_status" => cadence_import_status,
      "cadence_import_type" => Map.get(cadence_import, "activity_type"),
      "cadence_import_id" => Map.get(cadence_import, "external_id"),
      "cadence_import_contract" => Map.get(cadence_import, "schema_contract"),
      "cadence_import_provider" => Map.get(cadence_import, "provider"),
      "cadence_import_adapter" => Map.get(cadence_import, "adapter"),
      "cadence_import_adapter_version" => Map.get(cadence_import, "adapter_version"),
      "cadence_import_trust_boundary" =>
        Map.get(cadence_import, "trust_boundary") ||
          get_in(cadence_import, ["provenance", "trust_boundary"]),
      "cadence_import_provenance" => Map.get(cadence_import, "provenance"),
      "invalid_cadence_import" => if(invalid_import?, do: true),
      "invalid_cadence_import_reason" => if(invalid_import?, do: "cadence_import_must_be_object"),
      "source_cadence_import" =>
        if(invalid_import?,
          do: %{"invalid_import_shape" => encode_json_value(raw_cadence_import)}
        ),
      "has_cadence_import" => has_import?,
      "import_activity_context" =>
        contact
        |> proposed_contact_import_activity_context(raw_cadence_import, invalid_import?)
        |> normalize_provider_result_artifact_fields()
    }
    |> compact_map()
  end

  defp proposed_contact_cadence_import_status(true, _invalid_import?), do: "present"
  defp proposed_contact_cadence_import_status(_has_import?, true), do: "invalid"
  defp proposed_contact_cadence_import_status(_has_import?, _invalid_import?), do: "missing"

  defp proposed_contact_import_status("present"), do: "ready_for_import"
  defp proposed_contact_import_status("invalid"), do: "review_required_before_import"
  defp proposed_contact_import_status(_status), do: "blocked_missing_cadence_import"

  defp proposed_contact_import_activity_context(contact, raw_cadence_import, true) do
    contact
    |> Map.delete("cadence_import")
    |> Map.merge(%{
      "invalid_cadence_import" => true,
      "invalid_cadence_import_reason" => "cadence_import_must_be_object",
      "source_cadence_import" => %{
        "invalid_import_shape" => encode_json_value(raw_cadence_import)
      }
    })
  end

  defp proposed_contact_import_activity_context(contact, _raw_cadence_import, _invalid_import?),
    do: contact

  defp strategy_manifest_row(row, recommendation, rank, operational_feedback_context) do
    branch_id = row["branch_id"]
    selected? = Map.get(row, "selected", false)
    approval_status = Map.get(row, "approval_status") || recommendation["approval_status"]

    %{
      "id" => "cadence_import:strategy_branch:#{branch_id || rank}",
      "rank" => rank,
      "import_action" =>
        if(selected?,
          do: "import_strategy_recommendation",
          else: "review_strategy_branch_alternative"
        ),
      "import_status" => strategy_import_status(selected?, approval_status),
      "import_side" => "source",
      "source_review_row_id" => Map.get(row, "id") || "branch_comparison:#{branch_id || rank}",
      "source_review_type" => "strategy_branch_comparison",
      "source_review_action" =>
        if(selected?, do: "review_strategy_recommendation", else: "review_branch_comparison"),
      "subject_id" => branch_id,
      "branch_id" => branch_id,
      "recommended_branch_id" => recommendation["recommended_branch_id"],
      "approval_status" => approval_status,
      "required_operator_action" =>
        if(selected?, do: "review_strategy_recommendation", else: "review_branch_comparison"),
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "selected" => selected?,
      "score" => row["score"],
      "score_delta_from_recommended" => row["score_delta_from_recommended"],
      "raw_score" => row["raw_score"],
      "branch_probability" => row["branch_probability"],
      "expected_score" => row["expected_score"],
      "risk_count" => row["risk_count"],
      "risk_types" => row["risk_types"],
      "high_risk_types" => row["high_risk_types"],
      "approval_requirement_count" => row["approval_requirement_count"],
      "repair_delta_count" => row["repair_delta_count"],
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
      "branch_actual_downlink_completion_ratio" => row["branch_actual_downlink_completion_ratio"],
      "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
      "capacity_pack_statuses" => row["capacity_pack_statuses"],
      "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
      "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
      "capacity_pack_max_required_capacity_fraction" =>
        row["capacity_pack_max_required_capacity_fraction"],
      "capacity_pack_total_required_capacity_fraction" =>
        row["capacity_pack_total_required_capacity_fraction"],
      "capacity_pack_required_capacity_sources" => row["capacity_pack_required_capacity_sources"],
      "capacity_pack_contact_ids_by_direction" => row["capacity_pack_contact_ids_by_direction"],
      "capacity_pack_selected_contact_ids_by_direction" =>
        row["capacity_pack_selected_contact_ids_by_direction"],
      "capacity_pack_deferred_contact_ids_by_direction" =>
        row["capacity_pack_deferred_contact_ids_by_direction"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        row["capacity_pack_required_capacity_fraction_by_direction"],
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        row["capacity_pack_selected_required_capacity_fraction_by_direction"],
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        row["capacity_pack_deferred_required_capacity_fraction_by_direction"],
      "target_branch_base_id" => row["target_branch_base_id"],
      "target_branch_identity" => row["target_branch_identity"],
      "priority_commitment_required_target_count" =>
        row["priority_commitment_required_target_count"],
      "priority_commitment_satisfied_target_count" =>
        row["priority_commitment_satisfied_target_count"],
      "priority_commitment_missed_target_count" => row["priority_commitment_missed_target_count"],
      "priority_commitment_required_target_ids" => row["priority_commitment_required_target_ids"],
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
      "downlink_completion_planned_downlink_mb" => row["downlink_completion_planned_downlink_mb"],
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
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
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
      "repair_link_downlink_requirement_status" => row["repair_link_downlink_requirement_status"],
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
      "source_branch_comparison" => row,
      "source_recommendation" => recommendation
    }
    |> merge_strategy_recommendation_context(
      if(selected?, do: strategy_recommendation_risk_context(recommendation), else: %{})
    )
    |> merge_strategy_recommendation_context(
      if(selected?,
        do: strategy_recommendation_resource_pressure_context(recommendation),
        else: %{}
      )
    )
    |> merge_strategy_recommendation_context(
      if(selected?,
        do: strategy_recommendation_readiness_quality_gate_context(recommendation),
        else: %{}
      )
    )
    |> Map.merge(Map.take(row, branch_timeline_evidence_fields()))
    |> Map.merge(Map.take(row, branch_readiness_quality_gate_fields()))
    |> Map.merge(Map.take(row, branch_contact_allocation_fields()))
    |> Map.merge(operational_feedback_context)
    |> compact_map()
  end

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

  defp strategy_recommendation_readiness_quality_gate_context(%{"explanation" => explanation})
       when is_list(explanation) do
    rows = Enum.map(explanation, &stringify_keys/1)

    readiness_rows =
      Enum.filter(rows, &(&1["type"] == "operational_readiness_pressure"))

    quality_gate_rows =
      Enum.filter(rows, &(&1["type"] == "quality_gate_pressure"))

    %{
      "operational_readiness_report_ids" => risk_context_values(readiness_rows, "report_id"),
      "operational_readiness_source_artifact_types" =>
        risk_context_values(readiness_rows, "source_artifact_type"),
      "operational_readiness_source_artifact_ids" =>
        risk_context_values(readiness_rows, "source_artifact_id"),
      "operational_readiness_levels" => risk_context_values(readiness_rows, "readiness_level"),
      "operational_readiness_import_classifications" =>
        risk_context_values(readiness_rows, "import_classification"),
      "operational_readiness_statuses" =>
        risk_context_values(readiness_rows, "operational_readiness_status"),
      "operational_readiness_gate_ids" =>
        risk_context_values(readiness_rows, "readiness_gate_id"),
      "operational_readiness_gate_statuses" =>
        risk_context_values(readiness_rows, "readiness_gate_status"),
      "operational_readiness_gate_classifications" =>
        risk_context_values(readiness_rows, "readiness_gate_classification"),
      "operational_readiness_required_operator_actions" =>
        risk_context_values(readiness_rows, "required_operator_action"),
      "operational_readiness_feedback_sources" =>
        risk_context_values(readiness_rows, "feedback_source"),
      "operational_readiness_feedback_scopes" =>
        risk_context_values(readiness_rows, "feedback_scope"),
      "operational_readiness_feedback_keys" =>
        risk_context_values(readiness_rows, "feedback_key"),
      "operational_readiness_trust_boundaries" =>
        risk_context_values(readiness_rows, "trust_boundary"),
      "quality_gate_report_ids" => risk_context_values(quality_gate_rows, "report_id"),
      "quality_gate_source_artifact_types" =>
        risk_context_values(quality_gate_rows, "source_artifact_type"),
      "quality_gate_source_artifact_ids" =>
        risk_context_values(quality_gate_rows, "source_artifact_id"),
      "quality_gate_source_readiness_report_ids" =>
        risk_context_values(quality_gate_rows, "source_readiness_report_id"),
      "quality_gate_readiness_levels" =>
        risk_context_values(quality_gate_rows, "readiness_level"),
      "quality_gate_import_classifications" =>
        risk_context_values(quality_gate_rows, "import_classification"),
      "quality_gate_pressure_statuses" =>
        risk_context_values(quality_gate_rows, "quality_gate_status"),
      "quality_gate_ids" => risk_context_values(quality_gate_rows, "gate_id"),
      "quality_gate_statuses" => risk_context_values(quality_gate_rows, "gate_status"),
      "quality_gate_classifications" =>
        risk_context_values(quality_gate_rows, "gate_classification"),
      "quality_gate_required_operator_actions" =>
        risk_context_values(quality_gate_rows, "required_operator_action"),
      "quality_gate_feedback_sources" =>
        risk_context_values(quality_gate_rows, "feedback_source"),
      "quality_gate_feedback_scopes" => risk_context_values(quality_gate_rows, "feedback_scope"),
      "quality_gate_feedback_keys" => risk_context_values(quality_gate_rows, "feedback_key"),
      "quality_gate_trust_boundaries" => risk_context_values(quality_gate_rows, "trust_boundary"),
      "quality_gate_resource_availability_reason_ids" =>
        risk_context_values(quality_gate_rows, ["resource_availability_reason_ids"]),
      "quality_gate_unavailable_resource_reason_ids" =>
        risk_context_values(quality_gate_rows, ["unavailable_resource_reason_ids"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  defp strategy_recommendation_readiness_quality_gate_context(_recommendation), do: %{}

  defp strategy_recommendation_risk_context(%{"risks_remaining" => risks} = recommendation)
       when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    resource_margin_rows = strategy_recommendation_resource_margin_rows(recommendation)
    resource_margin_context_rows = risks ++ resource_margin_rows

    candidate_rejection_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "candidate_rejection" or
            Map.get(&1, "type") == "candidate_rejection_pressure")
      )

    provider_counteroffer_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "provider_counteroffer" or
            Map.get(&1, "type") == "provider_counteroffer_review" or
            Map.has_key?(&1, "provider_counteroffer_id"))
      )

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
        risk_context_values(risks, "first_resource_pressure_kind"),
      "candidate_rejection_candidate_ids" =>
        risk_context_values(candidate_rejection_risks, "candidate_id"),
      "candidate_rejection_activity_ids" =>
        risk_context_values(candidate_rejection_risks, "activity_id"),
      "candidate_rejection_activity_types" =>
        risk_context_values(candidate_rejection_risks, "activity_type"),
      "candidate_rejection_scenario_ids" =>
        risk_context_values(candidate_rejection_risks, "scenario_id"),
      "candidate_rejection_ground_station_ids" =>
        risk_context_values(candidate_rejection_risks, "ground_station_id"),
      "candidate_rejection_source_window_ids" =>
        risk_context_values(candidate_rejection_risks, "source_window_id"),
      "candidate_rejection_source_window_types" =>
        risk_context_values(candidate_rejection_risks, "source_window_type"),
      "candidate_rejection_statuses" =>
        risk_context_values(candidate_rejection_risks, "rejection_status"),
      "candidate_rejection_primary_reasons" =>
        risk_context_values(candidate_rejection_risks, "primary_rejection_reason"),
      "candidate_rejection_reason_ids" =>
        risk_context_values(candidate_rejection_risks, ["rejection_reasons"]),
      "candidate_rejection_violated_constraints" =>
        risk_context_values(candidate_rejection_risks, "violated_constraint"),
      "candidate_rejection_required_margin_values" =>
        risk_context_values(candidate_rejection_risks, "required_margin"),
      "candidate_rejection_actual_margin_values" =>
        risk_context_values(candidate_rejection_risks, "actual_margin"),
      "candidate_rejection_required_operator_actions" =>
        risk_context_values(candidate_rejection_risks, "required_operator_action"),
      "candidate_rejection_feedback_sources" =>
        risk_context_values(candidate_rejection_risks, "feedback_source"),
      "candidate_rejection_feedback_scopes" =>
        risk_context_values(candidate_rejection_risks, "feedback_scope"),
      "candidate_rejection_feedback_keys" =>
        risk_context_values(candidate_rejection_risks, "feedback_key"),
      "candidate_rejection_trust_boundaries" =>
        risk_context_values(candidate_rejection_risks, "trust_boundary"),
      "provider_counteroffer_ids" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_id"),
      "provider_counteroffer_statuses" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_status"),
      "provider_counteroffer_negotiation_states" =>
        risk_context_values(
          provider_counteroffer_risks,
          "provider_counteroffer_negotiation_state"
        ),
      "provider_counteroffer_reason_codes" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_reason_code"),
      "provider_counteroffer_cost_deltas" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_cost_delta"),
      "provider_counteroffer_lock_deadline_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_lock_deadline_s"),
      "provider_counteroffer_starts_at_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_starts_at_s"),
      "provider_counteroffer_ends_at_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_ends_at_s"),
      "provider_counteroffer_start_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_start_delta_s"),
      "provider_counteroffer_end_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_end_delta_s"),
      "provider_counteroffer_duration_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_duration_delta_s"),
      "provider_counteroffer_plan_impact_statuses" =>
        risk_context_values(provider_counteroffer_risks, "plan_impact_status"),
      "provider_counteroffer_affected_station_calendar_entry_ids" =>
        risk_context_values(provider_counteroffer_risks, ["affected_station_calendar_entry_ids"]),
      "provider_counteroffer_affected_provider_entry_ids" =>
        risk_context_values(provider_counteroffer_risks, ["affected_provider_entry_ids"]),
      "provider_counteroffer_impact_counteroffer_ids" =>
        risk_context_values(provider_counteroffer_risks, ["impact_counteroffer_ids"]),
      "provider_counteroffer_required_operator_actions" =>
        risk_context_values(provider_counteroffer_risks, "required_operator_action"),
      "provider_counteroffer_feedback_sources" =>
        risk_context_values(provider_counteroffer_risks, "feedback_source"),
      "provider_counteroffer_feedback_scopes" =>
        risk_context_values(provider_counteroffer_risks, "feedback_scope"),
      "provider_counteroffer_feedback_keys" =>
        risk_context_values(provider_counteroffer_risks, "feedback_key"),
      "provider_counteroffer_trust_boundaries" =>
        risk_context_values(provider_counteroffer_risks, "trust_boundary")
    }
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.validation_refresh_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.approval_boundary_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.provider_reservation_request_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.capacity_pack_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.contact_contention_resolution_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_contention_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.station_reservation_conflict_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.station_reservation_hold_import_readiness_context(
        risks
      )
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.relay_data_path_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.link_capacity_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_intent_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_allocation_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_filter_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.resource_filter_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.resource_projection_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.station_calendar_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.score_term_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.objective_satisfaction_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.objective_tradeoff_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.resource_margin_context(
        resource_margin_context_rows
      )
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.maneuver_execution_uncertainty_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_integrity_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.execution_success_feedback_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.operational_feedback_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_activity_precondition_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_activity_lifecycle_state_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_dependency_impact_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_publication_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_lifecycle_state_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_preservation_context(risks))
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  defp strategy_recommendation_risk_context(_recommendation), do: %{}

  defp strategy_recommendation_resource_margin_rows(%{"explanation" => explanation})
       when is_list(explanation) do
    explanation
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["type"] == "resource_margin_pressure"))
  end

  defp strategy_recommendation_resource_margin_rows(_recommendation), do: []

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

  defp operational_feedback_manifest_context(%{} = provenance) do
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

  defp operational_feedback_manifest_context(_provenance), do: %{}

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
              |> Enum.map(&encode_json_value/1)
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

  defp strategy_import_status(false, _approval_status), do: "not_applicable"
  defp strategy_import_status(true, "auto_approvable"), do: "ready_for_import"
  defp strategy_import_status(true, "not_required"), do: "ready_for_import"
  defp strategy_import_status(true, _approval_status), do: "review_required_before_import"

  defp strategy_review_manifest_rows(review_package, starting_rank) do
    review_package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&strategy_review_manifest_row?/1)
    |> Enum.with_index(starting_rank)
    |> Enum.map(fn {row, rank} -> review_manifest_row(row, rank) end)
  end

  defp strategy_review_package(artifact) do
    Map.get(artifact, "operator_review_package") ||
      OperatorReview.from_strategy_artifact(artifact)
  end

  defp strategy_review_count(review_package) do
    Map.get(review_package, "review_count") ||
      length(Map.get(review_package, "rows", []))
  end

  defp strategy_review_manifest_row?(%{"review_type" => "strategy_recommendation"}), do: false

  defp strategy_review_manifest_row?(row), do: import_manifest_review_row?(row)

  defp import_manifest_review_row?(%{"review_type" => review_type})
       when review_type in [
              "plan_delta_review",
              "realized_feedback",
              "operational_timeline_review",
              "contact_contention_recommendation",
              "contact_contention_review",
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
              "constraint_review",
              "objective_satisfaction_review",
              "resource_projection_review",
              "contact_suppression",
              "resource_suppression",
              "maneuver_review",
              "timeline_diff_review",
              "timeline_dependency_impact_review",
              "timeline_publication_review",
              "timeline_activity_precondition_review",
              "timeline_lifecycle_state_review",
              "timeline_preservation_review",
              "timeline_integrity_review",
              "approval_requirement",
              "policy_escalation",
              "timeline_protection",
              "warning",
              "risk_explanation",
              "strategy_recommendation",
              "strategy_tradeoff",
              "score_term_review",
              "objective_tradeoff_review",
              "ranking_comparison_review",
              "pareto_frontier_review",
              "schema_validation_review",
              "execution_review",
              "operational_readiness_review",
              "quality_gate_review"
            ],
       do: true

  defp import_manifest_review_row?(_row), do: false

  defp review_manifest_row(%{"review_type" => "realized_feedback"} = row, rank),
    do: realized_feedback_manifest_row(row, rank)

  defp review_manifest_row(
         %{"review_type" => review_type} = row,
         rank
       )
       when review_type in ["contact_contention_recommendation", "contact_contention_review"],
       do: contact_contention_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "contact_allocation_review"} = row, rank),
    do: contact_allocation_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "contact_intent_review"} = row, rank),
    do: contact_intent_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "candidate_diff_review"} = row, rank),
    do: candidate_diff_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "contact_suppression"} = row, rank),
    do: suppression_manifest_row(row, rank, "contact")

  defp review_manifest_row(%{"review_type" => "resource_suppression"} = row, rank),
    do: suppression_manifest_row(row, rank, "resource")

  defp review_manifest_row(%{"review_type" => "freshness_review"} = row, rank),
    do: freshness_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "refresh_budget_review"} = row, rank),
    do: refresh_budget_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "constraint_review"} = row, rank),
    do: constraint_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "objective_satisfaction_review"} = row, rank),
    do: objective_satisfaction_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "approval_requirement"} = row, rank),
    do: approval_requirement_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "maneuver_review"} = row, rank),
    do: maneuver_review_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "timeline_diff_review"} = row, rank),
    do: timeline_diff_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "timeline_protection"} = row, rank),
    do: timeline_protection_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "command_window_review"} = row, rank),
    do: command_window_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "station_calendar_review"} = row, rank),
    do: station_calendar_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "station_reservation_review"} = row, rank),
    do: station_reservation_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "link_capacity_review"} = row, rank),
    do: link_capacity_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "resource_projection_review"} = row, rank),
    do: resource_projection_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "policy_escalation"} = row, rank),
    do: policy_escalation_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "warning"} = row, rank),
    do: warning_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "risk_explanation"} = row, rank),
    do: risk_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "strategy_recommendation"} = row, rank),
    do: strategy_recommendation_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "strategy_tradeoff"} = row, rank),
    do: strategy_tradeoff_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "ranking_comparison_review"} = row, rank),
    do: ranking_comparison_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "score_term_review"} = row, rank),
    do: score_term_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "objective_tradeoff_review"} = row, rank),
    do: objective_tradeoff_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "pareto_frontier_review"} = row, rank),
    do: pareto_frontier_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "schema_validation_review"} = row, rank),
    do: schema_validation_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "execution_review"} = row, rank),
    do: execution_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "operational_readiness_review"} = row, rank),
    do: operational_readiness_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "quality_gate_review"} = row, rank),
    do: quality_gate_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "operational_timeline_review"} = row, rank),
    do: operational_timeline_manifest_row(row, rank)

  defp review_manifest_row(%{"review_type" => "plan_delta_review"} = row, rank),
    do: manifest_row(row, rank)

  defp review_manifest_row(row, rank), do: generic_review_manifest_row(row, rank)

  defp realized_feedback_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    cadence_import_status = row["cadence_import_status"] || "not_applicable"

    %{
      "id" => "cadence_import:realized_feedback:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => realized_feedback_import_action(approval_status),
      "import_status" => realized_feedback_import_status(cadence_import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "feedback_status" => row["feedback_status"],
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
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          row["realized_activity_context"] || row["source_activity_context"]
        ),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(row["source_activity_context"]),
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
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "provider_counteroffer_negotiation_state" => row["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
      "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
      "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "cadence_import_type" => row["cadence_import_type"],
      "cadence_import_id" => row["cadence_import_id"],
      "cadence_import_contract" => row["cadence_import_contract"],
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
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "cadence_import_status" => cadence_import_status,
      "has_cadence_import" => realized_feedback_has_cadence_import?(row, cadence_import_status),
      "source_feedback" => row["source_feedback"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp realized_feedback_has_cadence_import?(%{"has_cadence_import" => value}, _status)
       when is_boolean(value),
       do: value

  defp realized_feedback_has_cadence_import?(_row, "present"), do: true
  defp realized_feedback_has_cadence_import?(_row, _status), do: false

  defp realized_feedback_import_status("invalid", _approval_status),
    do: "review_required_before_import"

  defp realized_feedback_import_status("missing", _approval_status),
    do: "blocked_missing_cadence_import"

  defp realized_feedback_import_status(_cadence_import_status, approval_status),
    do: adapter_import_status("present", approval_status)

  defp realized_feedback_import_action("not_required"), do: "record_realized_feedback"
  defp realized_feedback_import_action(_approval_status), do: "review_realized_feedback"

  defp contact_contention_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:contact_contention:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => contact_contention_import_action(row),
      "import_status" => adapter_import_status("present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "resource_scope" => row["resource_scope"],
      "ground_station_id" => row["ground_station_id"],
      "ground_station_ids" => row["ground_station_ids"],
      "spacecraft_id" => row["spacecraft_id"],
      "spacecraft_ids" => row["spacecraft_ids"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "direction" => row["direction"],
      "directions" => row["directions"],
      "contact_count" => row["contact_count"],
      "contention_window_s" => row["contention_window_s"],
      "total_contact_duration_s" => row["total_contact_duration_s"],
      "overlap_duration_s" => row["overlap_duration_s"],
      "max_concurrent_contacts" => row["max_concurrent_contacts"],
      "overlap_contact_pair_count" => row["overlap_contact_pair_count"],
      "contact_id" => row["contact_id"],
      "contact_ids" => row["contact_ids"],
      "duplicate_contact_ids" => row["duplicate_contact_ids"],
      "duplicate_contact_id_count" => row["duplicate_contact_id_count"],
      "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
      "source_contact_candidates" => row["source_contact_candidates"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(row["contact_result"]),
      "command_result" => provider_result_artifact_value(row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "actual_throughput_mb" => row["actual_throughput_mb"],
      "actual_data_rate_throughput_derivations" => row["actual_data_rate_throughput_derivations"],
      "source_window_ids" => row["source_window_ids"],
      "scenario_ids" => row["scenario_ids"],
      "selected_contact_id" => row["selected_contact_id"],
      "selected_contact_ids" => row["selected_contact_ids"],
      "selected_priority" => row["selected_priority"],
      "selected_priority_source" => row["selected_priority_source"],
      "deferred_contact_ids" => row["deferred_contact_ids"],
      "review_contact_ids" => row["review_contact_ids"],
      "deferred_contact_priorities" => row["deferred_contact_priorities"],
      "candidate_count" => row["candidate_count"],
      "selection_reason" => row["selection_reason"],
      "resolution_selection_rule" => row["resolution_selection_rule"],
      "resolution_priority_fields" => row["resolution_priority_fields"],
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
      "resolution_tie_breakers" => row["resolution_tie_breakers"],
      "requested_selection_rule" => row["requested_selection_rule"],
      "ignored_tie_breakers" => row["ignored_tie_breakers"],
      "ignored_policy_input" => row["ignored_policy_input"],
      "policy_warnings" => row["policy_warnings"],
      "resolution_status" => row["resolution_status"],
      "resolution_issue" => row["resolution_issue"],
      "capacity_pack_required_capacity_fraction" =>
        row["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        row["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        row["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        row["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        row["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        row["required_capacity_fraction_source_counts"],
      "source_summary_model" => row["source_summary_model"],
      "source_summary_schema_contract" => row["source_summary_schema_contract"],
      "source_summary_source" => row["source_summary_source"],
      "source_artifact_type" => row["source_artifact_type"],
      "schema_contract" => row["schema_contract"],
      "duplicate_contact_candidates" => row["duplicate_contact_candidates"],
      "operator_action_reason" => row["operator_action_reason"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "source_contention_group" => row["source_contention_group"],
      "source_invalid_contact_input" => row["source_invalid_contact_input"],
      "source_contact_contention_resolution_summary" =>
        row["source_contact_contention_resolution_summary"],
      "source_recommendation" => row["source_recommendation"],
      "source_review_row" => row
    }
    |> Map.merge(Map.take(row, station_calendar_context_fields()))
    |> compact_map()
  end

  defp contact_contention_import_action(%{"review_type" => "contact_contention_recommendation"}),
    do: "review_contact_contention_resolution"

  defp contact_contention_import_action(_row), do: "review_contact_contention"

  defp contact_allocation_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    import_action = contact_allocation_import_action(row)

    %{
      "id" => "cadence_import:contact_allocation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => import_action,
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "contact_id" => row["contact_id"],
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
      "deferred_contact_ids" => row["deferred_contact_ids"],
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
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "provider_counteroffer_negotiation_state" => row["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
      "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
      "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "trust_boundary" => row["trust_boundary"],
      "provenance" => row["provenance"],
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
      "base_station_calendar_row_id" => row["base_station_calendar_row_id"],
      "duplicate_station_calendar_row_id_collision" =>
        row["duplicate_station_calendar_row_id_collision"],
      "duplicate_station_calendar_row_index" => row["duplicate_station_calendar_row_index"],
      "duplicate_station_calendar_row_count" => row["duplicate_station_calendar_row_count"],
      "approval_status" => approval_status,
      "policy_classification" => row["policy_classification"],
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_contact_allocation" => row["source_contact_allocation"],
      "source_contact_candidate" => row["source_contact_candidate"],
      "source_resource_summary" => row["source_resource_summary"],
      "source_resource_suppression" => row["source_resource_suppression"],
      "source_contact_suppression" => row["source_contact_suppression"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_contention_recommendation" => row["source_contention_recommendation"],
      "source_provider_reservation_request_summary" =>
        row["source_provider_reservation_request_summary"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp contact_allocation_import_action(%{
         "provider_reservation_request_status" => "request_ready"
       }),
       do: "review_provider_reservation_request"

  defp contact_allocation_import_action(_row), do: "review_contact_allocation"

  defp contact_intent_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    has_cadence_import = cadence_import_present?(row, import_status)
    requirement = first_approval_requirement(row)
    rule_match = first_approval_rule_match(row)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{})

    policy_escalation =
      (row["source_policy_escalation"] ||
         preferred_approval_escalation(policy_decision["escalations"], row, %{}))
      |> stringify_keys()

    %{
      "id" => "cadence_import:contact_intent:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_contact_intent",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "contact_id" => row["contact_id"],
      "timeline_id" => row["timeline_id"],
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "activity_type" => row["activity_type"],
      "direction" => row["direction"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "estimated_throughput_mb" => row["estimated_throughput_mb"],
      "station_availability" => row["station_availability"],
      "capacity_fraction" => row["capacity_fraction"],
      "capacity_fraction_min" => row["capacity_fraction_min"],
      "capacity_fraction_max" => row["capacity_fraction_max"],
      "required_capacity_fraction" => row["required_capacity_fraction"],
      "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
      "capacity_pack_required_capacity_fraction" =>
        row["capacity_pack_required_capacity_fraction"],
      "capacity_pack_contact_ids" => row["capacity_pack_contact_ids"],
      "contact_ids" => row["contact_ids"],
      "source_summary_model" => row["source_summary_model"],
      "source_summary_schema_contract" => row["source_summary_schema_contract"],
      "source_summary_source" => row["source_summary_source"],
      "source_artifact_type" => row["source_artifact_type"],
      "schema_contract" => row["schema_contract"],
      "station_contention_status" => row["station_contention_status"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "schedule_conflict_status" => row["schedule_conflict_status"],
      "contact_success" => row["contact_success"],
      "contact_result" => provider_result_artifact_value(row["contact_result"]),
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "command_result" => provider_result_artifact_value(row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "source_window_id" => row["source_window_id"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["cadence_import_type"],
      "cadence_import_id" => row["cadence_import_id"],
      "cadence_import_contract" => row["cadence_import_contract"],
      "has_cadence_import" => has_cadence_import,
      "contact_intent_gate" => "contact_intent_policy",
      "contact_intent_gate_status" => approval_status,
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || requirement["required_authority"] ||
          rule_match["required_authority"] || policy_escalation["required_authority"],
      "policy_bundle_id" =>
        row["policy_bundle_id"] || requirement["policy_bundle_id"] ||
          policy_decision["policy_bundle_id"],
      "rule_id" =>
        row["rule_id"] || requirement["rule_id"] || rule_match["rule_id"] ||
          policy_escalation["rule_id"],
      "escalation_level" =>
        row["escalation_level"] || rule_match["escalation_level"] ||
          policy_escalation["escalation_level"],
      "escalation_queue" =>
        row["escalation_queue"] || rule_match["escalation_queue"] ||
          policy_escalation["escalation_queue"],
      "escalation_role" =>
        row["escalation_role"] || rule_match["escalation_role"] ||
          policy_escalation["escalation_role"],
      "sla_s" => row["sla_s"] || rule_match["sla_s"] || policy_escalation["sla_s"],
      "reason" => row["reason"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "timeline_identity" => row["timeline_identity"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(generic_review_activity_context(row)),
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => non_empty_map(policy_escalation),
      "source_contact_intent_summary" => row["source_contact_intent_summary"],
      "source_contact_intent" => row["source_contact_intent"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp candidate_diff_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    semantic_change_reasons = semantic_change_reasons(row)
    changed_fields = candidate_diff_changed_fields(row)

    %{
      "id" => "cadence_import:candidate_diff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_candidate_diff",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "target_id" => row["target_id"],
      "source_target_id" => row["source_target_id"],
      "source_target" => row["source_target"],
      "target_latitude_deg" => row["target_latitude_deg"],
      "target_longitude_deg" => row["target_longitude_deg"],
      "target_minimum_elevation_deg" => row["target_minimum_elevation_deg"],
      "target_priority" => row["target_priority"],
      "target_priority_source" => row["target_priority_source"],
      "target_priority_objective_ids" => row["target_priority_objective_ids"],
      "target_priority_objective_type" => row["target_priority_objective_type"],
      "ground_station_id" => row["ground_station_id"],
      "direction" => row["direction"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "source_window" => row["source_window"],
      "source_window_lineage" => row["source_window_lineage"],
      "replacement_source_window_id" => row["replacement_source_window_id"],
      "replacement_source_window_type" => row["replacement_source_window_type"],
      "replacement_source_window" => row["replacement_source_window"],
      "replacement_source_window_lineage" => row["replacement_source_window_lineage"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "refresh_gate" => "candidate_diff",
      "refresh_gate_status" => candidate_diff_gate_status(row),
      "candidate_diff_reason_count" => length(semantic_change_reasons),
      "candidate_diff" => row["candidate_diff"],
      "invalidated_candidate_id" => row["invalidated_candidate_id"],
      "invalidated_candidate_ids" => row["invalidated_candidate_ids"],
      "replacement_candidate_id" => row["replacement_candidate_id"],
      "invalidated_reason" => row["invalidated_reason"],
      "semantic_change_reasons" => semantic_change_reasons,
      "semantic_change_details" => row["semantic_change_details"],
      "changed_fields" => changed_fields,
      "candidate_diff_changed_fields" => changed_fields,
      "candidate_diff_changed_field_count" => candidate_diff_changed_field_count(changed_fields),
      "candidate_diff_match_status" => row["candidate_diff_match_status"],
      "candidate_diff_match_count" => row["candidate_diff_match_count"],
      "semantic_match_status" => row["semantic_match_status"],
      "semantic_match_candidate_count" => row["semantic_match_candidate_count"],
      "semantic_match_candidate_ids" => row["semantic_match_candidate_ids"],
      "candidate_budget_match_status" => row["candidate_budget_match_status"],
      "candidate_budget_match_count" => row["candidate_budget_match_count"],
      "budget_dropped_candidate_ids" => row["budget_dropped_candidate_ids"],
      "invalid_prior_candidate_input" => row["invalid_prior_candidate_input"],
      "invalid_prior_candidate_input_reason" => row["invalid_prior_candidate_input_reason"],
      "source_candidate" => row["source_candidate"],
      "source_candidate_diff" => row["source_candidate_diff"],
      "source_review_row" => row
    }
    |> Map.merge(candidate_diff_scoped_context(row))
    |> compact_map()
  end

  defp candidate_diff_scoped_context(row) do
    row
    |> Map.take(@candidate_diff_scoped_context_fields)
    |> compact_map()
  end

  defp candidate_diff_gate_status(row) do
    row["candidate_diff_match_status"] ||
      row["semantic_match_status"] ||
      row["candidate_budget_match_status"] ||
      row["invalidated_reason"] ||
      get_in(row, ["candidate_diff", "diff_reason"]) ||
      "candidate_invalidated"
  end

  defp suppression_manifest_row(row, rank, suppression_type) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    requirement = first_approval_requirement(row)
    rule_match = first_approval_rule_match(row)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{})

    policy_escalation =
      (row["source_policy_escalation"] ||
         preferred_approval_escalation(policy_decision["escalations"], row, %{}))
      |> stringify_keys()

    %{
      "id" => "cadence_import:#{suppression_type}_suppression:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_#{suppression_type}_suppression",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "base_candidate_id" => row["base_candidate_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "target_id" => row["target_id"],
      "ground_station_id" => row["ground_station_id"],
      "direction" => row["direction"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "source_window_id" => row["source_window_id"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(row["contact_result"]),
      "command_result" => provider_result_artifact_value(row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_availability" => row["station_availability"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "provider_counteroffer_negotiation_state" => row["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
      "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
      "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
      "station_contention_status" => row["station_contention_status"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "duplicate_suppressed_candidate_id_collision" =>
        row["duplicate_suppressed_candidate_id_collision"],
      "duplicate_suppressed_candidate_index" => row["duplicate_suppressed_candidate_index"],
      "duplicate_suppressed_candidate_count" => row["duplicate_suppressed_candidate_count"],
      "invalid_candidate_input" => row["invalid_candidate_input"],
      "invalid_candidate_input_reason" => row["invalid_candidate_input_reason"],
      "source_candidate" => row["source_candidate"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
      "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
      "resource_source_quality" => row["resource_source_quality"],
      "resource_trust_boundary" => row["resource_trust_boundary"],
      "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
      "resource_provenance" => row["resource_provenance"],
      "resource_blocking_dimension" => row["resource_blocking_dimension"],
      "fuel_margin" => row["fuel_margin"],
      "thermal_margin_c" => row["thermal_margin_c"],
      "power_margin" => row["power_margin"],
      "storage_margin" => row["storage_margin"],
      "downlink_margin" => row["downlink_margin"],
      "spacecraft_available" => row["spacecraft_available"],
      "payload_available" => row["payload_available"],
      "antenna_available" => row["antenna_available"],
      "degraded" => row["degraded"],
      "mode" => row["mode"],
      "incompatible_activity_types" => row["incompatible_activity_types"],
      "suppressed_activity_types" => row["suppressed_activity_types"],
      "suppressed_reason" => row["suppressed_reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || requirement["required_authority"] ||
          policy_escalation["required_authority"],
      "policy_bundle_id" =>
        row["policy_bundle_id"] || requirement["policy_bundle_id"] ||
          policy_decision["policy_bundle_id"],
      "rule_id" =>
        row["rule_id"] || requirement["rule_id"] || rule_match["rule_id"] ||
          policy_escalation["rule_id"],
      "escalation_level" =>
        row["escalation_level"] || rule_match["escalation_level"] ||
          policy_escalation["escalation_level"],
      "escalation_queue" =>
        row["escalation_queue"] || rule_match["escalation_queue"] ||
          policy_escalation["escalation_queue"],
      "escalation_role" =>
        row["escalation_role"] || rule_match["escalation_role"] ||
          policy_escalation["escalation_role"],
      "sla_s" => row["sla_s"] || rule_match["sla_s"] || policy_escalation["sla_s"],
      "reason" => row["reason"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_contact_candidate" => row["source_contact_candidate"],
      "source_contact_suppression" => row["source_contact_suppression"],
      "source_resource_suppression" => row["source_resource_suppression"],
      "source_resource_summary" => row["source_resource_summary"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => non_empty_map(policy_escalation),
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp first_approval_requirement(%{"approval_requirements" => requirements})
       when is_list(requirements) do
    requirements
    |> Enum.find(%{}, &is_map/1)
    |> stringify_keys()
  end

  defp first_approval_requirement(_row), do: %{}

  defp first_approval_rule_match(%{"approval_rule_matches" => rule_matches} = row)
       when is_list(rule_matches) do
    preferred_approval_rule_match(rule_matches, row_approval_classification(row))
  end

  defp first_approval_rule_match(_row), do: %{}

  defp row_approval_classification(%{} = row) do
    row["approval_status"] || get_in(row, ["policy_decision", "classification"])
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

  defp preferred_approval_escalation(escalations, row, source_requirement)
       when is_list(escalations) do
    escalations = escalations |> Enum.filter(&is_map/1) |> Enum.map(&stringify_keys/1)

    rule_ids =
      [first_approval_rule_match(row), first_approval_rule_match(source_requirement)]
      |> Enum.map(& &1["rule_id"])
      |> Enum.reject(&is_nil/1)

    Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
      Enum.find(escalations, %{}, &policy_escalation_context?/1)
  end

  defp preferred_approval_escalation(_escalations, _row, _source_requirement), do: %{}

  defp policy_escalation_context?(%{} = escalation) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(escalation, &1)
    )
  end

  defp policy_escalation_context?(_escalation), do: false

  defp freshness_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    stale_reasons = List.wrap(row["stale_reasons"])
    unknown_reasons = List.wrap(row["unknown_reasons"])

    %{
      "id" => "cadence_import:freshness_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_refresh_freshness",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "refresh_gate" => "accepted_state_freshness",
      "refresh_gate_status" => row["freshness_status"],
      "freshness_reason_count" => length(stale_reasons) + length(unknown_reasons),
      "freshness_status" => row["freshness_status"],
      "generated_at" => row["generated_at"],
      "accepted_at" => row["accepted_at"],
      "accepted_state_quality_level" => row["accepted_state_quality_level"],
      "allowed_state_quality_levels" => row["allowed_state_quality_levels"],
      "state_quality_status" => row["state_quality_status"],
      "current_epoch_s" => row["current_epoch_s"],
      "horizon_starts_at_s" => row["horizon_starts_at_s"],
      "accepted_snapshot_age_s" => row["accepted_snapshot_age_s"],
      "horizon_start_offset_s" => row["horizon_start_offset_s"],
      "max_snapshot_age_s" => row["max_snapshot_age_s"],
      "max_horizon_start_offset_s" => row["max_horizon_start_offset_s"],
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => unknown_reasons,
      "source_freshness_report" => row["source_freshness_report"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp refresh_budget_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    dropped_count =
      row["dropped_candidate_count"] || length(List.wrap(row["dropped_candidate_ids"]))

    %{
      "id" => "cadence_import:refresh_budget_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_refresh_budget",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "refresh_gate" => "candidate_budget",
      "refresh_gate_status" => refresh_budget_gate_status(row),
      "refresh_budget_overflow_count" => dropped_count,
      "input_candidate_count" => row["input_candidate_count"],
      "kept_candidate_count" => row["kept_candidate_count"],
      "dropped_candidate_count" => row["dropped_candidate_count"],
      "max_candidate_activities" => row["max_candidate_activities"],
      "invalid_candidate_limit_policy" => row["invalid_candidate_limit_policy"],
      "invalid_candidate_limit_policy_reason" => row["invalid_candidate_limit_policy_reason"],
      "source_candidate_limit_policy" => row["source_candidate_limit_policy"],
      "selection_order" => row["selection_order"],
      "kept_candidate_ids" => row["kept_candidate_ids"],
      "dropped_candidate_ids" => row["dropped_candidate_ids"],
      "source_refresh_budget_report" => row["source_refresh_budget_report"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp refresh_budget_gate_status(%{"invalid_candidate_limit_policy" => true}),
    do: "invalid_candidate_limit_policy"

  defp refresh_budget_gate_status(_row), do: "candidate_budget_exceeded"

  defp operational_readiness_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:operational_readiness_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => generic_review_import_action("operational_readiness_review"),
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_artifact_type" => row["source_artifact_type"],
      "source_artifact_id" => row["source_artifact_id"],
      "readiness_level" => row["readiness_level"],
      "import_classification" => row["import_classification"],
      "operational_readiness_status" => row["operational_readiness_status"],
      "readiness_gate_id" => row["readiness_gate_id"],
      "readiness_gate_status" => row["readiness_gate_status"],
      "readiness_gate_classification" => row["readiness_gate_classification"],
      "readiness_gate_reason" => row["readiness_gate_reason"],
      "analysis_mode" => row["analysis_mode"],
      "analysis_mode_source" => row["analysis_mode_source"],
      "gate_count" => row["gate_count"],
      "passed_gate_count" => row["passed_gate_count"],
      "review_gate_count" => row["review_gate_count"],
      "analysis_gate_count" => row["analysis_gate_count"],
      "blocked_gate_count" => row["blocked_gate_count"],
      "gates" => row["gates"],
      "evidence" => row["evidence"],
      "source_operational_readiness_gate" => row["source_operational_readiness_gate"],
      "source_operational_readiness_report" => row["source_operational_readiness_report"],
      "source_review_row" => row
    }
    |> Map.merge(operational_readiness_resource_context(row))
    |> Map.merge(operational_readiness_adapter_boundary_context(row))
    |> Map.merge(operational_readiness_operator_training_context(row))
    |> Map.merge(operational_readiness_cadence_import_context(row))
    |> compact_map()
  end

  defp quality_gate_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:quality_gate_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_quality_gate",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_artifact_type" => row["source_artifact_type"],
      "source_artifact_id" => row["source_artifact_id"],
      "readiness_level" => row["readiness_level"],
      "import_classification" => row["import_classification"],
      "quality_gate_report_id" => row["quality_gate_report_id"],
      "quality_gate_id" => row["quality_gate_id"],
      "quality_gate_status" => row["quality_gate_status"],
      "quality_gate_classification" => row["quality_gate_classification"],
      "quality_gate_reason" => row["quality_gate_reason"],
      "readiness_gate_id" => row["readiness_gate_id"],
      "readiness_gate_status" => row["readiness_gate_status"],
      "readiness_gate_classification" => row["readiness_gate_classification"],
      "readiness_gate_reason" => row["readiness_gate_reason"],
      "analysis_mode" => row["analysis_mode"],
      "analysis_mode_source" => row["analysis_mode_source"],
      "source_quality_gate_row" => row["source_quality_gate_row"],
      "source_quality_gate_report" => row["source_quality_gate_report"],
      "source_review_row" => row
    }
    |> Map.merge(operational_readiness_cadence_import_context(row))
    |> Map.merge(operational_readiness_resource_context(row))
    |> compact_map()
  end

  defp operational_readiness_adapter_boundary_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "adapter_context_count" =>
        row["adapter_context_count"] || evidence["adapter_context_count"],
      "adapter_trust_boundary_declared_count" =>
        row["adapter_trust_boundary_declared_count"] ||
          evidence["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" =>
        row["adapter_trust_boundary_missing_count"] ||
          evidence["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" =>
        row["adapter_trust_boundary_untrusted_count"] ||
          evidence["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" =>
        row["adapter_boundary_status_counts"] || evidence["adapter_boundary_status_counts"]
    }
  end

  defp operational_readiness_resource_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "resource_availability_pressure_count" =>
        row["resource_availability_pressure_count"] ||
          evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" =>
        row["resource_availability_reason_counts"] ||
          evidence["resource_availability_reason_counts"],
      "resource_availability_reason_ids" =>
        row["resource_availability_reason_ids"] ||
          evidence["resource_availability_reason_ids"],
      "station_availability_reason_ids" =>
        row["station_availability_reason_ids"] ||
          evidence["station_availability_reason_ids"],
      "station_availability_reason_counts" =>
        row["station_availability_reason_counts"] ||
          evidence["station_availability_reason_counts"],
      "unavailable_resource_reason_ids" =>
        row["unavailable_resource_reason_ids"] ||
          evidence["unavailable_resource_reason_ids"],
      "resource_blocking_dimension_counts" =>
        row["resource_blocking_dimension_counts"] ||
          evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        row["resource_blocked_contact_ids_by_blocking_dimension"] ||
          evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        row["resource_blocked_contact_ids_by_spacecraft_id"] ||
          evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" =>
        row["resource_source_quality_counts"] || evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" =>
        row["resource_trust_boundary_status_counts"] ||
          evidence["resource_trust_boundary_status_counts"]
    }
  end

  defp operational_readiness_operator_training_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "operator_training_requirement_count" =>
        row["operator_training_requirement_count"] ||
          evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" =>
        row["operator_training_requirement_counts"] ||
          evidence["operator_training_requirement_counts"],
      "required_operator_roles" =>
        row["required_operator_roles"] || evidence["required_operator_roles"],
      "required_training_ids" =>
        row["required_training_ids"] || evidence["required_training_ids"],
      "required_certification_ids" =>
        row["required_certification_ids"] || evidence["required_certification_ids"],
      "required_qualification_ids" =>
        row["required_qualification_ids"] || evidence["required_qualification_ids"]
    }
  end

  defp operational_readiness_cadence_import_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "ready_for_import_count" =>
        row["ready_for_import_count"] || evidence["ready_for_import_count"],
      "manifest_review_required_count" =>
        row["manifest_review_required_count"] || evidence["manifest_review_required_count"],
      "blocked_import_count" => row["blocked_import_count"] || evidence["blocked_import_count"],
      "missing_import_count" => row["missing_import_count"] || evidence["missing_import_count"],
      "invalid_cadence_import_count" =>
        row["invalid_cadence_import_count"] || evidence["invalid_cadence_import_count"],
      "current_freshness_count" =>
        row["current_freshness_count"] || evidence["current_freshness_count"],
      "stale_freshness_count" =>
        row["stale_freshness_count"] || evidence["stale_freshness_count"],
      "unknown_freshness_count" =>
        row["unknown_freshness_count"] || evidence["unknown_freshness_count"],
      "freshness_status_counts" =>
        row["freshness_status_counts"] || evidence["freshness_status_counts"],
      "schema_validation_pass_count" =>
        row["schema_validation_pass_count"] || evidence["schema_validation_pass_count"],
      "schema_validation_fail_count" =>
        row["schema_validation_fail_count"] || evidence["schema_validation_fail_count"],
      "schema_validation_error_count" =>
        row["schema_validation_error_count"] || evidence["schema_validation_error_count"],
      "schema_validation_warning_count" =>
        row["schema_validation_warning_count"] || evidence["schema_validation_warning_count"],
      "schema_validation_remediation_count" =>
        row["schema_validation_remediation_count"] ||
          evidence["schema_validation_remediation_count"],
      "schema_validation_status_counts" =>
        row["schema_validation_status_counts"] || evidence["schema_validation_status_counts"],
      "import_status_counts" => row["import_status_counts"] || evidence["import_status_counts"],
      "cadence_import_status_counts" =>
        row["cadence_import_status_counts"] || evidence["cadence_import_status_counts"]
    }
  end

  defp approval_requirement_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    source_requirement = stringify_keys(row["source_requirement"] || %{})
    rule_match = first_approval_rule_match(row)
    source_rule_match = first_approval_rule_match(source_requirement)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{})

    policy_escalation =
      policy_decision["escalations"]
      |> preferred_approval_escalation(row, source_requirement)
      |> stringify_keys()

    %{
      "id" => "cadence_import:approval_requirement:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_approval_requirement",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "target_id" => row["target_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || source_requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || source_requirement["required_authority"] ||
          rule_match["required_authority"] || source_rule_match["required_authority"] ||
          policy_escalation["required_authority"],
      "policy_bundle_id" =>
        row["policy_bundle_id"] || source_requirement["policy_bundle_id"] ||
          policy_decision["policy_bundle_id"],
      "rule_id" =>
        row["rule_id"] || source_requirement["rule_id"] || rule_match["rule_id"] ||
          source_rule_match["rule_id"] || policy_escalation["rule_id"],
      "escalation_level" =>
        row["escalation_level"] || rule_match["escalation_level"] ||
          source_rule_match["escalation_level"] || policy_escalation["escalation_level"],
      "escalation_queue" =>
        row["escalation_queue"] || rule_match["escalation_queue"] ||
          source_rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
      "escalation_role" =>
        row["escalation_role"] || rule_match["escalation_role"] ||
          source_rule_match["escalation_role"] || policy_escalation["escalation_role"],
      "sla_s" =>
        row["sla_s"] || rule_match["sla_s"] || source_rule_match["sla_s"] ||
          policy_escalation["sla_s"],
      "reason" => row["reason"],
      "approval_rule_matches" =>
        row["approval_rule_matches"] || source_requirement["approval_rule_matches"],
      "candidate_diff" => row["candidate_diff"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(generic_review_activity_context(row)),
      "source_requirement" => row["source_requirement"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" =>
        row["source_policy_escalation"] || non_empty_map(policy_escalation),
      "source_review_row" => row
    }
    |> put_candidate_diff_fields(row["candidate_diff"])
    |> compact_map()
  end

  defp put_candidate_diff_fields(row, nil), do: row

  defp put_candidate_diff_fields(row, %{} = candidate_diff) do
    row
    |> Map.put("invalidated_candidate_id", candidate_diff["invalidated_candidate_id"])
    |> Map.put("invalidated_candidate_ids", candidate_diff["invalidated_candidate_ids"])
    |> Map.put("replacement_candidate_id", candidate_diff["replacement_candidate_id"])
    |> Map.put("invalidated_reason", candidate_diff["invalidated_reason"])
    |> Map.put("semantic_change_reasons", candidate_diff["semantic_change_reasons"])
    |> Map.put("semantic_change_details", candidate_diff["semantic_change_details"])
    |> put_candidate_diff_changed_fields(candidate_diff)
    |> Map.put("candidate_diff_match_status", candidate_diff["candidate_diff_match_status"])
    |> Map.put("candidate_diff_match_count", candidate_diff["candidate_diff_match_count"])
    |> Map.put("semantic_match_status", candidate_diff["semantic_match_status"])
    |> Map.put("semantic_match_candidate_count", candidate_diff["semantic_match_candidate_count"])
    |> Map.put("semantic_match_candidate_ids", candidate_diff["semantic_match_candidate_ids"])
    |> Map.put("candidate_budget_match_status", candidate_diff["candidate_budget_match_status"])
    |> Map.put("candidate_budget_match_count", candidate_diff["candidate_budget_match_count"])
    |> Map.put("budget_dropped_candidate_ids", candidate_diff["budget_dropped_candidate_ids"])
  end

  defp put_candidate_diff_changed_fields(row, candidate_diff) do
    changed_fields = candidate_diff_changed_fields(candidate_diff)

    row
    |> Map.put("changed_fields", changed_fields)
    |> Map.put("candidate_diff_changed_fields", changed_fields)
    |> Map.put(
      "candidate_diff_changed_field_count",
      candidate_diff_changed_field_count(changed_fields)
    )
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

  defp maneuver_review_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:maneuver_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_maneuver",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
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
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "execution_boundary" => row["execution_boundary"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_recommendation" => row["source_recommendation"],
      "source_maneuver_review" => row["source_maneuver_review"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp timeline_diff_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:timeline_diff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_timeline_diff",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
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
      "changed_fields" => row["changed_fields"],
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
      "selected_exclusivity_violation_group" => row["selected_exclusivity_violation_group"],
      "approval_status" => approval_status,
      "policy_classification" => row["policy_classification"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "operator_action_reason" => row["operator_action_reason"] || row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(generic_review_activity_context(row)),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(row["source_activity_context"]),
      "replacement_activity_context" =>
        normalize_provider_result_artifact_fields(row["replacement_activity_context"]),
      "timeline_link" => row["timeline_link"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "source_timeline_diff" => row["source_timeline_diff"],
      "source_timeline_diff_summary" => row["source_timeline_diff_summary"],
      "source_timeline_diff_summary_source_activity_count" =>
        row["source_timeline_diff_summary_source_activity_count"],
      "source_timeline_diff_summary_replacement_activity_count" =>
        row["source_timeline_diff_summary_replacement_activity_count"],
      "source_timeline_diff_summary_row_count" => row["source_timeline_diff_summary_row_count"],
      "source_timeline_diff_summary_added_count" =>
        row["source_timeline_diff_summary_added_count"],
      "source_timeline_diff_summary_removed_count" =>
        row["source_timeline_diff_summary_removed_count"],
      "source_timeline_diff_summary_changed_count" =>
        row["source_timeline_diff_summary_changed_count"],
      "source_timeline_diff_summary_unchanged_count" =>
        row["source_timeline_diff_summary_unchanged_count"],
      "source_timeline_diff_summary_review_required_count" =>
        row["source_timeline_diff_summary_review_required_count"],
      "source_timeline_diff_summary_duplicate_timeline_identity_count" =>
        row["source_timeline_diff_summary_duplicate_timeline_identity_count"],
      "source_timeline_diff_summary_invalid_source_activity_input_count" =>
        row["source_timeline_diff_summary_invalid_source_activity_input_count"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_count" =>
        row["source_timeline_diff_summary_invalid_replacement_activity_input_count"],
      "source_timeline_diff_summary_diff_status_counts" =>
        row["source_timeline_diff_summary_diff_status_counts"],
      "source_timeline_diff_summary_transition_decision_counts" =>
        row["source_timeline_diff_summary_transition_decision_counts"],
      "source_timeline_diff_summary_required_operator_action_counts" =>
        row["source_timeline_diff_summary_required_operator_action_counts"],
      "source_timeline_diff_summary_changed_field_counts" =>
        row["source_timeline_diff_summary_changed_field_counts"],
      "source_timeline_diff_summary_status_transition_category_counts" =>
        row["source_timeline_diff_summary_status_transition_category_counts"],
      "source_timeline_diff_summary_approval_transition_category_counts" =>
        row["source_timeline_diff_summary_approval_transition_category_counts"],
      "source_timeline_diff_summary_added_timeline_ids" =>
        row["source_timeline_diff_summary_added_timeline_ids"],
      "source_timeline_diff_summary_removed_timeline_ids" =>
        row["source_timeline_diff_summary_removed_timeline_ids"],
      "source_timeline_diff_summary_changed_timeline_ids" =>
        row["source_timeline_diff_summary_changed_timeline_ids"],
      "source_timeline_diff_summary_unchanged_timeline_ids" =>
        row["source_timeline_diff_summary_unchanged_timeline_ids"],
      "source_timeline_diff_summary_duplicate_timeline_identity_ids" =>
        row["source_timeline_diff_summary_duplicate_timeline_identity_ids"],
      "source_timeline_diff_summary_invalid_source_activity_input_ids" =>
        row["source_timeline_diff_summary_invalid_source_activity_input_ids"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_ids" =>
        row["source_timeline_diff_summary_invalid_replacement_activity_input_ids"],
      "source_timeline_diff_summary_review_timeline_ids" =>
        row["source_timeline_diff_summary_review_timeline_ids"],
      "source_timeline_diff_summary_review_timeline_ids_by_required_operator_action" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_required_operator_action"],
      "source_timeline_diff_summary_review_timeline_ids_by_status_transition_category" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_status_transition_category"],
      "source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category"],
      "source_timeline_diff_summary_timeline_ids_by_changed_field" =>
        row["source_timeline_diff_summary_timeline_ids_by_changed_field"],
      "transition_application_provenance" => row["transition_application_provenance"],
      "source_timeline_application" => row["source_timeline_application"],
      "source_timeline_transition_application_summary" =>
        row["source_timeline_transition_application_summary"],
      "source_transition_application_source_activity_count" =>
        row["source_transition_application_source_activity_count"],
      "source_transition_application_replacement_activity_count" =>
        row["source_transition_application_replacement_activity_count"],
      "source_transition_application_count" => row["source_transition_application_count"],
      "source_transition_application_selected_activity_count" =>
        row["source_transition_application_selected_activity_count"],
      "source_transition_application_review_required_count" =>
        row["source_transition_application_review_required_count"],
      "source_transition_application_preserved_source_count" =>
        row["source_transition_application_preserved_source_count"],
      "source_transition_application_recorded_replacement_count" =>
        row["source_transition_application_recorded_replacement_count"],
      "source_transition_application_withheld_review_count" =>
        row["source_transition_application_withheld_review_count"],
      "source_transition_application_selected_timeline_integrity_review_count" =>
        row["source_transition_application_selected_timeline_integrity_review_count"],
      "source_transition_application_selected_timeline_integrity_issue_count" =>
        row["source_transition_application_selected_timeline_integrity_issue_count"],
      "source_transition_application_selected_timeline_integrity_issue_types" =>
        row["source_transition_application_selected_timeline_integrity_issue_types"],
      "source_transition_application_status_counts" =>
        row["source_transition_application_status_counts"],
      "source_transition_application_decision_counts" =>
        row["source_transition_application_decision_counts"],
      "source_transition_application_required_operator_action_counts" =>
        row["source_transition_application_required_operator_action_counts"],
      "source_transition_application_status_transition_category_counts" =>
        row["source_transition_application_status_transition_category_counts"],
      "source_transition_application_approval_transition_category_counts" =>
        row["source_transition_application_approval_transition_category_counts"],
      "source_transition_application_selected_activity_ids" =>
        row["source_transition_application_selected_activity_ids"],
      "source_transition_application_selected_timeline_ids" =>
        row["source_transition_application_selected_timeline_ids"],
      "source_transition_application_review_activity_ids" =>
        row["source_transition_application_review_activity_ids"],
      "source_transition_application_review_timeline_ids" =>
        row["source_transition_application_review_timeline_ids"],
      "source_transition_application_review_timeline_ids_by_required_operator_action" =>
        row["source_transition_application_review_timeline_ids_by_required_operator_action"],
      "source_transition_application_review_timeline_ids_by_status_transition_category" =>
        row["source_transition_application_review_timeline_ids_by_status_transition_category"],
      "source_transition_application_review_timeline_ids_by_approval_transition_category" =>
        row["source_transition_application_review_timeline_ids_by_approval_transition_category"],
      "source_transition_application_preserved_source_timeline_ids" =>
        row["source_transition_application_preserved_source_timeline_ids"],
      "source_transition_application_recorded_replacement_timeline_ids" =>
        row["source_transition_application_recorded_replacement_timeline_ids"],
      "source_transition_application_withheld_review_timeline_ids" =>
        row["source_transition_application_withheld_review_timeline_ids"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp timeline_protection_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:timeline_protection:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_timeline_protection",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "activity_id" => row["activity_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "protection_category" => row["protection_category"],
      "protection_decision" => row["protection_decision"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_timeline_protection" => row["source_timeline_protection"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp command_window_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "not_applicable")

    %{
      "id" => "cadence_import:command_window:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_command_window",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "timeline_id" => row["timeline_id"],
      "scenario_id" => row["scenario_id"],
      "window_type" => row["window_type"],
      "direction" => row["direction"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "status" => row["status"],
      "approval_status" => approval_status,
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
      "required_operator_action" => row["required_operator_action"],
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
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "execution_boundary" => row["execution_boundary"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["cadence_import_type"] || "command_window",
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "has_source_window" => row["has_source_window"],
      "has_cadence_import" => row["has_cadence_import"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "timeline_identity" => row["timeline_identity"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_command_window" => row["source_command_window"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp station_calendar_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:station_calendar:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_station_calendar",
      "import_status" => adapter_import_status("present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "branch_id" => row["branch_id"],
      "subject_id" => row["subject_id"],
      "contact_id" => row["contact_id"],
      "scenario_id" => row["scenario_id"],
      "activity_type" => row["activity_type"],
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
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "provider_counteroffer_negotiation_state" => row["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
      "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
      "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "invalid_feedback_confidence" => row["invalid_feedback_confidence"],
      "invalid_feedback_confidence_reason" => row["invalid_feedback_confidence_reason"],
      "source_contact_candidate" => row["source_contact_candidate"],
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
      "station_reservation_hold_ids_by_direction" =>
        row["station_reservation_hold_ids_by_direction"],
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        row["station_reservation_hold_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_contact_ids_by_import_status" =>
        row["station_reservation_hold_contact_ids_by_import_status"],
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        row["station_reservation_hold_contact_ids_by_expiration_status"],
      "station_reservation_hold_contact_ids_by_direction" =>
        row["station_reservation_hold_contact_ids_by_direction"],
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        row["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_import_status_counts" =>
        row["station_reservation_hold_import_status_counts"],
      "station_reservation_hold_required_import_action_counts" =>
        row["station_reservation_hold_required_import_action_counts"],
      "station_reservation_hold_import_execution_boundary" =>
        row["station_reservation_hold_import_execution_boundary"],
      "station_reservation_hold_provider_write" => row["station_reservation_hold_provider_write"],
      "station_reservation_hold_cadence_write" => row["station_reservation_hold_cadence_write"],
      "station_reservation_hold_reservation_acceptance" =>
        row["station_reservation_hold_reservation_acceptance"],
      "source_station_reservation_hold_import_readiness_summary" =>
        row["source_station_reservation_hold_import_readiness_summary"],
      "provider_calendar_contention_status" => row["provider_calendar_contention_status"],
      "provider_calendar_contention_group_id" => row["provider_calendar_contention_group_id"],
      "provider_calendar_contention_entry_count" =>
        row["provider_calendar_contention_entry_count"],
      "provider_calendar_contention_entry_ids" => row["provider_calendar_contention_entry_ids"],
      "provider_calendar_contention_provider_ids" =>
        row["provider_calendar_contention_provider_ids"],
      "provider_calendar_contention_provider_entry_ids" =>
        row["provider_calendar_contention_provider_entry_ids"],
      "provider_calendar_contention_availabilities" =>
        row["provider_calendar_contention_availabilities"],
      "provider_calendar_contention_directions" => row["provider_calendar_contention_directions"],
      "provider_calendar_contention_reservation_ids" =>
        row["provider_calendar_contention_reservation_ids"],
      "provider_calendar_contention_reserved_by" =>
        row["provider_calendar_contention_reserved_by"],
      "provider_calendar_contention_reservation_statuses" =>
        row["provider_calendar_contention_reservation_statuses"],
      "provider_calendar_contention_reservation_expires_at_s" =>
        row["provider_calendar_contention_reservation_expires_at_s"],
      "provider_calendar_contention_trust_boundary_statuses" =>
        row["provider_calendar_contention_trust_boundary_statuses"],
      "provider_calendar_contention_overlap_pairs" =>
        row["provider_calendar_contention_overlap_pairs"],
      "base_station_calendar_row_id" => row["base_station_calendar_row_id"],
      "duplicate_station_calendar_row_id_collision" =>
        row["duplicate_station_calendar_row_id_collision"],
      "duplicate_station_calendar_row_index" => row["duplicate_station_calendar_row_index"],
      "duplicate_station_calendar_row_count" => row["duplicate_station_calendar_row_count"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "operator_action_reason" => row["operator_action_reason"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "required_authority" => row["required_authority"],
      "sla_s" => row["sla_s"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_station_calendar_provider_contention" =>
        row["source_station_calendar_provider_contention"],
      "source_station_calendar_review" => row["source_station_calendar_review"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp station_reservation_manifest_row(row, rank) do
    row
    |> station_calendar_manifest_row(rank)
    |> Map.merge(%{
      "id" => "cadence_import:station_reservation:#{row["id"] || rank}",
      "import_action" => "review_station_reservation",
      "source_station_reservation" => row["source_station_reservation"]
    })
    |> compact_map()
  end

  defp policy_escalation_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:policy_escalation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_policy_escalation",
      "import_status" => adapter_import_status("present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "policy_bundle_provenance" => row["policy_bundle_provenance"],
      "policy_bundle_provenance_source" => row["policy_bundle_provenance_source"],
      "policy_bundle_adapter" => row["policy_bundle_adapter"],
      "policy_bundle_organization_id" => row["policy_bundle_organization_id"],
      "policy_bundle_policy_source" => row["policy_bundle_policy_source"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "required_authority" => row["required_authority"],
      "sla_s" => row["sla_s"],
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp resource_projection_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:resource_projection:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_resource_projection",
      "import_status" => adapter_import_status("present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "activity_id" => row["activity_id"],
      "activity_ids" => row["activity_ids"],
      "activity_type" => row["activity_type"],
      "branch_id" => row["branch_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "scenario_id" => row["scenario_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
      "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
      "duplicate_resource_summary_scope" => row["duplicate_resource_summary_scope"],
      "mixed_wildcard_resource_summary_scope" => row["mixed_wildcard_resource_summary_scope"],
      "resource_summary_key" => row["resource_summary_key"],
      "duplicate_resource_summary_index" => row["duplicate_resource_summary_index"],
      "duplicate_resource_summary_count" => row["duplicate_resource_summary_count"],
      "activity_count" => row["activity_count"],
      "effective_activity_count" => row["effective_activity_count"],
      "ignored_activity_count" => row["ignored_activity_count"],
      "ignored_activity_ids" => row["ignored_activity_ids"],
      "observation_count" => row["observation_count"],
      "downlink_count" => row["downlink_count"],
      "storage_limited_downlinked_mb" => row["storage_limited_downlinked_mb"],
      "unused_downlink_capacity_mb" => row["unused_downlink_capacity_mb"],
      "projected_storage_margin" => row["projected_storage_margin"],
      "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
      "projected_downlink_margin" => row["projected_downlink_margin"],
      "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
      "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
      "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
      "projected_power_margin" => row["projected_power_margin"],
      "projected_battery_energy_used_wh" => row["projected_battery_energy_used_wh"],
      "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
      "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
      "resource_pressure_status" => row["resource_pressure_status"],
      "resource_pressure_types" => row["resource_pressure_types"],
      "resource_flow_count" => row["resource_flow_count"],
      "total_battery_energy_consumed_wh" => row["total_battery_energy_consumed_wh"],
      "total_battery_energy_generated_wh" => row["total_battery_energy_generated_wh"],
      "net_battery_energy_delta_wh" => row["net_battery_energy_delta_wh"],
      "peak_storage_overflow_mb" => row["peak_storage_overflow_mb"],
      "peak_downlink_shortfall_mb" => row["peak_downlink_shortfall_mb"],
      "peak_battery_overuse_wh" => row["peak_battery_overuse_wh"],
      "peak_unused_downlink_capacity_mb" => row["peak_unused_downlink_capacity_mb"],
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
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
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
      "degraded" => row["degraded"],
      "mode" => row["mode"],
      "incompatible_activity_types" => row["incompatible_activity_types"],
      "suppressed_activity_types" => row["suppressed_activity_types"],
      "warnings" => row["warnings"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_activity" => row["source_activity"],
      "source_resource_summary" => row["source_resource_summary"],
      "source_resource_projection" => row["source_resource_projection"],
      "source_resource_projection_flow_summary" => row["source_resource_projection_flow_summary"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp warning_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:warning:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_warning",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "scenario_id" => row["scenario_id"],
      "activity_id" => row["activity_id"] || row["first_resource_pressure_activity_id"],
      "activity_type" => row["activity_type"] || row["first_resource_pressure_activity_type"],
      "ground_station_id" =>
        row["ground_station_id"] || row["first_resource_pressure_ground_station_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "target_id" => row["target_id"],
      "direction" => row["direction"] || row["first_resource_pressure_direction"],
      "station_calendar_entry_id" =>
        row["station_calendar_entry_id"] ||
          row["first_resource_pressure_station_calendar_entry_id"],
      "station_calendar_provider_id" =>
        row["station_calendar_provider_id"] ||
          row["first_resource_pressure_station_calendar_provider_id"],
      "station_calendar_provider_entry_id" =>
        row["station_calendar_provider_entry_id"] ||
          row["first_resource_pressure_station_calendar_provider_entry_id"],
      "station_calendar_directions" =>
        row["station_calendar_directions"] ||
          row["first_resource_pressure_station_calendar_directions"],
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
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "severity" => row["severity"],
      "operational_feedback_trust_boundary_status" =>
        row["operational_feedback_trust_boundary_status"],
      "operational_feedback_trust_boundary" => row["operational_feedback_trust_boundary"],
      "operational_feedback_trust_boundaries" => row["operational_feedback_trust_boundaries"],
      "operational_feedback_field_trust_boundaries" =>
        row["operational_feedback_field_trust_boundaries"],
      "operational_feedback_input_keys" => row["operational_feedback_input_keys"],
      "source_operational_feedback" => row["source_operational_feedback"],
      "source_operational_feedback_provenance" => row["source_operational_feedback_provenance"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp risk_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:risk:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_risk",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "scenario_id" => row["scenario_id"],
      "activity_id" => row["activity_id"] || row["first_resource_pressure_activity_id"],
      "activity_type" => row["activity_type"] || row["first_resource_pressure_activity_type"],
      "ground_station_id" =>
        row["ground_station_id"] || row["first_resource_pressure_ground_station_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "target_id" => row["target_id"],
      "direction" => row["direction"] || row["first_resource_pressure_direction"],
      "station_calendar_entry_id" =>
        row["station_calendar_entry_id"] ||
          row["first_resource_pressure_station_calendar_entry_id"],
      "station_calendar_directions" =>
        row["station_calendar_directions"] ||
          row["first_resource_pressure_station_calendar_directions"],
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
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
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
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "risk_type" => row["risk_type"],
      "severity" => row["severity"],
      "value" => row["value"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_risk" => row["source_risk"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp strategy_recommendation_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:strategy_recommendation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_strategy_recommendation",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "recommended_branch_id" => row["recommended_branch_id"] || row["branch_id"],
      "ranked_branch_ids" => row["ranked_branch_ids"],
      "tradeoff_count" => row["tradeoff_count"],
      "risk_count" => row["risk_count"],
      "risk_types" => row["risk_types"],
      "activity_ids" => row["activity_ids"],
      "scenario_ids" => row["scenario_ids"],
      "ground_station_ids" => row["ground_station_ids"],
      "spacecraft_ids" => row["spacecraft_ids"],
      "target_ids" => row["target_ids"],
      "collection_ids" => row["collection_ids"],
      "product_ids" => row["product_ids"],
      "payload_ids" => row["payload_ids"],
      "instrument_ids" => row["instrument_ids"],
      "objective_ids" => row["objective_ids"],
      "objective_types" => row["objective_types"],
      "feedback_sources" => row["feedback_sources"],
      "feedback_scopes" => row["feedback_scopes"],
      "source_activity_ids" => row["source_activity_ids"],
      "missed_downlink_activity_ids" => row["missed_downlink_activity_ids"],
      "directions" => row["directions"],
      "source_window_ids" => row["source_window_ids"],
      "source_window_types" => row["source_window_types"],
      "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
      "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
      "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "resource_pressure_statuses" => row["resource_pressure_statuses"],
      "resource_pressure_types" => row["resource_pressure_types"],
      "first_resource_pressure_kinds" => row["first_resource_pressure_kinds"],
      "operational_readiness_report_ids" => row["operational_readiness_report_ids"],
      "operational_readiness_source_artifact_types" =>
        row["operational_readiness_source_artifact_types"],
      "operational_readiness_source_artifact_ids" =>
        row["operational_readiness_source_artifact_ids"],
      "operational_readiness_levels" => row["operational_readiness_levels"],
      "operational_readiness_import_classifications" =>
        row["operational_readiness_import_classifications"],
      "operational_readiness_statuses" => row["operational_readiness_statuses"],
      "operational_readiness_gate_ids" => row["operational_readiness_gate_ids"],
      "operational_readiness_gate_statuses" => row["operational_readiness_gate_statuses"],
      "operational_readiness_gate_classifications" =>
        row["operational_readiness_gate_classifications"],
      "operational_readiness_required_operator_actions" =>
        row["operational_readiness_required_operator_actions"],
      "operational_readiness_feedback_sources" => row["operational_readiness_feedback_sources"],
      "operational_readiness_feedback_scopes" => row["operational_readiness_feedback_scopes"],
      "operational_readiness_feedback_keys" => row["operational_readiness_feedback_keys"],
      "operational_readiness_trust_boundaries" => row["operational_readiness_trust_boundaries"],
      "quality_gate_report_ids" => row["quality_gate_report_ids"],
      "quality_gate_source_artifact_types" => row["quality_gate_source_artifact_types"],
      "quality_gate_source_artifact_ids" => row["quality_gate_source_artifact_ids"],
      "quality_gate_source_readiness_report_ids" =>
        row["quality_gate_source_readiness_report_ids"],
      "quality_gate_readiness_levels" => row["quality_gate_readiness_levels"],
      "quality_gate_import_classifications" => row["quality_gate_import_classifications"],
      "quality_gate_pressure_statuses" => row["quality_gate_pressure_statuses"],
      "quality_gate_ids" => row["quality_gate_ids"],
      "quality_gate_statuses" => row["quality_gate_statuses"],
      "quality_gate_classifications" => row["quality_gate_classifications"],
      "quality_gate_required_operator_actions" => row["quality_gate_required_operator_actions"],
      "quality_gate_feedback_sources" => row["quality_gate_feedback_sources"],
      "quality_gate_feedback_scopes" => row["quality_gate_feedback_scopes"],
      "quality_gate_feedback_keys" => row["quality_gate_feedback_keys"],
      "quality_gate_trust_boundaries" => row["quality_gate_trust_boundaries"],
      "quality_gate_resource_availability_reason_ids" =>
        row["quality_gate_resource_availability_reason_ids"],
      "quality_gate_unavailable_resource_reason_ids" =>
        row["quality_gate_unavailable_resource_reason_ids"],
      "candidate_rejection_candidate_ids" => row["candidate_rejection_candidate_ids"],
      "candidate_rejection_activity_ids" => row["candidate_rejection_activity_ids"],
      "candidate_rejection_activity_types" => row["candidate_rejection_activity_types"],
      "candidate_rejection_scenario_ids" => row["candidate_rejection_scenario_ids"],
      "candidate_rejection_ground_station_ids" => row["candidate_rejection_ground_station_ids"],
      "candidate_rejection_source_window_ids" => row["candidate_rejection_source_window_ids"],
      "candidate_rejection_source_window_types" => row["candidate_rejection_source_window_types"],
      "candidate_rejection_statuses" => row["candidate_rejection_statuses"],
      "candidate_rejection_primary_reasons" => row["candidate_rejection_primary_reasons"],
      "candidate_rejection_reason_ids" => row["candidate_rejection_reason_ids"],
      "candidate_rejection_violated_constraints" =>
        row["candidate_rejection_violated_constraints"],
      "candidate_rejection_required_margin_values" =>
        row["candidate_rejection_required_margin_values"],
      "candidate_rejection_actual_margin_values" =>
        row["candidate_rejection_actual_margin_values"],
      "candidate_rejection_required_operator_actions" =>
        row["candidate_rejection_required_operator_actions"],
      "candidate_rejection_feedback_sources" => row["candidate_rejection_feedback_sources"],
      "candidate_rejection_feedback_scopes" => row["candidate_rejection_feedback_scopes"],
      "candidate_rejection_feedback_keys" => row["candidate_rejection_feedback_keys"],
      "candidate_rejection_trust_boundaries" => row["candidate_rejection_trust_boundaries"],
      "provider_counteroffer_ids" => row["provider_counteroffer_ids"],
      "provider_counteroffer_statuses" => row["provider_counteroffer_statuses"],
      "provider_counteroffer_negotiation_states" =>
        row["provider_counteroffer_negotiation_states"],
      "provider_counteroffer_reason_codes" => row["provider_counteroffer_reason_codes"],
      "provider_counteroffer_cost_deltas" => row["provider_counteroffer_cost_deltas"],
      "provider_counteroffer_lock_deadline_values_s" =>
        row["provider_counteroffer_lock_deadline_values_s"],
      "provider_counteroffer_starts_at_values_s" =>
        row["provider_counteroffer_starts_at_values_s"],
      "provider_counteroffer_ends_at_values_s" => row["provider_counteroffer_ends_at_values_s"],
      "provider_counteroffer_start_delta_values_s" =>
        row["provider_counteroffer_start_delta_values_s"],
      "provider_counteroffer_end_delta_values_s" =>
        row["provider_counteroffer_end_delta_values_s"],
      "provider_counteroffer_duration_delta_values_s" =>
        row["provider_counteroffer_duration_delta_values_s"],
      "provider_counteroffer_plan_impact_statuses" =>
        row["provider_counteroffer_plan_impact_statuses"],
      "provider_counteroffer_affected_station_calendar_entry_ids" =>
        row["provider_counteroffer_affected_station_calendar_entry_ids"],
      "provider_counteroffer_affected_provider_entry_ids" =>
        row["provider_counteroffer_affected_provider_entry_ids"],
      "provider_counteroffer_impact_counteroffer_ids" =>
        row["provider_counteroffer_impact_counteroffer_ids"],
      "provider_counteroffer_required_operator_actions" =>
        row["provider_counteroffer_required_operator_actions"],
      "provider_counteroffer_feedback_sources" => row["provider_counteroffer_feedback_sources"],
      "provider_counteroffer_feedback_scopes" => row["provider_counteroffer_feedback_scopes"],
      "provider_counteroffer_feedback_keys" => row["provider_counteroffer_feedback_keys"],
      "provider_counteroffer_trust_boundaries" => row["provider_counteroffer_trust_boundaries"],
      "approval_requirement_count" => row["approval_requirement_count"],
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
      "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
      "capacity_pack_statuses" => row["capacity_pack_statuses"],
      "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
      "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
      "capacity_pack_max_required_capacity_fraction" =>
        row["capacity_pack_max_required_capacity_fraction"],
      "capacity_pack_total_required_capacity_fraction" =>
        row["capacity_pack_total_required_capacity_fraction"],
      "capacity_pack_required_capacity_sources" => row["capacity_pack_required_capacity_sources"],
      "operational_feedback_trust_boundary_status" =>
        row["operational_feedback_trust_boundary_status"],
      "operational_feedback_trust_boundary" => row["operational_feedback_trust_boundary"],
      "operational_feedback_trust_boundaries" => row["operational_feedback_trust_boundaries"],
      "operational_feedback_field_trust_boundaries" =>
        row["operational_feedback_field_trust_boundaries"],
      "operational_feedback_input_keys" => row["operational_feedback_input_keys"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_recommendation" => row["source_recommendation"],
      "source_operational_feedback" => row["source_operational_feedback"],
      "source_operational_feedback_provenance" => row["source_operational_feedback_provenance"],
      "source_review_row" => row
    }
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.validation_refresh_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.approval_boundary_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.provider_reservation_request_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.capacity_pack_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.contact_contention_resolution_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_contention_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.station_reservation_conflict_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.station_reservation_hold_import_readiness_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.relay_data_path_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.link_capacity_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_intent_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_allocation_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_filter_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_filter_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_projection_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.station_calendar_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.score_term_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.objective_satisfaction_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.objective_tradeoff_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_margin_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.maneuver_execution_uncertainty_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.timeline_integrity_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.execution_success_feedback_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.operational_feedback_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_activity_precondition_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_activity_lifecycle_state_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_dependency_impact_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.timeline_publication_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_lifecycle_state_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_preservation_context_keys()
      )
    )
    |> Map.merge(Map.take(row, branch_timeline_evidence_fields()))
    |> Map.merge(Map.take(row, branch_readiness_quality_gate_fields()))
    |> Map.merge(Map.take(row, branch_contact_allocation_fields()))
    |> compact_map()
  end

  defp branch_contact_allocation_fields do
    [
      "branch_contact_allocation_statuses",
      "branch_contact_allocation_effective_statuses",
      "branch_contact_allocation_reasons",
      "branch_contact_allocation_review_statuses",
      "branch_contact_allocation_approval_statuses",
      "branch_contact_allocation_policy_classifications",
      "branch_station_reservation_conflict_contact_ids",
      "branch_station_reservation_conflict_reservation_ids",
      "branch_station_reservation_conflict_match_statuses"
    ]
  end

  defp branch_readiness_quality_gate_fields do
    [
      "branch_operational_readiness_levels",
      "branch_operational_readiness_import_classifications",
      "branch_operational_readiness_statuses",
      "branch_operational_readiness_source_report_paths",
      "branch_operational_readiness_gate_ids",
      "branch_operational_readiness_gate_statuses",
      "branch_operational_readiness_gate_classifications",
      "branch_operational_readiness_review_required_gate_ids",
      "branch_operational_readiness_analysis_only_gate_ids",
      "branch_operational_readiness_blocked_gate_ids",
      "branch_operational_readiness_non_passed_gate_ids",
      "branch_quality_gate_readiness_levels",
      "branch_quality_gate_import_classifications",
      "branch_quality_gate_statuses",
      "branch_quality_gate_source_report_paths",
      "branch_quality_gate_gate_classifications",
      "branch_quality_gate_review_required_gate_ids",
      "branch_quality_gate_analysis_only_gate_ids",
      "branch_quality_gate_blocked_gate_ids",
      "branch_quality_gate_non_passed_gate_ids",
      "branch_quality_gate_review_required_row_ids",
      "branch_quality_gate_analysis_only_row_ids",
      "branch_quality_gate_blocked_row_ids",
      "branch_quality_gate_non_passed_row_ids"
    ]
  end

  defp branch_timeline_evidence_fields do
    branch_timeline_activity_evidence_fields() ++ branch_timeline_publication_fields()
  end

  defp branch_timeline_activity_evidence_fields do
    [
      "branch_timeline_dependency_impact_activity_ids",
      "branch_timeline_dependency_impact_timeline_ids",
      "branch_timeline_dependency_impact_scopes",
      "branch_impacted_dependency_activity_ids",
      "branch_impacted_dependency_timeline_ids",
      "branch_impacted_exclusive_with_activity_ids",
      "branch_impacted_exclusive_with_timeline_ids",
      "branch_timeline_lifecycle_state_statuses",
      "branch_timeline_lifecycle_state_review_timeline_ids",
      "branch_timeline_lifecycle_state_review_activity_ids",
      "branch_timeline_lifecycle_state_invalid_activity_input_ids",
      "branch_timeline_lifecycle_state_required_operator_actions",
      "branch_timeline_lifecycle_state_import_actions",
      "branch_timeline_activity_lifecycle_state_activity_ids",
      "branch_timeline_activity_lifecycle_state_timeline_ids",
      "branch_timeline_activity_lifecycle_state_transition_decisions",
      "branch_timeline_activity_lifecycle_state_required_operator_actions",
      "branch_timeline_activity_lifecycle_state_import_actions",
      "branch_timeline_activity_lifecycle_state_status_transition_categories",
      "branch_timeline_activity_lifecycle_state_approval_transition_categories",
      "branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons",
      "branch_timeline_activity_precondition_activity_ids",
      "branch_timeline_activity_precondition_timeline_ids",
      "branch_timeline_activity_precondition_statuses",
      "branch_timeline_activity_precondition_blocked_types",
      "branch_timeline_activity_precondition_review_types",
      "branch_timeline_activity_precondition_dependency_activity_ids",
      "branch_timeline_activity_precondition_dependency_timeline_ids",
      "branch_timeline_activity_precondition_exclusive_with_activity_ids",
      "branch_timeline_activity_precondition_exclusive_with_timeline_ids",
      "branch_timeline_activity_precondition_duplicate_dependency_activity_ids",
      "branch_timeline_activity_precondition_duplicate_dependency_timeline_ids",
      "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids",
      "branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
      "branch_timeline_activity_precondition_invalid_activity_input_reasons",
      "branch_timeline_preservation_activity_ids",
      "branch_timeline_preservation_timeline_ids",
      "branch_timeline_preservation_statuses",
      "branch_timeline_preservation_protection_decisions",
      "branch_timeline_preservation_protection_categories",
      "branch_timeline_preservation_protection_reasons",
      "branch_timeline_preservation_preserve_activity_ids",
      "branch_timeline_preservation_preserve_timeline_ids",
      "branch_timeline_preservation_review_change_activity_ids",
      "branch_timeline_preservation_review_change_timeline_ids",
      "branch_timeline_preservation_invalid_activity_input_reasons"
    ]
  end

  defp branch_timeline_publication_fields do
    [
      "branch_timeline_publication_ids",
      "branch_timeline_publication_statuses",
      "branch_timeline_publication_source_artifact_ids",
      "branch_timeline_publication_source_artifact_types",
      "branch_timeline_publication_downstream_invalidation_statuses",
      "branch_timeline_publication_invalidated_downstream_product_ids",
      "branch_timeline_publication_downstream_invalidation_reasons",
      "branch_timeline_publication_dependency_impact_statuses",
      "branch_timeline_publication_impacted_source_activity_ids",
      "branch_timeline_publication_impacted_source_timeline_ids",
      "branch_timeline_publication_dependent_activity_ids",
      "branch_timeline_publication_dependent_timeline_ids",
      "branch_timeline_publication_changed_fields",
      "branch_timeline_publication_changed_timeline_ids",
      "branch_timeline_publication_review_timeline_ids"
    ]
  end

  defp strategy_tradeoff_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:strategy_tradeoff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => strategy_tradeoff_import_action(row),
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "dimension" => row["dimension"],
      "baseline" => row["baseline"],
      "recommended" => row["recommended"],
      "delta" => row["delta"],
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
      "branch_actual_downlink_completion_ratio" => row["branch_actual_downlink_completion_ratio"],
      "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
      "capacity_pack_statuses" => row["capacity_pack_statuses"],
      "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
      "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
      "capacity_pack_max_required_capacity_fraction" =>
        row["capacity_pack_max_required_capacity_fraction"],
      "capacity_pack_total_required_capacity_fraction" =>
        row["capacity_pack_total_required_capacity_fraction"],
      "capacity_pack_required_capacity_sources" => row["capacity_pack_required_capacity_sources"],
      "capacity_pack_contact_ids_by_direction" => row["capacity_pack_contact_ids_by_direction"],
      "capacity_pack_selected_contact_ids_by_direction" =>
        row["capacity_pack_selected_contact_ids_by_direction"],
      "capacity_pack_deferred_contact_ids_by_direction" =>
        row["capacity_pack_deferred_contact_ids_by_direction"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        row["capacity_pack_required_capacity_fraction_by_direction"],
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        row["capacity_pack_selected_required_capacity_fraction_by_direction"],
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        row["capacity_pack_deferred_required_capacity_fraction_by_direction"],
      "target_branch_base_id" => row["target_branch_base_id"],
      "target_branch_identity" => row["target_branch_identity"],
      "priority_commitment_required_target_count" =>
        row["priority_commitment_required_target_count"],
      "priority_commitment_satisfied_target_count" =>
        row["priority_commitment_satisfied_target_count"],
      "priority_commitment_missed_target_count" => row["priority_commitment_missed_target_count"],
      "priority_commitment_required_target_ids" => row["priority_commitment_required_target_ids"],
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
      "downlink_completion_planned_downlink_mb" => row["downlink_completion_planned_downlink_mb"],
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
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
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
      "repair_link_downlink_requirement_status" => row["repair_link_downlink_requirement_status"],
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
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_tradeoff" => row["source_tradeoff"],
      "source_branch_comparison" => row["source_branch_comparison"],
      "source_review_row" => row
    }
    |> Map.merge(Map.take(row, branch_timeline_evidence_fields()))
    |> Map.merge(Map.take(row, branch_readiness_quality_gate_fields()))
    |> Map.merge(Map.take(row, branch_contact_allocation_fields()))
    |> compact_map()
  end

  defp strategy_tradeoff_import_action(%{
         "required_operator_action" => "review_branch_comparison"
       }),
       do: "review_strategy_tradeoff"

  defp strategy_tradeoff_import_action(_row), do: "review_strategy_tradeoff"

  defp ranking_comparison_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:ranking_comparison:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_ranking_comparison",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "scenario_index" => row["scenario_index"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "status" => row["status"],
      "left_rank" => row["left_rank"],
      "right_rank" => row["right_rank"],
      "rank_delta" => row["rank_delta"],
      "left_value" => row["left_value"],
      "right_value" => row["right_value"],
      "value_delta" => row["value_delta"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_ranking_comparison" => row["source_ranking_comparison"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp score_term_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:score_term:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_score_term",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "branch_id" => row["branch_id"],
      "term_key" => row["term_key"],
      "value" => row["value"],
      "timeline_score" => row["timeline_score"],
      "selected" => row["selected"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_score_term" => row["source_score_term"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp objective_tradeoff_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:objective_tradeoff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_objective_tradeoff",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "branch_id" => row["branch_id"],
      "score" => row["score"],
      "score_delta_from_selected" => row["score_delta_from_selected"],
      "activity_count" => row["activity_count"],
      "selected_observation_count" => row["selected_observation_count"],
      "selected_contact_count" => row["selected_contact_count"],
      "score_terms" => row["score_terms"],
      "activity_ids" => row["activity_ids"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_objective_tradeoff" => row["source_objective_tradeoff"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp pareto_frontier_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:pareto_frontier:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_pareto_frontier",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "branch_id" => row["branch_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "frontier" => row["frontier"],
      "objective_keys" => row["objective_keys"],
      "objective_values" => row["objective_values"],
      "dominated_by_ids" => row["dominated_by_ids"],
      "dominates_ids" => row["dominates_ids"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_pareto_frontier" => row["source_pareto_frontier"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp schema_validation_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    issue_count = (row["error_count"] || 0) + (row["warning_count"] || 0)

    %{
      "id" => "cadence_import:schema_validation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_schema_validation",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "schema_validation_gate" => "artifact_contract_validation",
      "schema_validation_gate_status" => row["validation_status"],
      "schema_validation_issue_count" => issue_count,
      "validation_status" => row["validation_status"],
      "validation_mode" => row["validation_mode"],
      "validated_contract" => row["validated_contract"],
      "validated_artifact_family" => row["validated_artifact_family"],
      "artifact_path" => row["artifact_path"],
      "issue_severity" => row["issue_severity"],
      "issue_path" => row["issue_path"],
      "issue_message" => row["issue_message"],
      "error_count" => row["error_count"],
      "warning_count" => row["warning_count"],
      "remediation_count" => row["remediation_count"],
      "remediation_category" => row["remediation_category"],
      "remediation_action" => row["remediation_action"],
      "source_validation_issue" => row["source_validation_issue"],
      "source_validation_remediation" => row["source_validation_remediation"],
      "source_schema_validation_report" => row["source_schema_validation_report"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp execution_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:execution:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_execution",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "scenario_index" => row["scenario_index"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "execution_status" => row["execution_status"],
      "execution_mode" => row["execution_mode"],
      "execution_stage" => row["execution_stage"],
      "execution_error" => row["execution_error"],
      "resumability" => row["resumability"],
      "retry_recommendation" => row["retry_recommendation"],
      "study_id" => row["study_id"],
      "run_id" => row["run_id"],
      "failed_scenario_count" => row["failed_scenario_count"],
      "completed_scenario_count" => row["completed_scenario_count"],
      "scenario_count" => row["scenario_count"],
      "source_execution_failure" => row["source_execution_failure"],
      "source_execution_report" => row["source_execution_report"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp constraint_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:constraint:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_constraint",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "branch_id" => row["branch_id"],
      "constraint_id" => row["constraint_id"],
      "metric" => row["metric"],
      "operator" => row["operator"],
      "threshold" => row["threshold"],
      "value" => row["value"],
      "score" => row["score"],
      "violation_severity" => row["violation_severity"],
      "constraint_status" => row["constraint_status"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_constraint_row" => row["source_constraint_row"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp objective_satisfaction_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:objective_satisfaction:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_objective_satisfaction",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "objective" => row["objective"],
      "objective_status" => row["objective_status"],
      "target_id" => row["target_id"],
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
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_objective_satisfaction" => row["source_objective_satisfaction"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp link_capacity_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:link_capacity:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_link_capacity",
      "import_status" => adapter_import_status("present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "contact_id" => row["contact_id"],
      "input_role" => row["input_role"],
      "ground_station_id" => row["ground_station_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
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
      "actual_data_rate_throughput_derivations" => row["actual_data_rate_throughput_derivations"],
      "actual_completion_fraction" => row["actual_completion_fraction"],
      "actual_completion_contact_count" => row["actual_completion_contact_count"],
      "actual_completion_contact_ids" => row["actual_completion_contact_ids"],
      "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
      "unmatched_actual_throughput_contact_count" =>
        row["unmatched_actual_throughput_contact_count"],
      "unmatched_actual_throughput_contact_ids" => row["unmatched_actual_throughput_contact_ids"],
      "unmatched_actual_completion_contact_count" =>
        row["unmatched_actual_completion_contact_count"],
      "unmatched_actual_completion_contact_ids" => row["unmatched_actual_completion_contact_ids"],
      "ambiguous_actual_throughput_contact_count" =>
        row["ambiguous_actual_throughput_contact_count"],
      "ambiguous_actual_throughput_contact_ids" => row["ambiguous_actual_throughput_contact_ids"],
      "ambiguous_actual_completion_contact_count" =>
        row["ambiguous_actual_completion_contact_count"],
      "ambiguous_actual_completion_contact_ids" => row["ambiguous_actual_completion_contact_ids"],
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
      "contact_ids" => row["contact_ids"],
      "selected_contact_ids" => row["selected_contact_ids"],
      "duplicate_contact_ids" => row["duplicate_contact_ids"],
      "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
      "ambiguous_selected_contact_ids" => row["ambiguous_selected_contact_ids"],
      "ambiguous_selected_contact_id_count" => row["ambiguous_selected_contact_id_count"],
      "unmatched_selected_contact_ids" => row["unmatched_selected_contact_ids"],
      "unmatched_selected_contact_count" => row["unmatched_selected_contact_count"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "invalid_policy_required_downlink_station_count" =>
        row["invalid_policy_required_downlink_station_count"],
      "invalid_policy_required_downlink_station_ids" =>
        row["invalid_policy_required_downlink_station_ids"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_contact_candidate" => row["source_contact_candidate"],
      "source_link_capacity" => row["source_link_capacity"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp operational_timeline_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    has_cadence_import = cadence_import_present?(row, import_status)

    %{
      "id" => "cadence_import:operational_timeline:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_operational_timeline",
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
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
      "pointing_mode" => row["pointing_mode"],
      "pointing_target_id" => row["pointing_target_id"],
      "boresight_axis" => row["boresight_axis"],
      "off_nadir_angle_deg" => row["off_nadir_angle_deg"],
      "slew_angle_deg" => row["slew_angle_deg"],
      "slew_rate_deg_s" => row["slew_rate_deg_s"],
      "pointing_error_deg" => row["pointing_error_deg"],
      "pointing_status" => row["pointing_status"],
      "pointing_model" => row["pointing_model"],
      "pointing_source" => row["pointing_source"],
      "pointing_confidence" => row["pointing_confidence"],
      "attitude_mode" => row["attitude_mode"],
      "attitude_target_id" => row["attitude_target_id"],
      "roll_deg" => row["roll_deg"],
      "pitch_deg" => row["pitch_deg"],
      "yaw_deg" => row["yaw_deg"],
      "attitude_error_deg" => row["attitude_error_deg"],
      "attitude_status" => row["attitude_status"],
      "attitude_model" => row["attitude_model"],
      "attitude_source" => row["attitude_source"],
      "attitude_confidence" => row["attitude_confidence"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "status" => row["status"],
      "approval_status" => approval_status,
      "source_approval_status" => row["source_approval_status"],
      "locked" => row["locked"],
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "operator_action_reason" => row["operator_action_reason"],
      "precondition_status" => row["precondition_status"],
      "blocked_precondition_count" => row["blocked_precondition_count"],
      "review_precondition_count" => row["review_precondition_count"],
      "blocked_precondition_types" => row["blocked_precondition_types"],
      "review_precondition_types" => row["review_precondition_types"],
      "preconditions" => row["preconditions"],
      "execution_boundary" => row["execution_boundary"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["cadence_import_type"],
      "cadence_import_id" => row["cadence_import_id"],
      "cadence_import_contract" => row["cadence_import_contract"],
      "cadence_import_provider" => row["cadence_import_provider"],
      "cadence_import_adapter" => row["cadence_import_adapter"],
      "cadence_import_adapter_version" => row["cadence_import_adapter_version"],
      "cadence_import_trust_boundary" => row["cadence_import_trust_boundary"],
      "cadence_import_provenance" => row["cadence_import_provenance"],
      "invalid_cadence_import" => row["invalid_cadence_import"],
      "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
      "source_cadence_import" => row["source_cadence_import"],
      "execution_uncertainty_status" => row["execution_uncertainty_status"],
      "execution_uncertainty" => row["execution_uncertainty"],
      "timing_3sigma_s" => row["timing_3sigma_s"],
      "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
      "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
      "execution_uncertainty_source" => row["execution_uncertainty_source"],
      "link_protocol" => row["link_protocol"],
      "frequency_band" => row["frequency_band"],
      "modulation" => row["modulation"],
      "coding_scheme" => row["coding_scheme"],
      "polarization" => row["polarization"],
      "data_rate_mbps" => row["data_rate_mbps"],
      "downlink_rate_mbps" => row["downlink_rate_mbps"],
      "data_rate_mb_s" => row["data_rate_mb_s"],
      "downlink_rate_mb_s" => row["downlink_rate_mb_s"],
      "actual_data_rate_mbps" => row["actual_data_rate_mbps"],
      "actual_downlink_rate_mbps" => row["actual_downlink_rate_mbps"],
      "actual_data_rate_mb_s" => row["actual_data_rate_mb_s"],
      "actual_downlink_rate_mb_s" => row["actual_downlink_rate_mb_s"],
      "delivered_rate_mbps" => row["delivered_rate_mbps"],
      "received_rate_mbps" => row["received_rate_mbps"],
      "delivered_rate_mb_s" => row["delivered_rate_mb_s"],
      "received_rate_mb_s" => row["received_rate_mb_s"],
      "actual_duration_s" => row["actual_duration_s"],
      "actual_contact_duration_s" => row["actual_contact_duration_s"],
      "contact_duration_s" => row["contact_duration_s"],
      "link_margin_db" => row["link_margin_db"],
      "snr_db" => row["snr_db"],
      "eb_no_db" => row["eb_no_db"],
      "bit_error_rate" => row["bit_error_rate"],
      "packet_loss_rate" => row["packet_loss_rate"],
      "frame_loss_rate" => row["frame_loss_rate"],
      "carrier_lock" => row["carrier_lock"],
      "symbol_lock" => row["symbol_lock"],
      "link_quality_status" => row["link_quality_status"],
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
      "planned_estimated_throughput_mb" => row["planned_estimated_throughput_mb"],
      "actual_throughput_mb" => row["actual_throughput_mb"],
      "actual_data_rate_throughput_derivation" => row["actual_data_rate_throughput_derivation"],
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
      "payload_available" => row["payload_available"],
      "antenna_available" => row["antenna_available"],
      "degraded" => row["degraded"],
      "mode" => row["mode"],
      "incompatible_activity_types" => row["incompatible_activity_types"],
      "suppressed_activity_types" => row["suppressed_activity_types"],
      "score" => row["score"],
      "score_terms" => row["score_terms"],
      "target_priority" => row["target_priority"],
      "target_priority_source" => row["target_priority_source"],
      "target_priority_objective_ids" => row["target_priority_objective_ids"],
      "target_priority_objective_type" => row["target_priority_objective_type"],
      "image_quality_score" => row["image_quality_score"],
      "image_quality_status" => row["image_quality_status"],
      "image_quality_source" => row["image_quality_source"],
      "cloud_cover_fraction" => row["cloud_cover_fraction"],
      "blur_score" => row["blur_score"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(row["contact_result"]),
      "command_result" => provider_result_artifact_value(row["command_result"]),
      "command_authority_status" => row["command_authority_status"],
      "command_safety_status" => row["command_safety_status"],
      "command_authorized" => row["command_authorized"],
      "command_safety_checked" => row["command_safety_checked"],
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "observation_success" => row["observation_success"],
      "observation_result" => provider_result_artifact_value(row["observation_result"]),
      "observation_success_factor" => row["observation_success_factor"],
      "observation_success_factor_source" => row["observation_success_factor_source"],
      "feedback_weight" => row["feedback_weight"],
      "feedback_weight_source" => row["feedback_weight_source"],
      "maneuver_success" => row["maneuver_success"],
      "maneuver_result" => provider_result_artifact_value(row["maneuver_result"]),
      "maneuver_success_factor" => row["maneuver_success_factor"],
      "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "station_availability" => row["station_availability"],
      "station_contention_status" => row["station_contention_status"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
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
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
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
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
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
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "has_source_window" => row["has_source_window"],
      "has_cadence_import" => has_cadence_import,
      "timeline_identity" => row["timeline_identity"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_operational_timeline" => row["source_operational_timeline"],
      "source_review_row" => row
    }
    |> compact_map()
  end

  defp generic_review_manifest_row(row, rank) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    cadence_import_status = Map.get(row, "cadence_import_status", "present")
    has_cadence_import = cadence_import_present?(row, cadence_import_status)

    %{
      "id" => "cadence_import:#{row["review_type"] || "review"}:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => generic_review_import_action(row["review_type"]),
      "import_status" => adapter_import_status(cadence_import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => cadence_import_status,
      "has_cadence_import" => has_cadence_import,
      "source_review_row" => row,
      "timeline_identity" => row["timeline_identity"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "timeline_link" => row["timeline_link"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(generic_review_activity_context(row))
    }
    |> Map.merge(
      row
      |> Map.take(OrbitalDynamics.CadenceImport.GenericReviewPassthroughFields.fields())
      |> Map.delete("has_cadence_import")
    )
    |> compact_map()
  end

  defp cadence_import_present?(%{"has_cadence_import" => value}, _status)
       when is_boolean(value),
       do: value

  defp cadence_import_present?(_row, "missing"), do: false

  defp cadence_import_present?(row, _status) do
    present_string?(row["cadence_import_id"]) ||
      present_string?(row["cadence_import_type"]) ||
      is_map(row["cadence_import"])
  end

  defp present_string?(value), do: is_binary(value) and value != ""

  defp generic_review_activity_context(row) do
    row["import_activity_context"] ||
      row["activity_context"] ||
      row["source_activity_context"] ||
      row["replacement_activity_context"]
  end

  defp manifest_row(row, rank) do
    import_side = import_side(row)
    import_status = Map.get(row, "#{import_side}_cadence_import_status", "not_applicable")
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => import_action(row),
      "import_status" => adapter_import_status(import_status, approval_status),
      "import_side" => import_side,
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(row),
      "subject_id" => row["subject_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "target_id" => row["target_id"],
      "repair_action" => row["repair_action"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "source_timeline_id" => row["source_timeline_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "replacement_timeline_id" => row["replacement_timeline_id"],
      "timeline_link" => row["timeline_link"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["#{import_side}_cadence_import_type"],
      "cadence_import_id" => row["#{import_side}_cadence_import_id"],
      "cadence_import_contract" => row["#{import_side}_cadence_import_contract"],
      "has_cadence_import" => row["#{import_side}_has_cadence_import"],
      "source_cadence_import_status" => row["source_cadence_import_status"],
      "replacement_cadence_import_status" => row["replacement_cadence_import_status"],
      "invalid_cadence_import" => row["invalid_cadence_import"],
      "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
      "source_cadence_import" => row["source_cadence_import"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(row["#{import_side}_activity_context"]),
      "source_delta" => row["source_delta"]
    }
    |> compact_map()
  end

  defp import_side(%{"replacement_activity_id" => replacement_id} = row)
       when is_binary(replacement_id) and replacement_id != "" do
    if Map.has_key?(row, "replacement_cadence_import_status"), do: "replacement", else: "source"
  end

  defp import_side(_row), do: "source"

  defp adapter_import_status("invalid", _approval_status), do: "review_required_before_import"
  defp adapter_import_status("missing", _approval_status), do: "blocked_missing_cadence_import"
  defp adapter_import_status("not_applicable", _approval_status), do: "not_applicable"

  defp adapter_import_status(_status, approval_status)
       when approval_status in ["operator_review_required", "blocked_by_policy"] do
    "review_required_before_import"
  end

  defp adapter_import_status("present", _approval_status), do: "ready_for_import"
  defp adapter_import_status(_status, _approval_status), do: "review_required_before_import"

  defp import_action(%{"repair_action" => action})
       when action in ["moved", "replaced"] do
    "import_replacement_activity"
  end

  defp import_action(%{"repair_action" => "canceled"}), do: "cancel_source_activity"
  defp import_action(%{"repair_action" => "suppressed"}), do: "suppress_source_activity"

  defp import_action(%{"repair_action" => "preserved_executed"}),
    do: "record_preserved_executed_activity"

  defp import_action(%{"repair_action" => "preserved"}) do
    "record_preserved_activity"
  end

  defp import_action(_row), do: "review_plan_delta"

  defp generic_review_import_action("link_capacity_review"), do: "review_link_capacity"

  defp generic_review_import_action("operational_timeline_review"),
    do: "review_operational_timeline"

  defp generic_review_import_action("contact_allocation_review"), do: "review_contact_allocation"

  defp generic_review_import_action("contact_allocation_capacity_pack_review"),
    do: "review_contact_allocation_capacity_pack"

  defp generic_review_import_action("contact_intent_review"), do: "review_contact_intent"

  defp generic_review_import_action("candidate_rejection_review"),
    do: "review_candidate_rejection"

  defp generic_review_import_action("provider_counteroffer_review"),
    do: "review_provider_counteroffer"

  defp generic_review_import_action("station_reservation_review"),
    do: "review_station_reservation"

  defp generic_review_import_action("candidate_diff_review"), do: "review_candidate_diff"
  defp generic_review_import_action("freshness_review"), do: "review_refresh_freshness"
  defp generic_review_import_action("refresh_budget_review"), do: "review_refresh_budget"
  defp generic_review_import_action("constraint_review"), do: "review_constraint"
  defp generic_review_import_action("score_term_review"), do: "review_score_term"

  defp generic_review_import_action("objective_tradeoff_review"),
    do: "review_objective_tradeoff"

  defp generic_review_import_action("objective_satisfaction_review"),
    do: "review_objective_satisfaction"

  defp generic_review_import_action("resource_projection_review"),
    do: "review_resource_projection"

  defp generic_review_import_action("contact_suppression"), do: "review_contact_suppression"
  defp generic_review_import_action("resource_suppression"), do: "review_resource_suppression"
  defp generic_review_import_action("maneuver_review"), do: "review_maneuver"
  defp generic_review_import_action("timeline_diff_review"), do: "review_timeline_diff"

  defp generic_review_import_action("timeline_dependency_impact_review"),
    do: "review_timeline_dependency_impact"

  defp generic_review_import_action("timeline_publication_review"),
    do: "review_timeline_publication"

  defp generic_review_import_action("timeline_activity_precondition_review"),
    do: "review_timeline_precondition"

  defp generic_review_import_action("timeline_lifecycle_state_review"),
    do: "review_timeline_lifecycle_state"

  defp generic_review_import_action("timeline_preservation_review"),
    do: "review_timeline_preservation"

  defp generic_review_import_action("timeline_integrity_review"),
    do: "review_timeline_integrity"

  defp generic_review_import_action("approval_requirement"), do: "review_approval_requirement"
  defp generic_review_import_action("policy_escalation"), do: "review_policy_escalation"
  defp generic_review_import_action("timeline_protection"), do: "review_timeline_protection"
  defp generic_review_import_action("warning"), do: "review_warning"
  defp generic_review_import_action("risk_explanation"), do: "review_risk"

  defp generic_review_import_action("strategy_recommendation"),
    do: "review_strategy_recommendation"

  defp generic_review_import_action("strategy_tradeoff"), do: "review_strategy_tradeoff"
  defp generic_review_import_action("ranking_comparison_review"), do: "review_ranking_comparison"
  defp generic_review_import_action("pareto_frontier_review"), do: "review_pareto_frontier"
  defp generic_review_import_action("schema_validation_review"), do: "review_schema_validation"

  defp generic_review_import_action("operational_readiness_review"),
    do: "review_operational_readiness"

  defp generic_review_import_action("quality_gate_review"), do: "review_quality_gate"

  defp generic_review_import_action(_review_type), do: "review_operator_row"

  defp review_package_row_source("timeline_feedback_report.v1"),
    do: "operator_review_package.realized_feedback"

  defp review_package_row_source("operational_timeline_report.v1"),
    do: "operator_review_package.operational_timeline_review"

  defp review_package_row_source("contact_contention_report.v1"),
    do: "operator_review_package.contact_contention_review"

  defp review_package_row_source("contact_contention_resolution_report.v1"),
    do: "operator_review_package.contact_contention_recommendation"

  defp review_package_row_source("campaign_plan.v1"),
    do: "operator_review_package.rows"

  defp review_package_row_source("campaign_repair.v2"),
    do: "operator_review_package.rows"

  defp review_package_row_source("command_window_report.v1"),
    do: "operator_review_package.command_window_review"

  defp review_package_row_source("station_calendar_report.v1"),
    do: "operator_review_package.station_calendar_review"

  defp review_package_row_source("station_reservation_report.v1"),
    do: "operator_review_package.station_reservation_review"

  defp review_package_row_source("contact_allocation_report.v1"),
    do: "operator_review_package.contact_allocation_review"

  defp review_package_row_source("resource_projection_report.v1"),
    do: "operator_review_package.resource_projection_review"

  defp review_package_row_source("resource_projection_flow_summary.v1"),
    do: "operator_review_package.resource_projection_review"

  defp review_package_row_source("candidate_rejection_report.v1"),
    do: "operator_review_package.candidate_rejection_review"

  defp review_package_row_source("provider_counteroffer_report.v1"),
    do: "operator_review_package.provider_counteroffer_review"

  defp review_package_row_source("operational_readiness_report.v1"),
    do: "operator_review_package.operational_readiness_review"

  defp review_package_row_source("quality_gate_report.v1"),
    do: "operator_review_package.quality_gate_review"

  defp review_package_row_source(source_artifact_type) when is_binary(source_artifact_type),
    do: "operator_review_package.rows"

  defp review_package_row_source(_source_artifact_type),
    do: "operator_review_package.rows"

  defp schema_validation_report_source_id(report) do
    [
      "schema_validation",
      report["validated_contract"],
      report["validation_mode"],
      report["status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp schema_validation_batch_report_source_id(report) do
    [
      "schema_validation_batch",
      report["validation_mode"],
      report["status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp execution_report_source_id(report) do
    [
      "execution",
      report["study_id"],
      report["run_id"] || report["status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp result_artifact_source_id(artifact) do
    [
      "result_artifact",
      artifact["study_id"],
      get_in(artifact, ["run", "id"]) || get_in(artifact, ["execution_report", "run_id"])
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp manifest_id(source_artifact_id)
       when is_binary(source_artifact_id) and source_artifact_id != "",
       do: "cadence_import_manifest:#{source_artifact_id}"

  defp manifest_id(_source_artifact_id), do: "cadence_import_manifest:unknown_source"

  defp option(opts, key, default \\ nil), do: Keyword.get(opts, key, default)

  defp unsupported_manifest_contract(%{} = artifact) do
    case artifact |> stringify_keys() |> Map.get("schema_contract") do
      contract when is_binary(contract) and contract != "" -> contract
      nil -> "unknown"
      contract when is_atom(contract) -> Atom.to_string(contract)
      contract -> inspect(contract)
    end
  end

  defp supported_manifest_contracts do
    capability()
    |> Map.fetch!(:supported_sources)
    |> Enum.join(", ")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(nil), do: nil
  defp stringify_keys(:null), do: nil
  defp stringify_keys(value), do: value

  defp encode_json_value(%{} = map), do: stringify_keys(map)
  defp encode_json_value(values) when is_list(values), do: Enum.map(values, &encode_json_value/1)

  defp encode_json_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> encode_json_value()

  defp encode_json_value(nil), do: nil
  defp encode_json_value(:null), do: nil
  defp encode_json_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_json_value(value), do: value

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

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil
end
