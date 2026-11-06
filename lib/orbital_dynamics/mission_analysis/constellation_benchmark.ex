defmodule OrbitalDynamics.MissionAnalysis.ConstellationBenchmark do
  @moduledoc """
  Bounded reference-mission benchmark. Fleet sizes use nested prefixes of one
  explicit manifest, keeping demand and numerical controls fixed. Timings are
  wall-clock observations; they are not deterministic evidence or performance gates.
  """
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  def run_case!(mission, study, size, opts \\ []) do
    unless is_integer(size) and size >= 1 and size <= length(mission["assets"]),
      do: raise(ArgumentError, "fleet size must be an available positive asset count")

    assets = Enum.take(mission["assets"], size)
    ids = Enum.map(assets, & &1["id"])
    mission = Map.put(mission, "assets", assets)

    study =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["path_constraints", "assets"],
          ["resources", "assets"],
          ["horizon", "terminals"]
        ],
        study,
        fn path, config -> update_in(config, path, &Map.take(&1, ids)) end
      )

    {total_us, {report, timings}} =
      :timer.tc(fn -> Reference.run_profiled!(mission, study, opts) end)

    {summarize(report, Map.put(timings, "total_ms", total_us / 1000)), report}
  end

  def summarize(report, timings) do
    attitude = report["attitude_planning"]
    resources = attitude["resource_feasibility"]

    batteries = Map.new(resources["assets"], fn {id, asset} -> {id, battery_summary(asset)} end)

    %{
      "asset_count" => map_size(report["remaining_resource_budgets"]),
      "request_count" => length(report["requests"]),
      "asset_request_pairs" => length(report["analyses"]),
      "opportunity_count" => length(report["opportunities"]),
      "scheduled_count" => length(report["activities"]),
      "fulfilled_value" => Enum.sum(Enum.map(report["activities"], & &1["value"])),
      "requested_value" => Enum.sum(Enum.map(report["requests"], & &1["value"])),
      "planning_status" => attitude["planning_status"],
      "resource_status" => resources["status"],
      "batteries" => batteries,
      "opportunity_evaluation_count" => opportunity_count(report["analyses"]),
      "attitude_model_evaluation_count" => attitude["model_evaluation_count"],
      "resource_model_evaluation_count" => resources["model_evaluation_count"],
      "decision_reasons" => Enum.frequencies_by(report["selection_decisions"], & &1["reason"]),
      "assignments" =>
        Enum.map(
          report["activities"],
          &Map.take(&1, ~w(asset_id request_id starts_at_s ends_at_s value))
        ),
      "timings" => timings
    }
    |> then(fn summary ->
      if report["scheduling_search"],
        do: Map.put(summary, "scheduling_search", report["scheduling_search"]),
        else: summary
    end)
  end

  defp opportunity_count(analyses) do
    counts = Enum.map(analyses, &get_in(&1, ["opportunity_evidence", "total_evaluation_count"]))
    if Enum.all?(counts, &is_number/1), do: Enum.sum(counts), else: :null
  end

  defp battery_summary(asset) do
    case Enum.find(Map.get(asset, "models", []), &(&1["id"] == "battery")) do
      nil ->
        %{
          "status" => "unknown",
          "reason" => Map.get(asset, "reason", "battery_model_evidence_unavailable"),
          "final_energy_wh_range" => :null,
          "minimum_energy_wh" => :null,
          "reserve_wh" => :null,
          "minimum_reserve_margin_wh" => :null
        }

      model ->
        comparison = model["state_comparison"]
        reserve = model["assumptions"]["reserve_wh"]
        minimum_range = energy_range(comparison, "minimum_state_range")
        minimum = if is_map(minimum_range), do: minimum_range["min"], else: :null

        %{
          "status" => model["status"],
          "final_energy_wh_range" => energy_range(comparison, "final_state_range"),
          "minimum_energy_wh" => minimum || :null,
          "reserve_wh" => reserve,
          "minimum_reserve_margin_wh" =>
            if(is_number(minimum) and is_number(reserve), do: minimum - reserve, else: :null)
        }
    end
  end

  defp energy_range(comparison, key) do
    case comparison[key] do
      %{"energy_wh" => %{} = range} -> range
      _ -> :null
    end
  end

  def markdown(summary) do
    rows =
      Enum.map(summary["runs"], fn r ->
        t = r["timings"]

        "| #{r["asset_count"]} | #{r["scheduled_count"]}/#{r["request_count"]} | #{r["fulfilled_value"]} | #{round(t["preparation_ms"])} | #{round(t["opportunity_generation_ms"])} | #{round(t["scheduling_ms"])} | #{round(t["total_ms"])} |\n"
      end)

    [
      "# Small constellation benchmark\n\n",
      "Analysis only. Synthetic spacecraft and demand; no Reflect Orbital specifications or operational acceptance.\n\n",
      "| Assets | Scheduled | Value | Preparation ms | Opportunities ms | Scheduling ms | Total ms |\n",
      "| --- | --- | --- | --- | --- | --- | --- |\n",
      rows,
      "\nTimings include sequential planning and final fleet replay; total also includes endpoint verification and report assembly. Compilation, artifact writing, and tiny quality cases are excluded. No warm-up or speed threshold.\n\n",
      "See summary.json for per-spacecraft battery reserves, evaluation counts, decisions, machine details, and tiny assignment quality cases. Full planning evidence is in the compressed report files.\n"
    ]
  end
end
