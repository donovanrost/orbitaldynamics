defmodule OrbitalDynamics.MissionAnalysis.ConstellationScaling do
  @moduledoc "Opt-in nested 6–100 spacecraft analysis benchmark; fixed or explicitly scaled demand, bounded runtime/memory and optional stack sampling."
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def inputs!(size, demand \\ 9) do
    unless is_integer(size) and size in 6..100 and is_integer(demand) and demand in 1..100,
      do: raise(ArgumentError, "scaling requires 6..100 spacecraft and 1..100 requests")

    m = ReferenceMission.load!("studies/small_constellation.json")
    s = ReferenceMission.load!("studies/small_constellation_planning.json")

    requests =
      for i <- 0..(demand - 1) do
        q = Enum.at(m["requests"], rem(i, 9))
        Map.put(q, "id", if(i < 9, do: q["id"], else: "request-#{i + 1}"))
      end

    assets =
      for i <- 0..(size - 1) do
        a = Enum.at(m["assets"], rem(i, 6))
        g = div(i, 6)
        angle = a["initial_argument_of_latitude_deg"] + 0.25 * g

        a
        |> Map.put("id", "demo-#{i + 1}")
        |> Map.put("initial_argument_of_latitude_deg", angle - 360 * :math.floor(angle / 360))
        |> Map.update!("local_time_ascending_node_h", &(&1 + 0.01 * g))
      end

    s =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["path_constraints", "assets"],
          ["resources", "assets"],
          ["horizon", "terminals"]
        ],
        s,
        fn path, s ->
          original = get_in(s, path)

          entries =
            assets
            |> Enum.with_index()
            |> Map.new(fn {asset, i} ->
              template = original["demo-#{rem(i, 6) + 1}"]

              template =
                if path == ["path_constraints", "assets"] do
                  modes =
                    requests
                    |> Enum.with_index()
                    |> Map.new(fn {q, j} ->
                      original_request = Enum.at(m["requests"], rem(j, 9))
                      {q["id"], template["activity_modes"][original_request["id"]]}
                    end)

                  Map.put(template, "activity_modes", modes)
                else
                  template
                end

              {asset["id"], template}
            end)

          put_in(s, path, entries)
        end
      )

    s =
      s
      |> put_in(["attitude", "max_evaluations"], 1_000_000)
      |> put_in(["path_constraints", "max_evaluations"], 1_000_000)
      |> put_in(["resources", "max_evaluations"], 1_000_000)

    {Map.put(m, "assets", assets) |> Map.put("requests", requests), s}
  end

  def run_case!(size, demand, opts) do
    unless Keyword.keyword?(opts), do: raise(ArgumentError, "scaling controls must be keywords")
    opts = Keyword.put_new(opts, :full_diagnostics, false)

    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts)) ==
               ~w(full_diagnostics max_memory_bytes profile timeout_ms)a,
           do: raise(ArgumentError, "explicit memory/time/profile controls required")

    budget = opts[:max_memory_bytes]
    timeout = opts[:timeout_ms]
    profile = opts[:profile]

    unless is_integer(budget) and budget in 16_000_000..8_000_000_000 and is_integer(timeout) and
             timeout in 1000..1_800_000 and is_boolean(profile) and
             is_boolean(opts[:full_diagnostics]),
           do: raise(ArgumentError, "invalid scaling resource controls")

    {mission, study} = inputs!(size, demand)

    task =
      Task.async(fn ->
        :erlang.garbage_collect()
        started = System.monotonic_time(:millisecond)

        try do
          {summary, report} =
            ConstellationBenchmark.run_case!(mission, study, size,
              include_samples: opts[:full_diagnostics]
            )

          # Full physical/evidence computation remains enabled. Large scaling runs
          # save a compact deterministic projection, not serialized diagnostic trees.
          digest = Snapshot.digest(Map.delete(summary, "timings"))

          %{
            status: "completed",
            path_rule_evaluation_count:
              get_in(report, ["attitude_planning", "path_constraints", "rule_evaluation_count"]) ||
                :null,
            summary:
              Map.merge(summary, %{
                "summary_sha256" => digest,
                "wall_ms" => System.monotonic_time(:millisecond) - started,
                "opportunity_search_status_counts" =>
                  Enum.frequencies_by(
                    report["analyses"],
                    &get_in(&1, ["opportunity_evidence", "status"])
                  )
              })
          }
        rescue
          e -> %{status: "failed", error: Exception.message(e)}
        catch
          kind, reason -> %{status: "failed", error: "#{kind}: #{inspect(reason)}"}
        end
      end)

    started = System.monotonic_time(:millisecond)

    initial = %{
      samples: 0,
      top: %{},
      inclusive: %{},
      modules: %{},
      peak: 0,
      last_memory: started - 1000
    }

    monitor(task, started, budget, timeout, profile, initial)
    |> Map.merge(%{
      "asset_count" => size,
      "request_count" => demand,
      "observed_wall_ms" => System.monotonic_time(:millisecond) - started,
      "input_sha256" => Snapshot.digest(%{"mission" => mission, "study" => study}),
      "controls" => Map.new(opts),
      "report_retention" =>
        "compact saved summary; all model/path/resource checks computed; dense opportunity diagnostics retained across pairs only with full_diagnostics=true"
    })
  end

  defp monitor(task, start, budget, timeout, profile, acc) do
    now = System.monotonic_time(:millisecond)
    memory? = now - acc.last_memory >= 1000
    total = if memory?, do: :erlang.memory(:total), else: acc.peak
    acc = if memory?, do: %{acc | peak: max(total, acc.peak), last_memory: now}, else: acc
    acc = if profile, do: sample(task.pid, acc), else: acc

    cond do
      total > budget ->
        Task.shutdown(task, :brutal_kill)

        finish(
          %{
            status: "memory_budget_exceeded",
            error: "sampled VM memory exceeded declared ceiling"
          },
          acc
        )

      now - start > timeout ->
        Task.shutdown(task, :brutal_kill)
        finish(%{status: "timeout", error: "declared runtime ceiling exceeded"}, acc)

      true ->
        case Task.yield(task, if(profile, do: 20, else: 100)) do
          {:ok, value} -> finish(value, acc)
          {:exit, reason} -> finish(%{status: "failed", error: inspect(reason)}, acc)
          nil -> monitor(task, start, budget, timeout, profile, acc)
        end
    end
  end

  defp sample(pid, acc) do
    case Process.info(pid, :current_stacktrace) do
      {:current_stacktrace, frames} ->
        keys =
          Enum.map(frames, fn {m, f, a, _} ->
            "#{inspect(m)}.#{f}/#{if(is_list(a), do: length(a), else: a)}"
          end)

        top = if keys == [], do: acc.top, else: Map.update(acc.top, hd(keys), 1, &(&1 + 1))

        inclusive =
          Enum.reduce(Enum.uniq(keys), acc.inclusive, fn k, m ->
            Map.update(m, k, 1, &(&1 + 1))
          end)

        modules =
          frames
          |> Enum.map(fn {m, _, _, _} -> inspect(m) end)
          |> Enum.uniq()
          |> Enum.reduce(acc.modules, fn m, counts -> Map.update(counts, m, 1, &(&1 + 1)) end)

        %{acc | samples: acc.samples + 1, top: top, inclusive: inclusive, modules: modules}

      _ ->
        acc
    end
  end

  defp finish(value, acc) do
    Map.new(value, fn {k, v} -> {Atom.to_string(k), v} end)
    |> Map.put("sampled_peak_vm_bytes", acc.peak)
    |> Map.put("stack_profile", %{
      "sample_count" => acc.samples,
      "interval_ms" => 20,
      "top_frames" => ranks(acc.top),
      "inclusive_frames" => ranks(acc.inclusive),
      "inclusive_modules" =>
        Enum.map(ranks(acc.modules), fn r ->
          %{"module" => r["function"], "samples" => r["samples"]}
        end),
      "limits" =>
        "Statistical live-stack observations, not call counts or exclusive CPU attribution; up to the VM's saved stack depth. Sampling perturbs timings; compare separate unprofiled runs."
    })
  end

  def supported?(r),
    do:
      r["status"] == "completed" and get_in(r, ["summary", "planning_status"]) == "supported" and
        get_in(r, ["summary", "resource_status"]) == "supported"

  def markdown(report) do
    rows =
      Enum.map(report["runs"], fn r ->
        s = r["summary"] || %{}
        t = s["timings"] || %{}

        "| #{r["asset_count"]} | #{r["request_count"]} | #{r["status"]} | #{s["scheduled_count"] || "—"} | #{if(is_number(t["total_ms"]), do: Float.round(t["total_ms"] / 1000, 2), else: "—")} | #{Float.round(r["sampled_peak_vm_bytes"] / 1.0e9, 2)} |\n"
      end)

    [
      "# Constellation scaling observations\n\nAnalysis-only synthetic clustered fleets. Demand, fidelity and bounds are explicit in summary.json.\n\n",
      "| Spacecraft | Requests | Case status | Scheduled | Planning seconds | Sampled VM GB |\n| --- | --- | --- | --- | --- | --- |\n",
      rows,
      "\nStatus and physical planning/resource status must all be supported. Summaries retain counters, assignments, battery margins and compact identity. All model/path/resource checks were computed; dense opportunity diagnostic retention is controlled explicitly. Sampled VM memory is not peak RSS. Stack samples are diagnostic and perturb timing. No operational acceptance or general scaling law is established.\n"
    ]
  end

  defp ranks(counts),
    do:
      counts
      |> Enum.sort_by(fn {name, n} -> {-n, name} end)
      |> Enum.take(40)
      |> Enum.map(fn {name, n} -> %{"function" => name, "samples" => n} end)
end
