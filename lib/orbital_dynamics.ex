defmodule OrbitalDynamics do
  @moduledoc """
  Minimal mission analysis tools for deterministic orbital propagation.

  This package intentionally starts with a narrow two-body analysis slice:

  * state vectors with explicit kilometers, kilometers per second, epochs, and frames
  * mission scenarios that bind a spacecraft to an initial state and time span
  * a deterministic fixed-step RK4 propagator
  * a concurrent scenario runner built on BEAM tasks
  """

  alias OrbitalDynamics.Propagators.{
    J2,
    J2Drag,
    J2ExlaCpu,
    TwoBody,
    TwoBodyDrag,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  alias OrbitalDynamics.ActivityTemplateCatalog
  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.Communications.CommandWindow
  alias OrbitalDynamics.Communications.ContactAllocation
  alias OrbitalDynamics.Communications.ContactContention
  alias OrbitalDynamics.Communications.ContactFilter
  alias OrbitalDynamics.Communications.ContactIntent
  alias OrbitalDynamics.Communications.DownlinkLinkBudget
  alias OrbitalDynamics.Communications.LinkCapacity
  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.Constraints.{ArtifactMetric, CampaignLocal}
  alias OrbitalDynamics.Environment
  alias OrbitalDynamics.FrameTransform
  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.ManeuverReview
  alias OrbitalDynamics.MissionPlan
  alias OrbitalDynamics.OperationalScale
  alias OrbitalDynamics.OperationalReadiness
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Optimizer
  alias OrbitalDynamics.OrbitData
  alias OrbitalDynamics.OrbitElements
  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.ResourceFilter
  alias OrbitalDynamics.ResourceProjection
  alias OrbitalDynamics.ResourceStateTrace
  alias OrbitalDynamics.ResourceSummary
  alias OrbitalDynamics.ResultSet.Report, as: ResultSetReport
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.ScenarioRunner
  alias OrbitalDynamics.Search.Grid
  alias OrbitalDynamics.Search.Local
  alias OrbitalDynamics.Search.MonteCarlo
  alias OrbitalDynamics.Study
  alias OrbitalDynamics.Study.Benchmark.Report, as: StudyBenchmarkReport
  alias OrbitalDynamics.StudyRunner
  alias OrbitalDynamics.SubsystemModel
  alias OrbitalDynamics.Timeline
  alias OrbitalDynamics.TimelineFeedback
  alias OrbitalDynamics.Units
  alias OrbitalDynamics.Validation

  alias OrbitalDynamics.EventDetectors.{
    AccessWindows,
    Eclipses,
    GroundTrackCrossings,
    TargetVisibility
  }

  @doc """
  Propagates one scenario with the default two-body propagator.
  """
  def propagate(scenario, opts \\ []) do
    TwoBody.propagate(scenario, opts)
  end

  @doc """
  Propagates one scenario through the opt-in scalar J2-plus-drag path.

  This facade does not change `propagate/2`, study manifests, or planner
  defaults. See `OrbitalDynamics.Propagators.J2Drag.propagate/2` for the
  supported LEO envelope and provider policy.
  """
  def propagate_j2_drag(scenario, opts \\ []) do
    J2Drag.propagate(scenario, opts)
  end

  @doc """
  Runs scenarios concurrently while preserving input order in the returned list.
  """
  def analyze(scenarios, opts \\ []) do
    ScenarioRunner.run(scenarios, opts)
  end

  @doc """
  Runs a study concurrently while preserving scenario order in the returned list.
  """
  def analyze_study(%Study{} = study, opts \\ []) do
    runner_opts =
      [
        propagator: study.propagator,
        propagator_opts: study.propagator_opts
      ]
      |> Keyword.merge(opts)

    ScenarioRunner.run(study.scenarios, runner_opts)
  end

  @doc """
  Returns deterministic task chunking guidance for concurrent scenario runs.
  """
  def task_chunking_recommendation(scenarios_or_count, opts \\ []) do
    ScenarioRunner.task_chunking_recommendation(scenarios_or_count, opts)
  end

  @doc """
  Resolves the effective task chunk size for a concurrent scenario run.
  """
  def resolve_task_chunk_size(scenarios_or_count, opts \\ []) do
    ScenarioRunner.resolve_task_chunk_size(scenarios_or_count, opts)
  end

  @doc """
  Runs a study-level workflow and returns a result set.
  """
  def run_study(%Study{} = study, opts \\ []) do
    StudyRunner.run(study, opts)
  end

  @doc """
  Validates study run inputs without propagating scenarios.
  """
  def validate_study_run_inputs(%Study{} = study, opts \\ []) do
    StudyRunner.validate_run_inputs(study, opts)
  end

  @doc """
  Returns the public capability metadata for analysis and planning surfaces.

  The catalog is a discovery API for application callers. It exposes the same
  model labels, validation levels, artifact contracts, and known-limit metadata
  declared by the underlying modules without running a study or planner.
  """
  def capability_catalog do
    %{
      analysis: %{
        propagator: TwoBody.capabilities(),
        force_models: %{
          atmospheric_drag: AtmosphericDrag.capabilities()
        },
        propagators: %{
          two_body: TwoBody.capabilities(),
          two_body_drag: TwoBodyDrag.capabilities(),
          j2: J2.capabilities(),
          j2_drag: J2Drag.capabilities(),
          two_body_nx: TwoBodyNx.capabilities(),
          two_body_nx_compiled: TwoBodyNxCompiled.capabilities(),
          two_body_exla_cpu: TwoBodyExlaCpu.capabilities(),
          j2_exla_cpu: J2ExlaCpu.capabilities()
        },
        access_windows: AccessWindows.capabilities(),
        eclipses: Eclipses.capabilities(),
        ground_track_crossings: GroundTrackCrossings.capabilities(),
        target_visibility: TargetVisibility.capabilities(),
        frame_transform: FrameTransform.capabilities(),
        orbit_elements: OrbitElements.capabilities(),
        orbit_data: OrbitData.capabilities()
      },
      planning: %{
        mission_plan_activity: MissionPlan.Activity.capabilities(),
        activity_templates: ActivityTemplateCatalog.capabilities(),
        candidate_refresh: CandidateRefresh.capabilities(),
        optimizer: Optimizer.capabilities(),
        subsystem_models: SubsystemModel.capabilities(),
        search: %{
          grid: Grid.capabilities(),
          local: Local.capabilities(),
          monte_carlo: MonteCarlo.capabilities()
        }
      },
      operations: %{
        timeline: Timeline.capabilities(),
        timeline_feedback: TimelineFeedback.capabilities(),
        command_window: CommandWindow.capabilities(),
        contact_intent: ContactIntent.capabilities(),
        station_calendar: StationCalendar.capabilities(),
        contact_contention: ContactContention.capabilities(),
        contact_allocation: ContactAllocation.capabilities(),
        downlink_link_budget: DownlinkLinkBudget.capabilities(),
        link_capacity: LinkCapacity.capabilities(),
        contact_filter: ContactFilter.capabilities(),
        resource_summary: ResourceSummary.capabilities(),
        resource_filter: ResourceFilter.capabilities(),
        resource_projection: ResourceProjection.capabilities(),
        resource_state_trace: ResourceStateTrace.capabilities(),
        policy: Policy.capabilities(),
        operator_review: OperatorReview.capabilities(),
        maneuver_review: ManeuverReview.capabilities(),
        cadence_import: CadenceImport.capabilities(),
        operational_readiness: OperationalReadiness.capabilities()
      },
      environment: %{
        models: Environment.model_capabilities(),
        providers: Environment.provider_capabilities()
      },
      constraints: %{
        artifact_metric: ArtifactMetric.capabilities(),
        campaign_local: CampaignLocal.capabilities()
      },
      validation: %{
        schema: Schema.capabilities(),
        models: Validation.capabilities()
      },
      reporting: %{
        result_set: ResultSetReport.capabilities(),
        study_benchmark: StudyBenchmarkReport.capabilities()
      }
    }
  end

  @doc """
  Returns the public capability catalog as a lintable, JSON-facing artifact map.
  """
  def capability_catalog_artifact do
    capability_catalog()
    |> json_safe_capability_value()
    |> Map.merge(%{
      "schema_contract" => "capability_catalog.v1",
      "schema_version" => 1,
      "model" => "public_capability_catalog"
    })
  end

  @doc """
  Builds a candidate refresh artifact from a completed study result set.
  """
  def candidate_refresh(result_set, opts \\ []) do
    CandidateRefresh.build(result_set, opts)
  end

  @doc """
  Summarizes candidate-refresh source-report provenance without mutating refresh state.
  """
  def candidate_refresh_source_report_summary(refresh_or_artifact) do
    CandidateRefresh.source_report_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local operational-readiness replay provenance without mutating refresh state.
  """
  def candidate_refresh_operational_readiness_replay_summary(refresh_or_artifact) do
    CandidateRefresh.operational_readiness_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local quality-gate replay provenance without mutating refresh state.
  """
  def candidate_refresh_quality_gate_replay_summary(refresh_or_artifact) do
    CandidateRefresh.quality_gate_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local model-acceptance replay provenance without mutating refresh state.
  """
  def candidate_refresh_model_acceptance_replay_summary(refresh_or_artifact) do
    CandidateRefresh.model_acceptance_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local validation-safety-case replay provenance without mutating refresh state.
  """
  def candidate_refresh_validation_safety_case_replay_summary(refresh_or_artifact) do
    CandidateRefresh.validation_safety_case_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local freshness replay provenance without mutating refresh state.
  """
  def candidate_refresh_freshness_replay_summary(refresh_or_artifact) do
    CandidateRefresh.freshness_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local refresh-budget replay provenance without mutating refresh state.
  """
  def candidate_refresh_refresh_budget_replay_summary(refresh_or_artifact) do
    CandidateRefresh.refresh_budget_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local schema-validation replay provenance without mutating refresh state.
  """
  def candidate_refresh_schema_validation_replay_summary(refresh_or_artifact) do
    CandidateRefresh.schema_validation_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local candidate-diff replay provenance without mutating refresh state.
  """
  def candidate_refresh_candidate_diff_replay_summary(refresh_or_artifact) do
    CandidateRefresh.candidate_diff_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local candidate-rejection replay provenance without mutating refresh state.
  """
  def candidate_refresh_candidate_rejection_replay_summary(refresh_or_artifact) do
    CandidateRefresh.candidate_rejection_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local provider-counteroffer replay provenance without mutating refresh state.
  """
  def candidate_refresh_provider_counteroffer_replay_summary(refresh_or_artifact) do
    CandidateRefresh.provider_counteroffer_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local contact-contention replay provenance without mutating refresh state.
  """
  def candidate_refresh_contact_contention_replay_summary(refresh_or_artifact) do
    CandidateRefresh.contact_contention_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local contact-contention-resolution replay provenance without mutating refresh state.
  """
  def candidate_refresh_contact_contention_resolution_replay_summary(refresh_or_artifact) do
    CandidateRefresh.contact_contention_resolution_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local contact-allocation replay provenance without mutating refresh state.
  """
  def candidate_refresh_contact_allocation_replay_summary(refresh_or_artifact) do
    CandidateRefresh.contact_allocation_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local link-capacity replay provenance without mutating refresh state.
  """
  def candidate_refresh_link_capacity_replay_summary(refresh_or_artifact) do
    CandidateRefresh.link_capacity_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local contact-filter replay provenance without mutating refresh state.
  """
  def candidate_refresh_contact_filter_replay_summary(refresh_or_artifact) do
    CandidateRefresh.contact_filter_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local resource-filter replay provenance without mutating refresh state.
  """
  def candidate_refresh_resource_filter_replay_summary(refresh_or_artifact) do
    CandidateRefresh.resource_filter_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local resource-projection replay provenance without mutating refresh state.
  """
  def candidate_refresh_resource_projection_replay_summary(refresh_or_artifact) do
    CandidateRefresh.resource_projection_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local storage/downlink pressure replay provenance without mutating refresh state.
  """
  def candidate_refresh_storage_downlink_pressure_replay_summary(refresh_or_artifact) do
    CandidateRefresh.storage_downlink_pressure_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local station-calendar replay provenance without mutating refresh state.
  """
  def candidate_refresh_station_calendar_replay_summary(refresh_or_artifact) do
    CandidateRefresh.station_calendar_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local station-reservation replay provenance without mutating refresh state.
  """
  def candidate_refresh_station_reservation_replay_summary(refresh_or_artifact) do
    CandidateRefresh.station_reservation_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local command-window replay provenance without mutating refresh state.
  """
  def candidate_refresh_command_window_replay_summary(refresh_or_artifact) do
    CandidateRefresh.command_window_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local maneuver-review replay provenance without mutating refresh state.
  """
  def candidate_refresh_maneuver_review_replay_summary(refresh_or_artifact) do
    CandidateRefresh.maneuver_review_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local contact-intent replay provenance without mutating refresh state.
  """
  def candidate_refresh_contact_intent_replay_summary(refresh_or_artifact) do
    CandidateRefresh.contact_intent_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-diff replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_diff_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_diff_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-integrity replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_integrity_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_integrity_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline activity-state replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_activity_state_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_activity_state_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline activity-status-state replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_activity_status_state_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_activity_status_state_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline activity-approval-state replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_activity_approval_state_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_activity_approval_state_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline activity-lifecycle-state replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_activity_lifecycle_state_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline activity-precondition replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_activity_precondition_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_activity_precondition_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-preservation replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_preservation_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_preservation_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline lifecycle-state replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_lifecycle_state_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_lifecycle_state_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline dependency-impact replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_dependency_impact_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_dependency_impact_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-publication replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_publication_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_publication_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-transition-application replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_transition_application_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_transition_application_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local objective-gap replay provenance without mutating refresh state.
  """
  def candidate_refresh_objective_gap_replay_summary(refresh_or_artifact) do
    CandidateRefresh.objective_gap_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local constraint replay provenance without mutating refresh state.
  """
  def candidate_refresh_constraint_replay_summary(refresh_or_artifact) do
    CandidateRefresh.constraint_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local timeline-feedback replay provenance without mutating refresh state.
  """
  def candidate_refresh_timeline_feedback_replay_summary(refresh_or_artifact) do
    CandidateRefresh.timeline_feedback_replay_summary(refresh_or_artifact)
  end

  @doc """
  Summarizes branch-local operational-timeline replay provenance without mutating refresh state.
  """
  def candidate_refresh_operational_timeline_replay_summary(refresh_or_artifact) do
    CandidateRefresh.operational_timeline_replay_summary(refresh_or_artifact)
  end

  @doc """
  Builds a V1 campaign-plan artifact from a completed study result set.
  """
  def campaign_plan(result_set, opts \\ []) do
    CampaignPlanner.build(result_set, opts)
  end

  @doc """
  Builds a V1 campaign plan through the opt-in bounded local-search selector.

  Every alternative is evaluated by the unchanged V1 greedy orchestration. The
  returned plan carries an optimizer search trace, or the function returns
  `{:no_selected_plan, trace}` when hard feasibility excludes every alternative.
  """
  def campaign_plan_with_local_search(result_set, opts) do
    CampaignPlanner.build_with_local_search(result_set, opts)
  end

  @doc """
  Builds a V2 rolling campaign-repair artifact.
  """
  def campaign_repair(request) do
    CampaignPlanner.repair(request)
  end

  @doc """
  Builds a V3 campaign-strategy comparison artifact.
  """
  def campaign_strategy(request) do
    CampaignPlanner.strategy(request)
  end

  @doc """
  Loads a JSON V2 campaign repair request file and returns a repair artifact.
  """
  def campaign_repair_from_file!(path, opts \\ []) do
    CampaignPlanner.repair_from_file!(path, opts)
  end

  @doc """
  Loads a JSON V3 campaign strategy request file and returns a strategy artifact.
  """
  def campaign_strategy_from_file!(path, opts \\ []) do
    CampaignPlanner.strategy_from_file!(path, opts)
  end

  @doc """
  Validates a JSON V2/V3 campaign request file without running planning.
  """
  def campaign_request_validation_report(type, path, opts \\ []) do
    CampaignPlanner.request_validation_report(type, path, opts)
  end

  @doc """
  Builds a typed mission-plan activity from an atom-keyed or JSON/string-keyed map.
  """
  def mission_plan_activity_from_map!(activity) do
    MissionPlan.Activity.from_map!(activity)
  end

  @doc """
  Public facade alias for `mission_plan_activity_from_map!/1`.
  """
  def mission_plan_activity_from_map(activity) do
    mission_plan_activity_from_map!(activity)
  end

  @doc """
  Returns a string-keyed mission-plan activity map for JSON-facing artifacts.
  """
  def mission_plan_activity_to_artifact_map(activity) do
    MissionPlan.Activity.to_artifact_map(activity)
  end

  @doc """
  Returns a mission-plan activity with a validated lifecycle status.
  """
  def mission_plan_activity_put_status!(activity, status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.put_status!(status)
  end

  @doc """
  Public facade alias for `mission_plan_activity_put_status!/2`.
  """
  def mission_plan_activity_put_status(activity, status) do
    mission_plan_activity_put_status!(activity, status)
  end

  @doc """
  Describes whether a mission-plan activity lifecycle status change is safe to apply.
  """
  def mission_plan_activity_status_transition(activity, status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.status_transition(status)
  end

  @doc """
  Returns a mission-plan activity with a validated, safe lifecycle status change.
  """
  def mission_plan_activity_transition_status!(activity, status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.transition_status!(status)
  end

  @doc """
  Public facade alias for `mission_plan_activity_transition_status!/2`.
  """
  def mission_plan_activity_transition_status(activity, status) do
    mission_plan_activity_transition_status!(activity, status)
  end

  @doc """
  Summarizes state and resource preconditions carried by a mission-plan activity.
  """
  def mission_plan_activity_precondition_summary(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.precondition_summary()
  end

  @doc """
  Returns a mission-plan activity with a validated approval status.
  """
  def mission_plan_activity_put_approval_status!(activity, approval_status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.put_approval_status!(approval_status)
  end

  @doc """
  Public facade alias for `mission_plan_activity_put_approval_status!/2`.
  """
  def mission_plan_activity_put_approval_status(activity, approval_status) do
    mission_plan_activity_put_approval_status!(activity, approval_status)
  end

  @doc """
  Describes whether a mission-plan activity approval-status change is safe to apply.
  """
  def mission_plan_activity_approval_transition(activity, approval_status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.approval_transition(approval_status)
  end

  @doc """
  Returns a mission-plan activity with a validated, safe approval-status change.
  """
  def mission_plan_activity_transition_approval_status!(activity, approval_status) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.transition_approval_status!(approval_status)
  end

  @doc """
  Public facade alias for `mission_plan_activity_transition_approval_status!/2`.
  """
  def mission_plan_activity_transition_approval_status(activity, approval_status) do
    mission_plan_activity_transition_approval_status!(activity, approval_status)
  end

  @doc """
  Applies a normalized lifecycle event to a mission-plan activity.
  """
  def mission_plan_activity_apply_lifecycle_event!(activity, event) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.apply_lifecycle_event!(event)
  end

  @doc """
  Public facade alias for `mission_plan_activity_apply_lifecycle_event!/2`.
  """
  def mission_plan_activity_apply_lifecycle_event(activity, event) do
    mission_plan_activity_apply_lifecycle_event!(activity, event)
  end

  @doc """
  Marks a mission-plan activity approved without executing external work.
  """
  def mission_plan_activity_approve!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.approve!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_approve!/1`.
  """
  def mission_plan_activity_approve(activity) do
    mission_plan_activity_approve!(activity)
  end

  @doc """
  Marks a mission-plan activity rejected for operator review/audit.
  """
  def mission_plan_activity_reject!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.reject!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_reject!/1`.
  """
  def mission_plan_activity_reject(activity) do
    mission_plan_activity_reject!(activity)
  end

  @doc """
  Locks a mission-plan activity so downstream planners can preserve it.
  """
  def mission_plan_activity_lock!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.lock!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_lock!/1`.
  """
  def mission_plan_activity_lock(activity) do
    mission_plan_activity_lock!(activity)
  end

  @doc """
  Records that a mission-plan activity has entered execution.
  """
  def mission_plan_activity_start_execution!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.start_execution!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_start_execution!/1`.
  """
  def mission_plan_activity_start_execution(activity) do
    mission_plan_activity_start_execution!(activity)
  end

  @doc """
  Records that a mission-plan activity has executed.
  """
  def mission_plan_activity_record_execution!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.record_execution!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_record_execution!/1`.
  """
  def mission_plan_activity_record_execution(activity) do
    mission_plan_activity_record_execution!(activity)
  end

  @doc """
  Records that a mission-plan activity completed successfully.
  """
  def mission_plan_activity_record_completion!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.record_completion!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_record_completion!/1`.
  """
  def mission_plan_activity_record_completion(activity) do
    mission_plan_activity_record_completion!(activity)
  end

  @doc """
  Records that a mission-plan activity partially completed.
  """
  def mission_plan_activity_record_partial!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.record_partial!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_record_partial!/1`.
  """
  def mission_plan_activity_record_partial(activity) do
    mission_plan_activity_record_partial!(activity)
  end

  @doc """
  Records that a mission-plan activity failed.
  """
  def mission_plan_activity_record_failure!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.record_failure!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_record_failure!/1`.
  """
  def mission_plan_activity_record_failure(activity) do
    mission_plan_activity_record_failure!(activity)
  end

  @doc """
  Records that a mission-plan activity was missed.
  """
  def mission_plan_activity_record_miss!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.record_miss!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_record_miss!/1`.
  """
  def mission_plan_activity_record_miss(activity) do
    mission_plan_activity_record_miss!(activity)
  end

  @doc """
  Records that a mission-plan activity was delayed.
  """
  def mission_plan_activity_delay!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.delay!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_delay!/1`.
  """
  def mission_plan_activity_delay(activity) do
    mission_plan_activity_delay!(activity)
  end

  @doc """
  Records that a mission-plan activity has been canceled.
  """
  def mission_plan_activity_cancel!(activity) do
    activity
    |> MissionPlan.Activity.from_map!()
    |> MissionPlan.Activity.cancel!()
  end

  @doc """
  Public facade alias for `mission_plan_activity_cancel!/1`.
  """
  def mission_plan_activity_cancel(activity) do
    mission_plan_activity_cancel!(activity)
  end

  @doc """
  Returns the executable artifact contracts known to the schema registry.
  """
  def artifact_contracts do
    Schema.contracts()
  end

  @doc """
  Validates an artifact map against the inferred or requested schema contract.
  """
  def validate_artifact(artifact, opts \\ []) do
    Schema.validate_artifact(artifact, opts)
  end

  @doc """
  Builds a `schema_validation_report.v1` artifact for one artifact map.
  """
  def schema_validation_report(artifact, opts \\ []) do
    Schema.validation_report(artifact, opts)
  end

  @doc """
  Exports a compatibility JSON Schema for one artifact contract.
  """
  def artifact_json_schema(name) do
    Schema.json_schema(name)
  end

  @doc """
  Exports the compatibility JSON Schema bundle for all public artifact contracts.
  """
  def artifact_json_schema_bundle do
    Schema.json_schema_bundle()
  end

  @doc """
  Returns the built-in artifact-only approval policy bundles.
  """
  def policy_bundles do
    Policy.bundles()
  end

  @doc """
  Returns one built-in approval policy bundle by ID.
  """
  def policy_bundle!(id) do
    Policy.bundle!(id)
  end

  @doc """
  Returns one built-in approval policy bundle as a lintable artifact map.
  """
  def policy_bundle_artifact!(id) do
    Policy.bundle_artifact!(id)
  end

  @doc """
  Returns built-in approval policy bundles as lintable artifact maps.
  """
  def policy_bundle_artifacts do
    Policy.bundle_artifacts()
  end

  @doc """
  Builds a schema-valid organization-specific policy bundle.
  """
  def organization_policy_bundle(id, approval_policy, opts \\ []) do
    Policy.organization_policy_bundle(id, approval_policy, opts)
  end

  @doc """
  Normalizes approval policy maps into deterministic string-keyed maps.
  """
  def normalize_approval_policy(policy) do
    Policy.normalize_approval_policy(policy)
  end

  @doc """
  Classifies approval requirements, risks, branch events, and candidate-plan context.
  """
  def policy_decision(approval_requirements, risk_indicators, branch, candidate_plan, policy) do
    Policy.decide(approval_requirements, risk_indicators, branch, candidate_plan, policy)
  end

  @doc """
  Returns model-validation records by stable ID.
  """
  def validation_registry do
    Validation.registry()
  end

  @doc """
  Fetches one model-validation record by stable ID or implementation module.
  """
  def validation_record(id_or_module) do
    Validation.record(id_or_module)
  end

  @doc """
  Returns validation records relevant to a result set's declared assumptions.
  """
  def validation_records_for_result_set(result_set) do
    Validation.records_for_result_set(result_set)
  end

  @doc """
  Builds a deterministic model-acceptance report for a declared intended use.
  """
  def validation_model_acceptance_report(models, opts \\ []) do
    Validation.model_acceptance_report(models, opts)
  end

  @doc """
  Builds an artifact-only safety-case summary from validation evidence.
  """
  def validation_safety_case_summary(evidence, opts \\ []) do
    Validation.safety_case_summary(evidence, opts)
  end

  @doc """
  Builds an artifact-only schema migration and deprecation report.
  """
  def validation_schema_migration_report(opts \\ []) do
    Validation.schema_migration_report(opts)
  end

  @doc """
  Returns the project-wide validation tolerance policy.
  """
  def validation_tolerance_policy do
    Validation.tolerance_policy()
  end

  @doc """
  Returns backend acceptance tiers for propagator implementations.
  """
  def backend_acceptance_policy do
    Validation.backend_acceptance_policy()
  end

  @doc """
  Returns backend acceptance evidence for one propagator implementation.
  """
  def backend_acceptance_evidence(implementation) do
    Validation.backend_acceptance_evidence(implementation)
  end

  @doc """
  Returns the package/dependency policy for numerical backend modules.
  """
  def dependency_policy do
    Validation.dependency_policy()
  end

  @doc """
  Returns curated validation reference fixtures by stable ID.
  """
  def validation_reference_fixtures do
    Validation.reference_fixtures()
  end

  @doc """
  Fetches one curated validation reference fixture by stable ID.
  """
  def validation_reference_fixture(id) do
    Validation.reference_fixture(id)
  end

  @doc """
  Verifies observations against one curated validation reference fixture.
  """
  def verify_validation_reference_fixture(id, observations) do
    Validation.verify_reference_fixture(id, observations)
  end

  @doc """
  Builds flat observations for product-level artifact contract fixtures.
  """
  def validation_artifact_observations(contract, artifact) do
    Validation.artifact_observations(contract, artifact)
  end

  @doc """
  Builds a deterministic validation reference fixture report.
  """
  def validation_reference_fixture_report(observations_by_fixture) do
    Validation.reference_fixture_report(observations_by_fixture)
  end

  @doc """
  Normalizes external Cartesian state estimates into `accepted_planning_state.v1`.
  """
  def accepted_planning_state(estimates, opts \\ []) do
    OrbitData.accepted_planning_state(estimates, opts)
  end

  @doc """
  Returns environment-model capability records implied by assumptions or a result set.
  """
  def environment_models(%{assumptions: _assumptions} = result_set),
    do: Environment.records_for_result_set(result_set)

  def environment_models(%{"assumptions" => assumptions}) when is_map(assumptions),
    do: Environment.records_for_assumptions(assumptions)

  def environment_models(%{} = assumptions), do: Environment.records_for_assumptions(assumptions)

  @doc """
  Describes the fixed inertial Sun-direction environment assumption.
  """
  def fixed_sun_direction(direction \\ {1.0, 0.0, 0.0}, opts \\ []) do
    Environment.fixed_sun_direction(direction, opts)
  end

  @doc """
  Describes the constant Earth-rotation environment assumption.
  """
  def constant_earth_rotation(opts \\ []) do
    Environment.constant_earth_rotation(opts)
  end

  @doc """
  Validates an environment model capability record.
  """
  def validate_environment_model_capability(record) do
    Environment.validate_capability(record)
  end

  @doc """
  Returns built-in environment model capability records.
  """
  def environment_model_capabilities do
    Environment.model_capabilities()
  end

  @doc """
  Returns internal environment provider capability records.
  """
  def environment_provider_capabilities do
    Environment.provider_capabilities()
  end

  @doc """
  Returns an environment provider capability record for a configured provider adapter.
  """
  def configured_environment_provider_capability(provider, opts \\ []) do
    Environment.configured_provider_capability(provider, opts)
  end

  @doc """
  Verifies and consumes a file-backed tabular Earth-orientation provider input.
  """
  def fetch_tabular_earth_orientation_from_file(path, content_identity, opts \\ []) do
    Environment.fetch_tabular_earth_orientation_from_file(path, content_identity, opts)
  end

  @doc """
  Validates an environment provider capability record.
  """
  def validate_environment_provider_capability(record) do
    Environment.validate_provider_capability(record)
  end

  @doc """
  Returns true when a provider capability covers a requested time span.
  """
  def environment_provider_covers_time_span?(record, request) do
    Environment.provider_covers_time_span?(record, request)
  end

  @doc """
  Returns true when a provider capability supports a requested time span, body, and output.
  """
  def environment_provider_supports_request?(record, request) do
    Environment.provider_supports_request?(record, request)
  end

  @doc """
  Returns true when a configured environment provider adapter supports a request.
  """
  def configured_environment_provider_supports_request?(provider, request, opts \\ []) do
    Environment.configured_provider_supports_request?(provider, request, opts)
  end

  @doc """
  Returns environment provider capability records that support a requested time span, body, and output.
  """
  def environment_provider_capabilities_for_request(request) do
    Environment.provider_capabilities_for_request(request)
  end

  @doc """
  Captures an explicit provider policy for Earth inertial/body-fixed state transforms.
  """
  def frame_transform_provider_policy(provider, opts \\ []) do
    FrameTransform.provider_policy(provider, opts)
  end

  @doc """
  Transforms an Earth state between J2000 inertial and provider-defined Earth-fixed frames.
  """
  def transform_state_frame(state, target_frame, central_body, provider_policy) do
    FrameTransform.transform(state, target_frame, central_body, provider_policy)
  end

  @doc """
  Returns built-in subsystem model capability records.
  """
  def subsystem_model_capabilities do
    SubsystemModel.capabilities()
  end

  @doc """
  Describes the planning-grade battery energy-storage subsystem model.
  """
  def battery_energy_storage_model(opts \\ []) do
    SubsystemModel.battery_energy_storage(opts)
  end

  @doc """
  Describes the planning-grade data-recorder storage subsystem model.
  """
  def data_storage_buffer_model(opts \\ []) do
    SubsystemModel.data_storage_buffer(opts)
  end

  @doc """
  Validates a subsystem model capability record.
  """
  def validate_subsystem_model_capability(record) do
    SubsystemModel.validate_capability(record)
  end

  @doc """
  Imports an orbit-data wrapper or simple state-estimate batch as
  `accepted_planning_state.v1`.
  """
  def import_orbit_data(source, opts \\ []) do
    OrbitData.import_orbit_data(source, opts)
  end

  @doc """
  Verifies and imports a file-backed simple JSON orbit-data input.
  """
  def import_orbit_data_from_file(path, content_identity, opts \\ []) do
    OrbitData.import_orbit_data_from_file(path, content_identity, opts)
  end

  @doc """
  Imports a single-object CCSDS OPM KVN message into `accepted_planning_state.v1`.
  """
  def import_ccsds_opm(kvn, opts \\ []) do
    OrbitData.import_ccsds_opm(kvn, opts)
  end

  @doc """
  Imports a single-object CCSDS OEM KVN message into `accepted_planning_state.v1`.

  Bounded strategy-epoch interpolation is available only through the explicit
  options documented by `OrbitalDynamics.OrbitData.import_ccsds_oem/2`.
  """
  def import_ccsds_oem(kvn, opts \\ []) do
    OrbitData.import_ccsds_oem(kvn, opts)
  end

  @doc """
  Exports an `accepted_planning_state.v1` artifact to deterministic JSON.
  """
  def export_orbit_data_json(artifact) do
    OrbitData.export_simple_json(artifact)
  end

  @doc """
  Exports a single-state `accepted_planning_state.v1` artifact as CCSDS OPM KVN.
  """
  def export_ccsds_opm(artifact, opts \\ []) do
    OrbitData.export_ccsds_opm(artifact, opts)
  end

  @doc """
  Exports a single-state `accepted_planning_state.v1` artifact as CCSDS OEM KVN.
  """
  def export_ccsds_oem(artifact, opts \\ []) do
    OrbitData.export_ccsds_oem(artifact, opts)
  end

  @doc """
  Parses TLE metadata without converting it into a Cartesian planning state.
  """
  def inspect_tle(source, opts \\ []) do
    OrbitData.inspect_tle(source, opts)
  end

  @doc """
  Parses CCSDS OMM KVN metadata without converting it into a Cartesian planning state.
  """
  def inspect_ccsds_omm(source, opts \\ []) do
    OrbitData.inspect_ccsds_omm(source, opts)
  end

  @doc """
  Converts a Cartesian state into two-body osculating orbital elements.
  """
  def orbital_elements(state, central_body_or_mu) do
    OrbitElements.from_state(state, central_body_or_mu)
  end

  @doc """
  Converts two-body osculating orbital elements into a Cartesian state vector.
  """
  def state_from_orbital_elements(elements, central_body_or_mu, opts \\ []) do
    OrbitElements.to_state(elements, central_body_or_mu, opts)
  end

  @doc """
  Returns the executable unit policy used by public structs and artifacts.
  """
  def units_policy, do: Units.policy()

  @doc """
  Returns operational scale targets by maturity level.
  """
  def operational_scale_targets, do: OperationalScale.targets()

  @doc """
  Compares observed metrics with an operational scale target.
  """
  def operational_scale_comparison(level, observed) do
    OperationalScale.compare(level, observed)
  end

  @doc """
  Evaluates provider-backed atmospheric-drag acceleration at one orbital state.

  This standalone evaluator does not propagate the state. See
  `OrbitalDynamics.ForceModels.AtmosphericDrag.evaluate/4` for provider options
  and fidelity limits.
  """
  def atmospheric_drag_acceleration(state, spacecraft, central_body, opts \\ []) do
    AtmosphericDrag.evaluate(state, spacecraft, central_body, opts)
  end

  @doc """
  Evaluates the opt-in scalar J2-plus-drag acceleration component sum.

  The result declares point-mass, J2, atmospheric-drag, and total acceleration
  vectors plus the captured offline provider provenance. No propagation is
  performed.
  """
  def j2_drag_acceleration(state, spacecraft, central_body, opts \\ []) do
    J2Drag.acceleration_components(state, spacecraft, central_body, opts)
  end

  @doc """
  Summarizes a persisted study benchmark with backend acceptance evidence.

  The summary compares matching scalar and accelerator benchmark groups and
  applies the declared backend acceptance policy. It does not rerun a study or
  create performance evidence beyond the supplied artifact.
  """
  def study_benchmark_summary(artifact, opts \\ []) do
    StudyBenchmarkReport.summarize(artifact, opts)
  end

  @doc """
  Compares a benchmark trend summary with an operational scale target.
  """
  def operational_scale_benchmark_trend_comparison(level, trend_summary) do
    OperationalScale.compare_benchmark_trend(level, trend_summary)
  end

  @doc """
  Compares two ranked scenario lists with deterministic rank and value deltas.
  """
  def compare_scenario_rankings(left_rows, right_rows, opts \\ []) do
    Optimizer.compare_rankings(left_rows, right_rows, opts)
  end

  @doc """
  Builds a schema-versioned ranking comparison report for two ranked scenario lists.
  """
  def ranking_comparison_report(left_rows, right_rows, opts \\ []) do
    Optimizer.ranking_comparison_report(left_rows, right_rows, opts)
  end

  @doc """
  Builds a schema-versioned Pareto-frontier report for objective vectors.
  """
  def pareto_frontier_report(rows, opts \\ []) do
    Optimizer.pareto_frontier_report(rows, opts)
  end

  @doc """
  Generates and evaluates one deterministic, bounded, explainable local neighborhood.
  """
  def explainable_local_search(seed_parameters, score_terms_fun, opts \\ []) do
    Optimizer.explainable_local_search(seed_parameters, score_terms_fun, opts)
  end

  @doc """
  Emits an executable certificate for opt-in exact enumeration of one complete
  bounded local neighborhood.

  Any supported best-alternative claim is limited to the declared finite search
  space; the default heuristic and campaign-planner paths are unchanged.
  """
  def certified_local_search(seed_parameters, source_evidence, evaluator_fun, opts) do
    Optimizer.certified_local_search(seed_parameters, source_evidence, evaluator_fun, opts)
  end

  @doc """
  Verifies a local-search certificate by exact replay against trusted inputs.
  """
  def verify_local_search_certificate(
        certificate,
        seed_parameters,
        source_evidence,
        evaluator_fun,
        opts
      ) do
    Optimizer.verify_local_search_certificate(
      certificate,
      seed_parameters,
      source_evidence,
      evaluator_fun,
      opts
    )
  end

  @doc """
  Evaluates artifact-level metric constraints against a persisted result artifact.

  Returns one deterministic row per scenario/constraint pair. This uses saved
  artifact metrics only; it does not rerun propagation.
  """
  def evaluate_artifact_metric_constraints(artifact, constraints) do
    ArtifactMetric.evaluate_all(artifact, constraints)
  end

  @doc """
  Builds a `constraint_report.v1` artifact from artifact-level metric constraints.

  The report can be passed to `operator_review_package/1` or
  `cadence_import_manifest/2` for review-gated constraint handoff.
  """
  def artifact_metric_constraint_report(artifact, constraints) do
    ArtifactMetric.report(artifact, constraints)
  end

  @doc """
  Builds a `constraint_report.v1` artifact from campaign-local planner constraints.

  This exposes the same V1/V2 campaign constraint row model used in campaign
  artifacts for callers that already have candidate activities, ranked
  timelines, and optional resource/link reports.
  """
  def campaign_local_constraint_report(
        candidates,
        timelines,
        constraints,
        resource_projection_report \\ nil,
        link_capacity_report \\ nil,
        opts \\ []
      ) do
    CampaignLocal.report(
      candidates,
      timelines,
      constraints,
      resource_projection_report,
      link_capacity_report,
      opts
    )
  end

  @doc """
  Reconciles planned activities with realized feedback rows.
  """
  def reconcile_timeline_feedback(planned_activities, realized_activities, opts \\ []) do
    TimelineFeedback.reconcile(planned_activities, realized_activities, opts)
  end

  @doc """
  Derives V3-compatible operational feedback from timeline feedback rows or a
  timeline feedback report with string or atom keys.
  """
  def timeline_operational_feedback(report_or_rows) do
    TimelineFeedback.operational_feedback(report_or_rows)
  end

  @doc """
  Normalizes one planned/realized activity pair into a compact timeline state.
  """
  def timeline_activity_state(planned_activity, realized_activity, opts \\ []) do
    TimelineFeedback.activity_state(planned_activity, realized_activity, opts)
  end

  @doc """
  Normalizes one realized timeline activity feedback row.
  """
  def normalize_realized_timeline_activity(activity, opts \\ []) do
    TimelineFeedback.normalize_realized_activity(activity, opts)
  end

  @doc """
  Normalizes realized timeline activity feedback rows.
  """
  def normalize_realized_timeline_activities(activities, opts \\ []) do
    TimelineFeedback.normalize_realized_activities(activities, opts)
  end

  @doc """
  Builds an operational timeline report for planned activities.
  """
  def operational_timeline_report(activities, opts \\ []) do
    Timeline.operational_report(activities, opts)
  end

  @doc """
  Builds an artifact-only candidate rejection explanation report.
  """
  def candidate_rejection_report(candidate_activities, opts \\ []) do
    Timeline.candidate_rejection_report(candidate_activities, opts)
  end

  @doc """
  Builds an artifact-only provider counteroffer review report.
  """
  def provider_counteroffer_report(station_calendar_or_report, opts \\ []) do
    StationCalendar.provider_counteroffer_report(station_calendar_or_report, opts)
  end

  @doc """
  Builds a compact artifact-only provider counteroffer review summary.
  """
  def provider_counteroffer_review_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.provider_counteroffer_review_summary(station_calendar_or_report, opts)
  end

  @doc """
  Builds a compact artifact-only provider counteroffer import-readiness summary.
  """
  def provider_counteroffer_import_readiness_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.provider_counteroffer_import_readiness_summary(
      station_calendar_or_report,
      opts
    )
  end

  @doc """
  Builds a compact artifact-only provider counteroffer plan-impact summary.
  """
  def provider_counteroffer_plan_impact_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.provider_counteroffer_plan_impact_summary(station_calendar_or_report, opts)
  end

  @doc """
  Builds a compact artifact-only station reservation review summary.
  """
  def station_reservation_review_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.reservation_review_summary(station_calendar_or_report, opts)
  end

  def station_reservation_review_summary(contacts, station_calendar, opts) do
    StationCalendar.reservation_review_summary(contacts, station_calendar, opts)
  end

  @doc """
  Builds a compact artifact-only station reservation-hold summary.
  """
  def station_reservation_hold_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.reservation_hold_summary(station_calendar_or_report, opts)
  end

  def station_reservation_hold_summary(contacts, station_calendar, opts) do
    StationCalendar.reservation_hold_summary(contacts, station_calendar, opts)
  end

  @doc """
  Builds a compact artifact-only station reservation-hold import-readiness summary.
  """
  def station_reservation_hold_import_readiness_summary(station_calendar_or_report, opts \\ []) do
    StationCalendar.reservation_hold_import_readiness_summary(station_calendar_or_report, opts)
  end

  def station_reservation_hold_import_readiness_summary(contacts, station_calendar, opts) do
    StationCalendar.reservation_hold_import_readiness_summary(contacts, station_calendar, opts)
  end

  @doc """
  Normalizes one planned activity into the shared operational timeline shape.
  """
  def normalize_timeline_activity(activity, opts \\ []) do
    Timeline.normalize_activity(activity, opts)
  end

  @doc """
  Normalizes planned activities into shared operational timeline activity rows.
  """
  def normalize_timeline_activities(activities, opts \\ []) do
    Timeline.normalize_activities(activities, opts)
  end

  @doc """
  Returns deterministic activity template artifacts for baseline planning activity types.
  """
  def activity_templates do
    ActivityTemplateCatalog.templates()
  end

  @doc """
  Looks up one baseline activity template by template id or activity type.
  """
  def activity_template(id_or_activity_type) when is_binary(id_or_activity_type) do
    ActivityTemplateCatalog.template(id_or_activity_type)
  end

  def activity_template(_id_or_activity_type), do: :error

  @doc """
  Instantiates an activity template into a normalized timeline activity row.
  """
  def activity_from_template(template_or_id, fields \\ %{})

  def activity_from_template(template_or_id, fields) when is_map(fields) do
    ActivityTemplateCatalog.activity(template_or_id, fields)
  end

  def activity_from_template(_template_or_id, _fields),
    do: {:error, %{reason: "invalid_activity_template_fields"}}

  @doc """
  Builds an artifact-only timeline diff report for source and replacement activities.
  """
  def timeline_diff_report(timeline_diff_report) do
    Timeline.diff_report(timeline_diff_report)
  end

  def timeline_diff_report(source_activities, replacement_activities, opts \\ []) do
    Timeline.diff_report(source_activities, replacement_activities, opts)
  end

  @doc """
  Builds a compact artifact-only summary for a timeline diff report.
  """
  def timeline_diff_summary(timeline_diff_report) do
    Timeline.diff_summary(timeline_diff_report)
  end

  def timeline_diff_summary(source_activities, replacement_activities, opts \\ []) do
    Timeline.diff_summary(source_activities, replacement_activities, opts)
  end

  @doc """
  Returns the persistent or derived timeline identity for one activity.
  """
  def timeline_identity(activity) do
    Timeline.timeline_identity(activity)
  end

  @doc """
  Returns the durable timeline identity and operational context for one activity.
  """
  def timeline_activity_context(activity) do
    Timeline.activity_context(activity)
  end

  @doc """
  Summarizes state and resource preconditions carried by one timeline activity.
  """
  def timeline_activity_precondition_summary(activity) do
    Timeline.activity_precondition_summary(activity)
  end

  @doc """
  Builds a stable source-to-replacement timeline link for repair/import rows.
  """
  def timeline_link(source_activity, replacement_activity) do
    Timeline.timeline_link(source_activity, replacement_activity)
  end

  @doc """
  Builds typed status and approval transition objects for source/replacement activities.
  """
  def timeline_activity_transition(source_activity, replacement_activity) do
    Timeline.activity_transition(source_activity, replacement_activity)
  end

  @doc """
  Normalizes planned/realized activity status into a compact review/import state.
  """
  def timeline_activity_status_state(planned_activity, realized_activity) do
    Timeline.activity_status_state(planned_activity, realized_activity)
  end

  @doc """
  Normalizes planned/realized activity approval status into a compact review/import state.
  """
  def timeline_activity_approval_state(planned_activity, realized_activity) do
    Timeline.activity_approval_state(planned_activity, realized_activity)
  end

  @doc """
  Normalizes planned/realized activity lifecycle state into a compact review/import state.
  """
  def timeline_activity_lifecycle_state(planned_activity, realized_activity) do
    Timeline.activity_lifecycle_state(planned_activity, realized_activity)
  end

  @doc """
  Summarizes planned/realized lifecycle state across activity sets.
  """
  def timeline_lifecycle_state_summary(planned_activities, realized_activities, opts \\ []) do
    Timeline.lifecycle_state_summary(planned_activities, realized_activities, opts)
  end

  @doc """
  Builds the typed status transition object for source/replacement activities.
  """
  def timeline_status_transition(source_activity, replacement_activity) do
    Timeline.status_transition(source_activity, replacement_activity)
  end

  @doc """
  Builds the typed approval-status transition object for source/replacement activities.
  """
  def timeline_approval_transition(source_activity, replacement_activity) do
    Timeline.approval_transition(source_activity, replacement_activity)
  end

  @doc """
  Applies a safe lifecycle-status transition to one timeline activity row.
  """
  def timeline_transition_activity_status(activity, status, opts \\ []) do
    Timeline.transition_activity_status(activity, status, opts)
  end

  @doc """
  Applies a safe lifecycle-status transition to one timeline activity row.

  Raises when the transition requires operator review.
  """
  def timeline_transition_activity_status!(activity, status, opts \\ []) do
    Timeline.transition_activity_status!(activity, status, opts)
  end

  @doc """
  Applies a safe approval-status transition to one timeline activity row.
  """
  def timeline_transition_activity_approval_status(activity, approval_status, opts \\ []) do
    Timeline.transition_activity_approval_status(activity, approval_status, opts)
  end

  @doc """
  Applies a safe approval-status transition to one timeline activity row.

  Raises when the transition requires operator review.
  """
  def timeline_transition_activity_approval_status!(activity, approval_status, opts \\ []) do
    Timeline.transition_activity_approval_status!(activity, approval_status, opts)
  end

  @doc """
  Applies a normalized lifecycle event to one timeline activity row.
  """
  def timeline_apply_lifecycle_event(activity, event, opts \\ []) do
    Timeline.apply_lifecycle_event(activity, event, opts)
  end

  @doc """
  Applies a normalized lifecycle event to one timeline activity row.

  Raises when the resulting status or approval transition requires operator review.
  """
  def timeline_apply_lifecycle_event!(activity, event, opts \\ []) do
    Timeline.apply_lifecycle_event!(activity, event, opts)
  end

  @doc """
  Classifies the artifact-only transition decision for one proposed activity change.
  """
  def timeline_transition_decision(source_activity, replacement_activity, opts \\ []) do
    Timeline.transition_decision(source_activity, replacement_activity, opts)
  end

  @doc """
  Resolves one timeline transition into an artifact-only application plan.
  """
  def timeline_transition_application(source_activity, replacement_activity, opts \\ []) do
    Timeline.transition_application(source_activity, replacement_activity, opts)
  end

  @doc """
  Builds a compact artifact-only summary for a transition application report.
  """
  def timeline_transition_application_summary(transition_application_report) do
    Timeline.transition_application_summary(transition_application_report)
  end

  def timeline_transition_application_summary(
        source_activities,
        replacement_activities,
        opts \\ []
      ) do
    Timeline.transition_application_summary(source_activities, replacement_activities, opts)
  end

  @doc """
  Builds a batch artifact-only application plan for a source and replacement timeline.
  """
  def timeline_transition_application_report(transition_application_report) do
    Timeline.transition_application_report(transition_application_report)
  end

  def timeline_transition_application_report(
        source_activities,
        replacement_activities,
        opts \\ []
      ) do
    Timeline.transition_application_report(source_activities, replacement_activities, opts)
  end

  @doc """
  Purely reapplies a revision-bound transition batch and reports identity conflicts.
  """
  def timeline_replay_transition_application_report(
        source_activities,
        replacement_activities,
        replay_report,
        opts \\ []
      ) do
    Timeline.replay_transition_application_report(
      source_activities,
      replacement_activities,
      replay_report,
      opts
    )
  end

  @doc """
  Returns the normalized activities selected as safe by a transition application report.
  """
  def timeline_transition_selected_activities(transition_application_report) do
    Timeline.transition_selected_activities(transition_application_report)
  end

  @doc """
  Builds a transition application report and returns only its selected safe activities.
  """
  def timeline_transition_selected_activities(
        source_activities,
        replacement_activities,
        opts \\ []
      ) do
    Timeline.transition_selected_activities(source_activities, replacement_activities, opts)
  end

  @doc """
  Classifies whether an operational activity should be preserved, reviewed, or mutable.
  """
  def timeline_protection_decision(activity, opts \\ []) do
    Timeline.protection_decision(activity, opts)
  end

  @doc """
  Builds an artifact-only lifecycle preservation status preflight for one activity.
  """
  def timeline_preservation_status(activity, opts \\ []) do
    Timeline.preservation_status(activity, opts)
  end

  @doc """
  Builds an artifact-only lifecycle preservation summary for timeline activities.
  """
  def timeline_preservation_report(activities, opts \\ []) do
    Timeline.preservation_report(activities, opts)
  end

  @doc """
  Builds an artifact-only downstream dependency impact summary for timeline changes.
  """
  def timeline_dependency_impact_summary(source_activities, replacement_activities, opts \\ []) do
    Timeline.dependency_impact_summary(source_activities, replacement_activities, opts)
  end

  @doc """
  Builds artifact-only timeline publication metadata for downstream handoff.
  """
  def timeline_publication_summary(source_artifact, opts \\ []) do
    Timeline.publication_summary(source_artifact, opts)
  end

  @doc """
  Builds an artifact-only dependency/exclusivity integrity summary for timeline activities.
  """
  def timeline_integrity_report(activities, opts \\ []) do
    Timeline.integrity_report(activities, opts)
  end

  @doc """
  Builds an artifact-only command-window report for planned activities.
  """
  def command_window_report(command_window_report) do
    CommandWindow.report(command_window_report)
  end

  def command_window_report(activities, opts) do
    CommandWindow.report(activities, opts)
  end

  @doc """
  Converts contact-like activities into artifact-only `contact_intent.v1` rows.
  """
  def contact_intents_from_activities(activities, opts \\ []) do
    ContactIntent.from_activities(activities, opts)
  end

  @doc """
  Summarizes contact-intent capacity demand without reserving provider assets.
  """
  def contact_intent_summary(contact_intents) do
    ContactIntent.summary(contact_intents)
  end

  @doc """
  Builds contact intents from activities and summarizes their capacity demand.
  """
  def contact_intent_summary(activities, opts) do
    ContactIntent.summary(activities, opts)
  end

  @doc """
  Converts one contact-like activity into a `contact_intent.v1` row.
  """
  def contact_intent_from_activity!(activity) do
    ContactIntent.from_activity!(activity)
  end

  @doc """
  Builds an artifact-only station-calendar overlay report for contact candidates.
  """
  def station_calendar_report(station_calendar_report) do
    StationCalendar.report(station_calendar_report)
  end

  def station_calendar_report(contacts, station_calendar, opts \\ []) do
    StationCalendar.report(contacts, station_calendar, opts)
  end

  @doc """
  Builds a compact artifact-only station-calendar precedence summary.
  """
  def station_calendar_precedence_summary(station_calendar_report) do
    StationCalendar.precedence_summary(station_calendar_report)
  end

  def station_calendar_precedence_summary(contacts, station_calendar, opts) do
    StationCalendar.precedence_summary(contacts, station_calendar, opts)
  end

  @doc """
  Builds an artifact-only station reservation review summary.
  """
  def station_reservation_report(station_calendar_report, opts \\ []) do
    StationCalendar.reservation_report(station_calendar_report, opts)
  end

  def station_reservation_report(contacts, station_calendar, opts) do
    StationCalendar.reservation_report(contacts, station_calendar, opts)
  end

  @doc """
  Converts declared station-calendar provider artifacts into ground-network intervals.
  """
  def station_calendar_ground_network(provider) do
    StationCalendar.to_ground_network(provider)
  end

  @doc """
  Builds an artifact-only same-station contact contention report.
  """
  def contact_contention_report(contact_contention_report) do
    ContactContention.report(contact_contention_report)
  end

  def contact_contention_report(contacts, opts) do
    ContactContention.report(contacts, opts)
  end

  @doc """
  Annotates contact candidates and returns `{annotated_contacts, contention_report}`.
  """
  def annotate_contact_contention(contacts, opts \\ []) do
    ContactContention.annotate_contacts(contacts, opts)
  end

  @doc """
  Builds an artifact-only advisory contact contention resolution report.
  """
  def contact_contention_resolution_report(contact_contention_resolution_report) do
    ContactContention.resolution_report(contact_contention_resolution_report)
  end

  def contact_contention_resolution_report(contacts, contention_report, opts \\ []) do
    ContactContention.resolution_report(contacts, contention_report, opts)
  end

  @doc """
  Builds a compact artifact-only contact-contention resolution routing summary.
  """
  def contact_contention_resolution_summary(contact_contention_resolution_report) do
    ContactContention.resolution_summary(contact_contention_resolution_report)
  end

  def contact_contention_resolution_summary(contacts, contention_report, opts \\ []) do
    ContactContention.resolution_summary(contacts, contention_report, opts)
  end

  @doc """
  Allocates contact candidates into artifact-only allocated/deferred/blocked rows.

  The second argument may be normalized ground-network rows or a declared
  `station_calendar_provider.v1` object. Provider inputs are normalized locally;
  this does not reserve provider time or mutate schedules.

  Pass `resource_summaries: [...]` to run the same planning-grade resource
  availability and margin filter before station allocation.
  """
  def allocate_contacts(contacts, ground_network \\ [], opts \\ []) do
    ContactAllocation.allocate_contacts(contacts, ground_network, opts)
  end

  @doc """
  Builds an artifact-only contact allocation report for candidate activities.

  The second argument may be normalized ground-network rows or a declared
  `station_calendar_provider.v1` object. Provider inputs are normalized locally;
  this does not reserve provider time or mutate schedules.

  Pass `resource_summaries: [...]` to embed a `resource_filter_report.v1` and
  preserve resource-suppressed contacts as blocked allocation rows.
  """
  def contact_allocation_report(contact_allocation_report) do
    ContactAllocation.report(contact_allocation_report)
  end

  def contact_allocation_report(contacts, ground_network, opts \\ []) do
    ContactAllocation.report(contacts, ground_network, opts)
  end

  @doc """
  Builds a compact artifact-only contact allocation triage summary.
  """
  def contact_allocation_summary(contact_allocation_report) do
    ContactAllocation.summary(contact_allocation_report)
  end

  def contact_allocation_summary(contact_allocation_report, opts)
      when is_map(contact_allocation_report) and is_list(opts) do
    ContactAllocation.summary(contact_allocation_report, opts)
  end

  def contact_allocation_summary(contacts, ground_network) do
    ContactAllocation.summary(contacts, ground_network, [])
  end

  def contact_allocation_summary(contacts, ground_network, opts) do
    ContactAllocation.summary(contacts, ground_network, opts)
  end

  @doc """
  Builds a compact artifact-only contact allocation station-pressure summary.
  """
  def contact_allocation_station_pressure_summary(contact_allocation_report) do
    ContactAllocation.station_pressure_summary(contact_allocation_report)
  end

  def contact_allocation_station_pressure_summary(contact_allocation_report, opts)
      when is_map(contact_allocation_report) and is_list(opts) do
    ContactAllocation.station_pressure_summary(contact_allocation_report, opts)
  end

  def contact_allocation_station_pressure_summary(contacts, ground_network) do
    ContactAllocation.station_pressure_summary(contacts, ground_network, [])
  end

  def contact_allocation_station_pressure_summary(contacts, ground_network, opts) do
    ContactAllocation.station_pressure_summary(contacts, ground_network, opts)
  end

  @doc """
  Builds a compact artifact-only contact allocation capacity-pack summary.
  """
  def contact_allocation_capacity_pack_summary(contact_allocation_report) do
    ContactAllocation.capacity_pack_summary(contact_allocation_report)
  end

  def contact_allocation_capacity_pack_summary(contact_allocation_report, opts)
      when is_map(contact_allocation_report) and is_list(opts) do
    ContactAllocation.capacity_pack_summary(contact_allocation_report, opts)
  end

  def contact_allocation_capacity_pack_summary(contacts, ground_network) do
    ContactAllocation.capacity_pack_summary(contacts, ground_network, [])
  end

  def contact_allocation_capacity_pack_summary(contacts, ground_network, opts) do
    ContactAllocation.capacity_pack_summary(contacts, ground_network, opts)
  end

  @doc """
  Builds a compact artifact-only contact allocation reservation-conflict summary.
  """
  def contact_allocation_reservation_conflict_summary(contact_allocation_report) do
    ContactAllocation.reservation_conflict_summary(contact_allocation_report)
  end

  def contact_allocation_reservation_conflict_summary(contact_allocation_report, opts)
      when is_map(contact_allocation_report) and is_list(opts) do
    ContactAllocation.reservation_conflict_summary(contact_allocation_report, opts)
  end

  def contact_allocation_reservation_conflict_summary(contacts, ground_network) do
    ContactAllocation.reservation_conflict_summary(contacts, ground_network, [])
  end

  def contact_allocation_reservation_conflict_summary(contacts, ground_network, opts) do
    ContactAllocation.reservation_conflict_summary(contacts, ground_network, opts)
  end

  @doc """
  Builds an artifact-only contact allocation provider-reservation request summary.
  """
  def contact_allocation_provider_reservation_request_summary(contact_allocation_report) do
    ContactAllocation.provider_reservation_request_summary(contact_allocation_report)
  end

  def contact_allocation_provider_reservation_request_summary(contact_allocation_report, opts)
      when is_map(contact_allocation_report) and is_list(opts) do
    ContactAllocation.provider_reservation_request_summary(contact_allocation_report, opts)
  end

  def contact_allocation_provider_reservation_request_summary(contacts, ground_network) do
    ContactAllocation.provider_reservation_request_summary(contacts, ground_network, [])
  end

  def contact_allocation_provider_reservation_request_summary(contacts, ground_network, opts) do
    ContactAllocation.provider_reservation_request_summary(contacts, ground_network, opts)
  end

  @doc """
  Builds deterministic schema-backed evidence for one fixed one-way downlink mode.
  """
  def downlink_link_budget(contact, params) do
    DownlinkLinkBudget.build(contact, params)
  end

  @doc """
  Builds an artifact-only fixed-rate link-capacity report.
  """
  def link_capacity_report(link_capacity_report) do
    LinkCapacity.report(link_capacity_report)
  end

  def link_capacity_report(contacts, selected_contacts, opts \\ []) do
    LinkCapacity.report(contacts, selected_contacts, opts)
  end

  @doc """
  Builds a compact artifact-only link-capacity triage summary.
  """
  def link_capacity_summary(link_capacity_report) do
    LinkCapacity.summary(link_capacity_report)
  end

  def link_capacity_summary(contacts, selected_contacts, opts \\ []) do
    LinkCapacity.summary(contacts, selected_contacts, opts)
  end

  @doc """
  Builds an artifact-only relay/store-and-forward data-path summary.
  """
  def relay_data_path_summary(routes, opts \\ []) do
    LinkCapacity.relay_data_path_summary(routes, opts)
  end

  @doc """
  Filters contact candidates using externally supplied ground-network availability
  rows or a `station_calendar_provider.v1` object.
  """
  def filter_contact_candidates(candidates, ground_network, opts \\ []) do
    ContactFilter.filter_candidates(candidates, ground_network, opts)
  end

  @doc """
  Builds an artifact-only contact filter report for candidate activities using
  ground-network rows or a `station_calendar_provider.v1` object.
  """
  def contact_filter_report(contact_filter_report) do
    ContactFilter.report(contact_filter_report)
  end

  def contact_filter_report(candidates, ground_network, opts \\ []) do
    ContactFilter.report(candidates, ground_network, opts)
  end

  @doc """
  Filters candidate activities using planning-grade resource summaries.
  """
  def filter_resource_candidates(candidates, summaries, opts \\ []) do
    ResourceFilter.filter_candidates(candidates, summaries, opts)
  end

  @doc """
  Normalizes resource-filter policy thresholds without filtering candidates.
  """
  def resource_filter_policy(policy) do
    ResourceFilter.resource_filter_policy(policy)
  end

  @doc """
  Normalizes one externally supplied planning-grade resource summary.
  """
  def resource_summary_from_map!(source) do
    ResourceSummary.from_map!(source)
  end

  @doc """
  Converts one planning-grade resource summary to a `resource_summary.v1` row.
  """
  def resource_summary_to_map(summary) do
    ResourceSummary.to_map(summary)
  end

  @doc """
  Converts planning-grade resource summaries to `resource_summary.v1` rows.
  """
  def resource_summaries_to_maps(summaries) do
    ResourceSummary.to_maps(summaries)
  end

  @doc """
  Projects one planning-grade resource summary across selected activities.
  """
  def resource_summary_roll_forward(summary, selected_activities, opts \\ []) do
    ResourceSummary.roll_forward(summary, selected_activities, opts)
  end

  @doc """
  Builds an artifact-only resource filter report for candidate activities.
  """
  def resource_filter_report(resource_filter_report) do
    ResourceFilter.report(resource_filter_report)
  end

  def resource_filter_report(candidates, summaries, opts \\ []) do
    ResourceFilter.report(candidates, summaries, opts)
  end

  @doc """
  Builds a compact artifact-only resource filter suppression summary.
  """
  def resource_filter_summary(resource_filter_report) do
    ResourceFilter.summary(resource_filter_report)
  end

  def resource_filter_summary(resource_filter_report, opts)
      when is_map(resource_filter_report) and is_list(opts) do
    ResourceFilter.summary(resource_filter_report, opts)
  end

  def resource_filter_summary(candidates, summaries) do
    ResourceFilter.summary(candidates, summaries, [])
  end

  def resource_filter_summary(candidates, summaries, opts) do
    ResourceFilter.summary(candidates, summaries, opts)
  end

  @doc """
  Builds an artifact-only resource projection report for selected activities.
  """
  def resource_projection_report(resource_projection_report) do
    ResourceProjection.report(resource_projection_report)
  end

  def resource_projection_report(activities, summaries, opts \\ []) do
    ResourceProjection.report(activities, summaries, opts)
  end

  @doc """
  Builds an artifact-only resource projection flow summary for selected activities.
  """
  def resource_projection_flow_report(resource_projection_report) do
    ResourceProjection.flow_report(resource_projection_report)
  end

  def resource_projection_flow_report(activities, summaries, opts \\ []) do
    ResourceProjection.flow_report(activities, summaries, opts)
  end

  @doc """
  Summarizes an existing resource projection report into compact flow evidence.
  """
  def resource_projection_flow_summary(resource_projection_report) do
    ResourceProjection.flow_summary(resource_projection_report)
  end

  @doc """
  Builds a deterministic Tier 1 battery and recorder state trace across selected activities.
  """
  def resource_state_trace(selected_activities, initial_resource_summary, opts \\ []) do
    ResourceStateTrace.trace(selected_activities, initial_resource_summary, opts)
  end

  @doc """
  Builds an artifact-only maneuver review report from maneuver recommendations.
  """
  def maneuver_review_report(recommendations, opts \\ []) do
    ManeuverReview.report(recommendations, opts)
  end

  @doc """
  Builds an artifact-only operator review package from a repair or strategy artifact.
  """
  def operator_review_package(
        %{"schema_contract" => "timeline_transition_application_report.v1"} = artifact,
        opts
      )
      when is_list(opts),
      do: OperatorReview.from_timeline_transition_application_report(artifact, opts)

  def operator_review_package(
        %{schema_contract: "timeline_transition_application_report.v1"} = artifact,
        opts
      )
      when is_list(opts),
      do: OperatorReview.from_timeline_transition_application_report(artifact, opts)

  def operator_review_package(%{"schema_contract" => "operator_review_package.v1"} = artifact),
    do: artifact

  def operator_review_package(%{"schema_contract" => "candidate_refresh.v1"} = artifact),
    do: OperatorReview.from_candidate_refresh_artifact(artifact)

  def operator_review_package(%{"schema_contract" => "result_artifact.v1"} = artifact),
    do: OperatorReview.from_result_artifact(artifact)

  def operator_review_package(
        %{"schema_contract" => "operational_readiness_report.v1"} = artifact
      ),
      do: OperatorReview.from_operational_readiness_report(artifact)

  def operator_review_package(%{"schema_contract" => "quality_gate_report.v1"} = artifact),
    do: OperatorReview.from_quality_gate_report(artifact)

  def operator_review_package(%{"schema_contract" => "model_acceptance_report.v1"} = artifact),
    do: OperatorReview.from_model_acceptance_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "validation_safety_case_summary.v1"} = artifact
      ),
      do: OperatorReview.from_validation_safety_case_summary(artifact)

  def operator_review_package(
        %{"schema_version" => 1, "run" => %{}, "execution_report" => %{}} = artifact
      ),
      do: OperatorReview.from_result_artifact(artifact)

  def operator_review_package(
        %{"schema_contract" => "resource_projection_flow_summary.v1"} = artifact
      ),
      do: OperatorReview.from_resource_projection_flow_summary(artifact)

  def operator_review_package(%{"schema_version" => 1} = artifact),
    do: OperatorReview.from_campaign_artifact(artifact)

  def operator_review_package(%{"schema_version" => 2} = artifact),
    do: OperatorReview.from_repair_artifact(artifact)

  def operator_review_package(%{"schema_version" => 3} = artifact),
    do: OperatorReview.from_strategy_artifact(artifact)

  def operator_review_package(%{"schema_contract" => "timeline_feedback_report.v1"} = artifact),
    do: OperatorReview.from_timeline_feedback_report(artifact)

  def operator_review_package(%{"schema_contract" => "realized_activity.v1"} = artifact),
    do: OperatorReview.from_realized_activity(artifact)

  def operator_review_package(%{"schema_contract" => "realized_state_snapshot.v1"} = artifact),
    do: OperatorReview.from_realized_state_snapshot(artifact)

  def operator_review_package(%{"schema_contract" => "planned_activity.v1"} = artifact),
    do: OperatorReview.from_planned_activity(artifact)

  def operator_review_package(
        %{"schema_contract" => "operational_timeline_report.v1"} = artifact
      ),
      do: OperatorReview.from_operational_timeline_report(artifact)

  def operator_review_package(%{"schema_contract" => "timeline_diff_report.v1"} = artifact),
    do: OperatorReview.from_timeline_diff_report(artifact)

  def operator_review_package(%{"schema_contract" => "timeline_diff_summary.v1"} = artifact),
    do: OperatorReview.from_timeline_diff_summary(artifact)

  def operator_review_package(%{"model" => "artifact_only_timeline_diff_summary"} = artifact),
    do: OperatorReview.from_timeline_diff_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_dependency_impact_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_dependency_impact_summary(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_dependency_impact_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_dependency_impact_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_publication_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_publication_summary(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_publication_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_publication_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_activity_precondition_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_precondition_summary(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_activity_precondition_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_precondition_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_lifecycle_state_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_lifecycle_state_summary(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_lifecycle_state_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_lifecycle_state_summary(artifact)

  def operator_review_package(%{"schema_contract" => "timeline_activity_state.v1"} = artifact),
    do: OperatorReview.from_timeline_activity_state(artifact)

  def operator_review_package(%{"model" => "artifact_only_timeline_activity_state"} = artifact),
    do: OperatorReview.from_timeline_activity_state(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_activity_status_state.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_status_state(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_activity_status_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_status_state(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_activity_approval_state.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_approval_state(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_activity_approval_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_approval_state(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_activity_lifecycle_state.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_lifecycle_state(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_activity_lifecycle_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_lifecycle_state(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_preservation_report.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_preservation_report(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_lifecycle_preservation_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_preservation_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_preservation_status.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_preservation_status(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_lifecycle_preservation_status"} = artifact
      ),
      do: OperatorReview.from_timeline_preservation_status(artifact)

  def operator_review_package(%{"schema_contract" => "timeline_integrity_report.v1"} = artifact),
    do: OperatorReview.from_timeline_integrity_report(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_integrity_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_integrity_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_transition_application_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_summary(artifact)

  def operator_review_package(
        %{"model" => "artifact_only_timeline_transition_application_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "timeline_transition_application_report.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_report(artifact)

  def operator_review_package(%{"schema_contract" => "command_window_report.v1"} = artifact),
    do: OperatorReview.from_command_window_report(artifact)

  def operator_review_package(%{"schema_contract" => "maneuver_review_report.v1"} = artifact),
    do: OperatorReview.from_maneuver_review_report(artifact)

  def operator_review_package(%{"schema_contract" => "maneuver_recommendation.v1"} = artifact),
    do: OperatorReview.from_maneuver_recommendation(artifact)

  def operator_review_package(%{"schema_contract" => "maneuver_execution_delta.v1"} = artifact),
    do: OperatorReview.from_maneuver_execution_delta(artifact)

  def operator_review_package(%{"schema_contract" => "station_calendar_report.v1"} = artifact),
    do: OperatorReview.from_station_calendar_report(artifact)

  def operator_review_package(%{"schema_contract" => "station_reservation_report.v1"} = artifact),
    do: OperatorReview.from_station_reservation_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "provider_counteroffer_report.v1"} = artifact
      ),
      do: OperatorReview.from_provider_counteroffer_report(artifact)

  def operator_review_package(%{"schema_contract" => "link_capacity_report.v1"} = artifact),
    do: OperatorReview.from_link_capacity_report(artifact)

  def operator_review_package(%{"schema_contract" => "contact_allocation_report.v1"} = artifact),
    do: OperatorReview.from_contact_allocation_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"} = artifact
      ),
      do: OperatorReview.from_contact_allocation_capacity_pack_summary(artifact)

  def operator_review_package(
        %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"} = artifact
      ),
      do: OperatorReview.from_contact_allocation_reservation_conflict_summary(artifact)

  def operator_review_package(%{"schema_contract" => "contact_intent.v1"} = artifact),
    do: OperatorReview.from_contact_intent(artifact)

  def operator_review_package(%{"schema_contract" => "contact_filter_report.v1"} = artifact),
    do: OperatorReview.from_contact_filter_report(artifact)

  def operator_review_package(%{"schema_contract" => "candidate_rejection_report.v1"} = artifact),
    do: OperatorReview.from_candidate_rejection_report(artifact)

  def operator_review_package(%{"schema_contract" => "candidate_diff_report.v1"} = artifact),
    do: OperatorReview.from_candidate_diff_report(artifact)

  def operator_review_package(%{"schema_contract" => "invalidated_candidate.v1"} = artifact),
    do: OperatorReview.from_invalidated_candidate(artifact)

  def operator_review_package(%{"schema_contract" => "resource_filter_report.v1"} = artifact),
    do: OperatorReview.from_resource_filter_report(artifact)

  def operator_review_package(%{"schema_contract" => "freshness_report.v1"} = artifact),
    do: OperatorReview.from_freshness_report(artifact)

  def operator_review_package(%{"schema_contract" => "refresh_budget_report.v1"} = artifact),
    do: OperatorReview.from_refresh_budget_report(artifact)

  def operator_review_package(%{"schema_contract" => "resource_projection_report.v1"} = artifact),
    do: OperatorReview.from_resource_projection_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "resource_projection_flow_summary.v1"} = artifact
      ),
      do: OperatorReview.from_resource_projection_flow_summary(artifact)

  def operator_review_package(%{"schema_contract" => "constraint_report.v1"} = artifact),
    do: OperatorReview.from_constraint_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "objective_satisfaction_report.v1"} = artifact
      ),
      do: OperatorReview.from_objective_satisfaction_report(artifact)

  def operator_review_package(%{"schema_contract" => "policy_decision.v1"} = artifact),
    do: OperatorReview.from_policy_decision(artifact)

  def operator_review_package(%{"schema_contract" => "approval_requirement.v1"} = artifact),
    do: OperatorReview.from_approval_requirement(artifact)

  def operator_review_package(%{"schema_contract" => "contact_contention_report.v1"} = artifact),
    do: OperatorReview.from_contact_contention_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "contact_contention_resolution_report.v1"} = artifact
      ),
      do: OperatorReview.from_contact_contention_resolution_report(artifact)

  def operator_review_package(%{"schema_contract" => "branch_comparison_report.v1"} = artifact),
    do: OperatorReview.from_branch_comparison_report(artifact)

  def operator_review_package(%{"schema_contract" => "ranking_comparison_report.v1"} = artifact),
    do: OperatorReview.from_ranking_comparison_report(artifact)

  def operator_review_package(%{"schema_contract" => "score_term_report.v1"} = artifact),
    do: OperatorReview.from_score_term_report(artifact)

  def operator_review_package(%{"schema_contract" => "objective_tradeoff_report.v1"} = artifact),
    do: OperatorReview.from_objective_tradeoff_report(artifact)

  def operator_review_package(%{"schema_contract" => "pareto_frontier_report.v1"} = artifact),
    do: OperatorReview.from_pareto_frontier_report(artifact)

  def operator_review_package(%{"schema_contract" => "schema_validation_report.v1"} = artifact),
    do: OperatorReview.from_schema_validation_report(artifact)

  def operator_review_package(
        %{"schema_contract" => "schema_validation_batch_report.v1"} = artifact
      ),
      do: OperatorReview.from_schema_validation_batch_report(artifact)

  def operator_review_package(%{"schema_contract" => "execution_report.v1"} = artifact),
    do: OperatorReview.from_execution_report(artifact)

  def operator_review_package(%{schema_contract: "operator_review_package.v1"} = artifact),
    do: stringify_operator_review_keys(artifact)

  def operator_review_package(%{schema_contract: "timeline_feedback_report.v1"} = artifact),
    do: OperatorReview.from_timeline_feedback_report(artifact)

  def operator_review_package(%{schema_contract: "realized_activity.v1"} = artifact),
    do: OperatorReview.from_realized_activity(artifact)

  def operator_review_package(%{schema_contract: "realized_state_snapshot.v1"} = artifact),
    do: OperatorReview.from_realized_state_snapshot(artifact)

  def operator_review_package(%{schema_contract: "result_artifact.v1"} = artifact),
    do: OperatorReview.from_result_artifact(artifact)

  def operator_review_package(%{schema_version: 1, run: %{}, execution_report: %{}} = artifact),
    do: OperatorReview.from_result_artifact(artifact)

  def operator_review_package(%{schema_contract: "planned_activity.v1"} = artifact),
    do: OperatorReview.from_planned_activity(artifact)

  def operator_review_package(%{schema_contract: "candidate_refresh.v1"} = artifact),
    do: OperatorReview.from_candidate_refresh_artifact(artifact)

  def operator_review_package(%{schema_contract: "operational_timeline_report.v1"} = artifact),
    do: OperatorReview.from_operational_timeline_report(artifact)

  def operator_review_package(%{schema_contract: "timeline_diff_report.v1"} = artifact),
    do: OperatorReview.from_timeline_diff_report(artifact)

  def operator_review_package(%{schema_contract: "timeline_diff_summary.v1"} = artifact),
    do: OperatorReview.from_timeline_diff_summary(artifact)

  def operator_review_package(%{model: "artifact_only_timeline_diff_summary"} = artifact),
    do: OperatorReview.from_timeline_diff_summary(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_dependency_impact_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_dependency_impact_summary(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_dependency_impact_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_dependency_impact_summary(artifact)

  def operator_review_package(%{schema_contract: "timeline_publication_summary.v1"} = artifact),
    do: OperatorReview.from_timeline_publication_summary(artifact)

  def operator_review_package(%{model: "artifact_only_timeline_publication_summary"} = artifact),
    do: OperatorReview.from_timeline_publication_summary(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_activity_precondition_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_precondition_summary(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_activity_precondition_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_precondition_summary(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_lifecycle_state_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_lifecycle_state_summary(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_lifecycle_state_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_lifecycle_state_summary(artifact)

  def operator_review_package(%{schema_contract: "timeline_activity_state.v1"} = artifact),
    do: OperatorReview.from_timeline_activity_state(artifact)

  def operator_review_package(%{model: "artifact_only_timeline_activity_state"} = artifact),
    do: OperatorReview.from_timeline_activity_state(artifact)

  def operator_review_package(%{schema_contract: "timeline_activity_status_state.v1"} = artifact),
    do: OperatorReview.from_timeline_activity_status_state(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_activity_status_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_status_state(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_activity_approval_state.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_approval_state(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_activity_approval_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_approval_state(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_activity_lifecycle_state.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_lifecycle_state(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_activity_lifecycle_state"} = artifact
      ),
      do: OperatorReview.from_timeline_activity_lifecycle_state(artifact)

  def operator_review_package(%{schema_contract: "timeline_preservation_report.v1"} = artifact),
    do: OperatorReview.from_timeline_preservation_report(artifact)

  def operator_review_package(
        %{model: "artifact_only_lifecycle_preservation_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_preservation_report(artifact)

  def operator_review_package(%{schema_contract: "timeline_preservation_status.v1"} = artifact),
    do: OperatorReview.from_timeline_preservation_status(artifact)

  def operator_review_package(%{model: "artifact_only_lifecycle_preservation_status"} = artifact),
    do: OperatorReview.from_timeline_preservation_status(artifact)

  def operator_review_package(%{schema_contract: "timeline_integrity_report.v1"} = artifact),
    do: OperatorReview.from_timeline_integrity_report(artifact)

  def operator_review_package(%{model: "artifact_only_timeline_integrity_summary"} = artifact),
    do: OperatorReview.from_timeline_integrity_report(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_transition_application_summary.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_summary(artifact)

  def operator_review_package(
        %{model: "artifact_only_timeline_transition_application_summary"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_summary(artifact)

  def operator_review_package(
        %{schema_contract: "timeline_transition_application_report.v1"} = artifact
      ),
      do: OperatorReview.from_timeline_transition_application_report(artifact)

  def operator_review_package(%{schema_contract: "command_window_report.v1"} = artifact),
    do: OperatorReview.from_command_window_report(artifact)

  def operator_review_package(%{schema_contract: "maneuver_review_report.v1"} = artifact),
    do: OperatorReview.from_maneuver_review_report(artifact)

  def operator_review_package(%{schema_contract: "maneuver_recommendation.v1"} = artifact),
    do: OperatorReview.from_maneuver_recommendation(artifact)

  def operator_review_package(%{schema_contract: "maneuver_execution_delta.v1"} = artifact),
    do: OperatorReview.from_maneuver_execution_delta(artifact)

  def operator_review_package(%{schema_contract: "station_calendar_report.v1"} = artifact),
    do: OperatorReview.from_station_calendar_report(artifact)

  def operator_review_package(%{schema_contract: "station_reservation_report.v1"} = artifact),
    do: OperatorReview.from_station_reservation_report(artifact)

  def operator_review_package(%{schema_contract: "provider_counteroffer_report.v1"} = artifact),
    do: OperatorReview.from_provider_counteroffer_report(artifact)

  def operator_review_package(%{schema_contract: "link_capacity_report.v1"} = artifact),
    do: OperatorReview.from_link_capacity_report(artifact)

  def operator_review_package(%{schema_contract: "contact_allocation_report.v1"} = artifact),
    do: OperatorReview.from_contact_allocation_report(artifact)

  def operator_review_package(
        %{schema_contract: "contact_allocation_capacity_pack_summary.v1"} = artifact
      ),
      do: OperatorReview.from_contact_allocation_capacity_pack_summary(artifact)

  def operator_review_package(
        %{schema_contract: "contact_allocation_reservation_conflict_summary.v1"} = artifact
      ),
      do: OperatorReview.from_contact_allocation_reservation_conflict_summary(artifact)

  def operator_review_package(%{schema_contract: "contact_intent.v1"} = artifact),
    do: OperatorReview.from_contact_intent(artifact)

  def operator_review_package(%{schema_contract: "contact_filter_report.v1"} = artifact),
    do: OperatorReview.from_contact_filter_report(artifact)

  def operator_review_package(%{schema_contract: "candidate_rejection_report.v1"} = artifact),
    do: OperatorReview.from_candidate_rejection_report(artifact)

  def operator_review_package(%{schema_contract: "candidate_diff_report.v1"} = artifact),
    do: OperatorReview.from_candidate_diff_report(artifact)

  def operator_review_package(%{schema_contract: "invalidated_candidate.v1"} = artifact),
    do: OperatorReview.from_invalidated_candidate(artifact)

  def operator_review_package(%{schema_contract: "resource_filter_report.v1"} = artifact),
    do: OperatorReview.from_resource_filter_report(artifact)

  def operator_review_package(%{schema_contract: "freshness_report.v1"} = artifact),
    do: OperatorReview.from_freshness_report(artifact)

  def operator_review_package(%{schema_contract: "refresh_budget_report.v1"} = artifact),
    do: OperatorReview.from_refresh_budget_report(artifact)

  def operator_review_package(%{schema_contract: "model_acceptance_report.v1"} = artifact),
    do: OperatorReview.from_model_acceptance_report(artifact)

  def operator_review_package(%{schema_contract: "validation_safety_case_summary.v1"} = artifact),
    do: OperatorReview.from_validation_safety_case_summary(artifact)

  def operator_review_package(%{schema_contract: "resource_projection_report.v1"} = artifact),
    do: OperatorReview.from_resource_projection_report(artifact)

  def operator_review_package(
        %{schema_contract: "resource_projection_flow_summary.v1"} = artifact
      ),
      do: OperatorReview.from_resource_projection_flow_summary(artifact)

  def operator_review_package(%{schema_contract: "constraint_report.v1"} = artifact),
    do: OperatorReview.from_constraint_report(artifact)

  def operator_review_package(%{schema_contract: "objective_satisfaction_report.v1"} = artifact),
    do: OperatorReview.from_objective_satisfaction_report(artifact)

  def operator_review_package(%{schema_contract: "policy_decision.v1"} = artifact),
    do: OperatorReview.from_policy_decision(artifact)

  def operator_review_package(%{schema_contract: "approval_requirement.v1"} = artifact),
    do: OperatorReview.from_approval_requirement(artifact)

  def operator_review_package(%{schema_contract: "contact_contention_report.v1"} = artifact),
    do: OperatorReview.from_contact_contention_report(artifact)

  def operator_review_package(
        %{schema_contract: "contact_contention_resolution_report.v1"} = artifact
      ),
      do: OperatorReview.from_contact_contention_resolution_report(artifact)

  def operator_review_package(%{schema_contract: "branch_comparison_report.v1"} = artifact),
    do: OperatorReview.from_branch_comparison_report(artifact)

  def operator_review_package(%{schema_contract: "ranking_comparison_report.v1"} = artifact),
    do: OperatorReview.from_ranking_comparison_report(artifact)

  def operator_review_package(%{schema_contract: "score_term_report.v1"} = artifact),
    do: OperatorReview.from_score_term_report(artifact)

  def operator_review_package(%{schema_contract: "objective_tradeoff_report.v1"} = artifact),
    do: OperatorReview.from_objective_tradeoff_report(artifact)

  def operator_review_package(%{schema_contract: "pareto_frontier_report.v1"} = artifact),
    do: OperatorReview.from_pareto_frontier_report(artifact)

  def operator_review_package(%{schema_contract: "schema_validation_report.v1"} = artifact),
    do: OperatorReview.from_schema_validation_report(artifact)

  def operator_review_package(%{schema_contract: "schema_validation_batch_report.v1"} = artifact),
    do: OperatorReview.from_schema_validation_batch_report(artifact)

  def operator_review_package(%{schema_contract: "execution_report.v1"} = artifact),
    do: OperatorReview.from_execution_report(artifact)

  def operator_review_package(%{schema_contract: "operational_readiness_report.v1"} = artifact),
    do: OperatorReview.from_operational_readiness_report(artifact)

  def operator_review_package(%{schema_contract: "quality_gate_report.v1"} = artifact),
    do: OperatorReview.from_quality_gate_report(artifact)

  def operator_review_package(%{schema_version: 1} = artifact),
    do: OperatorReview.from_campaign_artifact(artifact)

  def operator_review_package(%{schema_version: 2} = artifact),
    do: OperatorReview.from_repair_artifact(artifact)

  def operator_review_package(%{schema_version: 3} = artifact),
    do: OperatorReview.from_strategy_artifact(artifact)

  def operator_review_package(%{} = artifact) do
    contract = unsupported_operator_review_contract(artifact)

    raise ArgumentError,
          "unsupported operator review artifact contract #{inspect(contract)}; " <>
            "supported contracts: #{supported_operator_review_contracts()}"
  end

  def operator_review_package(_artifact) do
    raise ArgumentError, "operator review artifact must be a map"
  end

  @doc """
  Builds an artifact-only Cadence import manifest from a repair or review artifact.
  """
  def cadence_import_manifest(artifact, opts \\ []) do
    CadenceImport.manifest(artifact, opts)
  end

  @doc """
  Builds an artifact-only operational-readiness report from review/import evidence.
  """
  def operational_readiness_report(artifact, opts \\ []) do
    OperationalReadiness.report(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only import-eligibility summary.
  """
  def operational_import_eligibility(artifact, opts \\ []) do
    OperationalReadiness.import_eligibility(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only operational-readiness gate summary.
  """
  def operational_readiness_gate_summary(artifact, opts \\ []) do
    OperationalReadiness.gate_summary(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only execution-boundary summary from readiness evidence.
  """
  def operational_execution_boundary_summary(artifact, opts \\ []) do
    OperationalReadiness.execution_boundary_summary(artifact, opts)
  end

  @doc """
  Builds a standalone artifact-only quality-gate report from readiness evidence.
  """
  def operational_quality_gate_report(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_report(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only row-derived summary from quality gates.
  """
  def operational_quality_gate_summary(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_summary(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only unavailable-resource summary from quality gates.
  """
  def operational_quality_gate_unavailable_resource_summary(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_unavailable_resource_summary(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only operator-training summary from quality gates.
  """
  def operational_quality_gate_operator_training_summary(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_operator_training_summary(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only schema-validation summary from quality gates.
  """
  def operational_quality_gate_schema_validation_summary(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_schema_validation_summary(artifact, opts)
  end

  @doc """
  Builds a compact artifact-only import-readiness summary from quality gates.
  """
  def operational_quality_gate_import_readiness_summary(artifact, opts \\ []) do
    OperationalReadiness.quality_gate_import_readiness_summary(artifact, opts)
  end

  @doc """
  Compiles a mission plan into a propagation scenario.
  """
  def compile_plan(%MissionPlan{} = plan) do
    MissionPlan.to_scenario(plan)
  end

  @doc """
  Detects ground-station access windows for a trajectory.

  Linear boundary placement remains the default. Pass
  `boundary_refinement: :bracketed_bisection` to opt into bounded AOS/LOS
  refinement on the detector's cubic-Hermite state interpolant.
  """
  def access_windows(trajectory, ground_station, opts \\ []) do
    AccessWindows.detect(trajectory, Keyword.put(opts, :ground_station, ground_station))
  end

  @doc """
  Refines one bracketed AOS/LOS boundary between two trajectory samples.

  The compatibility default is linear elevation-margin interpolation. Pass
  `boundary_refinement: :bracketed_bisection` for bounded bisection over the
  detector's cubic-Hermite state interpolant; that opt-in path is analysis-grade
  interpolated-state geometry, not dense propagation or flight-fidelity timing.
  """
  def refine_access_boundary(before_state, after_state, ground_station, opts \\ []) do
    AccessWindows.refine_aos_los_boundary(before_state, after_state, ground_station, opts)
  end

  @doc """
  Detects cylindrical central-body eclipse intervals for a trajectory.
  """
  def eclipse_intervals(trajectory, opts \\ []) do
    Eclipses.detect(trajectory, opts)
  end

  @doc """
  Refines one bracketed cylindrical eclipse boundary between two trajectory samples.
  """
  def refine_eclipse_boundary(before_state, after_state, opts \\ []) do
    Eclipses.refine_eclipse_boundary(before_state, after_state, opts)
  end

  @doc """
  Detects target visibility windows for a trajectory.
  """
  def target_visibility_windows(trajectory, target, opts \\ []) do
    TargetVisibility.detect(trajectory, Keyword.put(opts, :target, target))
  end

  @doc """
  Refines one bracketed target visibility boundary between two trajectory samples.
  """
  def refine_target_visibility_boundary(before_state, after_state, target, opts \\ []) do
    TargetVisibility.refine_visibility_boundary(before_state, after_state, target, opts)
  end

  @doc """
  Refines one bracketed sampled ground-track latitude or longitude crossing.
  """
  def refine_ground_track_crossing_boundary(before_state, after_state, opts \\ []) do
    GroundTrackCrossings.refine_crossing_boundary(before_state, after_state, opts)
  end

  @doc """
  Detects sampled geocentric latitude crossings for a trajectory.
  """
  def latitude_crossings(trajectory, latitude_deg, opts \\ []) do
    GroundTrackCrossings.detect(
      trajectory,
      opts |> Keyword.put(:crossing, :latitude) |> Keyword.put(:latitude_deg, latitude_deg)
    )
  end

  @doc """
  Detects sampled geocentric longitude crossings for a trajectory.
  """
  def longitude_crossings(trajectory, longitude_deg, opts \\ []) do
    GroundTrackCrossings.detect(
      trajectory,
      opts |> Keyword.put(:crossing, :longitude) |> Keyword.put(:longitude_deg, longitude_deg)
    )
  end

  defp unsupported_operator_review_contract(%{} = artifact) do
    case artifact |> stringify_operator_review_keys() |> Map.get("schema_contract") do
      contract when is_binary(contract) and contract != "" -> contract
      nil -> "unknown"
      contract when is_atom(contract) -> Atom.to_string(contract)
      contract -> inspect(contract)
    end
  end

  defp supported_operator_review_contracts do
    OperatorReview.capabilities()
    |> Map.fetch!(:source_artifact_types)
    |> Enum.join(", ")
  end

  defp stringify_operator_review_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) ->
        {Atom.to_string(key), stringify_operator_review_keys(value)}

      {key, value} ->
        {key, stringify_operator_review_keys(value)}
    end)
  end

  defp stringify_operator_review_keys(values) when is_list(values),
    do: Enum.map(values, &stringify_operator_review_keys/1)

  defp stringify_operator_review_keys(value), do: value

  defp json_safe_capability_value(%{} = map) do
    Map.new(map, fn {key, value} ->
      {json_safe_capability_key(key), json_safe_capability_value(value)}
    end)
  end

  defp json_safe_capability_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> json_safe_capability_value()

  defp json_safe_capability_value(values) when is_list(values),
    do: Enum.map(values, &json_safe_capability_value/1)

  defp json_safe_capability_value(nil), do: :null
  defp json_safe_capability_value(:null), do: :null
  defp json_safe_capability_value(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe_capability_value(value), do: value

  defp json_safe_capability_key(key) when is_atom(key), do: Atom.to_string(key)
  defp json_safe_capability_key(key) when is_binary(key), do: key
  defp json_safe_capability_key(key), do: to_string(key)
end
