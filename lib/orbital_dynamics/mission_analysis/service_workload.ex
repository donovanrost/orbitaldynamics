defmodule OrbitalDynamics.MissionAnalysis.ServiceWorkload do
  @moduledoc "Reference-study comparison with repeated-service and inter-service energy diagnostics."
  alias OrbitalDynamics.MissionAnalysis.{ConstellationBenchmark, RepeatedServiceQualityCases}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Reference

  def run!(mission, study, max_trials, on_run \\ fn _, _ -> :ok end) do
    unless is_integer(max_trials) and max_trials in 1..64,
      do: raise(ArgumentError, "max_trials must be 1..64, including the baseline")

    protected =
      case study["scheduling"] do
        %{"protected_activities" => values} -> values
        _ -> []
      end

    study = Map.delete(study, "scheduling")

    for asset <- mission["assets"] do
      models = get_in(study, ["resources", "assets", asset["id"]])

      unless is_list(models) and
               Enum.any?(models, &(&1["id"] == "battery" and &1["model"] == "battery")),
             do:
               raise(
                 ArgumentError,
                 "workload comparison requires a resource named battery using the battery model for every asset"
               )
    end

    results =
      for {name, trials} <- [
            {"greedy", 1},
            {"bounded_reassignment", max_trials},
            {"bounded_replacement", max_trials}
          ] do
        config = %{"strategy" => name, "max_trials" => trials}

        config =
          if protected == [], do: config, else: Map.put(config, "protected_activities", protected)

        {summary, report} =
          ConstellationBenchmark.run_case!(
            mission,
            Map.put(study, "scheduling", config),
            length(mission["assets"])
          )

        summary = Map.merge(summary, diagnostics(report)) |> Map.put("strategy", name)
        on_run.(summary, report)

        {summary, report,
         RepeatedServiceQualityCases.run!(
           Reference.policy!(Map.delete(config, "protected_activities"))
         )}
      end

    summary = %{
      "format" => "repeated_service_comparison.v1",
      "mission_configuration" => mission,
      "planning_configuration" => study,
      "max_trials" => max_trials,
      "protected_activities" => protected,
      "runs" => Enum.map(results, &elem(&1, 0)),
      "quality_cases" => Map.new(results, fn {s, _, q} -> {s["strategy"], q} end),
      "runtime" => %{
        "elixir" => System.version(),
        "otp" => System.otp_release(),
        "architecture" => to_string(:erlang.system_info(:system_architecture)),
        "schedulers_online" => System.schedulers_online(),
        "warmup_runs" => 0
      },
      "limits" => [
        "synthetic reference assumptions; not company specifications",
        "single runtime observations; no speed gates",
        "finite sampled physical checks, not continuous certification",
        "fixed-time quality oracle does not bound the orbital workload's optimal value",
        "inter-service energy deltas compare tested cadences, not physical error bounds"
      ]
    }

    {summary, Enum.map(results, fn {s, r, _} -> {s["strategy"], r} end)}
  end

  def diagnostics(report) do
    activities = report["activities"]

    counts =
      Map.new(report["remaining_resource_budgets"], fn {id, _} ->
        {id, Enum.count(activities, &(&1["asset_id"] == id))}
      end)

    gaps =
      for {id, asset} <- report["attitude_planning"]["resource_feasibility"]["assets"],
          into: %{} do
        battery = Enum.find(Map.get(asset, "models", []), &(&1["id"] == "battery"))

        timeline =
          activities |> Enum.filter(&(&1["asset_id"] == id)) |> Enum.sort_by(& &1["starts_at_s"])

        {id, if(battery, do: recovery_gaps(timeline, battery["levels"]), else: :null)}
      end

    transitions = report["attitude_planning"]["transitions"]

    %{
      "activities_per_asset" => counts,
      "inter_service_energy" => gaps,
      "nonzero_slew_count" => Enum.count(transitions, &(&1["slew_angle_deg"] > 0)),
      "minimum_transition_time_margin_s" =>
        if(transitions == [],
          do: :null,
          else: transitions |> Enum.map(& &1["time_margin_s"]) |> Enum.min()
        ),
      "placement_rejection_reasons" =>
        report["selection_decisions"]
        |> Enum.flat_map(&(get_in(&1, ["attitude_assessment", "attempts"]) || []))
        |> Enum.reject(&(&1["status"] == "supported"))
        |> Enum.frequencies_by(& &1["reason"]),
      "unfulfilled_requests" =>
        report["requests"]
        |> Enum.filter(&(&1["status"] == "unfulfilled"))
        |> Enum.map(&Map.take(&1, ~w(request_id value reasons)))
    }
  end

  @doc "Signed net stored energy change between successive activities, at each tested resource cadence."
  def recovery_gaps(activities, levels) do
    activities
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] ->
      start = a["ends_at_s"]
      stop = b["starts_at_s"]

      observations =
        Enum.map(levels, fn level ->
          from = energy_at(level, start)
          to = energy_at(level, stop)

          delta =
            if is_number(from) and is_number(to) and level["uncovered_intervals"] == [],
              do: to - from,
              else: :null

          %{"sample_step_s" => level["sample_step_s"], "net_energy_change_wh" => delta}
        end)

      deltas = Enum.map(observations, & &1["net_energy_change_wh"])
      known = deltas != [] and Enum.all?(deltas, &is_number/1)

      %{
        "after_request_id" => a["request_id"],
        "before_request_id" => b["request_id"],
        "starts_at_s" => start,
        "ends_at_s" => stop,
        "status" => if(known, do: "known_at_tested_cadences", else: "unknown"),
        "net_energy_change_wh_range" =>
          if(known, do: %{"min" => Enum.min(deltas), "max" => Enum.max(deltas)}, else: :null),
        "levels" => observations
      }
    end)
  end

  defp energy_at(level, t) do
    case Enum.find(level["samples"], &(&1["epoch_s"] == t)) do
      nil -> :null
      %{"state" => %{"energy_wh" => value}} when is_number(value) -> value
      _ -> :null
    end
  end

  def markdown(summary) do
    rows =
      for r <- summary["runs"] do
        counts =
          r["activities_per_asset"]
          |> Enum.sort()
          |> Enum.map_join(", ", fn {id, n} -> "#{id}: #{n}" end)

        "| #{r["strategy"]} | #{r["scheduled_count"]}/#{r["request_count"]} | #{r["fulfilled_value"]} | #{Float.round(r["timings"]["total_ms"] / 1000, 2)} | #{counts} | #{r["planning_status"]} |\n"
      end

    quality =
      for {strategy, cases} <- Enum.sort(summary["quality_cases"]), c <- cases do
        "| #{strategy} | #{c["id"]} | #{c["planner_value"]} | #{c["optimal_value"]} | #{c["absolute_gap"]} |\n"
      end

    [
      "# Repeated service workload\n\nSynthetic analysis assumptions; see summary.json for complete inputs and evidence scopes.\n\n",
      "| Strategy | Fulfilled | Value | Total seconds | Activities per asset | Planning status |\n| --- | --- | --- | --- | --- | --- |\n",
      rows,
      "\nTotal includes opportunity generation and schedule search; compilation, quality cases and artifact writing are excluded. Single observations without a discarded warm-up.\n\n",
      "## Small fixed-time quality cases\n\n| Strategy | Case | Planner value | Exact declared-model optimum | Gap |\n| --- | --- | --- | --- | --- |\n",
      quality,
      "\nThe fixed-time oracle enumerates assignments and uses independent scalar slew/battery arithmetic. It does not establish the orbital workload's optimum.\n\n",
      "See summary.json for reserves, signed energy changes between services, rejected requests, evaluation counts and trial limits. Compressed full physical reports are stored per strategy.\n"
    ]
  end
end
