defmodule OrbitalDynamics.CadenceImport do
  @moduledoc """
  Builds artifact-only Cadence import manifests.

  The manifest is an adapter boundary: it names the repaired timeline changes
  that are ready, blocked, or still waiting on review before a downstream
  Cadence-side importer decides what to schedule. This module does not call
  Cadence APIs or mutate schedules.
  """

  alias OrbitalDynamics.CadenceImport.{
    ApprovalContextPolicy,
    BranchEvidenceFields,
    CandidateDiffFields,
    GenericReviewActionPolicy,
    ImportReadinessPolicy,
    JsonNormalization,
    ManifestContractDiagnostics,
    ManifestBuilder,
    ManifestMapNormalization,
    OperationalReadinessContext,
    ProviderResultNormalization,
    ReviewPackageImport,
    ReviewRowMetadata,
    ReviewRowDispatch,
    ReviewSummaryContext,
    SourceIdentifierPolicy,
    StationCalendarContextFields,
    StrategyDecisionImport,
    StrategyReview,
    TimelineReviewImport,
    ValidationReadinessImport
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
    TimelineReviewImport.from_timeline_diff_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline diff summary.
  """
  def from_timeline_diff_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_diff_summary(summary, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a timeline dependency-impact summary.
  """
  def from_timeline_dependency_impact_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_dependency_impact_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline publication summary.
  """
  def from_timeline_publication_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_publication_summary(summary, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a timeline activity precondition summary.
  """
  def from_timeline_activity_precondition_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_precondition_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline lifecycle-state summary.
  """
  def from_timeline_lifecycle_state_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_lifecycle_state_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a compact activity-state artifact.
  """
  def from_timeline_activity_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity status-state artifact.
  """
  def from_timeline_activity_status_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_status_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity approval-state artifact.
  """
  def from_timeline_activity_approval_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_approval_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity lifecycle-state artifact.
  """
  def from_timeline_activity_lifecycle_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_lifecycle_state(
      state,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline preservation report.
  """
  def from_timeline_preservation_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_preservation_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single timeline preservation status artifact.
  """
  def from_timeline_preservation_status(%{} = status, opts \\ []) do
    TimelineReviewImport.from_timeline_preservation_status(status, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline integrity report.
  """
  def from_timeline_integrity_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_integrity_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline transition-application summary.
  """
  def from_timeline_transition_application_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_transition_application_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline transition application report.
  """
  def from_timeline_transition_application_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_transition_application_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone approval requirement.
  """
  def from_approval_requirement(%{} = requirement, opts \\ []) do
    StrategyDecisionImport.from_approval_requirement(requirement, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a policy-decision artifact.
  """
  def from_policy_decision(%{} = decision, opts \\ []) do
    StrategyDecisionImport.from_policy_decision(decision, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a branch-comparison report.
  """
  def from_branch_comparison_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_branch_comparison_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a ranking-comparison report.
  """
  def from_ranking_comparison_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_ranking_comparison_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a score-term report.
  """
  def from_score_term_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_score_term_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an objective-tradeoff report.
  """
  def from_objective_tradeoff_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_objective_tradeoff_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a Pareto-frontier report.
  """
  def from_pareto_frontier_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_pareto_frontier_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a schema-validation report.
  """
  def from_schema_validation_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_schema_validation_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a schema-validation batch report.
  """
  def from_schema_validation_batch_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_schema_validation_batch_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from an execution report.
  """
  def from_execution_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_execution_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an operational-readiness report.
  """
  def from_operational_readiness_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_operational_readiness_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a quality-gate report.
  """
  def from_quality_gate_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_quality_gate_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an operator-review package.
  """
  def from_operator_review_package(%{} = package, opts \\ []) do
    ReviewPackageImport.build(
      package,
      opts,
      &review_manifest_row/2,
      schema_contract: @schema_contract,
      schema_version: @schema_version,
      accepted_statuses: @cadence_import_statuses,
      capability: capability()
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

  defp build_manifest(rows, provenance, context) do
    ManifestBuilder.build(rows, provenance, context,
      schema_contract: @schema_contract,
      schema_version: @schema_version,
      accepted_statuses: @cadence_import_statuses,
      capability: capability()
    )
  end

  defp review_summary_context(package), do: ReviewSummaryContext.build(package)

  defp source_review_action(row), do: ReviewRowMetadata.action(row)

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
    StrategyReview.manifest_rows(review_package, starting_rank, &review_manifest_row/2)
  end

  defp strategy_review_package(artifact), do: StrategyReview.package(artifact)

  defp strategy_review_count(review_package), do: StrategyReview.count(review_package)

  defp review_manifest_row(row, rank) do
    ReviewRowDispatch.dispatch(row, rank, %{
      approval_requirement: &approval_requirement_manifest_row/2,
      candidate_diff: &candidate_diff_manifest_row/2,
      command_window: &command_window_manifest_row/2,
      constraint: &constraint_manifest_row/2,
      contact_allocation: &contact_allocation_manifest_row/2,
      contact_contention: &contact_contention_manifest_row/2,
      contact_intent: &contact_intent_manifest_row/2,
      contact_suppression: &suppression_manifest_row(&1, &2, "contact"),
      execution: &execution_manifest_row/2,
      freshness: &freshness_manifest_row/2,
      generic: &generic_review_manifest_row/2,
      link_capacity: &link_capacity_manifest_row/2,
      maneuver_review: &maneuver_review_manifest_row/2,
      objective_satisfaction: &objective_satisfaction_manifest_row/2,
      objective_tradeoff: &objective_tradeoff_manifest_row/2,
      operational_readiness: &operational_readiness_manifest_row/2,
      operational_timeline: &operational_timeline_manifest_row/2,
      pareto_frontier: &pareto_frontier_manifest_row/2,
      plan_delta: &manifest_row/2,
      policy_escalation: &policy_escalation_manifest_row/2,
      quality_gate: &quality_gate_manifest_row/2,
      ranking_comparison: &ranking_comparison_manifest_row/2,
      realized_feedback: &realized_feedback_manifest_row/2,
      refresh_budget: &refresh_budget_manifest_row/2,
      resource_projection: &resource_projection_manifest_row/2,
      resource_suppression: &suppression_manifest_row(&1, &2, "resource"),
      risk: &risk_manifest_row/2,
      schema_validation: &schema_validation_manifest_row/2,
      score_term: &score_term_manifest_row/2,
      station_calendar: &station_calendar_manifest_row/2,
      station_reservation: &station_reservation_manifest_row/2,
      strategy_recommendation: &strategy_recommendation_manifest_row/2,
      strategy_tradeoff: &strategy_tradeoff_manifest_row/2,
      timeline_diff: &timeline_diff_manifest_row/2,
      timeline_protection: &timeline_protection_manifest_row/2,
      warning: &warning_manifest_row/2
    })
  end

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

  defp first_approval_requirement(row),
    do: ApprovalContextPolicy.first_requirement(row)

  defp first_approval_rule_match(row),
    do: ApprovalContextPolicy.first_rule_match(row)

  defp preferred_approval_escalation(escalations, row, source_requirement),
    do: ApprovalContextPolicy.preferred_escalation(escalations, row, source_requirement)

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

  defp operational_readiness_adapter_boundary_context(row),
    do: OperationalReadinessContext.adapter_boundary(row)

  defp operational_readiness_resource_context(row),
    do: OperationalReadinessContext.resource(row)

  defp operational_readiness_operator_training_context(row),
    do: OperationalReadinessContext.operator_training(row)

  defp operational_readiness_cadence_import_context(row),
    do: OperationalReadinessContext.cadence_import(row)

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

  defp candidate_diff_changed_fields(row),
    do: CandidateDiffFields.derive(row)

  defp candidate_diff_changed_field_count(fields),
    do: CandidateDiffFields.count(fields)

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

  defp branch_contact_allocation_fields,
    do: BranchEvidenceFields.contact_allocation()

  defp branch_readiness_quality_gate_fields,
    do: BranchEvidenceFields.readiness_quality_gate()

  defp branch_timeline_evidence_fields,
    do: BranchEvidenceFields.timeline()

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

  defp cadence_import_present?(row, status),
    do: ImportReadinessPolicy.cadence_import_present?(row, status)

  defp generic_review_activity_context(row),
    do: ReviewRowMetadata.activity_context(row)

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

  defp adapter_import_status(status, approval_status),
    do: ImportReadinessPolicy.adapter_import_status(status, approval_status)

  defp generic_review_import_action(review_type),
    do: GenericReviewActionPolicy.resolve(review_type)

  defp result_artifact_source_id(artifact),
    do: SourceIdentifierPolicy.result_artifact(artifact)

  defp option(opts, key, default), do: Keyword.get(opts, key, default)

  defp unsupported_manifest_contract(artifact),
    do: ManifestContractDiagnostics.unsupported_contract(artifact)

  defp supported_manifest_contracts,
    do: capability() |> ManifestContractDiagnostics.supported_contracts()

  defp stringify_keys(value), do: JsonNormalization.stringify_keys(value)

  defp encode_json_value(value), do: JsonNormalization.encode_json_value(value)

  defp normalize_provider_result_artifact_fields(value),
    do: ProviderResultNormalization.normalize_artifact_fields(value)

  defp provider_result_artifact_value(value),
    do: ProviderResultNormalization.artifact_value(value)

  defp station_calendar_context_fields,
    do: StationCalendarContextFields.all()

  defp compact_map(map), do: ManifestMapNormalization.compact(map)

  defp non_empty_map(map), do: ManifestMapNormalization.non_empty(map)
end
