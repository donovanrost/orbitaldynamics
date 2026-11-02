defmodule OrbitalDynamics.MissionAnalysis.Path.Runner do
  @moduledoc false
  alias OrbitalDynamics.MissionAnalysis.Path.{Policy, Result}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Motion, Quaternion}
  alias OrbitalDynamics.Schema.JsonSafety

  def prepare(nil, _assets, _requests, _context), do: nil

  def prepare(%Policy{} = p, assets, requests, context) do
    request_ids = MapSet.new(Enum.map(requests, & &1.id))

    sessions =
      Enum.reduce(p.assets, %{}, fn {id, a}, sessions ->
        unless Map.has_key?(assets, id),
          do: raise(ArgumentError, "path policy names unknown asset #{id}")

        unless Enum.all?(Map.keys(a.activity_modes), &MapSet.member?(request_ids, &1)),
          do: raise(ArgumentError, "path mode names unknown request")

        Enum.reduce(a.rules, sessions, fn rule, sessions ->
          case rule.module.prepare(assets[id], context, rule.configuration) do
            {:ok, session, assumptions} when is_map(assumptions) ->
              Map.put(sessions, {id, rule.id}, %{
                module: rule.module,
                session: session,
                assumptions: JsonSafety.normalize_input!(assumptions, "path assumptions")
              })

            {:error, reason} ->
              throw({:path_preparation_failed, id, rule.id, reason})

            _ ->
              raise ArgumentError, "invalid path preparation result"
          end
        end)
      end)

    %{policy: p, sessions: sessions, values: %{}, evaluations: 0}
  end

  def activity(asset, request, session, start, stop, pointing_at, state_at, cache) do
    mode =
      case cache.path do
        nil -> nil
        runtime -> get_in(runtime.policy.assets, [asset.id, :activity_modes, request.id])
      end

    descriptor = mode_descriptor(cache.path, asset.id, mode)

    {compatibility, cache} =
      cond do
        cache.path == nil ->
          {:disabled, cache}

        descriptor == nil or not function_exported?(request.model, :activity_mode, 2) ->
          {:unknown, cache}

        true ->
          service_mode(asset, request, descriptor, session, cache)
      end

    case compatibility do
      :disabled ->
        evaluate_path(asset, start, stop, [], "activity", mode, pointing_at, state_at, cache)

      :unknown ->
        {:unknown, :service_mode_unknown,
         %{"status" => "unknown", "reason" => "service_mode_unknown", "scope" => "activity"},
         cache}

      {:ok, %Result{} = result} ->
        result = Result.new!(result.checks, result.metrics)

        case Result.status(result) do
          "supported" ->
            evaluate_path(asset, start, stop, [], "activity", mode, pointing_at, state_at, cache)

          status ->
            evidence = %{
              "status" => status,
              "scope" => "activity",
              "mode" => descriptor,
              "checks" => result.checks,
              "reason" => "service_mode_incompatible_or_unknown"
            }

            {if(status == "violated", do: :infeasible, else: :unknown),
             :service_mode_incompatible_or_unknown, evidence, cache}
        end

      {:error, reason} ->
        {:error, reason, cache}

      _ ->
        {:error, :invalid_activity_mode_result, cache}
    end
  end

  defp service_mode(asset, request, mode, session, cache) do
    runtime = cache.path
    key = {:service_mode, asset.id, request.id, mode}

    case Map.fetch(runtime.values, key) do
      {:ok, response} ->
        {response, cache}

      :error ->
        if runtime.evaluations >= runtime.policy.max_evaluations do
          {{:error, :path_evaluation_budget_exhausted}, cache}
        else
          response = request.model.activity_mode(mode, session)

          response =
            case response do
              {:ok, %Result{} = r} -> {:ok, Result.new!(r.checks, r.metrics)}
              {:error, reason} -> {:error, reason}
              _ -> {:error, :invalid_activity_mode_result}
            end

          runtime = %{
            runtime
            | values: Map.put(runtime.values, key, response),
              evaluations: runtime.evaluations + 1
          }

          {response, %{cache | path: runtime}}
        end
    end
  end

  defp mode_descriptor(nil, _asset, _mode), do: nil

  defp mode_descriptor(runtime, asset, mode) do
    case get_in(runtime.policy.assets, [asset, :modes, mode]) do
      nil -> nil
      parameters -> %{"name" => mode, "parameters" => parameters}
    end
  end

  def transition(asset, plan, scope, state_at, cache) do
    mode =
      case cache.path do
        nil -> nil
        runtime -> get_in(runtime.policy.assets, [asset.id, :transition_mode])
      end

    origin = plan["source_epoch_s"]

    boundaries =
      plan["phases"]
      |> Enum.flat_map(&[origin + &1["starts_after_s"], origin + &1["ends_after_s"]])

    at = fn t, cache -> {:ok, Motion.at(plan, t - origin).quaternion, cache} end

    evaluate_path(
      asset,
      origin,
      plan["destination_epoch_s"],
      boundaries,
      scope,
      mode,
      at,
      state_at,
      cache
    )
  end

  defp evaluate_path(
         _asset,
         _start,
         _stop,
         _boundaries,
         _scope,
         _mode,
         _at,
         _state_at,
         %{path: nil} = cache
       ),
       do: {:ok, %{"status" => "not_enabled"}, cache}

  defp evaluate_path(asset, start, stop, boundaries, scope, mode, at, state_at, cache) do
    runtime = cache.path

    cond do
      not Map.has_key?(runtime.policy.assets, asset.id) ->
        {:unknown, :path_configuration_missing,
         %{"status" => "unknown", "reason" => "path_configuration_missing", "scope" => scope},
         cache}

      mode_descriptor(runtime, asset.id, mode) == nil ->
        {:unknown, :payload_mode_not_declared,
         %{"status" => "unknown", "reason" => "payload_mode_not_declared", "scope" => scope},
         cache}

      start < hd(asset.trajectory.states).epoch.seconds_since_j2000 or
          stop > List.last(asset.trajectory.states).epoch.seconds_since_j2000 ->
        {:unknown, :path_outside_coverage,
         %{
           "status" => "unknown",
           "reason" => "path_outside_trajectory_coverage",
           "scope" => scope
         }, cache}

      true ->
        {levels, cache} =
          Enum.map_reduce(runtime.policy.sample_steps_s, cache, fn step, cache ->
            level(
              asset,
              start,
              stop,
              boundaries,
              scope,
              mode_descriptor(runtime, asset.id, mode),
              step,
              at,
              state_at,
              cache
            )
          end)

        statuses = Enum.map(levels, & &1["status"])

        status =
          cond do
            "violated" in statuses -> "violated"
            "unknown" in statuses -> "unknown"
            true -> "supported"
          end

        evidence = %{
          "status" => status,
          "scope" => scope,
          "mode" => mode,
          "starts_at_s" => start,
          "ends_at_s" => stop,
          "resolution_status" =>
            if(length(Enum.uniq(statuses)) == 1,
              do: "agrees_across_tested_steps",
              else: "changes_across_tested_steps"
            ),
          "levels" => levels,
          "limits" =>
            "sampled path checks only; no continuous or mode-switch-mechanism certification"
        }

        case status do
          "supported" -> {:ok, evidence, cache}
          "violated" -> {:infeasible, :path_constraint_violated, evidence, cache}
          "unknown" -> {:unknown, :path_constraint_unknown, evidence, cache}
        end
    end
  catch
    {:path_evaluation_failed, reason, failed_cache} -> {:error, reason, failed_cache}
  end

  defp level(
         asset,
         start,
         stop,
         boundaries,
         scope,
         mode,
         step,
         at,
         state_at,
         cache
       ) do
    maximum = cache.path.policy.max_samples_per_segment
    count = trunc(:math.floor(max(0.0, stop - start) / step))

    cond do
      count + 1 > maximum ->
        {%{
           "sample_step_s" => step,
           "status" => "unknown",
           "reason" => "path_sample_budget_exhausted",
           "tested_sample_count" => 0
         }, cache}

      stop > start and (start + step == start or stop - step == stop) ->
        {%{
           "sample_step_s" => step,
           "status" => "unknown",
           "reason" => "path_epoch_precision_exhausted",
           "tested_sample_count" => 0
         }, cache}

      true ->
        times =
          (Enum.map(0..count, &(start + &1 * step)) ++ boundaries ++ [stop])
          |> Enum.filter(&(&1 >= start and &1 <= stop))
          |> Enum.map(&(&1 * 1.0))
          |> Enum.uniq()
          |> Enum.sort()

        if length(times) > maximum do
          {%{
             "sample_step_s" => step,
             "status" => "unknown",
             "reason" => "path_sample_budget_exhausted",
             "tested_sample_count" => 0
           }, cache}
        else
          {samples, cache} =
            Enum.reduce_while(times, {[], cache}, fn t, {samples, cache} ->
              result =
                with {:ok, q, cache} <- at.(t, cache), {:ok, state} <- state_at.(asset, t) do
                  point = Pointing.new!(state.frame, q)

                  {rules, cache} =
                    Enum.map_reduce(cache.path.policy.assets[asset.id].rules, cache, fn rule,
                                                                                        cache ->
                      evaluate_rule(asset, state, point, mode, rule, cache)
                    end)

                  statuses = Enum.map(rules, & &1["status"])

                  status =
                    cond do
                      "violated" in statuses -> "violated"
                      "unknown" in statuses -> "unknown"
                      true -> "supported"
                    end

                  {:ok,
                   %{
                     "epoch_s" => t,
                     "scope" => scope,
                     "mode" => mode,
                     "status" => status,
                     "rules" => rules
                   }, cache}
                else
                  {:unknown, reason, cache} ->
                    {:ok,
                     %{
                       "epoch_s" => t,
                       "scope" => scope,
                       "mode" => mode,
                       "status" => "unknown",
                       "reason" => inspect(reason),
                       "rules" => []
                     }, cache}

                  {:error, reason, cache} ->
                    throw({:path_evaluation_failed, reason, cache})

                  {:error, reason} ->
                    throw({:path_evaluation_failed, reason, cache})
                end

              {:ok, sample, cache} = result

              if sample["status"] == "supported",
                do: {:cont, {[sample | samples], cache}},
                else: {:halt, {[sample | samples], cache}}
            end)

          samples = Enum.reverse(samples)
          status = List.last(samples)["status"]

          largest =
            samples
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(fn [a, b] -> b["epoch_s"] - a["epoch_s"] end)
            |> Enum.max(fn -> 0.0 end)

          {%{
             "sample_step_s" => step,
             "status" => status,
             "tested_sample_count" => length(samples),
             "largest_tested_interval_s" => largest,
             "coverage" =>
               if(status == "supported",
                 do: "all_requested_path_samples",
                 else: "prefix_stopped_at_first_unsupported_sample"
               ),
             "first_issue" => if(status == "supported", do: :null, else: List.last(samples)),
             "samples" => samples
           }, cache}
        end
    end
  end

  defp evaluate_rule(asset, state, point, mode, rule, cache) do
    runtime = cache.path

    key =
      {asset.id, rule.id, state.epoch.seconds_since_j2000 * 1.0,
       Quaternion.new!(point.quaternion), mode}

    case Map.fetch(runtime.values, key) do
      {:ok, result} ->
        {result, cache}

      :error ->
        if runtime.evaluations >= runtime.policy.max_evaluations,
          do: throw({:path_evaluation_failed, :path_evaluation_budget_exhausted, cache})

        captured = runtime.sessions[{asset.id, rule.id}]

        case captured.module.evaluate(state, point, mode, captured.session) do
          {:ok, %Result{} = r} ->
            r = Result.new!(r.checks, r.metrics)

            result = %{
              "rule_id" => rule.id,
              "status" => Result.status(r),
              "checks" => r.checks,
              "metrics" => r.metrics
            }

            runtime = %{
              runtime
              | values: Map.put(runtime.values, key, result),
                evaluations: runtime.evaluations + 1
            }

            {result, %{cache | path: runtime}}

          {:error, reason} ->
            throw({:path_evaluation_failed, {:path_rule_error, rule.id, reason}, cache})

          _ ->
            throw({:path_evaluation_failed, {:invalid_path_rule_result, rule.id}, cache})
        end
    end
  end

  def brief(%{"levels" => levels} = e),
    do: %{e | "levels" => Enum.map(levels, &Map.delete(&1, "samples"))}

  def brief(e), do: e

  def brief_details(details),
    do:
      Map.update(details, "path_checks", %{}, fn checks ->
        Map.new(checks, fn {k, v} -> {k, brief(v)} end)
      end)

  def describe(nil), do: :null

  def describe(runtime),
    do: %{
      "rule_evaluation_count" => runtime.evaluations,
      "policy" => Policy.describe(runtime.policy),
      "captured_rules" =>
        runtime.sessions
        |> Enum.sort_by(fn {{a, r}, _} -> {a, r} end)
        |> Enum.map(fn {{a, r}, s} ->
          %{"asset_id" => a, "rule_id" => r, "assumptions" => s.assumptions}
        end),
      "coverage" =>
        "declared initial attitude through last scheduled activity only; no terminal idle or unselected asset path"
    }
end
