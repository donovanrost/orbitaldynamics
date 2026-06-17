defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports do
  @moduledoc false

  alias __MODULE__.MissionState
  alias __MODULE__.PriorPlan
  alias __MODULE__.PressureRows
  alias __MODULE__.ResultArtifacts

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

  def prior_plan_timeline_publication_summaries(prior_plan, opts) do
    PriorPlan.timeline_publication_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_lifecycle_state_summaries(prior_plan, opts) do
    PriorPlan.timeline_lifecycle_state_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_activity_lifecycle_states(prior_plan, opts) do
    PriorPlan.timeline_activity_lifecycle_states(prior_plan, opts)
  end

  def prior_plan_timeline_activity_precondition_summaries(prior_plan, opts) do
    PriorPlan.timeline_activity_precondition_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_preservation_reports(prior_plan, opts) do
    PriorPlan.timeline_preservation_reports(prior_plan, opts)
  end

  def prior_plan_timeline_preservation_statuses(prior_plan, opts) do
    PriorPlan.timeline_preservation_statuses(prior_plan, opts)
  end

  def prior_plan_timeline_dependency_impact_summaries(prior_plan, opts) do
    PriorPlan.timeline_dependency_impact_summaries(prior_plan, opts)
  end

  def prior_plan_timeline_integrity_reports(prior_plan, opts) do
    PriorPlan.timeline_integrity_reports(prior_plan, opts)
  end

  def prior_plan_timeline_diff_reports(prior_plan, opts) do
    PriorPlan.timeline_diff_reports(prior_plan, opts)
  end

  def prior_plan_timeline_transition_application_reports(prior_plan, opts) do
    PriorPlan.timeline_transition_application_reports(prior_plan, opts)
  end

  def mission_state_timeline_diff_reports(mission_state, opts) do
    MissionState.mission_state_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_reports(mission_state, opts) do
    MissionState.mission_state_source_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_reports(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_timeline_transition_application_reports(mission_state, opts) do
    MissionState.mission_state_timeline_transition_application_reports(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_reports(mission_state, opts) do
    MissionState.mission_state_source_timeline_transition_application_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_transition_application_reports(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_transition_application_reports(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_lifecycle_state_summaries(mission_state, opts) do
    MissionState.mission_state_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_timeline_integrity_reports(mission_state, opts) do
    MissionState.mission_state_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_source_timeline_integrity_reports(mission_state, opts) do
    MissionState.mission_state_source_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_integrity_reports(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_timeline_dependency_impact_summaries(mission_state, opts) do
    MissionState.mission_state_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_dependency_impact_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_timeline_publication_summaries(mission_state, opts) do
    MissionState.mission_state_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_publication_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_publication_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_activity_precondition_summaries(mission_state, opts) do
    MissionState.mission_state_timeline_activity_precondition_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_activity_precondition_summaries(mission_state, opts) do
    MissionState.mission_state_source_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_activity_precondition_summaries(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_preservation_reports(mission_state, opts) do
    MissionState.mission_state_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_reports(mission_state, opts) do
    MissionState.mission_state_source_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_reports(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_timeline_preservation_statuses(mission_state, opts) do
    MissionState.mission_state_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_statuses(mission_state, opts) do
    MissionState.mission_state_source_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_statuses(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_timeline_activity_lifecycle_states(mission_state, opts) do
    MissionState.mission_state_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_lifecycle_states(mission_state, opts) do
    MissionState.mission_state_source_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_states(mission_state, opts) do
    MissionState.mission_state_source_timeline_activity_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_states(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_activity_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_status_states(mission_state, opts) do
    MissionState.mission_state_source_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_status_states(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_approval_states(mission_state, opts) do
    MissionState.mission_state_source_timeline_activity_approval_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_approval_states(mission_state, opts) do
    MissionState.mission_state_canonical_timeline_activity_approval_states(mission_state, opts)
  end

  def timeline_preservation_report_pressure_rows(reports, opts) do
    PressureRows.timeline_preservation_report_pressure_rows(reports, opts)
  end

  def timeline_preservation_status_pressure_rows(statuses, opts) do
    PressureRows.timeline_preservation_status_pressure_rows(statuses, opts)
  end

  def timeline_transition_application_pressure_row(row, opts) do
    PressureRows.timeline_transition_application_pressure_row(row, opts)
  end

  def timeline_diff_pressure_rows(diff_reports, transition_application_reports, opts) do
    PressureRows.timeline_diff_pressure_rows(diff_reports, transition_application_reports, opts)
  end

  def timeline_integrity_pressure_rows(reports, opts) do
    PressureRows.timeline_integrity_pressure_rows(reports, opts)
  end

  def timeline_dependency_impact_pressure_rows(summaries, opts) do
    PressureRows.timeline_dependency_impact_pressure_rows(summaries, opts)
  end
end
