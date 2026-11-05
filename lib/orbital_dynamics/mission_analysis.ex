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
  activity; lifecycle adapters can carry explicit source-bound activity segments.
  """

  alias OrbitalDynamics.{Frame, StateVector}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Input, Request, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Policy
  alias OrbitalDynamics.MissionAnalysis.Scheduling
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
    case run_profiled(assets, requests, context, opts) do
      {:ok, report, _measurements} -> {:ok, report}
      error -> error
    end
  end

  @doc "Runs the same planner, returning monotonic wall times separately from deterministic evidence."
  def run_profiled(assets, requests, context, opts) do
    try do
      {gap, separation, include_samples?, refinement, attitude, opportunity_search, scheduling} =
        options!(opts)

      validate_inputs!(assets, requests, attitude)
      pairs = for asset <- assets, request <- requests, do: {asset, request}

      with {opportunity_us, {:ok, reports, sessions}} <-
             :timer.tc(fn ->
               case analyze_pairs(
                      pairs,
                      context,
                      gap,
                      include_samples?,
                      refinement,
                      opportunity_search
                    ) do
                 {:ok, reports, sessions} ->
                   reports =
                     Scheduling.Availability.apply(
                       reports,
                       if(scheduling, do: scheduling.availability, else: nil),
                       assets,
                       requests,
                       attitude
                     )

                   reports =
                     Scheduling.CommandDelivery.apply(
                       reports,
                       if(scheduling, do: scheduling.command_delivery, else: nil),
                       assets,
                       requests,
                       attitude
                     )

                   {:ok, reports, sessions}

                 error ->
                   error
               end
             end),
           {scheduling_us, {:ok, activities, decisions, balances, attitude_report, search_report}} <-
             :timer.tc(fn ->
               schedule_selected(
                 assets,
                 requests,
                 Enum.flat_map(reports, & &1["opportunities"]),
                 sessions,
                 attitude,
                 refinement,
                 separation,
                 context,
                 scheduling
               )
             end) do
        with {verification_us, {:ok, activities}} <-
               :timer.tc(fn ->
                 # Configured search verifies every eligible incumbent before
                 # returning it, inside its shared work scope. Repeating those
                 # callbacks here would escape the cap and duplicate work.
                 if scheduling,
                   do: {:ok, activities},
                   else:
                     verify_activity_endpoints(activities, assets, requests, sessions, refinement)
               end) do
          opportunities = Enum.flat_map(reports, & &1["opportunities"])
          activities = attach_opportunity_evidence(activities, opportunities, opportunity_search)
          request_by_id = Map.new(requests, &{&1.id, &1})

          activities =
            Enum.map(activities, fn a ->
              segment = Request.segment_description(request_by_id[a["request_id"]])
              if segment, do: Map.put(a, "activity_segment", segment), else: a
            end)

          decisions = attach_opportunity_evidence(decisions, opportunities, opportunity_search)
          scheduled = Map.new(activities, &{&1["request_id"], &1["id"]})

          request_reports =
            Enum.map(requests, fn request ->
              pair_reports = Enum.filter(reports, &(&1["request_id"] == request.id))
              count = Enum.count(opportunities, &(&1["request_id"] == request.id))
              activity_id = Map.get(scheduled, request.id)

              row = %{
                "request_id" => request.id,
                "activity_type" => request.activity_type,
                "allowed_starts_at_s" => request.starts_at_s,
                "allowed_ends_at_s" => request.ends_at_s,
                "required_duration_s" => request.duration_s,
                "value" => request.value,
                "resource_costs" => request.resource_costs,
                "opportunity_count" => count,
                "scheduling_summary" =>
                  Scheduling.Explanation.summary(decisions, search_report, request.id),
                "status" => if(activity_id, do: "scheduled", else: "unfulfilled"),
                "activity_ids" => List.wrap(activity_id),
                "reasons" =>
                  if(activity_id,
                    do: [],
                    else: request_reasons(request, pair_reports, decisions, count)
                  )
              }

              segment = Request.segment_description(request)
              if segment, do: Map.put(row, "activity_segment", segment), else: row
            end)

          {:ok,
           %{
             "format" => "mission_analysis.v1",
             "execution_boundary" => "analysis_only_no_command_execution",
             "time_system" => %{
               "epoch_origin" => "J2000",
               "scale" =>
                 Atom.to_string(
                   if(requests == [],
                     do: attitude.horizon.start.scale,
                     else: hd(requests).time_scale
                   )
                 )
             },
             "assumptions" =>
               Map.merge(
                 %{"max_sample_gap_s" => gap, "asset_separation_s" => separation},
                 if(refinement,
                   do: %{
                     "window_refinement" =>
                       if(opportunity_search,
                         do: %{
                           "usage" => "checked_state_sampler_and_fixed_lookback_only",
                           "tracking_lookback_s" => refinement.tracking_lookback_s
                         },
                         else: WindowRefinement.describe(refinement)
                       )
                   },
                   else: %{}
                 )
               )
               |> Map.merge(
                 if(attitude, do: %{"attitude" => Policy.describe(attitude)}, else: %{})
               ),
             "opportunity_search" =>
               if(opportunity_search,
                 do:
                   OrbitalDynamics.MissionAnalysis.Opportunity.Policy.describe(opportunity_search),
                 else: :null
               ),
             "attitude_planning" => attitude_report || :null,
             "model_limits" =>
               opportunity_limits(limits_for(refinement, attitude), opportunity_search),
             "analyses" => reports,
             "requests" => request_reports,
             "opportunities" => opportunities,
             "activities" => activities,
             "selection_decisions" => decisions,
             "remaining_resource_budgets" => balances
           }
           |> scheduling_evidence(search_report),
           %{
             "opportunity_generation_ms" => opportunity_us / 1000,
             "scheduling_ms" => scheduling_us / 1000,
             "endpoint_verification_ms" => verification_us / 1000
           }}
        else
          {_elapsed, {:error, _} = error} -> error
        end
      else
        {_elapsed, {:error, _} = error} -> error
      end
    rescue
      error in [ArgumentError, KeyError] ->
        {:error, {:invalid_mission_analysis, Exception.message(error)}}
    end
  end

  defp scheduling_evidence(report, nil), do: report

  defp scheduling_evidence(report, search) do
    report
    |> Map.put("scheduling_search", search)
    |> Map.update!("model_limits", fn limits ->
      Enum.map(limits, fn
        "deterministic value-first greedy scheduling; no global optimality claim" ->
          "bounded opportunity-priority search with shared feasibility evaluation; no global optimality claim"

        "no automatic repair, mission-plan import, approval, or execution authority" ->
          "no rolling operational repair, mission-plan import, approval, or execution authority"

        other ->
          other
      end)
    end)
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

    limits =
      if attitude,
        do: [
          "sampled kinematic attitude support; no actuator, disturbance, or achieved attitude validation"
          | List.delete(
              limits,
              "declared asset separation; no initial-attitude acquisition or slew simulation"
            )
        ],
        else: limits

    if attitude && attitude.resources,
      do: [
        "declared dynamic resource models at tested integration cadences; no hardware validation"
        | List.delete(
            limits,
            "declared non-replenishing resource budgets; no subsystem simulation"
          )
      ],
      else: limits
  end

  defp schedule_selected(
         assets,
         requests,
         opportunities,
         sessions,
         attitude,
         refinement,
         separation,
         context,
         scheduling
       ) do
    protected =
      Scheduling.Commitments.bind!(
        if(scheduling, do: scheduling.protected_activities, else: []),
        opportunities,
        requests,
        assets,
        separation
      )

    prepared =
      if attitude,
        do:
          OrbitalDynamics.MissionAnalysis.Attitude.Evaluator.prepare(
            assets,
            requests,
            sessions,
            attitude,
            context
          ),
        else: {:ok, nil}

    with {:ok, runtime} <- prepared do
      physical = fn ordered, reservations ->
        if attitude do
          OrbitalDynamics.MissionAnalysis.Attitude.Evaluator.evaluate(
            runtime,
            ordered,
            refinement,
            separation,
            fn asset, t -> sampled_state(asset, t, refinement) end,
            reservations
          )
        else
          Scheduling.StaticEvaluator.evaluate(assets, requests, ordered, separation, reservations)
        end
      end

      evaluator = fn ordered, reservations ->
        Scheduling.Work.trial(ordered, reservations, fn -> physical.(ordered, reservations) end)
      end

      verify_endpoints = fn activities ->
        case verify_activity_endpoints(activities, assets, requests, sessions, refinement) do
          {:error,
           {:activity_endpoint_verification_failed, {:scheduled_endpoint_ineligible, _}} = reason} ->
            {:invalid, reason}

          other ->
            other
        end
      end

      verifier = fn activities ->
        Scheduling.Work.guard(fn -> verify_endpoints.(activities) end)
      end

      Scheduling.Work.run(
        scheduling != nil and (scheduling.maintenance != nil or scheduling.work_budget != nil),
        if(scheduling, do: scheduling.work_budget, else: nil),
        fn ->
          if scheduling && scheduling.maintenance do
            Scheduling.Maintenance.run(
              opportunities,
              requests,
              assets,
              separation,
              scheduling,
              evaluator,
              verifier
            )
          else
            Scheduling.run(
              opportunities,
              requests,
              &evaluator.(&1, protected),
              scheduling,
              verifier
            )
          end
        end
      )
    end
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
                 :opportunity_search,
                 :attitude,
                 :scheduling
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

    opportunity_search =
      case Keyword.get(opts, :opportunity_search) do
        nil ->
          nil

        %OrbitalDynamics.MissionAnalysis.Opportunity.Policy{} = p ->
          OrbitalDynamics.MissionAnalysis.Opportunity.Policy.new!(
            Map.from_struct(p)
            |> Map.to_list()
          )

        _ ->
          raise ArgumentError, "opportunity_search must be an Opportunity.Policy"
      end

    if opportunity_search && refinement == nil,
      do:
        raise(
          ArgumentError,
          "opportunity search requires an explicit checked state sampling/refinement policy"
        )

    scheduling =
      case Keyword.get(opts, :scheduling) do
        nil -> nil
        %Scheduling.Policy{} = p -> Scheduling.Policy.validate!(p)
        _ -> raise ArgumentError, "scheduling must be a Scheduling.Policy"
      end

    if scheduling &&
         (scheduling.strategy != Scheduling.Greedy or scheduling.protected_activities != [] or
            scheduling.maintenance != nil) &&
         attitude &&
         attitude.horizon == nil,
       do:
         raise(ArgumentError, "alternative physical scheduling requires an explicit full horizon")

    if scheduling && scheduling.maintenance && (attitude == nil or attitude.horizon == nil),
      do:
        raise(
          ArgumentError,
          "automatic maintenance requires physical evaluation and a full horizon"
        )

    {gap, separation, include, refinement, attitude, opportunity_search, scheduling}
  end

  defp validate_inputs!(assets, requests, attitude) do
    unless is_list(assets) and assets != [] and is_list(requests) and
             (requests != [] or (attitude != nil and attitude.horizon != nil)),
           do:
             raise(
               ArgumentError,
               "nonempty assets and requests required; empty requests require an explicit attitude horizon"
             )

    unique_ids!(assets)
    unique_ids!(requests)

    if Enum.any?(requests, &(&1.segment != nil)) and (attitude == nil or attitude.horizon == nil),
      do:
        raise(ArgumentError, "activity segments require explicit attitude and horizon evaluation")

    unless length(Enum.uniq(Enum.map(requests, & &1.time_scale))) <= 1,
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
        resource_costs: r.resource_costs,
        segment: r.segment
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

        unless state.epoch.scale ==
                 if(requests == [],
                   do: attitude.horizon.start.scale,
                   else: hd(requests).time_scale
                 ) and
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

  defp analyze_pairs(pairs, context, gap, include?, refinement, opportunity_search) do
    Enum.reduce_while(pairs, {:ok, [], %{}}, fn {asset, request}, {:ok, reports, sessions} ->
      case analyze_pair(asset, request, context, gap, include?, refinement, opportunity_search) do
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

  defp analyze_pair(asset, request, context, gap, include?, refinement, opportunity_search) do
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

    capability =
      if request.segment && request.segment.asset_id != asset.id,
        do: :segment_asset_mismatch,
        else: Map.fetch(asset.capabilities, model)

    case capability do
      :segment_asset_mismatch ->
        {:ok,
         Map.merge(base, %{
           "status" => "activity_segment_asset_mismatch",
           "opportunities" => [],
           "failed_check_counts" => %{}
         }), nil}

      :error ->
        {:ok,
         Map.merge(base, %{
           "status" => "capability_unavailable",
           "opportunities" => [],
           "failed_check_counts" => %{}
         }), nil}

      {:ok, config} ->
        with {:ok, session, assumptions} <- prepare_model(model, request, config, context),
             {:ok, windows, samples, extra_count, event_evidence} <-
               pair_windows(
                 asset,
                 if(request.segment, do: request.segment.request, else: request),
                 session,
                 gap,
                 refinement,
                 opportunity_search
               ) do
          # A segment inherits the original physical request window and its
          # discovery margins. Reapplying those margins to a five-second prefix
          # would erase the reserved slot or fail on a coarse discovery grid.
          # Profiles/endpoints and complete subsystem checks still re-evaluate
          # the exact segment against the current declared environment.
          windows =
            if request.segment,
              do:
                Enum.flat_map(windows, fn window ->
                  a = max(window["starts_at_s"], request.starts_at_s)
                  b = min(window["ends_at_s"], request.ends_at_s)

                  if b > a,
                    do: [
                      window
                      |> Map.put("starts_at_s", a)
                      |> Map.put("ends_at_s", b)
                      |> Map.put("segment_source_window", window)
                      |> Map.put("sample_count_scope", "original_physical_request_window")
                    ],
                    else: []
                end),
              else: windows

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
              |> Map.merge(
                if(event_evidence,
                  do: %{"window_evidence" => Map.get(window, "segment_source_window", window)},
                  else: %{}
                )
              )
              |> then(fn opportunity ->
                if request.segment,
                  do:
                    Map.put(opportunity, "activity_segment", Request.segment_description(request)),
                  else: opportunity
              end)
            end)

          failures =
            samples
            |> Enum.flat_map(& &1["checks"])
            |> Enum.reject(& &1["passed"])
            |> Enum.frequencies_by(& &1["id"])

          status =
            cond do
              event_evidence &&
                  event_evidence["status"] in [
                    "no_state_coverage",
                    "model_opportunity_constraints_unavailable"
                  ] ->
                event_evidence["status"]

              event_evidence && opportunities == [] && event_evidence["windows"] != [] ->
                "no_conservative_opportunity"

              event_evidence && opportunities == [] && event_evidence["status"] == "unknown" ->
                "opportunity_search_incomplete"

              event_evidence && opportunities == [] ->
                "no_conservative_opportunity"

              samples == [] ->
                "no_ephemeris_samples_in_request_window"

              opportunities == [] ->
                "no_sample_supported_opportunity"

              true ->
                "opportunities_found"
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
            if refinement && opportunity_search == nil,
              do:
                Map.merge(report, %{
                  "window_evidence" => windows,
                  "transition_refinement_evaluation_count" => extra_count
                }),
              else: report

          report =
            if event_evidence,
              do: Map.put(report, "opportunity_evidence", event_evidence),
              else: report

          {:ok, if(include?, do: Map.put(report, "samples", samples), else: report), session}
        end
    end
  end

  defp pair_windows(asset, request, session, gap, refinement, nil) do
    with {:ok, samples} <- evaluate_samples(asset, request, session, gap, refinement),
         {:ok, windows, samples, count} <-
           analyze_windows(asset, request, session, samples, gap, refinement),
         do: {:ok, windows, samples, count, nil}
  end

  defp pair_windows(asset, request, session, _gap, refinement, policy) do
    with {:ok, windows, samples, evidence} <-
           OrbitalDynamics.MissionAnalysis.Opportunity.Runner.run(
             asset,
             request,
             session,
             refinement,
             policy
           ),
         do: {:ok, windows, samples, 0, evidence}
  end

  defp attach_opportunity_evidence(rows, _opportunities, nil), do: rows

  defp attach_opportunity_evidence(rows, opportunities, _) do
    by_id = Map.new(opportunities, &{&1["id"], &1["window_evidence"]})

    Enum.map(
      rows,
      &Map.put(&1, "opportunity_evidence", Map.get(by_id, &1["opportunity_id"], :null))
    )
  end

  defp opportunity_limits(limits, nil), do: limits

  defp opportunity_limits(limits, _) do
    [
      "constraint intersections use conservative numerical bounds and explicit mission timing margins; neither bounds physical uncertainty",
      "shared scalar search has finite discovery coverage; unknown spans are excluded; no continuous feasibility proof"
      | Enum.reject(
          limits,
          &(&1 in [
              "opportunities end at observed eligible samples; no extrapolation or root finding",
              "eligible-side brackets refine observed transitions; no guarantee of continuous feasibility"
            ])
        )
    ]
  end

  defp prepare_model(model, request, config, context) do
    original = if request.segment, do: request.segment.request, else: request

    case model.prepare(original, config, context) do
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
    Scheduling.Work.charge!("endpoint")

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

  defp request_reasons(request, reports, decisions, count) do
    if count == 0 do
      statuses = Enum.map(reports, & &1["status"])

      rejected =
        for report <- reports,
            e = report["opportunity_evidence"],
            is_map(e),
            w <- Map.get(e, "windows", []),
            w["status"] == "rejected",
            do: w["reason"]

      (statuses ++ rejected) |> Enum.uniq() |> Enum.sort()
    else
      decisions
      |> Enum.filter(&(&1["request_id"] == request.id))
      |> Enum.map(& &1["reason"])
      |> Enum.uniq()
      |> Enum.sort()
    end
  end
end
