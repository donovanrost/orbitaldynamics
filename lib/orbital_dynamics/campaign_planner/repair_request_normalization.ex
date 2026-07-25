defmodule OrbitalDynamics.CampaignPlanner.RepairRequestNormalization do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.Study.Manifest

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    CandidateRefreshNormalization,
    CandidateRefreshRequest,
    MissionStateNormalization,
    RepairCandidateRefreshInheritance,
    RepairMetadata,
    RepairPolicySemantics,
    RepairRealizedState,
    ReplanRequest,
    ScalarValues,
    StrategyPolicyNormalization,
    ValueEncoding
  }

  alias OrbitalDynamics.{CandidateRefresh, Schema, StudyRunner}

  def from_map(request) do
    %ReplanRequest{
      prior_plan:
        ValueEncoding.get_key(request, :prior_plan) ||
          ValueEncoding.get_key(request, :campaign_plan) ||
          ValueEncoding.get_key(request, :source_plan),
      mission_state: ValueEncoding.get_key(request, :mission_state),
      realized_state: ValueEncoding.get_key(request, :realized_state) || %{},
      current_epoch_s: ValueEncoding.get_key(request, :current_epoch_s),
      remaining_horizon: ValueEncoding.get_key(request, :remaining_horizon),
      constraints: ValueEncoding.get_key(request, :constraints),
      scoring_policy: ValueEncoding.get_key(request, :scoring_policy),
      repair_policy: ValueEncoding.get_key(request, :repair_policy),
      approval_policy: ValueEncoding.get_key(request, :approval_policy),
      candidate_refresh:
        ValueEncoding.get_key(request, :candidate_refresh) ||
          ValueEncoding.get_key(request, :refreshed_candidates),
      candidate_refresh_request:
        ValueEncoding.get_key(request, :candidate_refresh_request) ||
          ValueEncoding.get_key(request, :refresh_request),
      ground_network:
        ValueEncoding.get_key(request, :ground_network) ||
          ValueEncoding.get_key(request, :station_calendar),
      generated_at: ValueEncoding.get_key(request, :generated_at),
      metadata: ValueEncoding.get_key(request, :metadata) || %{}
    }
  end

  def normalize(%ReplanRequest{} = request) do
    prior_plan = ValueEncoding.stringify_keys(request.prior_plan || %{})
    mission_state = normalize_mission_state(request.mission_state)
    realized_state = RepairRealizedState.normalize(request.realized_state || %{})
    current_epoch_s = ScalarValues.numeric!(request.current_epoch_s, "current_epoch_s")

    remaining_horizon =
      ActivityTiming.remaining_horizon(prior_plan, request.remaining_horizon, current_epoch_s)

    generated_at = normalize_generated_at(request.generated_at || DateTime.utc_now())

    candidate_refresh_request =
      request.candidate_refresh_request
      |> CandidateRefreshNormalization.request()
      |> RepairCandidateRefreshInheritance.inherit(
        request.approval_policy,
        mission_state,
        prior_plan
      )

    prebuilt_candidate_refresh = CandidateRefreshNormalization.artifact(request.candidate_refresh)

    candidate_refresh =
      prebuilt_candidate_refresh ||
        execute_candidate_refresh_request(
          prior_plan,
          current_epoch_s,
          candidate_refresh_request,
          generated_at
        )

    scoring_policy =
      prior_plan
      |> ValueEncoding.get_key("ranking_explanation")
      |> case do
        %{} = explanation -> ValueEncoding.get_key(explanation, "policy") || %{}
        _explanation -> %{}
      end
      |> Map.merge(ValueEncoding.stringify_keys(request.scoring_policy || %{}))

    repair_policy = RepairPolicySemantics.normalize(request.repair_policy || %{})
    approval_policy = StrategyPolicyNormalization.approval(request.approval_policy || %{})

    source_station_calendar_provider =
      source_station_calendar_provider(request.ground_network)

    ground_network = normalize_ground_network(request.ground_network)

    %{
      prior_plan: prior_plan,
      mission_state: mission_state,
      realized_state: realized_state,
      current_epoch_s: current_epoch_s,
      remaining_horizon: remaining_horizon,
      constraints:
        Map.merge(
          ValueEncoding.stringify_keys(ValueEncoding.get_key(prior_plan, "assumptions") || %{})
          |> ValueEncoding.get_key("constraints") ||
            %{},
          ValueEncoding.stringify_keys(request.constraints || %{})
        ),
      scoring_policy:
        scoring_policy
        |> Map.put_new("schedule_churn_cost_weight", repair_policy.schedule_churn_cost_weight)
        |> Map.put_new("schedule_move_cost_weight", repair_policy.schedule_move_cost_weight),
      repair_policy: repair_policy,
      approval_policy: approval_policy,
      candidate_refresh: candidate_refresh,
      candidate_refresh_request: candidate_refresh_request,
      candidate_source:
        RepairMetadata.candidate_source(
          prior_plan,
          candidate_refresh,
          candidate_refresh_request
        ),
      source_station_calendar_provider: source_station_calendar_provider,
      ground_network: ground_network,
      generated_at: generated_at,
      metadata: ValueEncoding.stringify_keys(request.metadata || %{})
    }
  end

  defp normalize_mission_state(nil), do: %{"objectives" => []}

  defp normalize_mission_state(%{} = mission_state),
    do: MissionStateNormalization.normalize(mission_state)

  defp execute_candidate_refresh_request(
         _prior_plan,
         _current_epoch_s,
         nil,
         _generated_at
       ),
       do: nil

  defp execute_candidate_refresh_request(
         prior_plan,
         current_epoch_s,
         candidate_refresh_request,
         generated_at
       ) do
    manifest_source =
      candidate_refresh_request
      |> CandidateRefreshRequest.manifest(
        "repair_refresh_#{RepairMetadata.source_plan_id(prior_plan)}",
        %{
          "repair_source_plan_id" => RepairMetadata.source_plan_id(prior_plan),
          "repair_current_epoch_s" => current_epoch_s
        }
      )

    with {:ok, manifest} <- Manifest.from_map(manifest_source),
         {:ok, result_set} <-
           StudyRunner.run(
             manifest.study,
             CandidateRefreshRequest.deterministic_run_opts(
               manifest.run_opts,
               manifest.study.id,
               generated_at
             )
           ) do
      CandidateRefresh.build(result_set,
        candidate_refresh: manifest.study.metadata["candidate_refresh"],
        generated_at: generated_at
      )
    else
      {:error, reason} ->
        raise ArgumentError, "invalid repair candidate_refresh_request: #{inspect(reason)}"
    end
  end

  defp normalize_ground_network(nil), do: nil

  defp normalize_ground_network(ground_network) when is_list(ground_network),
    do: Enum.map(ground_network, &ValueEncoding.stringify_keys/1)

  defp normalize_ground_network(%{} = station_calendar_provider),
    do: StationCalendar.to_ground_network(station_calendar_provider)

  defp normalize_ground_network(_ground_network) do
    raise ArgumentError, "ground_network must be a list or station calendar provider object"
  end

  defp source_station_calendar_provider(%{} = provider) do
    provider = ValueEncoding.stringify_keys(provider)

    with "station_calendar_provider.v1" <- Map.get(provider, "schema_contract"),
         {:ok, _report} <-
           Schema.validate_artifact(provider,
             schema_contract: "station_calendar_provider.v1"
           ) do
      provider
    else
      _invalid_or_legacy_provider -> nil
    end
  end

  defp source_station_calendar_provider(_ground_network), do: nil

  def normalize_generated_at(%DateTime{} = generated_at), do: generated_at

  def normalize_generated_at(generated_at) when is_binary(generated_at) do
    case DateTime.from_iso8601(generated_at) do
      {:ok, datetime, _offset} ->
        datetime

      {:error, reason} ->
        raise ArgumentError, "invalid generated_at: #{inspect(reason)}"
    end
  end

  def normalize_generated_at(generated_at) do
    raise ArgumentError, "invalid generated_at: #{inspect(generated_at)}"
  end
end
