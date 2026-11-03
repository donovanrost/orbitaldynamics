defmodule OrbitalDynamics.EventSearch do
  @moduledoc """
  Opt-in bounded scalar event search. Keeps discovery evidence distinct from
  root-bracket precision. Functions may supply their time derivative to search
  one observed stationary point inside each check interval. This cannot certify
  the absence of unresolved oscillations or multiple unobserved extrema.
  """
  alias OrbitalDynamics.{Epoch, EventSearch.Source, EventSearch.Function}
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety

  def run(%Source{} = source, functions, opts) do
    previous_context = OrbitalDynamics.EventSearch.Context.current()

    try do
      unless Keyword.keyword?(opts),
        do: raise(ArgumentError, "event search controls must be unique keywords")

      {record_ids, opts} = Keyword.pop(opts, :record_function_observations, [])

      unless is_list(record_ids) and length(record_ids) <= 32 and
               Enum.all?(record_ids, &is_binary/1) and
               length(record_ids) == length(Enum.uniq(record_ids)),
             do: raise(ArgumentError, "bounded unique observation function IDs required")

      {start, stop, controls} = controls!(source, functions, opts)

      unless Enum.all?(record_ids, fn id -> Enum.any?(functions, &(&1.id == id)) end),
        do: raise(ArgumentError, "observation IDs must name searched functions")

      OrbitalDynamics.EventSearch.Context.open(controls.max_evaluations)
      count = ceil((stop - start) / controls.max_check_step_s)
      if count > 10000, do: raise(ArgumentError, "event scan exceeds 10000 intervals")

      times =
        [start | for(i <- 1..count, do: min(stop, start + i * controls.max_check_step_s))]
        |> Enum.dedup_by(&(&1 * 1.0))

      unless length(times) == count + 1 and List.last(times) == stop,
        do: raise(ArgumentError, "event scan epochs cannot resolve the requested cadence")

      runtime = %{
        source: source,
        controls: controls,
        states: %{},
        values: %{},
        source_queries: 0,
        function_evaluations: 0
      }

      {reports, _runtime} =
        Enum.map_reduce(functions, runtime, fn f, runtime -> search(f, times, runtime) end)

      reports =
        Enum.zip(reports, functions) |> Enum.map(fn {report, f} -> audit(report, f, source) end)

      counts = OrbitalDynamics.EventSearch.Context.counts()

      report =
        %{
          "format" => "event_search.v1",
          "source" => Source.describe(source),
          "starts_at_s" => start,
          "ends_at_s" => stop,
          "scan_epoch_count" => length(times),
          "maximum_observed_scan_gap_s" =>
            times
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(fn [a, b] -> b - a end)
            |> Enum.max(),
          "controls" =>
            Map.from_struct(controls) |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end),
          "status" =>
            if(Enum.any?(reports, &(&1["status"] == "unknown")),
              do: "unknown",
              else: "complete_under_search_policy"
            ),
          "source_query_count" => counts.source_queries,
          "function_evaluation_count" => counts.function_evaluations,
          "results" => reports,
          "limits" => [
            "finite scan and optional observed derivative sign changes; no proof that all crossings or grazes were discovered",
            "root brackets bound time relative to the supplied state/function model, not physical uncertainty",
            "state sources and event functions must remain deterministic under captured assumptions",
            "a zero-event result is not proof of continuous event absence"
          ]
        }

      report =
        if record_ids == [],
          do: report,
          else:
            Map.merge(report, %{
              "recorded_function_ids" => record_ids,
              "function_observations" =>
                OrbitalDynamics.EventSearch.Context.function_observations(record_ids)
            })

      {:ok, report}
    rescue
      e in [ArgumentError, KeyError, ArithmeticError] ->
        {:error, {:invalid_event_search, Exception.message(e)}}
    catch
      {:event_search_failed, reason} -> {:error, reason}
    after
      OrbitalDynamics.EventSearch.Context.restore(previous_context)
    end
  end

  defmodule Controls do
    @moduledoc false
    defstruct [
      :max_check_step_s,
      :time_tolerance_s,
      :max_iterations,
      :max_evaluations,
      :include_samples
    ]
  end

  defp controls!(source, functions, opts) do
    unless is_list(functions) and length(functions) in 1..32 and
             Enum.all?(functions, &match?(%Function{}, &1)),
           do: raise(ArgumentError, "1..32 event functions required")

    if length(Enum.uniq_by(functions, & &1.id)) != length(functions),
      do: raise(ArgumentError, "duplicate event function IDs")

    Enum.each(functions, fn f ->
      Function.new!(f.id, f.evaluate,
        units: f.units,
        value_tolerance: f.value_tolerance,
        condition: f.condition,
        direction: f.direction,
        labels: f.labels,
        root_filter: f.root_filter,
        assumptions: f.assumptions
      )
    end)

    keys = ~w(starts_at ends_at max_check_step_s time_tolerance_s max_iterations max_evaluations)a

    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts) -- [:include_samples]) == Enum.sort(keys) and
             length(opts) == length(Enum.uniq(Keyword.keys(opts))),
           do:
             raise(ArgumentError, "explicit event search window and numerical controls required")

    a = opts[:starts_at]
    b = opts[:ends_at]

    unless match?(%Epoch{}, a) and match?(%Epoch{}, b),
      do: raise(ArgumentError, "explicit Epoch search bounds required")

    start = Input.number!(a.seconds_since_j2000, "event search start", -1.0e12, 1.0e12)
    stop = Input.number!(b.seconds_since_j2000, "event search end", -1.0e12, 1.0e12)

    unless a.scale == source.start.scale and b.scale == a.scale and stop > start,
      do:
        raise(
          ArgumentError,
          "event window must be ordered and match the explicit source time scale"
        )

    step = Input.positive!(opts[:max_check_step_s], "event maximum check step")
    tolerance = Input.positive!(opts[:time_tolerance_s], "event time tolerance")

    unless tolerance < step,
      do: raise(ArgumentError, "event time tolerance must be smaller than scan cadence")

    include = Keyword.get(opts, :include_samples, false)
    unless is_boolean(include), do: raise(ArgumentError, "include_samples must be boolean")

    {start, stop,
     %Controls{
       max_check_step_s: step,
       time_tolerance_s: tolerance,
       max_iterations: integer!(opts[:max_iterations], 128),
       max_evaluations: integer!(opts[:max_evaluations], 100_000),
       include_samples: include
     }}
  end

  defp integer!(n, upper) do
    unless is_integer(n) and n in 1..upper,
      do: raise(ArgumentError, "event budget must be 1..#{upper}")

    n
  end

  defp search(f, times, runtime) do
    {samples, runtime} = Enum.map_reduce(times, runtime, fn t, r -> sample(f, t, r) end)

    {events, issues, windows, runtime} =
      Enum.reduce(Enum.chunk_every(samples, 2, 1, :discard), {[], [], [], runtime}, fn [a, b],
                                                                                       {events,
                                                                                        issues,
                                                                                        windows,
                                                                                        r} ->
        {found, gaps, r} = interval(f, a, b, r)
        {parts, gaps2, r} = windows(f, a, b, found, gaps, r)
        {events ++ found, issues ++ gaps ++ gaps2, windows ++ parts, r}
      end)

    hits =
      samples
      |> Enum.with_index()
      |> Enum.flat_map(fn {s, i} ->
        previous = if i > 0, do: Enum.at(samples, i - 1), else: nil
        following = Enum.at(samples, i + 1)

        plateau =
          Enum.any?([previous, following], fn n -> n != nil and known?(n) and near?(f, n) end)

        if known?(s) and s.value == 0 and not plateau do
          direction =
            cond do
              is_number(s.rate) and s.rate != 0 ->
                if(s.rate > 0, do: :increasing, else: :decreasing)

              previous != nil and following != nil and known?(previous) and known?(following) ->
                direction(previous.value, following.value)

              true ->
                :boundary
            end

          [event(f, s, s, s, direction, "exact_sample_zero")]
        else
          []
        end
      end)

    all_events = events ++ hits

    events =
      all_events
      |> Enum.filter(&accept?(f, &1))
      |> Enum.uniq_by(&{&1["bracket_start_s"] * 1.0, &1["bracket_end_s"] * 1.0, &1["direction"]})
      |> Enum.sort_by(& &1["epoch_s"])

    direction_issues =
      for e <- hits,
          e["direction"] == "boundary" and f.direction != :any,
          do: issue(e["epoch_s"], e["epoch_s"], "boundary_direction_unknown")

    issues = issues ++ direction_issues

    windows =
      merge_windows(windows)
      |> Enum.map(fn w ->
        start_edge = boundary(w["starts_at_s"], all_events)
        end_edge = boundary(w["ends_at_s"], all_events)

        Map.merge(w, %{
          "starts_at_s" => Map.get(start_edge, "estimate_s", w["starts_at_s"]),
          "ends_at_s" => Map.get(end_edge, "estimate_s", w["ends_at_s"]),
          "start_boundary" => start_edge,
          "end_boundary" => end_edge,
          "start_kind" =>
            if(start_edge["kind"] == "estimated_event",
              do: "refined_event",
              else: w["start_kind"]
            ),
          "end_kind" =>
            if(end_edge["kind"] == "estimated_event", do: "refined_event", else: w["end_kind"])
        })
      end)
      |> Enum.filter(&(&1["ends_at_s"] > &1["starts_at_s"]))

    report = %{
      "function" => Function.describe(f),
      "status" => if(issues == [], do: "complete_under_search_policy", else: "unknown"),
      "events" => events,
      "condition_windows" => windows,
      "window_boundary_policy" => "estimates_with_bracket_uncertainty_not_eligible_side_bounds",
      "uncovered_intervals" => merge_issues(issues),
      "discovery_policy" => "sampled_sign_changes_and_observed_derivative_extrema",
      "root_timing_scope" => "supplied_state_and_function_model"
    }

    report =
      if runtime.controls.include_samples,
        do: Map.put(report, "scan_samples", Enum.map(samples, &json_sample/1)),
        else: report

    {report, runtime}
  end

  defp interval(f, a, b, runtime) do
    cond do
      not known?(a) or not known?(b) ->
        {[], [issue(a.t, b.t, "unknown_scan_endpoint")], runtime}

      near?(f, a) and near?(f, b) ->
        {[], [issue(a.t, b.t, "nonisolated_or_underresolved_zero")], runtime}

      true ->
        if is_number(a.rate) and is_number(b.rate) and opposite?(a.rate, b.rate) do
          case refine(f, a, b, :rate, runtime, 0) do
            {:ok, left, right, critical, runtime} ->
              {roots1, gaps1, runtime} = crossing(f, a, critical, runtime)
              {roots2, gaps2, runtime} = crossing(f, critical, b, runtime)

              contact =
                if roots1 == [] and roots2 == [] and near?(f, critical),
                  do: [
                    event(
                      f,
                      left,
                      right,
                      critical,
                      :touching,
                      "stationary_contact_within_value_tolerance"
                    )
                  ],
                  else: []

              {roots1 ++ roots2 ++ contact, gaps1 ++ gaps2, runtime}

            {:unknown, reason, runtime} ->
              {[], [issue(a.t, b.t, reason)], runtime}
          end
        else
          crossing(f, a, b, runtime)
        end
    end
  end

  defp crossing(f, a, b, runtime) do
    if opposite?(a.value, b.value) do
      case refine(f, a, b, :value, runtime, 0) do
        {:ok, left, right, root, runtime} ->
          {[event(f, left, right, root, direction(a.value, b.value), "sign_change_root")], [],
           runtime}

        {:unknown, reason, runtime} ->
          {[], [issue(a.t, b.t, reason)], runtime}
      end
    else
      {[], [], runtime}
    end
  end

  defp refine(f, a, b, component, runtime, iteration) do
    mid = a.t + (b.t - a.t) / 2

    cond do
      iteration >= runtime.controls.max_iterations ->
        {:unknown, "root_iteration_limit", runtime}

      mid <= a.t or mid >= b.t ->
        {:unknown, "root_epoch_resolution_insufficient", runtime}

      true ->
        {s, runtime} = sample(f, mid, runtime)

        cond do
          not known?(s) or not is_number(Map.get(s, component)) ->
            {:unknown, "root_function_unknown", runtime}

          Map.fetch!(s, component) == 0 ->
            {:ok, s, s, s, runtime}

          b.t - a.t <= runtime.controls.time_tolerance_s ->
            {:ok, a, b, s, runtime}

          opposite?(Map.fetch!(a, component), Map.fetch!(s, component)) ->
            refine(f, a, s, component, runtime, iteration + 1)

          true ->
            refine(f, s, b, component, runtime, iteration + 1)
        end
    end
  end

  defp event(f, a, b, s, direction, kind) do
    %{
      "function_id" => f.id,
      "type" => Map.get(f.labels, direction, f.id),
      "epoch_s" => s.t,
      "direction" => Atom.to_string(direction),
      "event_class" => kind,
      "timing_target" =>
        if(kind == "stationary_contact_within_value_tolerance",
          do: "stationary_point_not_proven_function_zero",
          else: "event_function_zero"
        ),
      "solver" =>
        if(kind == "exact_sample_zero", do: "sampled_exact_zero", else: "bracketed_bisection"),
      "bracket_start_s" => a.t,
      "bracket_end_s" => b.t,
      "bracket_width_s" => b.t - a.t,
      "midpoint_time_bound_s" => (b.t - a.t) / 2,
      "value" => s.value,
      "value_units" => f.units,
      "metadata" => s.metadata
    }
  end

  defp accept?(f, e) do
    direction = f.direction == :any or Atom.to_string(f.direction) == e["direction"]
    filter = if f.root_filter, do: f.root_filter.(e["metadata"]), else: true
    unless is_boolean(filter), do: raise(ArgumentError, "event root filter must return boolean")
    direction and filter
  end

  defp windows(%{condition: :none}, _, _, _, _, r), do: {[], [], r}

  defp windows(f, a, b, events, gaps, r) do
    if gaps != [] or not known?(a) or not known?(b) do
      {[], [], r}
    else
      times =
        [a.t, b.t | Enum.map(events, & &1["epoch_s"])]
        |> Enum.sort()
        |> Enum.dedup_by(&(&1 * 1.0))

      Enum.reduce(Enum.chunk_every(times, 2, 1, :discard), {[], [], r}, fn [start, stop],
                                                                           {windows, issues, r} ->
        mid = start + (stop - start) / 2

        if mid <= start or mid >= stop do
          {windows, issues ++ [issue(start, stop, "window_epoch_resolution_insufficient")], r}
        else
          {s, r} = sample(f, mid, r)

          cond do
            not known?(s) ->
              {windows, issues ++ [issue(start, stop, "window_function_unknown")], r}

            ((start == a.t and opposite?(a.value, s.value)) or
               (stop == b.t and opposite?(s.value, b.value))) and
                not Enum.any?(events, fn e ->
                  e["bracket_start_s"] <= start and e["bracket_end_s"] >= stop
                end) ->
              evidence =
                Map.merge(
                  issue(start, stop, "unresolved_crossings_observed_by_window_midpoint"),
                  %{
                    "midpoint_s" => mid,
                    "midpoint_value" => s.value,
                    "scan_start_value" => a.value,
                    "scan_end_value" => b.value
                  }
                )

              {windows, issues ++ [evidence], r}

            (f.condition == :nonnegative and s.value >= 0) or
                (f.condition == :nonpositive and s.value <= 0) ->
              w = %{
                "starts_at_s" => start,
                "ends_at_s" => stop,
                "evidence" => "condition_at_tested_epochs",
                "start_kind" =>
                  if(start == a.t, do: "scan_or_search_clip", else: "refined_event"),
                "end_kind" => if(stop == b.t, do: "scan_or_search_clip", else: "refined_event")
              }

              {windows ++ [w], issues, r}

            true ->
              {windows, issues, r}
          end
        end
      end)
    end
  end

  defp audit(report, f, source) do
    observations = OrbitalDynamics.EventSearch.Context.observations(f, source)

    {events, event_gaps} =
      Enum.reduce(report["events"], {[], []}, fn e, {events, gaps} ->
        if Enum.any?(
             observations,
             &(&1.status == :unknown and &1.t >= e["bracket_start_s"] and
                 &1.t <= e["bracket_end_s"])
           ) do
          {events,
           [
             issue(
               e["bracket_start_s"],
               e["bracket_end_s"],
               "observed_unknown_inside_event_bracket"
             )
             | gaps
           ]}
        else
          {[e | events], gaps}
        end
      end)

    {windows, window_gaps} =
      Enum.reduce(report["condition_windows"], {[], []}, fn w, {windows, gaps} ->
        contradiction =
          Enum.any?(observations, fn s ->
            inside = s.t >= w["starts_at_s"] and s.t <= w["ends_at_s"]

            uncertain =
              Enum.any?([w["start_boundary"], w["end_boundary"]], fn edge ->
                edge["kind"] == "estimated_event" and s.t >= edge["bracket_start_s"] and
                  s.t <= edge["bracket_end_s"]
              end)

            (inside or uncertain) and
              (s.status == :unknown or
                 (inside and not uncertain and
                    ((f.condition == :nonnegative and s.value < 0) or
                       (f.condition == :nonpositive and s.value > 0))))
          end)

        if contradiction,
          do:
            {windows,
             [issue(w["starts_at_s"], w["ends_at_s"], "observed_condition_contradiction") | gaps]},
          else: {[w | windows], gaps}
      end)

    gaps = merge_issues(report["uncovered_intervals"] ++ event_gaps ++ window_gaps)

    %{
      report
      | "events" => Enum.reverse(events),
        "condition_windows" => Enum.reverse(windows),
        "uncovered_intervals" => gaps,
        "status" => if(gaps == [], do: "complete_under_search_policy", else: "unknown")
    }
  end

  defp boundary(t, events) do
    exact = Enum.find(events, &(&1["epoch_s"] == t))
    containing = Enum.filter(events, &(t >= &1["bracket_start_s"] and t <= &1["bracket_end_s"]))
    candidate = exact || Enum.min_by(containing, &abs(&1["epoch_s"] - t), fn -> nil end)

    case candidate do
      nil ->
        %{"kind" => "scan_or_search_clip"}

      e ->
        Map.merge(
          Map.take(e, ~w(bracket_start_s bracket_end_s midpoint_time_bound_s timing_target)),
          %{"kind" => "estimated_event", "estimate_s" => e["epoch_s"]}
        )
    end
  end

  defp merge_windows(windows) do
    Enum.reduce(windows, [], fn w, acc ->
      case acc do
        [last | rest] ->
          if(last["ends_at_s"] == w["starts_at_s"],
            do: [%{last | "ends_at_s" => w["ends_at_s"], "end_kind" => w["end_kind"]} | rest],
            else: [w | acc]
          )

        _ ->
          [w | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp merge_issues(issues),
    do:
      Enum.uniq_by(issues, &{&1["starts_at_s"] * 1.0, &1["ends_at_s"] * 1.0, &1["reason"]})
      |> Enum.sort_by(& &1["starts_at_s"])

  defp issue(a, b, reason), do: %{"starts_at_s" => a, "ends_at_s" => b, "reason" => reason}
  defp opposite?(a, b), do: (a < 0 and b > 0) or (a > 0 and b < 0)

  defp direction(a, b) do
    cond do
      a < 0 and b > 0 -> :increasing
      a > 0 and b < 0 -> :decreasing
      true -> :touching
    end
  end

  defp known?(s), do: s.status == :known
  defp near?(f, s), do: abs(s.value) <= f.value_tolerance

  defp json_sample(s) do
    if known?(s),
      do: %{
        "epoch_s" => s.t,
        "value" => s.value,
        "rate" => s.rate || :null,
        "metadata" => s.metadata
      },
      else: %{"epoch_s" => s.t, "status" => "unknown", "reason" => inspect(s.reason)}
  end

  defp sample(f, t, r) do
    key = {f.id, t * 1.0}

    case Map.fetch(r.values, key) do
      {:ok, s} ->
        {s, r}

      :error ->
        {state, r} = state(t, r)

        {s, r} =
          case state do
            {:unknown, reason} ->
              {%{t: t, status: :unknown, reason: reason}, r}

            {:ok, state} ->
              r = charge(r, :function_evaluations)

              s =
                case Function.call(f, state) do
                  {:ok, value, rate, metadata} when is_map(metadata) ->
                    Input.number!(value, "event function value", -1.0e30, 1.0e30)

                    if rate != nil,
                      do: Input.number!(rate, "event function rate", -1.0e30, 1.0e30)

                    %{
                      t: t,
                      status: :known,
                      value: value,
                      rate: rate,
                      metadata: JsonSafety.normalize_input!(metadata, "event metadata")
                    }

                  {:unknown, reason} ->
                    %{t: t, status: :unknown, reason: reason}

                  {:error, reason} ->
                    throw({:event_search_failed, reason})

                  _ ->
                    raise ArgumentError, "invalid event function result"
                end

              {s, r}
          end

        {s, %{r | values: Map.put(r.values, key, s)}}
    end
  end

  defp state(t, r) do
    key = t * 1.0

    case Map.fetch(r.states, key) do
      {:ok, s} ->
        {s, r}

      :error ->
        r = charge(r, :source_queries)

        result =
          case Source.at(r.source, t) do
            {:error, reason} -> throw({:event_search_failed, reason})
            result -> result
          end

        {result, %{r | states: Map.put(r.states, key, result)}}
    end
  end

  defp charge(r, key) do
    case key do
      :source_queries -> %{r | source_queries: r.source_queries + 1}
      :function_evaluations -> %{r | function_evaluations: r.function_evaluations + 1}
    end
  end
end
