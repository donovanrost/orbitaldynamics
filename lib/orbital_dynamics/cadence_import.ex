defmodule OrbitalDynamics.CadenceImport do
  @moduledoc """
  Builds artifact-only Cadence import manifests.

  The manifest is an adapter boundary: it names the repaired timeline changes
  that are ready, blocked, or still waiting on review before a downstream
  Cadence-side importer decides what to schedule. This module does not call
  Cadence APIs or mutate schedules.
  """

  alias OrbitalDynamics.CadenceImport.{
    GenericReviewActionPolicy,
    ProviderResultNormalization,
    ReviewPackageRowSourcePolicy,
    SourceIdentifierPolicy
  }

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
      provider_result_map_value_keys: ProviderResultNormalization.map_value_keys(),
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
    OrbitalDynamics.CadenceImport.ProposedContactManifestRow.build(
      contact,
      rank,
      encode_json_value: &encode_json_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp strategy_manifest_row(row, recommendation, rank, operational_feedback_context) do
    OrbitalDynamics.CadenceImport.StrategyManifestRow.build(
      row,
      recommendation,
      rank,
      operational_feedback_context,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      stringify_keys: &stringify_keys/1,
      compact_map: &compact_map/1
    )
  end

  defp operational_feedback_manifest_context(provenance) do
    OrbitalDynamics.CadenceImport.OperationalFeedbackManifestContext.build(
      provenance,
      stringify_keys: &stringify_keys/1,
      encode_json_value: &encode_json_value/1,
      compact_map: &compact_map/1
    )
  end

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
    OrbitalDynamics.CadenceImport.RealizedFeedbackManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp contact_contention_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactContentionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      station_calendar_context_fields: &station_calendar_context_fields/0,
      compact_map: &compact_map/1
    )
  end

  defp contact_allocation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactAllocationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
  end

  defp contact_intent_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactIntentManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      first_approval_requirement: &first_approval_requirement/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      stringify_keys: &stringify_keys/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      non_empty_map: &non_empty_map/1,
      compact_map: &compact_map/1
    )
  end

  defp candidate_diff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.CandidateDiffManifestRow.build(
      row,
      rank,
      candidate_diff_changed_fields: &candidate_diff_changed_fields/1,
      candidate_diff_changed_field_count: &candidate_diff_changed_field_count/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp suppression_manifest_row(row, rank, suppression_type) do
    OrbitalDynamics.CadenceImport.SuppressionManifestRow.build(
      row,
      rank,
      suppression_type,
      first_approval_requirement: &first_approval_requirement/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      stringify_keys: &stringify_keys/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      non_empty_map: &non_empty_map/1,
      compact_map: &compact_map/1
    )
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
    OrbitalDynamics.CadenceImport.FreshnessManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp refresh_budget_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RefreshBudgetManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp operational_readiness_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.OperationalReadinessManifestRow.build(
      row,
      rank,
      generic_review_import_action: &generic_review_import_action/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      operational_readiness_resource_context: &operational_readiness_resource_context/1,
      operational_readiness_adapter_boundary_context:
        &operational_readiness_adapter_boundary_context/1,
      operational_readiness_operator_training_context:
        &operational_readiness_operator_training_context/1,
      operational_readiness_cadence_import_context:
        &operational_readiness_cadence_import_context/1,
      compact_map: &compact_map/1
    )
  end

  defp quality_gate_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.QualityGateManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      operational_readiness_cadence_import_context:
        &operational_readiness_cadence_import_context/1,
      operational_readiness_resource_context: &operational_readiness_resource_context/1,
      compact_map: &compact_map/1
    )
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
    OrbitalDynamics.CadenceImport.ApprovalRequirementManifestRow.build(
      row,
      rank,
      stringify_keys: &stringify_keys/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      non_empty_map: &non_empty_map/1,
      candidate_diff_changed_fields: &candidate_diff_changed_fields/1,
      candidate_diff_changed_field_count: &candidate_diff_changed_field_count/1,
      compact_map: &compact_map/1
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

  defp semantic_change_detail_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
  end

  defp candidate_diff_changed_field_count([]), do: nil
  defp candidate_diff_changed_field_count(fields), do: length(fields)

  defp maneuver_review_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ManeuverReviewManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp timeline_diff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.TimelineDiffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp timeline_protection_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.TimelineProtectionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp command_window_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.CommandWindowManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp station_calendar_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.StationCalendarManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
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
    OrbitalDynamics.CadenceImport.PolicyEscalationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp resource_projection_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ResourceProjectionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp warning_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.WarningManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp risk_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RiskManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp strategy_recommendation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.StrategyRecommendationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      compact_map: &compact_map/1
    )
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
    OrbitalDynamics.CadenceImport.StrategyTradeoffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      compact_map: &compact_map/1
    )
  end

  defp ranking_comparison_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RankingComparisonManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp score_term_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ScoreTermManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp objective_tradeoff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ObjectiveTradeoffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp pareto_frontier_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ParetoFrontierManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp schema_validation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.SchemaValidationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp execution_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ExecutionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp constraint_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ConstraintManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp objective_satisfaction_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ObjectiveSatisfactionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp link_capacity_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.LinkCapacityManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
  end

  defp operational_timeline_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.OperationalTimelineManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp generic_review_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.GenericReviewManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      generic_review_import_action: &generic_review_import_action/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
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
    OrbitalDynamics.CadenceImport.PlanDeltaManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp adapter_import_status("invalid", _approval_status), do: "review_required_before_import"
  defp adapter_import_status("missing", _approval_status), do: "blocked_missing_cadence_import"
  defp adapter_import_status("not_applicable", _approval_status), do: "not_applicable"

  defp adapter_import_status(_status, approval_status)
       when approval_status in ["operator_review_required", "blocked_by_policy"] do
    "review_required_before_import"
  end

  defp adapter_import_status("present", _approval_status), do: "ready_for_import"
  defp adapter_import_status(_status, _approval_status), do: "review_required_before_import"

  defp generic_review_import_action(review_type),
    do: GenericReviewActionPolicy.resolve(review_type)

  defp review_package_row_source(source_artifact_type),
    do: ReviewPackageRowSourcePolicy.resolve(source_artifact_type)

  defp schema_validation_report_source_id(report),
    do: SourceIdentifierPolicy.schema_validation_report(report)

  defp schema_validation_batch_report_source_id(report),
    do: SourceIdentifierPolicy.schema_validation_batch_report(report)

  defp execution_report_source_id(report),
    do: SourceIdentifierPolicy.execution_report(report)

  defp result_artifact_source_id(artifact),
    do: SourceIdentifierPolicy.result_artifact(artifact)

  defp manifest_id(source_artifact_id),
    do: SourceIdentifierPolicy.manifest(source_artifact_id)

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

  defp normalize_provider_result_artifact_fields(value),
    do: ProviderResultNormalization.normalize_artifact_fields(value)

  defp provider_result_artifact_value(value),
    do: ProviderResultNormalization.artifact_value(value)

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
