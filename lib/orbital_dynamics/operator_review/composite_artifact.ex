defmodule OrbitalDynamics.OperatorReview.CompositeArtifact do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.BranchComparison
  alias OrbitalDynamics.OperatorReview.CandidateDiff
  alias OrbitalDynamics.OperatorReview.CandidateRejection
  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.CommandWindow
  alias OrbitalDynamics.OperatorReview.ConstraintObjective
  alias OrbitalDynamics.OperatorReview.ContactAllocation
  alias OrbitalDynamics.OperatorReview.ContactAllocationSummary
  alias OrbitalDynamics.OperatorReview.ContactContention
  alias OrbitalDynamics.OperatorReview.ContactIntent
  alias OrbitalDynamics.OperatorReview.FilterReview
  alias OrbitalDynamics.OperatorReview.LinkCapacity
  alias OrbitalDynamics.OperatorReview.ManeuverReview
  alias OrbitalDynamics.OperatorReview.ModelAcceptance
  alias OrbitalDynamics.OperatorReview.OperationalReadiness
  alias OrbitalDynamics.OperatorReview.OperationalTimeline
  alias OrbitalDynamics.OperatorReview.OptimizationReview
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.PolicyApproval
  alias OrbitalDynamics.OperatorReview.ProviderCounteroffer
  alias OrbitalDynamics.OperatorReview.QualityGate
  alias OrbitalDynamics.OperatorReview.RefreshState
  alias OrbitalDynamics.OperatorReview.RepairReview
  alias OrbitalDynamics.OperatorReview.ResourceProjection
  alias OrbitalDynamics.OperatorReview.RiskReview
  alias OrbitalDynamics.OperatorReview.SchemaValidation
  alias OrbitalDynamics.OperatorReview.StationCalendar
  alias OrbitalDynamics.OperatorReview.StationReservation
  alias OrbitalDynamics.OperatorReview.StrategyBranch
  alias OrbitalDynamics.OperatorReview.StrategyRecommendation
  alias OrbitalDynamics.OperatorReview.Suppression
  alias OrbitalDynamics.OperatorReview.TimelineDiff
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.TimelineIntegrity
  alias OrbitalDynamics.OperatorReview.TimelineLifecycleState
  alias OrbitalDynamics.OperatorReview.TimelinePrecondition
  alias OrbitalDynamics.OperatorReview.TimelinePreservation
  alias OrbitalDynamics.OperatorReview.TimelinePublication
  alias OrbitalDynamics.OperatorReview.TimelineTransitionApplication
  alias OrbitalDynamics.OperatorReview.ValidationSafetyCase
  alias OrbitalDynamics.OperatorReview.WarningReview

  @schema_contract "operator_review_package.v1"

  def campaign_package(artifact) do
    {rows, source_artifact_id, provenance} = campaign_package_input(artifact)

    package(rows, "campaign_plan.v1", source_artifact_id, provenance)
    |> ContactAllocationSummary.put_from_paths(artifact, [
      ["contact_allocation_report"]
    ])
  end

  def candidate_refresh_package(artifact) do
    {rows, source_artifact_id, provenance} = candidate_refresh_package_input(artifact)

    package(rows, "candidate_refresh.v1", source_artifact_id, provenance)
    |> ContactAllocationSummary.put_candidate_refresh(artifact)
  end

  def repair_package(artifact) do
    {rows, source_artifact_id, provenance} = repair_package_input(artifact)

    package(rows, "campaign_repair.v2", source_artifact_id, provenance)
    |> ContactAllocationSummary.put_from_paths(artifact, [
      ["source_contact_allocation_report"],
      ["contact_allocation_report"],
      ["source_contact_allocation_provider_reservation_request_summary"],
      ["contact_allocation_provider_reservation_request_summary"]
    ])
  end

  def strategy_package(artifact) do
    {rows, source_artifact_id, provenance} = strategy_package_input(artifact)

    package(rows, "campaign_strategy.v3", source_artifact_id, provenance)
    |> ContactAllocationSummary.put_strategy(artifact)
  end

  def campaign_package_input(artifact) do
    artifact = stringify_keys(artifact || %{})

    {
      campaign_rows(artifact),
      Map.get(artifact, "plan_id"),
      Map.get(artifact, "provenance", %{})
    }
  end

  def candidate_refresh_package_input(artifact) do
    artifact = stringify_keys(artifact || %{})

    {
      candidate_refresh_rows(artifact),
      Map.get(artifact, "refresh_id"),
      Map.get(artifact, "provenance", %{})
    }
  end

  def repair_package_input(artifact) do
    artifact = stringify_keys(artifact || %{})

    {
      repair_rows(artifact),
      get_in(artifact, ["repair_metadata", "repair_id"]),
      Map.get(artifact, "provenance", %{})
    }
  end

  def strategy_package_input(artifact) do
    artifact = stringify_keys(artifact || %{})

    {
      strategy_rows(artifact),
      get_in(artifact, ["strategy_metadata", "strategy_id"]),
      Map.get(artifact, "provenance", %{})
    }
  end

  def campaign_rows(%{} = artifact) do
    ContactContention.rows(
      get_in(artifact, ["contact_contention_resolution_report", "recommendations"]) || []
    ) ++
      ContactContention.group_rows(
        get_in(artifact, ["contact_contention_report", "conflict_groups"]) || [],
        "campaign_plan.contact_contention_report.conflict_groups"
      ) ++
      OperationalTimeline.rows(get_in(artifact, ["operational_timeline_report", "rows"]) || []) ++
      TimelineIntegrity.source_report_rows(
        Map.get(artifact, "timeline_integrity_report"),
        "campaign_plan.timeline_integrity_report"
      ) ++
      TimelinePrecondition.source_summary_rows(
        Map.get(artifact, "timeline_activity_precondition_summaries"),
        "campaign_plan.timeline_activity_precondition_summaries"
      ) ++
      CommandWindow.rows(get_in(artifact, ["command_window_report", "rows"]) || []) ++
      ContactAllocation.rows(
        get_in(artifact, ["contact_allocation_report", "rows"]) || [],
        "campaign_plan.contact_allocation_report.rows"
      ) ++
      ContactAllocation.capacity_pack_rows(
        get_in(artifact, ["contact_allocation_report", "reduced_capacity_pack_groups"]) || [],
        "campaign_plan.contact_allocation_report.reduced_capacity_pack_groups"
      ) ++
      ContactIntent.rows(
        Map.get(artifact, "contact_intents", []),
        "campaign_plan.contact_intents"
      ) ++
      StationCalendar.rows(
        get_in(artifact, ["station_calendar_report", "affected_contacts"]) || [],
        "campaign_plan.station_calendar_report.affected_contacts"
      ) ++
      LinkCapacity.report_rows(
        Map.get(artifact, "link_capacity_report"),
        "campaign_plan.link_capacity_report"
      ) ++
      ResourceProjection.rows(
        ResourceProjection.projected_resource_rows(
          Map.get(artifact, "resource_projection_report")
        ),
        "campaign_plan.resource_projection_report.projected_resources"
      ) ++
      ResourceProjection.flow_summary_rows(
        Map.get(artifact, "resource_projection_flow_summary") || %{},
        "campaign_plan.resource_projection_flow_summary.projected_resources"
      ) ++
      ConstraintObjective.objective_satisfaction_rows(
        get_in(artifact, ["objective_satisfaction_report", "rows"]) || [],
        "campaign_plan.objective_satisfaction_report.rows"
      ) ++
      OptimizationReview.score_term_rows(
        get_in(artifact, ["score_term_report", "rows"]) || [],
        "campaign_plan.score_term_report.rows"
      ) ++
      OptimizationReview.objective_tradeoff_rows(
        get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
        "campaign_plan.objective_tradeoff_report.tradeoffs"
      ) ++
      ConstraintObjective.constraint_rows(
        get_in(artifact, ["constraint_report", "rows"]) || [],
        "campaign_plan.constraint_report.rows"
      ) ++
      Suppression.contact_rows(
        contact_suppressed_candidates(artifact, "contact_filter_report"),
        "campaign_plan.contact_filter_report.suppressed_candidates"
      ) ++
      Suppression.resource_rows(resource_suppressed_candidates(artifact)) ++
      WarningReview.rows(Map.get(artifact, "warnings", []), "campaign_plan.warnings")
  end

  def candidate_refresh_rows(%{} = artifact) do
    run_input_sources = candidate_refresh_run_input_sources(artifact)

    (ContactIntent.rows(
       Map.get(artifact, "contact_intents", []),
       "candidate_refresh.contact_intents"
     ) ++
       ContactIntent.candidate_refresh_rows(artifact) ++
       ContactAllocation.candidate_refresh_rows(artifact) ++
       LinkCapacity.candidate_refresh_rows(artifact) ++
       ContactContention.candidate_refresh_rows(artifact) ++
       ContactContention.candidate_refresh_resolution_rows(artifact) ++
       CandidateDiff.candidate_refresh_rows(artifact) ++
       CommandWindow.candidate_refresh_rows(artifact) ++
       ManeuverReview.candidate_refresh_rows(artifact) ++
       TimelineDiff.candidate_refresh_rows(artifact) ++
       TimelineIntegrity.candidate_refresh_rows(artifact) ++
       TimelinePublication.candidate_refresh_dependency_impact_rows(artifact) ++
       TimelinePublication.candidate_refresh_publication_rows(artifact) ++
       TimelinePrecondition.candidate_refresh_rows(artifact) ++
       TimelineLifecycleState.candidate_refresh_summary_rows(artifact) ++
       TimelineLifecycleState.candidate_refresh_activity_state_rows(artifact) ++
       TimelineLifecycleState.candidate_refresh_activity_lifecycle_state_rows(artifact) ++
       TimelinePreservation.candidate_refresh_rows(artifact) ++
       TimelineTransitionApplication.candidate_refresh_rows(artifact) ++
       ConstraintObjective.candidate_refresh_rows(artifact) ++
       OptimizationReview.candidate_refresh_rows(artifact) ++
       CandidateRejection.candidate_refresh_rows(artifact) ++
       RefreshState.candidate_refresh_rows(artifact) ++
       ModelAcceptance.candidate_refresh_rows(artifact) ++
       ValidationSafetyCase.candidate_refresh_rows(artifact) ++
       SchemaValidation.candidate_refresh_rows(artifact) ++
       QualityGate.candidate_refresh_rows(artifact) ++
       TimelineFeedback.candidate_refresh_rows(artifact) ++
       OperationalTimeline.candidate_refresh_rows(artifact) ++
       OperationalReadiness.candidate_refresh_rows(artifact) ++
       FilterReview.candidate_refresh_rows(artifact) ++
       ResourceProjection.candidate_refresh_rows(artifact) ++
       ProviderCounteroffer.candidate_refresh_rows(artifact) ++
       StationCalendar.candidate_refresh_rows(artifact) ++
       StationReservation.candidate_refresh_rows(artifact) ++
       WarningReview.candidate_refresh_rows(artifact))
    |> put_candidate_refresh_run_input_sources(run_input_sources)
  end

  def repair_rows(%{} = artifact) do
    PolicyApproval.approval_rows(
      Map.get(artifact, "approval_requirements", []),
      "campaign_repair.approval_requirements"
    ) ++
      PolicyApproval.policy_escalation_rows(
        Map.get(artifact, "policy_decision"),
        "campaign_repair.policy_decision"
      ) ++
      TimelineFeedback.repair_rows(
        artifact,
        "campaign_repair.source_timeline_feedback_report.rows"
      ) ++
      OperationalTimeline.rows(get_in(artifact, ["operational_timeline_report", "rows"]) || []) ++
      TimelineTransitionApplication.rows(
        get_in(artifact, ["timeline_transition_application_report", "applications"]) || [],
        "campaign_repair.timeline_transition_application_report.applications",
        Map.get(artifact, "approval_policy")
      ) ++
      CommandWindow.rows(get_in(artifact, ["command_window_report", "rows"]) || []) ++
      RepairReview.plan_delta_rows(Map.get(artifact, "deltas", []), "campaign_repair.deltas") ++
      OptimizationReview.score_term_rows(
        get_in(artifact, ["score_term_report", "rows"]) || [],
        "campaign_repair.score_term_report.rows"
      ) ++
      OptimizationReview.objective_tradeoff_rows(
        get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
        "campaign_repair.objective_tradeoff_report.tradeoffs"
      ) ++
      CandidateDiff.report_rows(
        Map.get(artifact, "source_candidate_diff_report"),
        "campaign_repair.source_candidate_diff_report"
      ) ++
      CandidateRejection.source_report_rows(
        Map.get(artifact, "source_candidate_rejection_report"),
        "campaign_repair.source_candidate_rejection_report"
      ) ++
      ConstraintObjective.constraint_rows(
        get_in(artifact, ["constraint_report", "rows"]) || [],
        "campaign_repair.constraint_report.rows"
      ) ++
      ConstraintObjective.constraint_rows(
        get_in(artifact, ["source_constraint_report", "rows"]) || [],
        "campaign_repair.source_constraint_report.rows"
      ) ++
      ConstraintObjective.objective_satisfaction_rows(
        get_in(artifact, ["source_objective_satisfaction_report", "rows"]) || [],
        "campaign_repair.source_objective_satisfaction_report.rows"
      ) ++
      OptimizationReview.objective_tradeoff_rows(
        get_in(artifact, ["source_objective_tradeoff_report", "tradeoffs"]) || [],
        "campaign_repair.source_objective_tradeoff_report.tradeoffs"
      ) ++
      OptimizationReview.score_term_rows(
        get_in(artifact, ["source_score_term_report", "rows"]) || [],
        "campaign_repair.source_score_term_report.rows"
      ) ++
      TimelineDiff.rows(
        get_in(artifact, ["source_timeline_diff_report", "rows"]) || [],
        "campaign_repair.source_timeline_diff_report.rows"
      ) ++
      SchemaValidation.rows(
        Map.get(artifact, "source_schema_validation_report") || %{},
        "campaign_repair.source_schema_validation_report"
      ) ++
      ModelAcceptance.rows(
        Map.get(artifact, "source_model_acceptance_report") || %{},
        "campaign_repair.source_model_acceptance_report.rows"
      ) ++
      ValidationSafetyCase.rows(
        Map.get(artifact, "source_validation_safety_case_summary") || %{},
        "campaign_repair.source_validation_safety_case_summary.evidence"
      ) ++
      ProviderCounteroffer.rows(
        get_in(artifact, ["source_provider_counteroffer_report", "rows"]) || [],
        "campaign_repair.source_provider_counteroffer_report.rows"
      ) ++
      LinkCapacity.report_rows(
        Map.get(artifact, "link_capacity_report"),
        "campaign_repair.link_capacity_report"
      ) ++
      LinkCapacity.report_rows(
        Map.get(artifact, "source_link_capacity_report"),
        "campaign_repair.source_link_capacity_report"
      ) ++
      StationReservation.report_rows(
        Map.get(artifact, "source_station_reservation_report") || %{},
        "campaign_repair.source_station_reservation_report"
      ) ++
      StationCalendar.rows(
        get_in(artifact, ["source_station_calendar_report", "affected_contacts"]) || [],
        "campaign_repair.source_station_calendar_report.affected_contacts"
      ) ++
      RepairReview.timeline_protection_rows(
        get_in(artifact, ["repair_metadata", "timeline_protection"]),
        "campaign_repair.repair_metadata.timeline_protection"
      ) ++
      Suppression.contact_rows(
        contact_suppressed_candidates(artifact, "source_contact_filter_report"),
        "campaign_repair.source_contact_filter_report.suppressed_candidates"
      ) ++
      ContactAllocation.rows(
        get_in(artifact, ["source_contact_allocation_report", "rows"]) || [],
        "campaign_repair.source_contact_allocation_report.rows"
      ) ++
      ContactAllocation.capacity_pack_rows(
        get_in(artifact, [
          "source_contact_allocation_report",
          "reduced_capacity_pack_groups"
        ]) || [],
        "campaign_repair.source_contact_allocation_report.reduced_capacity_pack_groups"
      ) ++
      ContactContention.invalid_input_rows(
        get_in(artifact, ["source_contact_contention_report", "invalid_contact_inputs"]) || [],
        "campaign_repair.source_contact_contention_report.invalid_contact_inputs"
      ) ++
      ContactContention.group_rows(
        get_in(artifact, ["source_contact_contention_report", "conflict_groups"]) || [],
        "campaign_repair.source_contact_contention_report.conflict_groups"
      ) ++
      ContactContention.rows(
        get_in(artifact, [
          "source_contact_contention_resolution_report",
          "recommendations"
        ]) || [],
        "campaign_repair.source_contact_contention_resolution_report.recommendations"
      ) ++
      ContactAllocation.rows(
        get_in(artifact, ["contact_allocation_report", "rows"]) || [],
        "campaign_repair.contact_allocation_report.rows"
      ) ++
      ContactAllocation.capacity_pack_rows(
        get_in(artifact, ["contact_allocation_report", "reduced_capacity_pack_groups"]) || [],
        "campaign_repair.contact_allocation_report.reduced_capacity_pack_groups"
      ) ++
      ContactIntent.rows(
        Map.get(artifact, "source_contact_intents", []),
        "campaign_repair.source_contact_intents"
      ) ++
      Suppression.resource_rows(
        resource_suppressed_candidates(artifact, "source_resource_filter_report"),
        "campaign_repair.source_resource_filter_report.suppressed_candidates"
      ) ++
      ResourceProjection.rows(
        ResourceProjection.projected_resource_rows(
          Map.get(artifact, "source_resource_projection_report")
        ),
        "campaign_repair.source_resource_projection_report.projected_resources"
      ) ++
      RefreshState.freshness_rows(
        Map.get(artifact, "source_freshness_report"),
        "campaign_repair.source_freshness_report"
      ) ++
      OperationalReadiness.source_report_rows(
        Map.get(artifact, "source_operational_readiness_report"),
        "campaign_repair.source_operational_readiness_report"
      ) ++
      QualityGate.source_report_rows(
        Map.get(artifact, "source_quality_gate_report"),
        "campaign_repair.source_quality_gate_report"
      ) ++
      RefreshState.refresh_budget_rows(
        Map.get(artifact, "source_refresh_budget_report"),
        "campaign_repair.source_refresh_budget_report"
      ) ++
      WarningReview.rows(Map.get(artifact, "warnings", []), "campaign_repair.warnings")
  end

  def strategy_rows(%{} = artifact) do
    recommendation = Map.get(artifact, "recommendation", %{})

    StrategyRecommendation.rows(
      recommendation,
      Map.get(artifact, "operational_feedback_provenance")
    ) ++
      BranchComparison.rows(
        get_in(artifact, ["branch_comparison_report", "rows"]) || [],
        "campaign_strategy.branch_comparison_report.rows"
      ) ++
      OptimizationReview.ranking_comparison_rows(
        get_in(artifact, ["ranking_comparison_report", "rows"]) || [],
        "campaign_strategy.ranking_comparison_report.rows"
      ) ++
      OptimizationReview.pareto_frontier_rows(
        get_in(artifact, ["pareto_frontier_report", "rows"]) || [],
        "campaign_strategy.pareto_frontier_report.rows"
      ) ++
      OptimizationReview.score_term_rows(
        get_in(artifact, ["score_term_report", "rows"]) || [],
        "campaign_strategy.score_term_report.rows"
      ) ++
      OptimizationReview.objective_tradeoff_rows(
        get_in(artifact, ["objective_tradeoff_report", "tradeoffs"]) || [],
        "campaign_strategy.objective_tradeoff_report.tradeoffs"
      ) ++
      PolicyApproval.approval_rows(
        Map.get(recommendation, "requires_approval", []),
        "campaign_strategy.recommendation.requires_approval"
      ) ++
      PolicyApproval.policy_escalation_rows(
        Map.get(artifact, "policy_decision"),
        "campaign_strategy.policy_decision"
      ) ++
      RiskReview.rows(
        Map.get(recommendation, "risks_remaining", []),
        "campaign_strategy.recommendation.risks_remaining"
      ) ++
      StrategyBranch.rows(Map.get(artifact, "branches", []))
  end

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

  defp package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
