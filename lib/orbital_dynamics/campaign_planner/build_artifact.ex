defmodule OrbitalDynamics.CampaignPlanner.BuildArtifact do
  @moduledoc false

  alias OrbitalDynamics.Communications.CommandWindow
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding
  alias OrbitalDynamics.{CadenceImport, OperatorReview, OperationalReadiness, ResultSet}

  @schema_version 1

  def build(%ResultSet{} = result_set, %{} = campaign, %{} = attrs) do
    activities = Map.fetch!(attrs, :activities)
    approval_policy = Map.fetch!(attrs, :approval_policy)

    %{
      "schema_version" => @schema_version,
      "generated_at" => attrs |> Map.fetch!(:generated_at) |> DateTime.to_iso8601(),
      "planner" => "OrbitalDynamics.CampaignPlanner.V1",
      "plan_id" => Map.fetch!(attrs, :plan_id),
      "study_id" => ValueEncoding.encode_value(result_set.study_id),
      "planning_horizon" => Map.get(campaign, "planning_horizon", %{}),
      "activities" => activities,
      "proposed_contacts" => Map.fetch!(attrs, :proposed_contacts),
      "contact_intents" => Map.fetch!(attrs, :contact_intents),
      "contact_filter_report" => Map.fetch!(attrs, :contact_filter_report),
      "resource_filter_report" => Map.fetch!(attrs, :resource_filter_report),
      "station_calendar_report" => Map.fetch!(attrs, :station_calendar_report),
      "contact_contention_report" => Map.fetch!(attrs, :contact_contention_report),
      "contact_contention_resolution_report" =>
        Map.fetch!(attrs, :contact_contention_resolution_report),
      "contact_allocation_report" => Map.fetch!(attrs, :contact_allocation_report),
      "link_capacity_report" => Map.fetch!(attrs, :link_capacity_report),
      "resource_projection_report" => Map.fetch!(attrs, :resource_projection_report),
      "resource_projection_flow_summary" => Map.fetch!(attrs, :resource_projection_flow_summary),
      "timeline_activity_precondition_summaries" =>
        Map.fetch!(attrs, :timeline_activity_precondition_summaries),
      "timeline_integrity_report" => Map.fetch!(attrs, :timeline_integrity_report),
      "target_commitments" => Map.fetch!(attrs, :target_commitments),
      "objective_satisfaction_report" => Map.fetch!(attrs, :objective_satisfaction_report),
      "operational_timeline_report" => Map.fetch!(attrs, :operational_timeline_report),
      "command_window_report" =>
        CommandWindow.report(activities,
          source: "campaign_plan.activities",
          source_assumption: "selected campaign_plan.activities",
          approval_policy: approval_policy
        ),
      "candidate_activities" => Map.fetch!(attrs, :candidate_activities),
      "ranked_timelines" => Map.fetch!(attrs, :ranked_timelines),
      "optimizer_contract" => Map.fetch!(attrs, :optimizer_contract),
      "constraint_report" => Map.fetch!(attrs, :constraint_report),
      "objective_tradeoff_report" => Map.fetch!(attrs, :objective_tradeoff_report),
      "score_term_report" => Map.fetch!(attrs, :score_term_report),
      "warnings" => Map.fetch!(attrs, :warnings),
      "assumptions" => Map.fetch!(attrs, :assumptions),
      "provenance" => Map.fetch!(attrs, :provenance),
      "ranking_explanation" => Map.fetch!(attrs, :ranking_explanation)
    }
    |> attach_operator_review()
    |> attach_cadence_import()
    |> attach_operational_readiness_reports()
  end

  def attach_optimizer_search_trace(%{} = artifact, %{} = trace) do
    artifact
    |> Map.drop([
      "operator_review_package",
      "cadence_import_manifest",
      "operational_readiness_report",
      "quality_gate_report"
    ])
    |> Map.put("optimizer_search_trace", trace)
    |> attach_operator_review()
    |> attach_cadence_import()
    |> attach_operational_readiness_reports()
  end

  defp attach_operator_review(artifact) do
    Map.put(artifact, "operator_review_package", OperatorReview.from_campaign_artifact(artifact))
  end

  defp attach_cadence_import(artifact) do
    Map.put(artifact, "cadence_import_manifest", CadenceImport.from_campaign_artifact(artifact))
  end

  defp attach_operational_readiness_reports(artifact) do
    readiness_report = OperationalReadiness.report(artifact)

    artifact
    |> Map.put("operational_readiness_report", readiness_report)
    |> Map.put("quality_gate_report", OperationalReadiness.quality_gate_report(readiness_report))
  end
end
