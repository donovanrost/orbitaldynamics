defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports do
  @moduledoc false

  alias __MODULE__.MissionState
  alias __MODULE__.PriorPlan
  alias __MODULE__.PressureRows
  alias __MODULE__.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, ValueEncoding}

  def result_artifact_timeline_diff_reports(container, opts) do
    ResultArtifacts.timeline_diff_reports(container, opts)
  end

  def result_artifact_timeline_integrity_reports(container, opts) do
    ResultArtifacts.timeline_integrity_reports(container, opts)
  end

  def result_artifact_timeline_dependency_impact_summaries(container, opts) do
    ResultArtifacts.timeline_dependency_impact_summaries(container, opts)
  end

  def result_artifact_timeline_publication_summaries(container, opts) do
    ResultArtifacts.timeline_publication_summaries(container, opts)
  end

  def result_artifact_timeline_lifecycle_state_summaries(container, opts) do
    ResultArtifacts.timeline_lifecycle_state_summaries(container, opts)
  end

  def result_artifact_timeline_activity_lifecycle_states(container, opts) do
    ResultArtifacts.timeline_activity_lifecycle_states(container, opts)
  end

  def result_artifact_timeline_activity_precondition_summaries(container, opts) do
    ResultArtifacts.timeline_activity_precondition_summaries(container, opts)
  end

  def result_artifact_timeline_preservation_reports(container, opts) do
    ResultArtifacts.timeline_preservation_reports(container, opts)
  end

  def result_artifact_timeline_preservation_statuses(container, opts) do
    ResultArtifacts.timeline_preservation_statuses(container, opts)
  end

  def result_artifact_timeline_transition_application_reports(container, opts) do
    ResultArtifacts.timeline_transition_application_reports(container, opts)
  end

  def prior_plan_timeline_publication_summaries(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_publication_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_lifecycle_state_summaries(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_lifecycle_state_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_activity_lifecycle_states(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_activity_lifecycle_states(prior_plan, opts)
  end

  def prior_plan_timeline_activity_precondition_summaries(
        prior_plan,
        opts \\ prior_plan_callbacks()
      ) do
    PriorPlan.timeline_activity_precondition_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_preservation_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_preservation_reports(prior_plan, opts)
  end

  def prior_plan_timeline_preservation_statuses(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_preservation_statuses(prior_plan, opts)
  end

  def prior_plan_timeline_dependency_impact_summaries(
        prior_plan,
        opts \\ prior_plan_callbacks()
      ) do
    PriorPlan.timeline_dependency_impact_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_integrity_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_integrity_reports(prior_plan, opts)
  end

  def prior_plan_timeline_diff_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    PriorPlan.timeline_diff_reports(prior_plan, opts)
  end

  def prior_plan_timeline_transition_application_reports(
        prior_plan,
        opts \\ prior_plan_callbacks()
      ) do
    PriorPlan.timeline_transition_application_reports(prior_plan, opts)
  end

  def mission_state_timeline_diff_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_source_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_canonical_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_summaries(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_source_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_timeline_transition_application_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_timeline_transition_application_reports(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_transition_application_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_transition_application_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_transition_application_reports(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_lifecycle_state_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_lifecycle_state_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_lifecycle_state_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_timeline_integrity_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_source_timeline_integrity_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_source_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_integrity_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_timeline_dependency_impact_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_dependency_impact_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_dependency_impact_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_timeline_publication_summaries(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_publication_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_publication_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_activity_precondition_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_timeline_activity_precondition_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_activity_precondition_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_activity_precondition_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_preservation_reports(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_reports(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_timeline_preservation_statuses(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_statuses(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_statuses(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_timeline_activity_lifecycle_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_lifecycle_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_lifecycle_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_states(mission_state, opts \\ default_callbacks()) do
    MissionState.mission_state_source_timeline_activity_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_activity_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_status_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_status_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_approval_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_source_timeline_activity_approval_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_approval_states(
        mission_state,
        opts \\ default_callbacks()
      ) do
    MissionState.mission_state_canonical_timeline_activity_approval_states(mission_state, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, candidate_refresh_source_input(mission_state, collector)}
    end)
  end

  def timeline_preservation_report_pressure_rows(reports, opts \\ pressure_row_callbacks()) do
    PressureRows.timeline_preservation_report_pressure_rows(reports, opts)
  end

  def timeline_preservation_status_pressure_rows(statuses, opts \\ pressure_row_callbacks()) do
    PressureRows.timeline_preservation_status_pressure_rows(statuses, opts)
  end

  def pressure_entries(entries) do
    PressureRows.pressure_entries(entries)
  end

  def timeline_transition_application_pressure_row(row) do
    PressureRows.timeline_transition_application_pressure_row(row, pressure_row_callbacks())
  end

  def timeline_transition_application_pressure_row(row, opts) do
    PressureRows.timeline_transition_application_pressure_row(row, opts)
  end

  def timeline_diff_pressure_rows(
        diff_reports,
        transition_application_reports,
        opts \\ pressure_row_callbacks()
      ) do
    PressureRows.timeline_diff_pressure_rows(diff_reports, transition_application_reports, opts)
  end

  def timeline_integrity_pressure_rows(reports, opts \\ pressure_row_callbacks()) do
    PressureRows.timeline_integrity_pressure_rows(reports, opts)
  end

  def timeline_dependency_impact_pressure_rows(summaries, opts \\ pressure_row_callbacks()) do
    PressureRows.timeline_dependency_impact_pressure_rows(summaries, opts)
  end

  defp candidate_refresh_source_input(mission_state, collector) do
    BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_timeline_diff_report", &mission_state_source_timeline_diff_reports/1},
      {"timeline_diff_report", &mission_state_canonical_timeline_diff_reports/1},
      {"source_timeline_diff_summary", &mission_state_source_timeline_diff_summaries/1},
      {"timeline_diff_summary", &mission_state_canonical_timeline_diff_summaries/1},
      {"source_timeline_lifecycle_state_summary",
       &mission_state_source_timeline_lifecycle_state_summaries/1},
      {"timeline_lifecycle_state_summary",
       &mission_state_canonical_timeline_lifecycle_state_summaries/1},
      {"source_timeline_integrity_report", &mission_state_source_timeline_integrity_reports/1},
      {"timeline_integrity_report", &mission_state_canonical_timeline_integrity_reports/1},
      {"source_timeline_dependency_impact_summary",
       &mission_state_source_timeline_dependency_impact_summaries/1},
      {"timeline_dependency_impact_summary",
       &mission_state_canonical_timeline_dependency_impact_summaries/1},
      {"source_timeline_activity_precondition_summary",
       &mission_state_source_timeline_activity_precondition_summaries/1},
      {"timeline_activity_precondition_summary",
       &mission_state_canonical_timeline_activity_precondition_summaries/1},
      {"source_timeline_preservation_report",
       &mission_state_source_timeline_preservation_reports/1},
      {"timeline_preservation_report", &mission_state_canonical_timeline_preservation_reports/1},
      {"source_timeline_preservation_status",
       &mission_state_source_timeline_preservation_statuses/1},
      {"timeline_preservation_status", &mission_state_canonical_timeline_preservation_statuses/1},
      {"source_timeline_publication_summary",
       &mission_state_source_timeline_publication_summaries/1},
      {"timeline_publication_summary", &mission_state_canonical_timeline_publication_summaries/1},
      {"source_timeline_transition_application_summary",
       &mission_state_source_timeline_transition_application_summaries/1},
      {"timeline_transition_application_summary",
       &mission_state_canonical_timeline_transition_application_summaries/1},
      {"source_timeline_activity_state", &mission_state_source_timeline_activity_states/1},
      {"timeline_activity_state", &mission_state_canonical_timeline_activity_states/1},
      {"source_timeline_activity_status_state",
       &mission_state_source_timeline_activity_status_states/1},
      {"timeline_activity_status_state",
       &mission_state_canonical_timeline_activity_status_states/1},
      {"source_timeline_activity_approval_state",
       &mission_state_source_timeline_activity_approval_states/1},
      {"timeline_activity_approval_state",
       &mission_state_canonical_timeline_activity_approval_states/1},
      {"source_timeline_activity_lifecycle_state",
       &mission_state_source_timeline_activity_lifecycle_states/1},
      {"timeline_activity_lifecycle_state",
       &mission_state_canonical_timeline_activity_lifecycle_states/1},
      {"source_timeline_transition_application_report",
       &mission_state_source_timeline_transition_application_reports/1},
      {"timeline_transition_application_report",
       &mission_state_canonical_timeline_transition_application_reports/1}
    ]

  defp default_callbacks,
    do: [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      result_artifact_embedded_report_entries:
        &BranchRefreshSourceInputs.result_artifact_embedded_report_entries/3,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      reject_empty_values: &ValueEncoding.reject_empty_values/1
    ]

  defp prior_plan_callbacks,
    do: [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      result_artifact_embedded_report_entries:
        &BranchRefreshSourceInputs.result_artifact_embedded_report_entries/3,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      reject_empty_values: &ValueEncoding.reject_empty_values/1
    ]

  defp pressure_row_callbacks,
    do: [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      result_artifact_embedded_report_entries:
        &BranchRefreshSourceInputs.result_artifact_embedded_report_entries/3,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      reject_empty_values: &ValueEncoding.reject_empty_values/1
    ]

  defp mission_state_result_artifacts_with_source(mission_state) do
    BranchRefreshSourceInputs.result_artifacts_with_source(mission_state, "mission_state")
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
  end
end
