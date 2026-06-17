defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.PriorPlan do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def timeline_publication_summaries(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_publication_summary", "prior_plan.source_timeline_publication_summary"},
        {"timeline_publication_summary", "prior_plan.timeline_publication_summary"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_publication_summaries(prior_plan, opts)
  end

  def timeline_lifecycle_state_summaries(prior_plan, opts) do
    prior_plan
    |> SourceEntries.source_report_entries(
      [
        {"source_timeline_lifecycle_state_summary",
         "prior_plan.source_timeline_lifecycle_state_summary"},
        {"timeline_lifecycle_state_summary", "prior_plan.timeline_lifecycle_state_summary"}
      ],
      opts
    )
    |> Enum.map(fn {summary, path} ->
      {SourceEntries.put_timeline_lifecycle_state_summary_trust_boundary(summary), path}
    end)
    |> Kernel.++(ResultArtifacts.timeline_lifecycle_state_summaries(prior_plan, opts))
  end

  def timeline_activity_lifecycle_states(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_activity_lifecycle_state",
         "prior_plan.source_timeline_activity_lifecycle_state"},
        {"timeline_activity_lifecycle_state", "prior_plan.timeline_activity_lifecycle_state"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_activity_lifecycle_states(prior_plan, opts)
  end

  def timeline_activity_precondition_summaries(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_activity_precondition_summary",
         "prior_plan.source_timeline_activity_precondition_summary"},
        {"timeline_activity_precondition_summary",
         "prior_plan.timeline_activity_precondition_summary"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_activity_precondition_summaries(prior_plan, opts)
  end

  def timeline_preservation_reports(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_preservation_report", "prior_plan.source_timeline_preservation_report"},
        {"timeline_preservation_report", "prior_plan.timeline_preservation_report"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_preservation_reports(prior_plan, opts)
  end

  def timeline_preservation_statuses(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_preservation_status", "prior_plan.source_timeline_preservation_status"},
        {"timeline_preservation_status", "prior_plan.timeline_preservation_status"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_preservation_statuses(prior_plan, opts)
  end

  def timeline_dependency_impact_summaries(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_dependency_impact_summary",
         "prior_plan.source_timeline_dependency_impact_summary"},
        {"timeline_dependency_impact_summary", "prior_plan.timeline_dependency_impact_summary"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_dependency_impact_summaries(prior_plan, opts)
  end

  def timeline_integrity_reports(prior_plan, opts) do
    SourceEntries.source_report_entries(
      prior_plan,
      [
        {"source_timeline_integrity_report", "prior_plan.source_timeline_integrity_report"},
        {"timeline_integrity_report", "prior_plan.timeline_integrity_report"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_integrity_reports(prior_plan, opts)
  end

  def timeline_diff_reports(prior_plan, opts) do
    SourceEntries.direct_single_report_entries(
      prior_plan,
      [
        {"source_timeline_diff_report", "prior_plan.source_timeline_diff_report"},
        {"timeline_diff_report", "prior_plan.timeline_diff_report"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_diff_reports(prior_plan, opts)
  end

  def timeline_transition_application_reports(prior_plan, opts) do
    SourceEntries.direct_single_report_entries(
      prior_plan,
      [
        {"source_timeline_transition_application_report",
         "prior_plan.source_timeline_transition_application_report.applications"},
        {"timeline_transition_application_report",
         "prior_plan.timeline_transition_application_report.applications"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_transition_application_reports(prior_plan, opts)
  end
end
