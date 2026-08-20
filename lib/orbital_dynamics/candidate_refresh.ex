defmodule OrbitalDynamics.CandidateRefresh do
  @moduledoc """
  Builds `candidate_refresh.v1` artifacts from refreshed study results.

  V1 is deliberately a transparent vertical slice: accepted planning-state
  snapshots are propagated by the study pipeline, event windows are copied from
  existing detectors, and candidate activities use the same deterministic
  scoring conventions as campaign V1.
  """

  alias OrbitalDynamics.CandidateRefresh.{
    Build,
    Capabilities,
    ModelLimits,
    ReplaySummary,
    Runner,
    SourceReportSummary
  }

  alias OrbitalDynamics.ResultSet

  @doc """
  Declares the candidate-refresh artifact model and known limits.
  """
  def capabilities do
    Capabilities.capabilities()
  end

  @doc """
  Builds a JSON-serializable candidate refresh artifact.
  """
  def build(%ResultSet{} = result_set, opts \\ []) do
    Build.build(result_set, opts)
  end

  @doc """
  Runs the opt-in, offline deterministic Earth J2/drag refresh bundle.

  Returns `{:ok, artifact}` or a typed stage error. The legacy `build/2`
  composition boundary is unchanged and remains available for callers that
  already supply a result set.
  """
  def run(refresh, opts \\ []) do
    Runner.run(refresh, opts)
  end

  @doc """
  Builds an artifact-only summary of candidate-refresh source-report provenance.
  """
  def source_report_summary(refresh_or_artifact),
    do: SourceReportSummary.build(refresh_or_artifact)

  @doc """
  Builds a compact branch-local candidate-diff replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, select candidates, or write to Cadence.
  """
  def candidate_diff_replay_summary(refresh_or_artifact) do
    ReplaySummary.candidate_diff(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local candidate-rejection replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, select candidates, import rejected candidates, or write to
  Cadence.
  """
  def candidate_rejection_replay_summary(refresh_or_artifact) do
    ReplaySummary.candidate_rejection(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local provider-counteroffer replay summary.

  The summary is derived from candidate-refresh source-report provenance. It
  does not replay refresh generation, accept counteroffers, mutate schedules,
  approve imports, or write to Cadence.
  """
  def provider_counteroffer_replay_summary(refresh_or_artifact) do
    ReplaySummary.provider_counteroffer(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local contact-contention replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  contact allocation, select candidates, approve imports, or write to Cadence.
  """
  def contact_contention_replay_summary(refresh_or_artifact) do
    ReplaySummary.contact_contention(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local contact-contention-resolution replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  contact allocation, select candidates, approve imports, or write to Cadence.
  """
  def contact_contention_resolution_replay_summary(refresh_or_artifact) do
    ReplaySummary.contact_contention_resolution(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local contact-allocation replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  contact allocation, select candidates, approve imports, or write to Cadence.
  """
  def contact_allocation_replay_summary(refresh_or_artifact) do
    ReplaySummary.contact_allocation(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local link-capacity replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  contact allocation, select candidates, approve imports, or write to Cadence.
  """
  def link_capacity_replay_summary(refresh_or_artifact) do
    ReplaySummary.link_capacity(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local contact-filter replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  contact allocation, select candidates, approve imports, or write to Cadence.
  """
  def contact_filter_replay_summary(refresh_or_artifact) do
    ReplaySummary.contact_filter(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local resource-filter replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  resource filtering, select candidates, approve imports, or write to Cadence.
  """
  def resource_filter_replay_summary(refresh_or_artifact) do
    ReplaySummary.resource_filter(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local resource-projection replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  resource projection, select candidates, approve imports, or write to Cadence.
  """
  def resource_projection_replay_summary(refresh_or_artifact) do
    ReplaySummary.resource_projection(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local storage/downlink pressure replay summary.

  The summary composes contact-allocation, link-capacity, and
  resource-projection source-report provenance. It does not replay refresh
  generation, mutate projections or allocations, select candidates, approve
  imports, or write to Cadence.
  """
  def storage_downlink_pressure_replay_summary(refresh_or_artifact) do
    ReplaySummary.storage_downlink_pressure(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local station-calendar replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  station calendars or schedules, select candidates, approve imports, or write
  to Cadence.
  """
  def station_calendar_replay_summary(refresh_or_artifact) do
    ReplaySummary.station_calendar(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local station-reservation replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not reserve provider time, mutate station
  calendars or schedules, select candidates, approve imports, write to Cadence,
  or regenerate candidates.
  """
  def station_reservation_replay_summary(refresh_or_artifact) do
    ReplaySummary.station_reservation(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local command-window replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, execute
  commands, select candidates, approve imports, or write to Cadence.
  """
  def command_window_replay_summary(refresh_or_artifact) do
    ReplaySummary.command_window(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local maneuver-review replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, execute
  maneuvers, select candidates, approve imports, or write to Cadence.
  """
  def maneuver_review_replay_summary(refresh_or_artifact) do
    ReplaySummary.maneuver_review(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local contact-intent replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, generate
  contacts, select candidates, approve imports, or write to Cadence.
  """
  def contact_intent_replay_summary(refresh_or_artifact) do
    ReplaySummary.contact_intent(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline activity-state replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not apply activity-state changes, mutate
  timelines, select candidates, approve imports, execute commands, or write to
  Cadence.
  """
  def timeline_activity_state_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_activity_state(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline activity-status-state replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not apply status changes, mutate
  timelines, select candidates, approve imports, execute commands, or write to
  Cadence.
  """
  def timeline_activity_status_state_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_activity_status_state(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline activity-approval-state replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not apply approval changes, mutate
  timelines, select candidates, approve imports, execute commands, or write to
  Cadence.
  """
  def timeline_activity_approval_state_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_activity_approval_state(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline activity-lifecycle-state replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not apply lifecycle-state changes, mutate
  timelines, select candidates, approve imports, execute commands, or write to
  Cadence.
  """
  def timeline_activity_lifecycle_state_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_activity_lifecycle_state(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline activity-precondition replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not evaluate preconditions, mutate
  timelines, select candidates, approve imports, execute commands, reserve
  resources, or write to Cadence.
  """
  def timeline_activity_precondition_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_activity_precondition(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline-preservation replay summary.

  The summary is derived from candidate-refresh preservation review provenance.
  It prefers branch-local candidate-source preservation rows when present and
  falls back to candidate-refresh preservation review provenance. It does not
  apply preservation decisions, mutate timelines, select candidates, approve
  imports, execute commands, or write to Cadence.
  """
  def timeline_preservation_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_preservation(refresh_or_artifact)
  end

  @doc """
   Builds a compact branch-local timeline-diff replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  timelines, select candidates, approve imports, or write to Cadence.
  """
  def timeline_diff_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_diff(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline-integrity replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  timelines, select candidates, approve imports, or write to Cadence.
  """
  def timeline_integrity_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_integrity(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline lifecycle-state replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not apply lifecycle transitions, mutate
  timelines, select candidates, approve imports, write to Cadence, or regenerate
  candidates.
  """
  def timeline_lifecycle_state_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_lifecycle_state(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline dependency-impact replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  timelines, select candidates, approve imports, or write to Cadence.
  """
  def timeline_dependency_impact_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_dependency_impact(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline-publication replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not publish, notify, mutate timelines,
  select candidates, approve imports, or write to Cadence.
  """
  def timeline_publication_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_publication(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline-transition-application replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, apply
  timeline transitions, select candidates, approve imports, or write to Cadence.
  """
  def timeline_transition_application_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_transition_application(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local objective-gap replay summary.

  The summary is derived from candidate-refresh source-report provenance. It
  does not replay refresh generation, create objectives, score candidates,
  select candidates, approve imports, or write to Cadence.
  """
  def objective_gap_replay_summary(refresh_or_artifact) do
    ReplaySummary.objective_gap(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local constraint replay summary.

  The summary is derived from candidate-refresh source-report provenance. It
  does not replay refresh generation, create objectives, mutate resource state,
  select candidates, approve imports, or write to Cadence.
  """
  def constraint_replay_summary(refresh_or_artifact) do
    ReplaySummary.constraint(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local timeline-feedback replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, apply
  operational feedback, mutate timelines, select candidates, approve imports,
  or write to Cadence.
  """
  def timeline_feedback_replay_summary(refresh_or_artifact) do
    ReplaySummary.timeline_feedback(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local operational-timeline replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, apply
  operational feedback, mutate timelines, select candidates, approve imports,
  or write to Cadence.
  """
  def operational_timeline_replay_summary(refresh_or_artifact) do
    ReplaySummary.operational_timeline(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local operational-readiness replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, approve operator actions, or write to Cadence.
  """
  def operational_readiness_replay_summary(refresh_or_artifact) do
    ReplaySummary.operational_readiness(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local quality-gate replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, approve operator actions, or write to Cadence.
  """
  def quality_gate_replay_summary(refresh_or_artifact) do
    ReplaySummary.quality_gate(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local model-acceptance replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, certify models, approve imports, or write to Cadence.
  """
  def model_acceptance_replay_summary(refresh_or_artifact) do
    ReplaySummary.model_acceptance(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local validation-safety-case replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, certify safety cases, approve imports, or write to Cadence.
  """
  def validation_safety_case_replay_summary(refresh_or_artifact) do
    ReplaySummary.validation_safety_case(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local freshness replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, approve imports, or write to Cadence.
  """
  def freshness_replay_summary(refresh_or_artifact) do
    ReplaySummary.freshness(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local refresh-budget replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, approve imports, or write to Cadence.
  """
  def refresh_budget_replay_summary(refresh_or_artifact) do
    ReplaySummary.refresh_budget(refresh_or_artifact)
  end

  @doc """
  Builds a compact branch-local schema-validation replay summary.

  The summary is derived from candidate-refresh source-report summaries,
  preferring branch-local candidate-source summary metadata when present and
  falling back to provenance. It does not replay refresh generation, mutate
  candidates, approve imports, or write to Cadence.
  """
  def schema_validation_replay_summary(refresh_or_artifact) do
    ReplaySummary.schema_validation(refresh_or_artifact)
  end

  @doc """
  Returns the declared model limits for candidate-refresh artifacts and reports.
  """
  def model_limits do
    ModelLimits.strings()
  end
end
