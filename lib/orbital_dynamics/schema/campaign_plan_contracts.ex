defmodule OrbitalDynamics.Schema.CampaignPlanContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CampaignPlanActivityContracts,
    CampaignPlanActivitySnapshotContracts,
    CampaignPlanAssumptionContracts,
    CampaignPlanCadenceImportContracts,
    CampaignPlanCommandWindowContracts,
    CampaignPlanConstraintContracts,
    CampaignPlanContactAllocationContracts,
    CampaignPlanContactIntentContracts,
    CampaignPlanHorizonContracts,
    CampaignPlanIdentityContracts,
    CampaignPlanOptimizerContracts,
    CampaignPlanProvenanceContracts,
    CampaignPlanProposedContactContracts,
    CampaignPlanScoreContracts,
    CampaignPlanSearchContracts,
    CampaignPlanTargetCommitmentContracts,
    CampaignPlanTradeoffContracts,
    CampaignPlanWarningContracts
  }

  def validate(issues, artifact, required_fields, callbacks) when is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, ["$", artifact, required_fields])
    |> call(callbacks, :validate_stable_ids, ["$", artifact, ["plan_id", "study_id"]])
    |> CampaignPlanIdentityContracts.validate(artifact)
    |> call(callbacks, :expect_equal, ["$", artifact, "schema_version", 1])
    |> call(callbacks, :expect_equal, [
      "$",
      artifact,
      "planner",
      "OrbitalDynamics.CampaignPlanner.V1"
    ])
    |> call(callbacks, :expect_type, ["$", artifact, "planning_horizon", :map])
    |> CampaignPlanHorizonContracts.validate(artifact)
    |> call(callbacks, :expect_type, ["$", artifact, "activities", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "proposed_contacts", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "contact_intents", :list])
    |> call(callbacks, :validate_optional_contact_contention_report, [
      Map.get(artifact, "contact_contention_report")
    ])
    |> call(callbacks, :validate_optional_contact_contention_resolution_report, [
      Map.get(artifact, "contact_contention_resolution_report")
    ])
    |> call(callbacks, :validate_optional_station_calendar_report, [
      Map.get(artifact, "station_calendar_report")
    ])
    |> call(callbacks, :validate_optional_objective_tradeoff_report, [
      Map.get(artifact, "objective_tradeoff_report")
    ])
    |> call(callbacks, :validate_optional_objective_satisfaction_report, [
      Map.get(artifact, "objective_satisfaction_report")
    ])
    |> call(callbacks, :validate_optional_operational_timeline_report, [
      Map.get(artifact, "operational_timeline_report")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_report, [
      "$.timeline_transition_application_report",
      Map.get(artifact, "timeline_transition_application_report")
    ])
    |> call(callbacks, :validate_optional_operator_review_package, [
      Map.get(artifact, "operator_review_package")
    ])
    |> call(callbacks, :validate_optional_operational_readiness_report, [
      "$.operational_readiness_report",
      Map.get(artifact, "operational_readiness_report")
    ])
    |> call(callbacks, :validate_optional_quality_gate_report, [
      "$.quality_gate_report",
      Map.get(artifact, "quality_gate_report")
    ])
    |> call(callbacks, :validate_optional_optimizer_contract, [
      Map.get(artifact, "optimizer_contract")
    ])
    |> call(callbacks, :validate_optional_constraint_report, [
      Map.get(artifact, "constraint_report")
    ])
    |> call(callbacks, :validate_optional_contact_allocation_report, [
      Map.get(artifact, "contact_allocation_report")
    ])
    |> call(callbacks, :validate_optional_cadence_import_manifest, [
      Map.get(artifact, "cadence_import_manifest")
    ])
    |> call(callbacks, :validate_optional_command_window_report, [
      Map.get(artifact, "command_window_report")
    ])
    |> call(callbacks, :validate_optional_link_capacity_report, [
      Map.get(artifact, "link_capacity_report")
    ])
    |> call(callbacks, :validate_optional_resource_projection_report, [
      "$.resource_projection_report",
      Map.get(artifact, "resource_projection_report")
    ])
    |> call(callbacks, :validate_optional_resource_projection_flow_summary, [
      "$.resource_projection_flow_summary",
      Map.get(artifact, "resource_projection_flow_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_activity_precondition_summaries, [
      "$.timeline_activity_precondition_summaries",
      Map.get(artifact, "timeline_activity_precondition_summaries")
    ])
    |> call(callbacks, :validate_optional_timeline_integrity_report, [
      "$.timeline_integrity_report",
      Map.get(artifact, "timeline_integrity_report")
    ])
    |> call(callbacks, :validate_optional_resource_filter_report, [
      "$.resource_filter_report",
      Map.get(artifact, "resource_filter_report")
    ])
    |> call(callbacks, :validate_optional_score_term_report, [
      Map.get(artifact, "score_term_report")
    ])
    |> call(callbacks, :expect_type, ["$", artifact, "candidate_activities", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "ranked_timelines", :list])
    |> CampaignPlanScoreContracts.validate(artifact)
    |> CampaignPlanTradeoffContracts.validate(artifact)
    |> CampaignPlanOptimizerContracts.validate(artifact)
    |> CampaignPlanConstraintContracts.validate(artifact)
    |> CampaignPlanContactAllocationContracts.validate(artifact)
    |> CampaignPlanCadenceImportContracts.validate(artifact)
    |> CampaignPlanCommandWindowContracts.validate(artifact)
    |> CampaignPlanTargetCommitmentContracts.validate(artifact)
    |> CampaignPlanActivityContracts.validate(artifact)
    |> CampaignPlanActivitySnapshotContracts.validate(artifact)
    |> CampaignPlanProposedContactContracts.validate(artifact)
    |> CampaignPlanContactIntentContracts.validate(artifact)
    |> call(callbacks, :expect_type, ["$", artifact, "warnings", :list])
    |> CampaignPlanWarningContracts.validate(artifact)
    |> call(callbacks, :expect_type, ["$", artifact, "assumptions", :map])
    |> CampaignPlanAssumptionContracts.validate(artifact)
    |> call(callbacks, :expect_type, ["$", artifact, "provenance", :map])
    |> CampaignPlanProvenanceContracts.validate(artifact)
    |> call(callbacks, :expect_type, ["$", artifact, "ranking_explanation", :map])
    |> call(callbacks, :validate_rows, [
      "$.activities",
      Map.get(artifact, "activities", []),
      callback(callbacks, :validate_activity)
    ])
    |> call(callbacks, :validate_rows, [
      "$.candidate_activities",
      Map.get(artifact, "candidate_activities", []),
      callback(callbacks, :validate_activity)
    ])
    |> call(callbacks, :validate_rows, [
      "$.proposed_contacts",
      Map.get(artifact, "proposed_contacts", []),
      callback(callbacks, :validate_proposed_contact)
    ])
    |> call(callbacks, :validate_rows, [
      "$.contact_intents",
      Map.get(artifact, "contact_intents", []),
      callback(callbacks, :validate_contact_intent)
    ])
    |> call(callbacks, :validate_optional_contact_filter_report, [
      Map.get(artifact, "contact_filter_report")
    ])
    |> CampaignPlanSearchContracts.validate_plan(artifact)
  end

  defp callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp call(issues, callbacks, name, args),
    do: apply(callback(callbacks, name), [issues | args])
end
