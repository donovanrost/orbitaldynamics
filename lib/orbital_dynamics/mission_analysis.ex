defmodule OrbitalDynamics.MissionAnalysis do
  @moduledoc """
  Opt-in mission-independent sampled opportunity analysis and scheduling.

  Models own physical feasibility and predicted outcomes. This runner owns
  request/asset identities, sampling integrity, opportunity grouping, static
  resource budgets, deterministic scheduling, and explanations. It accepts
  existing `Trajectory` values, independently of how they were generated.

  All times are absolute seconds since J2000 in one explicitly declared scale.
  No frame/time transformation, propagation, command execution, or legacy
  campaign-artifact adaptation is implicit. Every request asks for one continuous
  activity; spacecraft aggregation and rolling repair are future extensions.
  """

  alias OrbitalDynamics.{Frame, StateVector}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Input, Request, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Policy, Scheduler}
  alias OrbitalDynamics.Schema.JsonSafety

  @limits [
    "sampled feasibility only; constraints may fail between samples",
    "opportunities end at observed eligible samples; no extrapolation or root finding",
    "one asset and one continuous activity per fulfilled request",
    "deterministic value-first greedy scheduling; no global optimality claim",
    "declared non-replenishing resource budgets; no subsystem simulation",
    "declared asset separation; no initial-attitude acquisition or slew simulation",
    "no automatic repair, mission-plan import, approval, or execution authority"
  ]

  @doc "Analyzes model opportunities and builds an explainable analysis-only schedule."
  def run(assets, requests, context, opts) do
    try do
      {gap, separation, include_samples?, refinement, attitude} = options!(opts)
      validate_inputs!(assets, requests)
      pairs = for asset <- assets, request <- requests, do: {asset, request}

      with {:ok, reports, sessions} <-
             analyze_pairs(pairs, context, gap, include_samples?, refinement),
           {:ok, activities, decisions, balances, attitude_report} <-
             schedule_selected(
               assets,
               requests,
               Enum.flat_map(reports, & &1["opportunities"]),
               sessions,
               attitude,
               refinement,
               separation,
               context
             ) do
        opportunities = Enum.flat_map(reports, & &1["opportunities"])

        with {:ok, activities} <-
               verify_activity_endpoints(activities, assets, requests, sessions, refinement) do
          scheduled = Map.new(activities, &{&1["request_id"], &1["id"]})

          request_reports =
            Enum.map(requests, fn request ->
              pair_reports = Enum.filter(reports, &(&1["request_id"] == request.id))
              count = Enum.count(opportunities, &(&1["request_id"] == request.id))
              activity_id = Map.get(scheduled, request.id)

              %{
                "request_id" => request.id,
                "activity_type" => request.activity_type,
                "allowed_starts_at_s" => request.starts_at_s,
                "allowed_ends_at_s" => request.ends_at_s,
                "required_duration_s" => request.duration_s,
                "value" => request.value,
                "resource_costs" => request.resource_costs,
                "opportunity_count" => count,
                "status" => if(activity_id, do: "scheduled", else: "unfulfilled"),
                "activity_ids" => List.wrap(activity_id),
                "reasons" =>
                  if(activity_id,
                    do: [],
                    else: request_reasons(request, pair_reports, decisions, count)
                  )
              }
            end)

          {:ok,
           %{
             "format" => "mission_analysis.v1",
             "execution_boundary" => "analysis_only_no_command_execution",
             "time_system" => %{
               "epoch_origin" => "J2000",
               "scale" => Atom.to_string(hd(requests).time_scale)
             },
             "assumptions" =>
               Map.merge(
                 %{"max_sample_gap_s" => gap, "asset_separation_s" => separation},
                 if(refinement,
                   do: %{"window_refinement" => WindowRefinement.describe(refinement)},
                   else: %{}
                 )
               )
               |> Map.merge(
                 if(attitude, do: %{"attitude" => Policy.describe(attitude)}, else: %{})
               ),
             "attitude_planning" => attitude_report || :null,
             "model_limits" => limits_for(refinement, attitude),
             "analyses" => reports,
             "requests" => request_reports,
             "opportunities" => opportunities,
             "activities" => activities,
             "selection_decisions" => decisions,
             "remaining_resource_budgets" => balances
           }}
        end
      end
    rescue
      error in [ArgumentError, KeyError] ->
        {:error, {:invalid_mission_analysis, Exception.message(error)}}
    end
  end

  defp limits_for(refinement, attitude) do
    limits =
      if refinement,
        do: [
          "eligible-side brackets refine observed transitions; no guarantee of continuous feasibility"
          | List.delete(
              @limits,
              "opportunities end at observed eligible samples; no extrapolation or root finding"
            )
        ],
        else: @limits

    if attitude,
      do: [
        "sampled kinematic attitude support; no actuator, disturbance, or achieved attitude validation"
        | List.delete(
            limits,
            "declared asset separation; no initial-attitude acquisition or slew simulation"
          )
      ],
      else: limits
  end

  defp schedule_selected(
         assets,
         requests,
         opportunities,
         _sessions,
         nil,
         _refinement,
         separation,
         _context
       ) do
    {a, d, b} = schedule(assets, requests, opportunities, separation)
    {:ok, a, d, b, nil}
  end

  defp schedule_selected(
         assets,
         requests,
         opportunities,
         sessions,
         attitude,
         refinement,
         separation,
         context
       ) do
    Scheduler.schedule(
      assets,
      requests,
      opportunities,
      sessions,
      attitude,
      refinement,
      separation,
      fn asset, t -> sampled_state(asset, t, refinement) end,
      context
    )
  end

  defp verify_activity_endpoints(activities, _assets, _requests, _sessions, nil),
    do: {:ok, activities}

  defp verify_activity_endpoints(activities, assets, requests, sessions, policy) do
    assets = Map.new(assets, &{&1.id, &1})
    requests = Map.new(requests, &{&1.id, &1})

    Enum.reduce_while(activities, {:ok, []}, fn activity, {:ok, checked} ->
      asset = assets[activity["asset_id"]]
      request = requests[activity["request_id"]]

      session = Map.fetch!(sessions, {asset.id, request.id})

      result =
        with {:ok, first} <- sample_at(asset, request, session, activity["starts_at_s"], policy),
             {:ok, last} <- sample_at(asset, request, session, activity["ends_at_s"], policy) do
          if first["feasible"] and last["feasible"],
            do: {:ok, [first, last]},
            else: {:error, {:scheduled_endpoint_ineligible, activity["id"]}}
        end

      case result do
        {:ok, samples} ->
          {:cont,
           {:ok,
            [
              Map.merge(activity, %{
                "endpoint_samples" => samples,
                "endpoint_evaluation_count" => 2
              })
              | checked
            ]}}

        {:error, reason} ->
          {:halt, {:error, {:activity_endpoint_verification_failed, reason}}}
      end
    end)
    |> case do
      {:ok, checked} -> {:ok, Enum.reverse(checked)}
      error -> error
    end
  end

  defp options!(opts) do
    unless is_list(opts) and Keyword.keyword?(opts) and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))) and
             Keyword.keys(opts) --
               [
                 :max_sample_gap_s,
                 :asset_separation_s,
                 :include_samples,
                 :window_refinement,
                 :attitude
               ] ==
               [] do
      raise ArgumentError, "invalid mission analysis options"
    end

    gap = Input.positive!(Keyword.fetch!(opts, :max_sample_gap_s), "max_sample_gap_s")

    separation =
      Input.number!(Keyword.fetch!(opts, :asset_separation_s), "asset_separation_s", 0, 1.0e12)

    include = Keyword.get(opts, :include_samples, true)
    unless is_boolean(include), do: raise(ArgumentError, "include_samples must be boolean")

    refinement =
      case Keyword.get(opts, :window_refinement) do
        nil ->
          nil

        %WindowRefinement{} = r ->
          WindowRefinement.new!(
            state_at: r.state_at,
            tracking_lookback_s: r.tracking_lookback_s,
            time_tolerance_s: r.time_tolerance_s,
            max_extra_evaluations: r.max_extra_evaluations
          )

        _ ->
          raise ArgumentError, "window_refinement must be a WindowRefinement policy"
      end

    attitude =
      case Keyword.get(opts, :attitude) do
        nil -> nil
        %Policy{} = p -> Policy.validate!(p)
        _ -> raise ArgumentError, "attitude must be an Attitude.Policy"
      end

    if attitude != nil and refinement == nil,
      do:
        raise(
          ArgumentError,
          "attitude planning requires an explicit window refinement/state sampling policy"
        )

    {gap, separation, include, refinement, attitude}
  end

  defp validate_inputs!(assets, requests) do
    unless is_list(assets) and assets != [] and is_list(requests) and requests != [],
      do: raise(ArgumentError, "nonempty asset and request lists required")

    unique_ids!(assets)
    unique_ids!(requests)

    unless length(Enum.uniq(Enum.map(requests, & &1.time_scale))) == 1,
      do: raise(ArgumentError, "requests must share one explicit time scale")

    Enum.each(requests, fn %Request{} = r ->
      Request.new!(r.id, r.model, r.subject,
        activity_type: r.activity_type,
        starts_at_s: r.starts_at_s,
        ends_at_s: r.ends_at_s,
        duration_s: r.duration_s,
        time_scale: r.time_scale,
        value: r.value,
        parameters: r.parameters,
        resource_costs: r.resource_costs
      )
    end)

    Enum.each(assets, fn %Asset{} = asset ->
      Asset.new!(asset.id, asset.trajectory, asset.capabilities, asset.resource_budgets)
      states = asset.trajectory.states

      unless is_list(states) and length(states) in 2..10_000,
        do: raise(ArgumentError, "trajectories require 2..10000 ordered samples")

      first = hd(states)

      Enum.reduce(states, nil, fn %StateVector{} = state, previous ->
        Input.vector!(state.position_km, "position_km")
        Input.vector!(state.velocity_km_s, "velocity_km_s")
        t = Input.number!(state.epoch.seconds_since_j2000, "sample epoch", -1.0e12, 1.0e12)

        unless state.epoch.scale == hd(requests).time_scale and
                 Frame.compatible?(first.frame, state.frame),
               do:
                 raise(
                   ArgumentError,
                   "trajectory frames/time scales must be consistent; no implicit conversion"
                 )

        if previous != nil and t <= previous,
          do: raise(ArgumentError, "sample epochs must strictly increase")

        t
      end)
    end)

    if Enum.sum(Enum.map(assets, &length(&1.trajectory.states))) * length(requests) > 100_000,
      do: raise(ArgumentError, "mission analysis exceeds 100000 sample evaluations")
  end

  defp unique_ids!(values) do
    ids = Enum.map(values, &Input.id!(&1.id))
    if length(ids) != length(Enum.uniq(ids)), do: raise(ArgumentError, "duplicate mission IDs")
  end

  defp analyze_pairs(pairs, context, gap, include?, refinement) do
    Enum.reduce_while(pairs, {:ok, [], %{}}, fn {asset, request}, {:ok, reports, sessions} ->
      case analyze_pair(asset, request, context, gap, include?, refinement) do
        {:ok, report, session} ->
          {:cont, {:ok, [report | reports], Map.put(sessions, {asset.id, request.id}, session)}}

        {:error, reason} ->
          {:halt, {:error, {:model_error, asset.id, request.id, reason}}}
      end
    end)
    |> case do
      {:ok, reports, sessions} -> {:ok, Enum.reverse(reports), sessions}
      error -> error
    end
  end

  defp analyze_pair(asset, request, context, gap, include?, refinement) do
    model = request.model

    unless Code.ensure_loaded?(model) and function_exported?(model, :prepare, 3) and
             function_exported?(model, :evaluate, 3) and
             function_exported?(model, :capabilities, 0),
           do: raise(ArgumentError, "model must implement MissionAnalysis.Model")

    base = %{
      "asset_id" => asset.id,
      "request_id" => request.id,
      "model" => JsonSafety.normalize_input!(model.capabilities(), "model capabilities"),
      "trajectory_assumptions" =>
        JsonSafety.normalize_input!(asset.trajectory.assumptions, "trajectory assumptions")
    }

    case Map.fetch(asset.capabilities, model) do
      :error ->
        {:ok,
         Map.merge(base, %{
           "status" => "capability_unavailable",
           "opportunities" => [],
           "failed_check_counts" => %{}
         }), nil}

      {:ok, config} ->
        with {:ok, session, assumptions} <- prepare_model(model, request, config, context),
             {:ok, samples} <- evaluate_samples(asset, request, session, gap, refinement),
             {:ok, windows, samples, extra_count} <-
               analyze_windows(asset, request, session, samples, gap, refinement) do
          opportunities =
            windows
            |> Enum.filter(&(&1["ends_at_s"] - &1["starts_at_s"] >= request.duration_s))
            |> Enum.with_index(1)
            |> Enum.map(fn {window, index} ->
              %{
                "id" =>
                  "opportunity:#{byte_size(asset.id)}:#{asset.id}:#{byte_size(request.id)}:#{request.id}:#{index}",
                "asset_id" => asset.id,
                "request_id" => request.id,
                "activity_type" => request.activity_type,
                "starts_at_s" => window["starts_at_s"],
                "ends_at_s" => window["ends_at_s"],
                "sample_count" => window["sample_count"]
              }
            end)

          failures =
            samples
            |> Enum.flat_map(& &1["checks"])
            |> Enum.reject(& &1["passed"])
            |> Enum.frequencies_by(& &1["id"])

          status =
            cond do
              samples == [] -> "no_ephemeris_samples_in_request_window"
              opportunities == [] -> "no_sample_supported_opportunity"
              true -> "opportunities_found"
            end

          report =
            Map.merge(base, %{
              "status" => status,
              "assumptions" => JsonSafety.normalize_input!(assumptions, "model assumptions"),
              "evaluated_sample_count" => length(samples),
              "feasible_sample_count" => Enum.count(samples, & &1["feasible"]),
              "failed_check_counts" => failures,
              "opportunities" => opportunities
            })

          report =
            if refinement,
              do:
                Map.merge(report, %{
                  "window_evidence" => windows,
                  "transition_refinement_evaluation_count" => extra_count
                }),
              else: report

          {:ok, if(include?, do: Map.put(report, "samples", samples), else: report), session}
        end
    end
  end

  defp prepare_model(model, request, config, context) do
    case model.prepare(request, config, context) do
      {:ok, session, assumptions} when is_map(assumptions) -> {:ok, session, assumptions}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_model_preparation}
    end
  end

  defp evaluate_samples(asset, request, session, gap, refinement) do
    asset.trajectory.states
    |> Enum.reduce_while({:ok, [], nil}, fn state, {:ok, samples, previous} ->
      t = state.epoch.seconds_since_j2000

      if t >= request.starts_at_s and t <= request.ends_at_s do
        prior =
          if previous && t - previous.epoch.seconds_since_j2000 <= gap, do: previous, else: nil

        result =
          if refinement,
            do: sample_at(asset, request, session, t, refinement),
            else: evaluate_result(request.model, session, state, prior)

        case result do
          {:ok, sample} -> {:cont, {:ok, [sample | samples], state}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:cont, {:ok, samples, state}}
      end
    end)
    |> case do
      {:ok, samples, _} -> {:ok, Enum.reverse(samples)}
      error -> error
    end
  end

  defp analyze_windows(_asset, _request, _session, samples, gap, nil) do
    result =
      Enum.map(windows(samples, gap), fn w ->
        %{
          "starts_at_s" => hd(w)["epoch_s"],
          "ends_at_s" => List.last(w)["epoch_s"],
          "sample_count" => length(w)
        }
      end)

    {:ok, result, samples, 0}
  end

  defp analyze_windows(asset, request, session, samples, gap, refinement) do
    states = asset.trajectory.states
    start = max(request.starts_at_s, hd(states).epoch.seconds_since_j2000)
    stop = min(request.ends_at_s, List.last(states).epoch.seconds_since_j2000)

    if start > stop,
      do: {:ok, [], [], 0},
      else:
        WindowRefinement.run(
          samples,
          &sample_at(asset, request, session, &1, refinement),
          start,
          stop,
          gap,
          refinement
        )
  end

  defp sample_at(asset, request, session, t, refinement) do
    start = hd(asset.trajectory.states).epoch.seconds_since_j2000
    before = t - refinement.tracking_lookback_s

    with {:ok, state} <- sampled_state(asset, t, refinement),
         {:ok, prior} <-
           if(before >= start, do: sampled_state(asset, before, refinement), else: {:ok, nil}) do
      evaluate_result(request.model, session, state, prior)
    end
  end

  defp sampled_state(asset, t, refinement) do
    first = hd(asset.trajectory.states)

    case refinement.state_at.(asset, t) do
      {:ok, %StateVector{} = state} ->
        Input.vector!(state.position_km, "sampled position")
        Input.vector!(state.velocity_km_s, "sampled velocity")

        unless state.epoch.seconds_since_j2000 == t and state.epoch.scale == first.epoch.scale and
                 Frame.compatible?(state.frame, first.frame),
               do:
                 raise(
                   ArgumentError,
                   "state sampler must preserve requested epoch, frame and scale"
                 )

        {:ok, state}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :invalid_state_sampler_result}
    end
  end

  defp evaluate_result(model, session, state, previous) do
    case model.evaluate(state, previous, session) do
      {:ok, %Evaluation{} = result} ->
        result = Evaluation.new!(result.checks, result.metrics)

        {:ok,
         %{
           "epoch_s" => state.epoch.seconds_since_j2000,
           "feasible" => Evaluation.feasible?(result),
           "checks" => result.checks,
           "metrics" => result.metrics
         }}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :invalid_model_evaluation}
    end
  end

  defp windows(samples, gap) do
    {finished, current} =
      Enum.reduce(samples, {[], []}, fn sample, {finished, current} ->
        cond do
          not sample["feasible"] -> {finish(current, finished), []}
          current == [] -> {finished, [sample]}
          sample["epoch_s"] - hd(current)["epoch_s"] <= gap -> {finished, [sample | current]}
          true -> {finish(current, finished), [sample]}
        end
      end)

    finish(current, finished) |> Enum.reverse()
  end

  defp finish([], finished), do: finished
  defp finish(current, finished), do: [Enum.reverse(current) | finished]

  defp schedule(assets, requests, opportunities, separation) do
    request_map = Map.new(requests, &{&1.id, &1})
    balances = Map.new(assets, &{&1.id, &1.resource_budgets})

    opportunities
    |> Enum.sort_by(fn o ->
      {-request_map[o["request_id"]].value, o["starts_at_s"], o["asset_id"], o["id"]}
    end)
    |> Enum.reduce({[], [], balances}, fn opportunity, {activities, decisions, balances} ->
      r = request_map[opportunity["request_id"]]
      asset_id = opportunity["asset_id"]

      start =
        earliest_slot(
          opportunity["starts_at_s"],
          r.duration_s,
          Enum.filter(activities, &(&1["asset_id"] == asset_id)),
          separation
        )

      available = balances[asset_id]

      missing =
        for {key, cost} <- r.resource_costs,
            cost > 0 and not Map.has_key?(available, key),
            do: key

      insufficient =
        for {key, cost} <- r.resource_costs, cost > Map.get(available, key, 0), do: key

      reason =
        cond do
          Enum.any?(activities, &(&1["request_id"] == r.id)) -> "request_already_scheduled"
          start + r.duration_s > opportunity["ends_at_s"] -> "asset_conflict"
          missing != [] -> "undeclared_resource_budget"
          insufficient != [] -> "insufficient_resource_budget"
          true -> "selected"
        end

      decision = %{
        "opportunity_id" => opportunity["id"],
        "request_id" => r.id,
        "asset_id" => asset_id,
        "reason" => reason,
        "resource_ids" => Enum.sort(Enum.uniq(missing ++ insufficient))
      }

      if reason == "selected" do
        activity = %{
          "id" => "activity:#{opportunity["id"]}",
          "opportunity_id" => opportunity["id"],
          "request_id" => r.id,
          "asset_id" => asset_id,
          "type" => r.activity_type,
          "starts_at_s" => start,
          "ends_at_s" => start + r.duration_s,
          "value" => r.value,
          "resource_costs" => r.resource_costs
        }

        remaining =
          Enum.reduce(r.resource_costs, available, fn {key, cost}, acc ->
            Map.update(acc, key, 0.0, &(&1 - cost))
          end)

        {[activity | activities], [decision | decisions], Map.put(balances, asset_id, remaining)}
      else
        {activities, [decision | decisions], balances}
      end
    end)
    |> then(fn {a, d, b} ->
      {Enum.sort_by(a, &{&1["starts_at_s"], &1["id"]}), Enum.reverse(d), b}
    end)
  end

  defp earliest_slot(start, duration, activities, separation) do
    activities
    |> Enum.sort_by(& &1["starts_at_s"])
    |> Enum.reduce(start, fn activity, candidate ->
      if candidate + duration + separation <= activity["starts_at_s"] or
           candidate >= activity["ends_at_s"] + separation,
         do: candidate,
         else: activity["ends_at_s"] + separation
    end)
  end

  defp request_reasons(request, reports, decisions, count) do
    if count == 0 do
      Enum.map(reports, & &1["status"]) |> Enum.uniq() |> Enum.sort()
    else
      decisions
      |> Enum.filter(&(&1["request_id"] == request.id))
      |> Enum.map(& &1["reason"])
      |> Enum.uniq()
      |> Enum.sort()
    end
  end
end
