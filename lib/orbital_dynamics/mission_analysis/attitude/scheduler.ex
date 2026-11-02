defmodule OrbitalDynamics.MissionAnalysis.Attitude.Scheduler do
  @moduledoc false
  alias OrbitalDynamics.MissionAnalysis.Resource.Runner, as: ResourceRunner
  alias OrbitalDynamics.Frame
  alias OrbitalDynamics.MissionAnalysis.Path.Runner, as: PathRunner
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Motion, Profile, Horizon}

  def schedule(
        assets,
        requests,
        opportunities,
        sessions,
        policy,
        refinement,
        separation,
        state_at,
        context
      ) do
    assets = Map.new(assets, &{&1.id, &1})
    requests = Map.new(requests, &{&1.id, &1})
    validate_frames!(assets, policy)
    Horizon.validate!(assets, policy)
    balances = Map.new(assets, fn {id, a} -> {id, a.resource_budgets} end)

    cache = %{
      values: %{},
      evaluations: 0,
      resource: ResourceRunner.prepare(policy.resources, assets, requests, sessions, context),
      path: PathRunner.prepare(policy.path_constraints, assets, Map.values(requests), context)
    }

    ordered =
      Enum.sort_by(opportunities, fn o ->
        {-requests[o["request_id"]].value, o["starts_at_s"], o["asset_id"], o["id"]}
      end)

    Enum.reduce_while(ordered, {:ok, [], [], balances, cache}, fn opportunity,
                                                                  {:ok, activities, decisions,
                                                                   balances, cache} ->
      request = requests[opportunity["request_id"]]
      asset = assets[opportunity["asset_id"]]
      available = balances[asset.id]

      missing =
        for {key, cost} <- request.resource_costs,
            cost > 0 and not Map.has_key?(available, key),
            do: key

      insufficient =
        for {key, cost} <- request.resource_costs, cost > Map.get(available, key, 0), do: key

      skip =
        cond do
          Enum.any?(activities, &(&1["request_id"] == request.id)) -> "request_already_scheduled"
          missing != [] -> "undeclared_resource_budget"
          insufficient != [] -> "insufficient_resource_budget"
          true -> nil
        end

      result =
        if skip do
          {:rejected, skip, %{"status" => "not_evaluated"}, cache}
        else
          fit(
            asset,
            request,
            opportunity,
            activities,
            sessions[{asset.id, request.id}],
            policy,
            refinement,
            separation,
            state_at,
            cache
          )
        end

      decision = %{
        "opportunity_id" => opportunity["id"],
        "request_id" => request.id,
        "asset_id" => asset.id,
        "resource_ids" => Enum.sort(Enum.uniq(missing ++ insufficient))
      }

      case result do
        {:selected, start, profile, assessment, cache} ->
          activity = %{
            "id" => "activity:#{opportunity["id"]}",
            "opportunity_id" => opportunity["id"],
            "request_id" => request.id,
            "asset_id" => asset.id,
            "type" => request.activity_type,
            "starts_at_s" => start,
            "ends_at_s" => start + request.duration_s,
            "value" => request.value,
            "resource_costs" => request.resource_costs,
            "attitude_profile" => profile,
            "path_evidence" =>
              Map.get(assessment, "activity_path_evidence", %{"status" => "not_enabled"}),
            "attitude_frame" => %{
              "name" => Atom.to_string(hd(asset.trajectory.states).frame.name),
              "center" => Atom.to_string(hd(asset.trajectory.states).frame.center),
              "orientation" => Atom.to_string(hd(asset.trajectory.states).frame.orientation)
            },
            "attitude_status" => "supported_by_sampled_kinematic_model"
          }

          remaining =
            Enum.reduce(request.resource_costs, available, fn {key, cost}, acc ->
              Map.update(acc, key, 0.0, &(&1 - cost))
            end)

          decision =
            Map.merge(decision, %{
              "reason" => "selected",
              "attitude_assessment" => Map.delete(assessment, "activity_path_evidence")
            })

          {:cont,
           {:ok, [activity | activities], [decision | decisions],
            Map.put(balances, asset.id, remaining), cache}}

        {:rejected, reason, assessment, cache} ->
          {:cont,
           {:ok, activities,
            [
              Map.merge(decision, %{"reason" => reason, "attitude_assessment" => assessment})
              | decisions
            ], balances, cache}}

        {:error, reason, _cache} ->
          {:halt, {:error, {:attitude_analysis_failed, asset.id, request.id, reason}}}
      end
    end)
    |> case do
      {:ok, activities, decisions, balances, cache} ->
        activities = Enum.sort_by(activities, &{&1["starts_at_s"], &1["id"]})

        with {:ok, transitions, cache} <-
               final_transitions(activities, policy, assets, state_at, cache),
             {:ok, horizon, cache} <- Horizon.finish(assets, activities, policy, state_at, cache),
             {:ok, resources, cache} <-
               ResourceRunner.finish(assets, activities, policy, state_at, cache) do
          {:ok, activities, Enum.reverse(decisions), balances,
           %{
             "resource_feasibility" => resources,
             "planning_status" => planning_status(horizon, resources),
             "horizon_coverage" => horizon,
             "model_evaluation_count" => cache.evaluations,
             "path_constraints" => PathRunner.describe(cache.path),
             "path_status" =>
               cond do
                 horizon != :null -> horizon["status"]
                 cache.path == nil -> "not_enabled"
                 activities == [] -> "no_scheduled_path"
                 true -> "supported_at_tested_epochs"
               end,
             "transitions" => transitions,
             "limits" => [
               "activity profiles and physical eligibility are sampled, not continuously certified",
               "initial state, mount transforms and roll rules are declared assumptions",
               "motion phases are a constructed kinematic path, not spacecraft commands or actuator validation"
             ]
           }}
        end

      error ->
        error
    end
  catch
    {:resource_preparation_failed, asset, model, reason} ->
      {:error, {:resource_preparation_failed, asset, model, reason}}

    {:path_preparation_failed, asset, rule, reason} ->
      {:error, {:path_preparation_failed, asset, rule, reason}}
  end

  defp planning_status(:null, _), do: :null

  defp planning_status(horizon, resources) do
    statuses = [horizon["status"]] ++ if(resources == :null, do: [], else: [resources["status"]])

    cond do
      "violated" in statuses -> "violated"
      "unknown" in statuses -> "unknown"
      true -> "supported"
    end
  end

  defp validate_frames!(assets, policy) do
    Enum.each(policy.assets, fn {id, a} ->
      unless Map.has_key?(assets, id),
        do: raise(ArgumentError, "attitude policy names unknown asset #{id}")

      first = hd(assets[id].trajectory.states)

      if first.frame.orientation == :body_fixed,
        do: raise(ArgumentError, "attitude planning requires inertial axes")

      if a.initial !=
           :unknown and
           (not Frame.compatible?(a.initial.frame, first.frame) or
              a.initial.epoch.scale !=
                first.epoch.scale),
         do: raise(ArgumentError, "initial attitude frame and scale must match the asset")
    end)
  end

  defp fit(
         asset,
         request,
         opportunity,
         activities,
         session,
         policy,
         refinement,
         separation,
         state_at,
         cache
       ) do
    limits = policy.assets[asset.id]

    cond do
      limits == nil ->
        unknown("attitude_configuration_missing", cache)

      limits.initial == :unknown ->
        unknown("initial_attitude_unknown", cache)

      policy.horizon != nil and Horizon.readiness(asset, policy) != nil ->
        unknown(Atom.to_string(Horizon.readiness(asset, policy)), cache)

      not Map.has_key?(limits.pointing_configurations, request.model) ->
        unknown("pointing_configuration_missing", cache)

      not function_exported?(request.model, :pointing, 3) ->
        unknown("pointing_model_unavailable", cache)

      true ->
        config = limits.pointing_configurations[request.model]

        start =
          if policy.horizon,
            do: max(opportunity["starts_at_s"], policy.horizon.start.seconds_since_j2000),
            else: opportunity["starts_at_s"]

        stop =
          if policy.horizon,
            do:
              min(opportunity["ends_at_s"], policy.horizon.stop.seconds_since_j2000) -
                request.duration_s,
            else: opportunity["ends_at_s"] - request.duration_s

        count = trunc(:math.floor(max(0, stop - start) / policy.search_step_s))
        truncated = count + 1 > policy.max_candidate_starts

        times =
          Enum.map(
            0..min(count, policy.max_candidate_starts - 1),
            &(start + &1 * policy.search_step_s)
          )

        {times, truncated} =
          if List.last(times) != stop and not truncated do
            if length(times) < policy.max_candidate_starts,
              do: {times ++ [stop], false},
              else: {times, true}
          else
            {times, truncated}
          end

        timeline =
          activities
          |> Enum.filter(&(&1["asset_id"] == asset.id))
          |> Enum.sort_by(& &1["starts_at_s"])

        times = if stop < start, do: [], else: times

        Enum.reduce_while(times, {:search, [], cache}, fn t, {:search, attempts, cache} ->
          result =
            try_start(
              asset,
              request,
              session,
              t,
              timeline,
              config,
              policy,
              refinement,
              separation,
              state_at,
              cache
            )

          result =
            case result do
              {:ok, profile, details, cache} ->
                candidate = %{
                  "asset_id" => asset.id,
                  "request_id" => request.id,
                  "starts_at_s" => t,
                  "ends_at_s" => t + request.duration_s,
                  "attitude_profile" => profile
                }

                timeline = Enum.sort_by([candidate | timeline], & &1["starts_at_s"])

                case ResourceRunner.assess(asset, timeline, policy, state_at, cache) do
                  {:ok, evidence, cache} ->
                    details = Map.put(details, "resource_checks", ResourceRunner.brief(evidence))

                    case evidence["status"] do
                      "supported" -> {:ok, profile, details, cache}
                      "not_enabled" -> {:ok, profile, details, cache}
                      "violated" -> {:infeasible, :resource_feasibility_violated, details, cache}
                      "unknown" -> {:unknown, :resource_feasibility_unknown, details, cache}
                    end

                  error ->
                    error
                end

              other ->
                other
            end

          case result do
            {:ok, profile, details, cache} ->
              attempt =
                Map.merge(PathRunner.brief_details(details), %{
                  "start_s" => t,
                  "status" => "supported"
                })

              {:halt,
               {:selected, t, profile,
                %{
                  "status" => "supported_by_sampled_kinematic_model",
                  "activity_path_evidence" =>
                    get_in(details, ["path_checks", "activity"]) || %{"status" => "not_enabled"},
                  "tested_start_count" => length(attempts) + 1,
                  "attempts" => Enum.reverse([attempt | attempts])
                }, cache}}

            {status, reason, details, cache} when status in [:infeasible, :unknown] ->
              attempt =
                Map.merge(PathRunner.brief_details(details), %{
                  "start_s" => t,
                  "status" => Atom.to_string(status),
                  "reason" => inspect(reason)
                })

              {:cont, {:search, [attempt | attempts], cache}}

            {:error, reason, cache} ->
              {:halt, {:error, reason, cache}}
          end
        end)
        |> case do
          {:search, attempts, cache} ->
            unknown = truncated or Enum.any?(attempts, &(&1["status"] == "unknown"))

            {:rejected,
             if(unknown,
               do:
                 if(policy.resources,
                   do: "planning_feasibility_unknown",
                   else: "attitude_feasibility_unknown"
                 ),
               else:
                 if(policy.resources,
                   do: "planning_start_grid_infeasible",
                   else: "attitude_start_grid_infeasible"
                 )
             ),
             %{
               "status" => if(unknown, do: "unknown", else: "infeasible_on_tested_start_grid"),
               "search_truncated" => truncated,
               "tested_start_count" => length(attempts),
               "attempts" => Enum.reverse(attempts)
             }, cache}

          other ->
            other
        end
    end
  end

  defp try_start(
         asset,
         request,
         session,
         start,
         timeline,
         config,
         policy,
         refinement,
         separation,
         state_at,
         cache
       ) do
    stop = start + request.duration_s

    collision =
      Enum.any?(timeline, fn a ->
        not (stop + separation <= a["starts_at_s"] or start >= a["ends_at_s"] + separation)
      end)

    if collision do
      {:infeasible, :asset_conflict, %{}, cache}
    else
      previous = timeline |> Enum.filter(&(&1["ends_at_s"] <= start)) |> List.last()
      following = Enum.find(timeline, &(&1["starts_at_s"] >= stop))

      source =
        if previous,
          do: List.last(previous["attitude_profile"]),
          else: initial_pose(policy.assets[asset.id].initial)

      with {:ok, first, cache} <-
             Profile.sample(asset, request, session, start, config, policy, state_at, cache),
           {:ok, last, cache} <-
             Profile.sample(asset, request, session, stop, config, policy, state_at, cache) do
        incoming = Motion.transition(source, first, policy.assets[asset.id])

        outgoing =
          cond do
            following ->
              Motion.transition(last, hd(following["attitude_profile"]), policy.assets[asset.id])

            policy.horizon ->
              Horizon.transition(asset, last, policy)

            true ->
              {:ok, %{"status" => "no_successor"}}
          end

        details = %{"incoming" => brief(incoming), "outgoing" => brief(outgoing)}

        case {incoming, outgoing} do
          {{:infeasible, _}, _} ->
            {:infeasible, :incoming_transition, details, cache}

          {_, {:infeasible, _}} ->
            {:infeasible, :outgoing_transition, details, cache}

          {{:ok, _}, {:ok, _}} ->
            case Profile.tracking(
                   asset,
                   request,
                   session,
                   start,
                   stop,
                   config,
                   policy,
                   refinement,
                   state_at,
                   cache
                 ) do
              {:ok, points, cache} ->
                check_paths(
                  asset,
                  request,
                  session,
                  start,
                  stop,
                  points,
                  incoming,
                  outgoing,
                  following,
                  config,
                  policy,
                  state_at,
                  details,
                  cache
                )

              {status, reason, cache} when status in [:infeasible, :unknown] ->
                {status, reason, details, cache}

              error ->
                error
            end
        end
      else
        {status, reason, cache} when status in [:infeasible, :unknown] ->
          {status, reason, %{}, cache}

        error ->
          error
      end
    end
  end

  defp check_paths(
         asset,
         request,
         session,
         start,
         stop,
         points,
         {:ok, incoming},
         {:ok, outgoing},
         following,
         config,
         policy,
         state_at,
         details,
         cache
       ) do
    at = fn t, cache ->
      Profile.orientation(asset, request, session, t, config, policy, state_at, cache)
    end

    checks = [
      {"incoming",
       fn cache ->
         PathRunner.transition(asset, incoming, "incoming_transition", state_at, cache)
       end},
      {"activity",
       fn cache ->
         PathRunner.activity(asset, request, session, start, stop, at, state_at, cache)
       end}
    ]

    checks =
      if following,
        do:
          checks ++
            [
              {"outgoing",
               fn cache ->
                 PathRunner.transition(asset, outgoing, "outgoing_transition", state_at, cache)
               end}
            ],
        else:
          if(policy.horizon,
            do:
              checks ++
                [
                  {"terminal",
                   fn cache -> Horizon.check(asset, outgoing, policy, state_at, cache) end}
                ],
            else: checks
          )

    Enum.reduce_while(checks, {:ok, %{}, cache}, fn {scope, check}, {:ok, evidence, cache} ->
      case check.(cache) do
        {:ok, result, cache} ->
          {:cont, {:ok, Map.put(evidence, scope, result), cache}}

        {status, reason, result, cache} when status in [:unknown, :infeasible] ->
          {:halt,
           {status, reason, Map.put(details, "path_checks", Map.put(evidence, scope, result)),
            cache}}

        error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, evidence, cache} -> {:ok, points, Map.put(details, "path_checks", evidence), cache}
      other -> other
    end
  end

  defp unknown(reason, cache),
    do:
      {:rejected, "attitude_feasibility_unknown",
       %{"status" => "unknown", "reason" => reason, "tested_start_count" => 0}, cache}

  defp brief({status, details}),
    do: Map.put(Map.drop(details, ["phases"]), "status", Atom.to_string(status))

  defp initial_pose(initial),
    do: %{
      "epoch_s" => initial.epoch.seconds_since_j2000,
      "quaternion_wxyz" => Tuple.to_list(initial.quaternion),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(initial.angular_velocity_deg_s)
    }

  defp final_transitions(activities, policy, assets, state_at, cache) do
    activities
    |> Enum.group_by(& &1["asset_id"])
    |> Enum.sort()
    |> Enum.reduce_while({:ok, [], cache}, fn {id, timeline}, {:ok, all, cache} ->
      result =
        Enum.reduce_while(
          timeline,
          {:ok, [], initial_pose(policy.assets[id].initial), :null, cache},
          fn activity, {:ok, plans, source, source_id, cache} ->
            {:ok, transition} =
              Motion.transition(source, hd(activity["attitude_profile"]), policy.assets[id])

            case PathRunner.transition(
                   assets[id],
                   transition,
                   "final_transition",
                   state_at,
                   cache
                 ) do
              {:ok, evidence, cache} ->
                plan =
                  Map.merge(transition, %{
                    "asset_id" => id,
                    "from_activity_id" => source_id,
                    "to_activity_id" => activity["id"],
                    "path_evidence" => evidence
                  })

                {:cont,
                 {:ok, [plan | plans], List.last(activity["attitude_profile"]), activity["id"],
                  cache}}

              {_, reason, _, _} ->
                {:halt, {:error, {:final_path_verification_failed, reason}}}

              {:error, reason, _} ->
                {:halt, {:error, {:final_path_verification_failed, reason}}}
            end
          end
        )

      case result do
        {:ok, plans, _, _, cache} -> {:cont, {:ok, all ++ Enum.reverse(plans), cache}}
        error -> {:halt, error}
      end
    end)
  end
end
