defmodule OrbitalDynamics.CampaignPlanner.BranchCandidateRefresh do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchEventApplication,
    BranchOperationalFeedback,
    BranchRefreshAcceptedState,
    BranchRefreshGroundNetwork,
    BranchRefreshPolicies,
    BranchRefreshRequestBuilder,
    BranchRefreshRequestOptions,
    BranchRefreshResourceSummaries,
    BranchRefreshSourceInputs,
    BranchRefreshTargets,
    CandidateRefreshRequest,
    MissionStateCandidateRefreshSourceReports,
    MissionStateResourceSources,
    OperationalFeedbackNormalization,
    PriorActivityContext,
    RepairRealizedState,
    ValueEncoding
  }

  alias OrbitalDynamics.Study.Manifest

  alias OrbitalDynamics.{
    CandidateRefresh,
    StudyRunner
  }

  def request(branch, request, derive_request_fun) do
    cond do
      Map.get(branch, "candidate_refresh_request") ->
        Map.get(branch, "candidate_refresh_request")

      Map.get(branch, "candidate_refresh") ->
        nil

      true ->
        derive_request_fun.(branch, request)
    end
  end

  def refresh(branch, request, candidate_refresh_request, source_plan_id) do
    cond do
      Map.get(branch, "candidate_refresh") ->
        Map.get(branch, "candidate_refresh")

      candidate_refresh_request ->
        branch
        |> Map.put("candidate_refresh_request", candidate_refresh_request)
        |> execute(request, source_plan_id)

      true ->
        request.candidate_refresh
    end
  end

  def derive(%{"id" => "baseline"}, _request), do: nil

  def derive(%{"events" => []}, _request), do: nil

  def derive(branch, request) do
    with %{} = accepted_state <-
           BranchRefreshAcceptedState.for_branch(
             branch,
             request.mission_state,
             request.prior_plan
           ) do
      defaults = Map.get(request.mission_state, "candidate_refresh_defaults", %{})

      operational_feedback =
        operational_feedback(branch, request.operational_feedback)

      targets =
        BranchRefreshTargets.build(
          branch,
          request.mission_state,
          operational_feedback
        )

      ground_stations = BranchRefreshGroundNetwork.ground_stations(request.mission_state)
      outputs = BranchRefreshRequestOptions.outputs(targets, ground_stations)

      BranchRefreshRequestBuilder.build(branch, request, defaults, %{
        accepted_state: accepted_state,
        outputs: outputs,
        ground_stations: ground_stations,
        remaining_horizon: BranchRefreshRequestOptions.horizon(request, defaults),
        targets: targets,
        ground_network:
          BranchRefreshGroundNetwork.build(
            branch,
            request.mission_state,
            operational_feedback
          ),
        constraints: BranchRefreshRequestOptions.constraints(request, defaults),
        resource_filter_policy: BranchRefreshPolicies.resource_filter_policy(branch, defaults),
        candidate_limit_policy: BranchRefreshPolicies.candidate_limit_policy(branch, defaults),
        source_timeline_feedback_report:
          BranchRefreshSourceInputs.timeline_feedback_source_report(request.mission_state),
        timeline_feedback_report:
          BranchRefreshSourceInputs.timeline_feedback_report_input(request.mission_state),
        source_operational_timeline_report:
          BranchRefreshSourceInputs.operational_timeline_source_report(request.mission_state),
        operational_timeline_report:
          BranchRefreshSourceInputs.operational_timeline_report_input(request.mission_state),
        mission_state: MissionStateCandidateRefreshSourceReports.build(request.mission_state),
        operational_feedback: operational_feedback,
        scoring_policy: BranchRefreshRequestOptions.scoring_policy(request, defaults),
        resource_summaries: resource_summaries(branch, request.mission_state),
        prior_candidate_activities: PriorActivityContext.candidate_activities(request.prior_plan),
        approval_policy: BranchRefreshRequestOptions.approval_policy(request)
      })
    else
      _missing -> nil
    end
  end

  defp execute(branch, request, source_plan_id) do
    manifest_source =
      branch["candidate_refresh_request"]
      |> CandidateRefreshRequest.manifest(
        "branch_refresh_#{branch["id"]}",
        metadata(branch, source_plan_id)
      )

    with {:ok, manifest} <- Manifest.from_map(manifest_source),
         {:ok, result_set} <-
           StudyRunner.run(
             manifest.study,
             CandidateRefreshRequest.deterministic_run_opts(
               manifest.run_opts,
               manifest.study.id,
               request.generated_at
             )
           ) do
      CandidateRefresh.build(result_set,
        candidate_refresh: manifest.study.metadata["candidate_refresh"],
        generated_at: request.generated_at
      )
    else
      {:error, reason} ->
        raise ArgumentError,
              "invalid branch candidate_refresh_request for #{branch["id"]}: #{inspect(reason)}"
    end
  end

  def operational_feedback(branch, feedback) do
    BranchOperationalFeedback.derive(branch, feedback,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      normalize_resource_margin_aliases:
        &OperationalFeedbackNormalization.normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases:
        &OperationalFeedbackNormalization.normalize_resource_availability_aliases/1,
      event_ground_station_id:
        &OrbitalDynamics.CampaignPlanner.BranchEventNormalizer.ground_station_id/1,
      branch_event_spacecraft_id: &BranchEventApplication.spacecraft_id/1
    )
  end

  defp resource_summaries(branch, mission_state) do
    base_summaries =
      case Map.get(mission_state, "resource_summaries") do
        summaries when is_list(summaries) and summaries != [] ->
          summaries

        _other ->
          MissionStateResourceSources.summaries(mission_state)
      end
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Enum.map(&RepairRealizedState.spacecraft_state_booleans/1)

    branch
    |> BranchRefreshResourceSummaries.build(base_summaries,
      branch_event_spacecraft_id: &BranchEventApplication.spacecraft_id/1,
      degraded_event_mode: &BranchEventApplication.degraded_mode/1,
      normalize_incompatible_activity_types:
        &BranchOperationalFeedback.normalize_incompatible_activity_types/1
    )
  end

  defp metadata(branch, source_plan_id) do
    %{
      "strategy_branch_id" => branch["id"],
      "strategy_source_plan_id" => source_plan_id,
      "strategy_branch_events" => branch["events"]
    }
  end
end
