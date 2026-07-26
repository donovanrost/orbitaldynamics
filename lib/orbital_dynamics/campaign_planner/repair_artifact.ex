defmodule OrbitalDynamics.CampaignPlanner.RepairArtifact do
  @moduledoc false

  alias OrbitalDynamics.Communications.CommandWindow

  alias OrbitalDynamics.CampaignPlanner.{
    RepairCandidateDiff,
    RepairCandidateInputs,
    RepairMetadata,
    RepairPolicySemantics,
    RepairSourceReports,
    RepairTimelineSummary,
    StrategyPolicyNormalization
  }

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Timeline}

  @schema_version 2

  def build(request, attrs) when is_map(request) and is_map(attrs) do
    prior_plan = Map.fetch!(attrs, :prior_plan)
    activities = Map.fetch!(attrs, :activities)
    candidates = Map.fetch!(attrs, :candidates)
    deltas = Map.fetch!(attrs, :deltas)
    approval_requirements = Map.fetch!(attrs, :approval_requirements)

    timeline_transition_application_report =
      Map.fetch!(attrs, :timeline_transition_application_report)

    %{
      "schema_version" => @schema_version,
      "generated_at" => DateTime.to_iso8601(request.generated_at),
      "planner" => "OrbitalDynamics.CampaignPlanner.V2",
      "source_plan_id" => RepairMetadata.source_plan_id(prior_plan),
      "source_planner" => Map.get(prior_plan, "planner"),
      "study_id" => Map.get(prior_plan, "study_id"),
      "current_epoch_s" => request.current_epoch_s,
      "remaining_horizon" => request.remaining_horizon,
      "activities" => activities,
      "operational_timeline_report" =>
        Timeline.operational_report(activities,
          source: "campaign_repair.activities",
          source_assumption: "repaired campaign_repair.activities"
        ),
      "timeline_transition_application_report" => timeline_transition_application_report,
      "command_window_report" =>
        CommandWindow.report(activities,
          source: "campaign_repair.activities",
          source_assumption: "repaired campaign_repair.activities",
          approval_policy: request.approval_policy
        ),
      "source_candidate_activities" => candidates,
      "source_contact_intents" =>
        RepairCandidateInputs.contact_intents(request.candidate_refresh),
      "source_resource_summaries" => Map.fetch!(attrs, :source_resource_summaries),
      "preserved_activities" => RepairTimelineSummary.preserved_activities(activities),
      "deltas" => Enum.map(deltas, &RepairTimelineSummary.delta_to_map/1),
      "change_summary" => RepairTimelineSummary.change_summary(deltas),
      "approval_requirements" => approval_requirements,
      "approval_status" => Map.fetch!(attrs, :approval_status),
      "approval_policy" => StrategyPolicyNormalization.approval_to_map(request.approval_policy),
      "approval_rule_matches" => Map.fetch!(attrs, :approval_rule_matches),
      "policy_decision" => Map.fetch!(attrs, :policy_decision),
      "warnings" => Map.fetch!(attrs, :warnings),
      "realized_state_snapshot" => request.realized_state,
      "repair_policy" => RepairPolicySemantics.to_map(request.repair_policy),
      "scoring_policy" => request.scoring_policy,
      "score" => Map.fetch!(attrs, :score),
      "score_terms" => Map.fetch!(attrs, :score_terms),
      "score_term_report" => Map.fetch!(attrs, :score_term_report),
      "objective_tradeoff_report" => Map.fetch!(attrs, :objective_tradeoff_report),
      "constraint_report" => Map.fetch!(attrs, :constraint_report),
      "link_capacity_report" => Map.fetch!(attrs, :link_capacity_report),
      "contact_allocation_report" => Map.fetch!(attrs, :contact_allocation_report),
      "assumptions" => RepairMetadata.assumptions(prior_plan, request),
      "provenance" => RepairMetadata.provenance(prior_plan, request.candidate_source),
      "repair_metadata" => %{
        "repair_id" =>
          RepairMetadata.id(
            prior_plan,
            request.realized_state,
            request.current_epoch_s,
            request.candidate_source
          ),
        "source_plan_id" => RepairMetadata.source_plan_id(prior_plan),
        "delta_count" => length(deltas),
        "approval_required_count" => length(approval_requirements),
        "candidate_window_count" => length(candidates),
        "candidate_source" => request.candidate_source,
        "repaired_activity_count" => length(activities),
        "transition_selected_activity_count" =>
          length(Timeline.transition_selected_activities(timeline_transition_application_report)),
        "transition_application_review_required_count" =>
          timeline_transition_application_report["review_required_count"],
        "timeline_protection" => Map.fetch!(attrs, :timeline_protection)
      }
    }
    |> put_source_reports(
      "source_suppressed_candidate_activities",
      RepairCandidateInputs.suppressed_candidate_activities(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_window_lineage",
      RepairSourceReports.source_window_lineage(request.candidate_refresh)
    )
    |> put_source_report(
      "source_candidate_refresh_provenance",
      RepairSourceReports.candidate_refresh_provenance(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_validation_records",
      RepairSourceReports.validation_records(request.candidate_refresh)
    )
    |> put_source_report(
      "source_candidate_diff_report",
      candidate_diff_report(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_intent_summary",
      RepairSourceReports.contact_intent_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_realized_state_snapshot",
      RepairSourceReports.realized_state_snapshot(request.candidate_refresh)
    )
    |> put_source_report(
      "source_candidate_rejection_report",
      RepairSourceReports.candidate_rejection_report(request)
    )
    |> put_source_report(
      "source_freshness_report",
      RepairSourceReports.freshness(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_readiness_report",
      RepairSourceReports.operational_readiness(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_import_eligibility_summary",
      RepairSourceReports.operational_import_eligibility(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_readiness_gate_summary",
      RepairSourceReports.operational_readiness_gate_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_execution_boundary_summary",
      RepairSourceReports.operational_execution_boundary_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_quality_gate_summary",
      RepairSourceReports.operational_quality_gate_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_quality_gate_unavailable_resource_summary",
      RepairSourceReports.operational_quality_gate_unavailable_resource_summary(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_operational_quality_gate_operator_training_summary",
      RepairSourceReports.operational_quality_gate_operator_training_summary(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_operational_quality_gate_schema_validation_summary",
      RepairSourceReports.operational_quality_gate_schema_validation_summary(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_operational_quality_gate_import_readiness_summary",
      RepairSourceReports.operational_quality_gate_import_readiness_summary(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_quality_gate_report",
      RepairSourceReports.quality_gate(request.candidate_refresh)
    )
    |> put_source_report(
      "source_refresh_budget_report",
      RepairSourceReports.refresh_budget(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_filter_report",
      RepairSourceReports.contact_filter(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_allocation_report",
      RepairSourceReports.contact_allocation(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_allocation_summary",
      RepairSourceReports.contact_allocation_summary(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_contact_allocation_summaries",
      RepairSourceReports.contact_allocation_summaries(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_allocation_station_pressure_summary",
      RepairSourceReports.contact_allocation_station_pressure_summary(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_contact_allocation_station_pressure_summaries",
      RepairSourceReports.contact_allocation_station_pressure_summaries(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_allocation_reservation_conflict_summary",
      RepairSourceReports.contact_allocation_reservation_conflict_summary(
        request.candidate_refresh
      )
    )
    |> put_source_reports(
      "source_contact_allocation_reservation_conflict_summaries",
      RepairSourceReports.contact_allocation_reservation_conflict_summaries(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_contact_allocation_capacity_pack_summary",
      RepairSourceReports.contact_allocation_capacity_pack_summary(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_contact_allocation_capacity_pack_summaries",
      RepairSourceReports.contact_allocation_capacity_pack_summaries(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_allocation_provider_reservation_request_summary",
      RepairSourceReports.contact_allocation_provider_reservation_request_summary(
        request.candidate_refresh
      )
    )
    |> put_source_reports(
      "source_contact_allocation_provider_reservation_request_summaries",
      RepairSourceReports.contact_allocation_provider_reservation_request_summaries(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_contact_contention_report",
      RepairSourceReports.contact_contention(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_contention_resolution_report",
      RepairSourceReports.contact_contention_resolution(request.candidate_refresh)
    )
    |> put_source_report(
      "source_contact_contention_resolution_summary",
      RepairSourceReports.contact_contention_resolution_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_link_capacity_report",
      RepairSourceReports.link_capacity(request.candidate_refresh)
    )
    |> put_source_report(
      "source_link_capacity_summary",
      RepairSourceReports.link_capacity_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_relay_data_path_summary",
      RepairSourceReports.relay_data_path_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_station_reservation_report",
      RepairSourceReports.station_reservation(request.candidate_refresh)
    )
    |> put_source_report(
      "source_station_reservation_review_summary",
      RepairSourceReports.station_reservation_review_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_station_reservation_hold_import_readiness_summary",
      RepairSourceReports.station_reservation_hold_import_readiness_summary(
        request.candidate_refresh
      )
    )
    |> put_source_report(
      "source_station_reservation_hold_summary",
      RepairSourceReports.station_reservation_hold_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_constraint_report",
      RepairSourceReports.constraint(request.candidate_refresh)
    )
    |> put_source_report(
      "source_objective_satisfaction_report",
      RepairSourceReports.objective_satisfaction(request.candidate_refresh)
    )
    |> put_source_report(
      "source_objective_tradeoff_report",
      RepairSourceReports.objective_tradeoff(request.candidate_refresh)
    )
    |> put_source_report(
      "source_score_term_report",
      RepairSourceReports.score_term(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_diff_report",
      RepairSourceReports.timeline_diff(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_diff_summary",
      RepairSourceReports.timeline_diff_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_integrity_report",
      RepairSourceReports.timeline_integrity(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_dependency_impact_summary",
      RepairSourceReports.timeline_dependency_impact(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_lifecycle_state_summary",
      RepairSourceReports.timeline_lifecycle_state(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_timeline_activity_precondition_summaries",
      RepairSourceReports.timeline_activity_precondition_summaries(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_timeline_activity_lifecycle_states",
      RepairSourceReports.timeline_activity_lifecycle_states(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_timeline_activity_states",
      RepairSourceReports.timeline_activity_states(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_timeline_preservation_statuses",
      RepairSourceReports.timeline_preservation_statuses(request.candidate_refresh)
    )
    |> put_source_reports(
      "source_timeline_publication_summaries",
      RepairSourceReports.timeline_publication_summaries(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_preservation_report",
      RepairSourceReports.timeline_preservation(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_transition_application_report",
      RepairSourceReports.timeline_transition_application(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_transition_application_summary",
      RepairSourceReports.timeline_transition_application_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_operational_timeline_report",
      RepairSourceReports.operational_timeline(request.candidate_refresh)
    )
    |> put_source_report(
      "source_command_window_report",
      RepairSourceReports.command_window(request.candidate_refresh)
    )
    |> put_source_report(
      "source_maneuver_review_report",
      RepairSourceReports.maneuver_review(request.candidate_refresh)
    )
    |> put_source_report(
      "source_schema_validation_report",
      RepairSourceReports.schema_validation(request.candidate_refresh)
    )
    |> put_source_report(
      "source_schema_validation_batch_report",
      RepairSourceReports.schema_validation_batch(request.candidate_refresh)
    )
    |> put_source_report(
      "source_model_acceptance_report",
      RepairSourceReports.model_acceptance(request.candidate_refresh)
    )
    |> put_source_report(
      "source_validation_safety_case_summary",
      RepairSourceReports.validation_safety_case(request.candidate_refresh)
    )
    |> put_source_report(
      "source_provider_counteroffer_report",
      RepairSourceReports.provider_counteroffer(request.candidate_refresh)
    )
    |> put_source_report(
      "source_provider_counteroffer_review_summary",
      RepairSourceReports.provider_counteroffer_review(request.candidate_refresh)
    )
    |> put_source_report(
      "source_provider_counteroffer_plan_impact_summary",
      RepairSourceReports.provider_counteroffer_plan_impact(request.candidate_refresh)
    )
    |> put_source_report(
      "source_provider_counteroffer_import_readiness_summary",
      RepairSourceReports.provider_counteroffer_import_readiness(request.candidate_refresh)
    )
    |> put_source_report(
      "source_resource_filter_report",
      RepairSourceReports.resource_filter(request.candidate_refresh)
    )
    |> put_source_report(
      "source_resource_filter_summary",
      RepairSourceReports.resource_filter_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_resource_projection_report",
      Map.fetch!(attrs, :source_resource_projection_report)
    )
    |> put_source_report(
      "source_resource_projection_flow_summary",
      RepairSourceReports.resource_projection_flow_summary(request.candidate_refresh)
    )
    |> put_source_report(
      "source_timeline_feedback_report",
      Map.fetch!(attrs, :source_timeline_feedback_report)
    )
    |> put_source_report(
      "source_station_calendar_provider",
      Map.get(request, :source_station_calendar_provider)
    )
    |> put_source_report(
      "source_station_calendar_report",
      Map.fetch!(attrs, :station_calendar_report)
    )
    |> put_source_report(
      "source_station_calendar_precedence_summary",
      RepairSourceReports.station_calendar_precedence_summary(request.candidate_refresh)
    )
    |> attach_operator_review()
    |> attach_cadence_import()
  end

  defp candidate_diff_report(nil), do: nil

  defp candidate_diff_report(%{} = candidate_refresh),
    do: RepairCandidateDiff.report(candidate_refresh)

  defp put_source_report(artifact, _key, nil), do: artifact
  defp put_source_report(artifact, key, %{} = report), do: Map.put(artifact, key, report)

  defp put_source_reports(artifact, _key, []), do: artifact

  defp put_source_reports(artifact, key, reports) when is_list(reports),
    do: Map.put(artifact, key, reports)

  defp attach_operator_review(artifact) do
    Map.put(artifact, "operator_review_package", OperatorReview.from_repair_artifact(artifact))
  end

  defp attach_cadence_import(artifact) do
    Map.put(artifact, "cadence_import_manifest", CadenceImport.from_repair_artifact(artifact))
  end
end
