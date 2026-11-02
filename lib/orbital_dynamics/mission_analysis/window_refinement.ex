defmodule OrbitalDynamics.MissionAnalysis.WindowRefinement do
  @moduledoc """
  Opt-in brackets around observed eligibility transitions, using actual evaluations.

  The evaluator has one fixed meaning at every epoch (including tracking lookback).
  Bisection retains an eligible endpoint and an ineligible endpoint. Window endpoints
  use the eligible side. This narrows observed transition brackets; it does not
  certify continuity, discover every crossing, or bound spacecraft/model error.
  """
  alias OrbitalDynamics.MissionAnalysis.Input
  @enforce_keys [:state_at, :tracking_lookback_s, :time_tolerance_s, :max_extra_evaluations]
  defstruct @enforce_keys

  def new!(opts) do
    keys = ~w(state_at tracking_lookback_s time_tolerance_s max_extra_evaluations)a

    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(keys),
      do: raise(ArgumentError, "explicit refinement options required: #{inspect(keys)}")

    state_at = Keyword.fetch!(opts, :state_at)

    unless is_function(state_at, 2),
      do: raise(ArgumentError, "state_at must accept asset and epoch seconds")

    budget = Keyword.fetch!(opts, :max_extra_evaluations)

    unless is_integer(budget) and budget in 1..10_000,
      do: raise(ArgumentError, "max_extra_evaluations must be 1..10000 per pair")

    %__MODULE__{
      state_at: state_at,
      tracking_lookback_s: Input.positive!(opts[:tracking_lookback_s], "tracking_lookback_s"),
      time_tolerance_s:
        Input.number!(opts[:time_tolerance_s], "time_tolerance_s", 0.000001, 1.0e6),
      max_extra_evaluations: budget
    }
  end

  def describe(r),
    do: %{
      "method" => "eligible_side_transition_brackets",
      "tracking_lookback_s" => r.tracking_lookback_s,
      "time_tolerance_s" => r.time_tolerance_s,
      "max_extra_evaluations_per_pair" => r.max_extra_evaluations,
      "evaluation_budget_scope" =>
        "transition probes only; selected activity endpoint checks are counted separately",
      "limits" => [
        "bracket widths are epoch resolution only, not physical uncertainty",
        "multiple crossings and ineligible islands between tested samples can remain undetected",
        "tracking remains a fixed-lookback secant, not an instantaneous bound"
      ]
    }

  @doc "Refines runs, including short runs; the caller applies requested duration afterwards."
  def run(samples, evaluate_at, starts_at_s, ends_at_s, gap, %__MODULE__{} = policy) do
    try do
      cache =
        Map.new(samples, &{&1["epoch_s"] * 1.0, Map.put(&1, "epoch_s", &1["epoch_s"] * 1.0)})

      state = {cache, 0}
      {_, state} = fetch(starts_at_s, evaluate_at, state, policy)
      {_, state} = fetch(ends_at_s, evaluate_at, state, policy)
      seeds = state |> elem(0) |> Map.values() |> Enum.sort_by(& &1["epoch_s"])
      # Explicit gap breaks are never bridged by refinement.
      runs =
        seeds
        |> Enum.with_index()
        |> Enum.chunk_by(fn {s, _} -> s["feasible"] end)
        |> Enum.filter(fn [{s, _} | _] -> s["feasible"] end)
        |> Enum.flat_map(fn run ->
          Enum.chunk_while(
            run,
            [],
            fn {s, _} = item, acc ->
              if acc == [] or s["epoch_s"] - elem(hd(acc), 0)["epoch_s"] <= gap,
                do: {:cont, [item | acc]},
                else: {:cont, Enum.reverse(acc), [item]}
            end,
            fn acc -> {:cont, Enum.reverse(acc), []} end
          )
        end)

      {windows, state} =
        Enum.map_reduce(runs, state, fn run, state ->
          {first, first_index} = hd(run)
          {last, last_index} = List.last(run)
          before = if first_index > 0, do: Enum.at(seeds, first_index - 1)
          after_sample = Enum.at(seeds, last_index + 1)
          {entry, state} = edge(before, first, gap, evaluate_at, state, policy)
          {exit, state} = edge(after_sample, last, gap, evaluate_at, state, policy)

          {%{
             "starts_at_s" => entry["inside_at_s"],
             "ends_at_s" => exit["inside_at_s"],
             "entry" => entry,
             "exit" => exit
           }, state}
        end)

      {cache, count} = state
      all_samples = cache |> Map.values() |> Enum.sort_by(& &1["epoch_s"])

      windows =
        Enum.map(windows, fn w ->
          Map.put(
            w,
            "sample_count",
            Enum.count(
              all_samples,
              &(&1["feasible"] and &1["epoch_s"] >= w["starts_at_s"] and
                  &1["epoch_s"] <= w["ends_at_s"])
            )
          )
        end)

      {:ok, windows, all_samples, count}
    catch
      {:refinement_error, reason} -> {:error, reason}
    end
  end

  defp edge(outside, inside, gap, evaluate, state, policy) do
    if outside != nil and not outside["feasible"] and
         abs(outside["epoch_s"] - inside["epoch_s"]) <= gap do
      {outside, inside, state} = bisect(outside, inside, evaluate, state, policy)

      {%{
         "kind" => "observed_transition_bracket",
         "inside_at_s" => inside["epoch_s"],
         "outside_at_s" => outside["epoch_s"],
         "width_s" => abs(outside["epoch_s"] - inside["epoch_s"]),
         "outside_failed_checks" =>
           outside["checks"] |> Enum.reject(& &1["passed"]) |> Enum.map(& &1["id"])
       }, state}
    else
      {%{
         "kind" => if(outside == nil, do: "request_or_coverage_clip", else: "sample_gap_clip"),
         "inside_at_s" => inside["epoch_s"],
         "width_s" => 0.0,
         "limits" => "no transition located beyond this endpoint"
       }, state}
    end
  end

  defp bisect(outside, inside, evaluate, state, policy) do
    if abs(outside["epoch_s"] - inside["epoch_s"]) <= policy.time_tolerance_s do
      {outside, inside, state}
    else
      t = (outside["epoch_s"] + inside["epoch_s"]) / 2

      if t == outside["epoch_s"] or t == inside["epoch_s"],
        do: throw({:refinement_error, :epoch_precision_exhausted})

      {middle, state} = fetch(t, evaluate, state, policy)

      if middle["feasible"],
        do: bisect(outside, middle, evaluate, state, policy),
        else: bisect(middle, inside, evaluate, state, policy)
    end
  end

  defp fetch(t, evaluate, {cache, count} = state, policy) do
    t = t * 1.0

    case Map.fetch(cache, t) do
      {:ok, sample} ->
        {sample, state}

      :error ->
        if count >= policy.max_extra_evaluations,
          do: throw({:refinement_error, :refinement_evaluation_budget_exhausted})

        case evaluate.(t) do
          {:ok, %{"epoch_s" => epoch, "feasible" => eligible, "checks" => checks} = sample}
          when epoch == t and is_boolean(eligible) and is_list(checks) ->
            {Map.put(sample, "epoch_s", t),
             {Map.put(cache, t, Map.put(sample, "epoch_s", t)), count + 1}}

          {:error, reason} ->
            throw({:refinement_error, reason})

          _ ->
            throw({:refinement_error, :invalid_refinement_evaluation})
        end
    end
  end
end
