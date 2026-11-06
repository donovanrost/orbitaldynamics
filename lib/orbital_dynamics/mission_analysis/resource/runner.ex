defmodule OrbitalDynamics.MissionAnalysis.Resource.Runner do
  @moduledoc false
  alias OrbitalDynamics.MissionAnalysis.{Input, Resource.Policy}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Horizon, Motion, Pointing, Profile}
  alias OrbitalDynamics.MissionAnalysis.Path.Result
  alias OrbitalDynamics.Schema.JsonSafety

  def prepare(nil, _, _, _, _), do: nil

  def prepare(%Policy{} = p, assets, requests, sessions, context) do
    prepared =
      Map.new(p.assets, fn {id, models} ->
        unless Map.has_key?(assets, id),
          do: raise(ArgumentError, "resource policy names unknown asset #{id}")

        entries =
          Enum.map(models, fn m ->
            for r <- Map.values(requests),
                Map.has_key?(assets[id].capabilities, r.model),
                key <- m.exclusive_cost_keys,
                Map.get(r.resource_costs, key, 0) > 0 do
              raise ArgumentError,
                    "dynamic resource #{m.id} overlaps static cost #{key} on request #{r.id}"
            end

            case m.module.prepare(assets[id], context, m.configuration) do
              {:ok, session, assumptions} when is_map(assumptions) ->
                initial = native_state!(m.module.initial(session))
                boundaries = m.module.boundaries(session)

                unless is_list(boundaries) and length(boundaries) <= 10000,
                  do: raise(ArgumentError, "resource boundaries must be a bounded list")

                Enum.each(
                  boundaries,
                  &Input.number!(&1, "resource boundary epoch", -1.0e12, 1.0e12)
                )

                %{
                  id: m.id,
                  module: m.module,
                  session: session,
                  initial: initial,
                  boundaries: boundaries,
                  assumptions: JsonSafety.normalize_input!(assumptions, "resource assumptions")
                }

              {:error, reason} ->
                throw({:resource_preparation_failed, id, m.id, reason})

              _ ->
                raise ArgumentError, "invalid resource preparation result"
            end
          end)

        {id, entries}
      end)

    %{policy: p, prepared: prepared, requests: requests, sessions: sessions, evaluations: 0}
  end

  def assess(_asset, _timeline, %{resources: nil}, _state_at, cache),
    do: {:ok, %{"status" => "not_enabled"}, cache}

  def assess(asset, timeline, policy, state_at, cache) do
    reason = Horizon.readiness(asset, policy)

    cond do
      not Map.has_key?(cache.resource.prepared, asset.id) ->
        {:ok, unknown(policy, "resource_configuration_missing"), cache}

      reason != nil ->
        {:ok, unknown(policy, Atom.to_string(reason)), cache}

      true ->
        case segments(asset, timeline, policy, cache.resource) do
          {:ok, segments} -> evaluate(asset, segments, policy, state_at, cache)
          {:infeasible, reason} -> {:ok, unknown(policy, reason), cache}
        end
    end
  catch
    {:resource_evaluation_failed, reason, failed_cache} -> {:error, reason, failed_cache}
  end

  def finish(_assets, _activities, %{resources: nil}, _state_at, cache), do: {:ok, :null, cache}

  def finish(assets, activities, policy, state_at, cache) do
    Enum.reduce_while(Enum.sort(assets), {:ok, %{}, cache}, fn {id, asset},
                                                               {:ok, reports, cache} ->
      timeline =
        activities |> Enum.filter(&(&1["asset_id"] == id)) |> Enum.sort_by(& &1["starts_at_s"])

      case assess(asset, timeline, policy, state_at, cache) do
        {:ok, report, cache} ->
          report =
            Map.update(
              report,
              "models",
              [],
              &OrbitalDynamics.MissionAnalysis.ReportData.complete/1
            )

          {:cont, {:ok, Map.put(reports, id, report), cache}}

        {:error, reason, _cache} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, reports, cache} ->
        {:ok,
         %{
           "status" => status(Enum.map(reports, fn {_, r} -> r["status"] end)),
           "model_evaluation_count" => cache.resource.evaluations,
           "assets" => reports,
           "limits" =>
             "Declared models and tested integration cadences only; no continuous certification, telemetry or hardware validation."
         }, cache}

      error ->
        error
    end
  end

  def brief(report) do
    Map.update(report, "models", [], fn models ->
      Enum.map(models, fn m ->
        Map.update!(m, "levels", fn levels -> Enum.map(levels, &Map.delete(&1, "samples")) end)
      end)
    end)
  end

  defp unknown(policy, reason),
    do: %{
      "status" => "unknown",
      "reason" => reason,
      "uncovered_intervals" => [
        %{
          "starts_at_s" => policy.horizon.start.seconds_since_j2000,
          "ends_at_s" => policy.horizon.stop.seconds_since_j2000,
          "reason" => reason
        }
      ]
    }

  defp pose(i),
    do: %{
      "epoch_s" => i.epoch.seconds_since_j2000,
      "quaternion_wxyz" => Tuple.to_list(i.quaternion),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(i.angular_velocity_deg_s)
    }

  defp segments(asset, timeline, policy, runtime) do
    result =
      Enum.reduce_while(timeline, {:ok, [], pose(policy.assets[asset.id].initial)}, fn a,
                                                                                       {:ok,
                                                                                        segments,
                                                                                        source} ->
        case Motion.acquire(
               source,
               hd(a["attitude_profile"]),
               policy.assets[asset.id],
               a["request_id"]
             ) do
          {:ok, plan} ->
            request = runtime.requests[a["request_id"]]
            config = policy.assets[asset.id].pointing_configurations[request.model]

            at = fn t, cache ->
              Profile.orientation(
                asset,
                request,
                runtime.sessions[{asset.id, request.id}],
                t,
                config,
                policy,
                cache.resource_state_at,
                cache
              )
            end

            segment = %{
              start: a["starts_at_s"],
              stop: a["ends_at_s"],
              phase: "activity",
              scope: "activity:#{request.id}",
              mode:
                mode(
                  policy,
                  asset.id,
                  get_in(policy.path_constraints.assets, [asset.id, :activity_modes, request.id])
                ),
              at: at,
              activity_type: request.activity_type,
              kinematics_at: fn t, cache ->
                Profile.sample(
                  asset,
                  request,
                  runtime.sessions[{asset.id, request.id}],
                  t,
                  config,
                  policy,
                  cache.resource_state_at,
                  cache
                )
              end
            }

            {:cont,
             {:ok,
              segments ++
                motion_segments(
                  asset,
                  plan,
                  policy,
                  "transition",
                  mode(
                    policy,
                    asset.id,
                    get_in(policy.path_constraints.assets, [asset.id, :transition_mode])
                  )
                ) ++ [segment], List.last(a["attitude_profile"])}}

          {:infeasible, _} ->
            {:halt, {:infeasible, "resource_timeline_transition_infeasible"}}
        end
      end)

    case result do
      {:ok, segments, source} ->
        case Horizon.transition(asset, source, policy) do
          {:ok, plan} ->
            {:ok,
             segments ++
               motion_segments(
                 asset,
                 plan,
                 policy,
                 "terminal",
                 mode(policy, asset.id, policy.horizon.terminals[asset.id].mode)
               )}

          {:infeasible, _} ->
            {:infeasible, "resource_terminal_path_unavailable"}
        end

      other ->
        other
    end
  end

  defp mode(policy, id, name) do
    case get_in(policy.path_constraints.assets, [id, :modes, name]) do
      nil -> nil
      parameters -> %{"name" => name, "parameters" => parameters}
    end
  end

  defp motion_segments(asset, plan, policy, scope, default_mode) do
    origin = plan["source_epoch_s"]
    at = fn t, cache -> {:ok, Motion.at_epoch(plan, t).quaternion, cache} end

    segments =
      for p <- plan["phases"], p["ends_after_s"] > p["starts_after_s"] do
        %{
          start: max(origin, min(plan["destination_epoch_s"], origin + p["starts_after_s"])),
          stop: max(origin, min(plan["destination_epoch_s"], origin + p["ends_after_s"])),
          phase: p["kind"],
          scope: scope,
          mode:
            if(p["mode_name"], do: mode(policy, asset.id, p["mode_name"]), else: default_mode),
          activity_type: nil,
          kinematics_at: fn t, cache ->
            k = Motion.kinematics_at_phase(p, origin, t)

            {:ok,
             %{
               "epoch_s" => t,
               "quaternion_wxyz" => Tuple.to_list(k.quaternion),
               "angular_velocity_inertial_deg_s" => Tuple.to_list(k.angular_velocity_deg_s),
               "angular_acceleration_inertial_deg_s2" =>
                 Tuple.to_list(k.angular_acceleration_deg_s2)
             }, cache}
          end,
          at: at
        }
      end

    case segments do
      [] ->
        []

      segments ->
        segments
        |> List.update_at(0, &%{&1 | start: origin})
        |> List.update_at(-1, &%{&1 | stop: plan["destination_epoch_s"]})
        |> Enum.filter(&(&1.stop > &1.start))
    end
  end

  defp evaluate(asset, segments, policy, state_at, cache) do
    cache = Map.put(cache, :resource_state_at, state_at)
    {models, cache} = search_boundaries(asset, policy, state_at, cache)
    boundaries = Enum.flat_map(models, & &1.boundaries)

    grids =
      Enum.map(policy.resources.sample_steps_s, fn step ->
        {step, intervals(segments, boundaries, step, policy.resources.max_intervals_per_asset)}
      end)

    {reports, cache} =
      Enum.map_reduce(models, cache, fn model, cache ->
        {levels, cache} =
          Enum.map_reduce(grids, cache, fn {step, grid}, cache ->
            grid =
              if model.boundary_status != :complete,
                do: {:unknown, :resource_contact_search_incomplete},
                else: grid

            case grid do
              {:unknown, reason} -> {unknown_level(step, policy, reason), cache}
              {:ok, intervals} -> level(asset, model, intervals, step, policy, state_at, cache)
            end
          end)

        statuses = Enum.map(levels, & &1["status"])

        {%{
           "id" => model.id,
           "status" => status(statuses),
           "assumptions" => model.assumptions,
           "state_comparison" =>
             OrbitalDynamics.MissionAnalysis.Resource.Comparison.summarize(levels),
           "resolution_status" =>
             if(length(Enum.uniq(statuses)) == 1,
               do: "agrees_across_tested_steps",
               else: "changes_across_tested_steps"
             ),
           "levels" => report_levels(levels)
         }, cache}
      end)

    {:ok, %{"status" => status(Enum.map(reports, & &1["status"])), "models" => reports},
     Map.delete(cache, :resource_state_at)}
  end

  defp search_boundaries(asset, policy, state_at, cache) do
    source =
      OrbitalDynamics.EventSearch.Source.new!(
        fn t -> state_at.(asset, t) end,
        policy.horizon.start,
        policy.horizon.stop,
        hd(asset.trajectory.states).frame,
        %{"evaluation" => "planning_runtime_state_sampler", "asset_id" => asset.id}
      )

    Enum.map_reduce(cache.resource.prepared[asset.id], cache, fn model, cache ->
      key = {asset.id, model.id, source.start, source.stop, state_at}
      searches = Map.get(cache, :resource_boundary_searches, %{})

      result =
        case Map.fetch(searches, key) do
          {:ok, result} ->
            result

          :error ->
            if function_exported?(model.module, :search_boundaries, 2),
              do: model.module.search_boundaries(model.session, source),
              else: {:ok, [], :null}
        end

      cache = Map.put(cache, :resource_boundary_searches, Map.put(searches, key, result))

      case result do
        {:ok, boundaries, evidence} ->
          unless is_list(boundaries) and length(boundaries) <= 10000,
            do: raise(ArgumentError, "bounded resource contact list required")

          Enum.each(
            boundaries,
            &Input.number!(
              &1,
              "resource contact",
              source.start.seconds_since_j2000,
              source.stop.seconds_since_j2000
            )
          )

          assumptions =
            Map.put(
              model.assumptions,
              "contact_search",
              JsonSafety.normalize_input!(evidence, "resource contact search")
            )

          {Map.merge(model, %{
             boundaries: model.boundaries ++ boundaries,
             boundary_status: :complete,
             assumptions: assumptions
           }), cache}

        {:error, reason} ->
          throw({:resource_evaluation_failed, reason, cache})

        {:unknown, evidence} ->
          # Unknown geometry/budget exhaustion cannot be silently integrated as sunlight.
          assumptions =
            Map.put(model.assumptions, "contact_search", %{
              "status" => "unknown",
              "evidence" =>
                if(is_map(evidence),
                  do: JsonSafety.normalize_input!(evidence, "incomplete resource contact search"),
                  else: inspect(evidence, limit: 20)
                )
            })

          {Map.merge(model, %{boundary_status: :unknown, assumptions: assumptions}), cache}

        _ ->
          raise ArgumentError, "invalid resource contact search result"
      end
    end)
  end

  defp intervals(segments, boundaries, step, limit) do
    Enum.reduce_while(segments, {:ok, []}, fn segment, {:ok, all} ->
      count = ceil((segment.stop - segment.start) / step)

      if count > limit do
        {:halt, {:unknown, "resource_interval_limit_exceeded"}}
      else
        critical = [
          segment.start,
          segment.stop | Enum.filter(boundaries, &(&1 > segment.start and &1 < segment.stop))
        ]

        # Uniform ticks a floating-point neighbour from a mandatory boundary can
        # create a fictitious interval with no representable midpoint. Retain the
        # exact boundary and omit only that redundant uniform tick. Distinct
        # mandatory boundaries still fail unknown if they cannot be resolved.
        ticks =
          for i <- 1..max(1, count),
              t = segment.start + i * step,
              t < segment.stop,
              Enum.all?(critical, fn edge ->
                lo = min(t, edge)
                hi = max(t, edge)
                mid = lo + (hi - lo) / 2
                t == edge or (mid > lo and mid < hi)
              end),
              do: t

        times = critical ++ ticks

        intervals =
          times
          |> Enum.sort()
          |> Enum.dedup_by(&(&1 * 1.0))
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.map(fn [a, b] -> {segment, a, b} end)

        if length(all) + length(intervals) > limit,
          do: {:halt, {:unknown, "resource_interval_limit_exceeded"}},
          else: {:cont, {:ok, all ++ intervals}}
      end
    end)
  end

  defp level(asset, model, intervals, step, policy, state_at, cache) do
    start = policy.horizon.start.seconds_since_j2000
    stop = policy.horizon.stop.seconds_since_j2000

    initial = %{
      state: model.initial,
      samples: [],
      statuses: [],
      first_issue: :null,
      extrema: extrema(%{}, model.initial),
      margins: %{},
      last: start,
      uncovered: []
    }

    {segment, _, _} = hd(intervals)
    evaluations = [{segment, start, start} | intervals]

    {acc, cache} =
      Enum.reduce_while(evaluations, {initial, cache}, fn {segment, a, b}, {acc, cache} ->
        midpoint = a + (b - a) / 2

        cond do
          b > a and (midpoint <= a or midpoint >= b) ->
            {:halt, {halt_unknown(acc, a, stop, "resource_epoch_resolution_insufficient"), cache}}

          a != acc.last ->
            {:halt,
             {halt_unknown(acc, acc.last, stop, "resource_timeline_gap_or_overlap"), cache}}

          true ->
            case model_input(model, asset, segment, a, b, midpoint, state_at, cache) do
              {:ok, input, cache} ->
                input = Map.merge(input, %{interval_start_s: a, interval_end_s: b})
                {next, result, cache} = call(model, acc.state, input, b - a, cache)
                status = Result.status(result)

                evidence = %{
                  "starts_at_s" => a,
                  "ends_at_s" => b,
                  "evaluated_at_s" => midpoint,
                  "scope" => segment.scope,
                  "phase" => segment.phase,
                  "mode" => segment.mode,
                  "checks" => result.checks,
                  "metrics" =>
                    OrbitalDynamics.MissionAnalysis.ReportData.pending(
                      result.metrics,
                      "resource metrics"
                    )
                }

                issue =
                  if status != "supported" and acc.first_issue == :null,
                    do: evidence,
                    else: acc.first_issue

                acc = %{
                  acc
                  | statuses: [status | acc.statuses],
                    first_issue: issue,
                    margins: margins(acc.margins, result.checks)
                }

                if Enum.any?(result.checks, &(&1.status == :unknown)) do
                  {:halt, {halt_unknown(acc, a, stop, "resource_model_unknown"), cache}}
                else
                  sample =
                    Map.merge(evidence, %{
                      "epoch_s" => b,
                      "state" =>
                        OrbitalDynamics.MissionAnalysis.ReportData.pending(next, "resource state")
                    })

                  sample =
                    if Map.has_key?(input, :kinematics_start),
                      do:
                        Map.put(sample, "kinematics", %{
                          "start" =>
                            Map.take(
                              input.kinematics_start,
                              ~w(epoch_s quaternion_wxyz angular_velocity_inertial_deg_s angular_acceleration_inertial_deg_s2)
                            ),
                          "mid" =>
                            Map.take(
                              input.kinematics_mid,
                              ~w(epoch_s quaternion_wxyz angular_velocity_inertial_deg_s angular_acceleration_inertial_deg_s2)
                            ),
                          "end" =>
                            Map.take(
                              input.kinematics_end,
                              ~w(epoch_s quaternion_wxyz angular_velocity_inertial_deg_s angular_acceleration_inertial_deg_s2)
                            )
                        }),
                      else: sample

                  {:cont,
                   {%{
                      acc
                      | state: next,
                        last: b,
                        samples: [sample | acc.samples],
                        extrema: extrema(acc.extrema, next)
                    }, cache}}
                end

              {:unknown, reason, cache} ->
                {:halt, {halt_unknown(acc, a, stop, inspect(reason)), cache}}

              {:error, reason, cache} ->
                throw({:resource_evaluation_failed, reason, cache})
            end
        end
      end)

    acc =
      if acc.last < stop and acc.uncovered == [],
        do: halt_unknown(acc, acc.last, stop, "resource_timeline_incomplete"),
        else: acc

    {%{
       "sample_step_s" => step,
       "status" => status(acc.statuses),
       "initial_state" => model.initial,
       "samples" => Enum.reverse(acc.samples),
       "requested_interval_count" => length(intervals),
       "propagated_interval_count" =>
         Enum.count(acc.samples, &(&1["ends_at_s"] > &1["starts_at_s"])),
       "maximum_requested_interval_s" =>
         intervals |> Enum.map(fn {_, a, b} -> b - a end) |> Enum.max(),
       "state_extrema" => acc.extrema,
       "minimum_margins" => acc.margins,
       "first_issue" => acc.first_issue,
       "uncovered_intervals" => acc.uncovered,
       "evaluated_through_s" => acc.last,
       "final_state" => if(acc.uncovered == [], do: acc.state, else: :null)
     }, cache}
  end

  defp model_input(model, asset, segment, a, b, t, state_at, cache) do
    with {:ok, input, cache} <- input(asset, segment, t, state_at, cache) do
      if model.module == OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels do
        with {:ok, first, cache} <- segment.kinematics_at.(a, cache),
             {:ok, mid, cache} <- segment.kinematics_at.(t, cache),
             {:ok, last, cache} <- segment.kinematics_at.(b, cache) do
          {:ok,
           Map.merge(input, %{
             kinematics_start: first,
             kinematics_mid: mid,
             kinematics_end: last,
             activity_type: segment.activity_type
           }), cache}
        end
      else
        {:ok, input, cache}
      end
    end
  end

  defp input(asset, segment, t, state_at, cache) do
    if segment.mode == nil do
      {:unknown, :resource_payload_mode_unknown, cache}
    else
      case state_at.(asset, t) do
        {:ok, state} ->
          case segment.at.(t, cache) do
            {:ok, q, cache} ->
              {:ok,
               %{
                 epoch_s: t,
                 spacecraft_state: state,
                 pointing: Pointing.new!(state.frame, q),
                 mode: segment.mode,
                 scope: segment.scope,
                 phase: segment.phase
               }, cache}

            other ->
              other
          end

        {:error, reason} ->
          {:error, reason, cache}
      end
    end
  end

  defp call(model, state, input, dt, cache) do
    if cache.resource.evaluations >= cache.resource.policy.max_evaluations,
      do: throw({:resource_evaluation_failed, :resource_evaluation_budget_exhausted, cache})

    cache = update_in(cache.resource.evaluations, &(&1 + 1))

    OrbitalDynamics.MissionAnalysis.Scheduling.Work.charge!("resource")

    case model.module.step(state, input, dt, model.session) do
      {:ok, next, %Result{} = result} ->
        {native_state!(next), Result.validate!(result), cache}

      {:error, reason} ->
        throw({:resource_evaluation_failed, reason, cache})

      _ ->
        raise ArgumentError, "invalid resource step result"
    end
  end

  defp report_levels(levels) do
    Enum.map(levels, fn level ->
      Enum.reduce(["initial_state", "final_state"], level, fn field, report ->
        case Map.fetch(report, field) do
          {:ok, value} when is_map(value) ->
            Map.put(
              report,
              field,
              OrbitalDynamics.MissionAnalysis.ReportData.pending(value, "resource state")
            )

          _ ->
            report
        end
      end)
    end)
  end

  defp native_state!(state) when is_map(state),
    do: OrbitalDynamics.MissionAnalysis.NativeData.container!(state, "resource state")

  defp native_state!(_),
    do: raise(ArgumentError, "resource state must be native map or struct data")

  defp status(statuses) do
    cond do
      "violated" in statuses -> "violated"
      statuses == [] or "unknown" in statuses -> "unknown"
      true -> "supported"
    end
  end

  defp halt_unknown(acc, a, b, reason),
    do: %{
      acc
      | statuses: ["unknown" | acc.statuses],
        uncovered: [%{"starts_at_s" => a, "ends_at_s" => b, "reason" => reason}]
    }

  defp unknown_level(step, policy, reason),
    do: %{
      "sample_step_s" => step,
      "status" => "unknown",
      "samples" => [],
      "uncovered_intervals" => unknown(policy, reason)["uncovered_intervals"],
      "reason" => reason
    }

  defp extrema(acc, state) do
    Enum.reduce(OrbitalDynamics.MissionAnalysis.NativeData.fields(state), acc, fn
      {key, x}, acc when is_number(x) ->
        Map.update(acc, key, %{"min" => x, "max" => x}, fn old ->
          %{"min" => min(old["min"], x), "max" => max(old["max"], x)}
        end)

      _, acc ->
        acc
    end)
  end

  defp margins(acc, checks) do
    Enum.reduce(checks, acc, fn c, acc ->
      if is_number(c.margin),
        do:
          Map.update(acc, c.id, %{"margin" => c.margin, "margin_unit" => c.margin_unit}, fn old ->
            if old["margin_unit"] != c.margin_unit,
              do: raise(ArgumentError, "resource check margin units changed during integration")

            %{old | "margin" => min(old["margin"], c.margin)}
          end),
        else: acc
    end)
  end
end
