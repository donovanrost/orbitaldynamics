# Isolated, opt-in instrumentation. Production source files are never rewritten.
# Usage: MIX_ENV=test mix run dev/profile_planning_memory.exs DIR ASSETS REQUESTS natural|natural_gc|retained

defmodule PlanningMemoryProbe do
  alias OrbitalDynamics.MissionAnalysis.{ConstellationScaling, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot
  @key {__MODULE__, :configuration}

  def checkpoint(stage, terms) do
    %{owner: owner, mode: mode} = Process.get(@key)
    send(owner, {:stage, stage})

    if mode == "retained" do
      before_gc = memory(self())
      :erlang.garbage_collect()
      after_gc = memory(self())
      values = terms.()
      word = :erlang.system_info(:wordsize)

      sizes =
        Map.new(values, fn {name, value} -> {name, :erts_debug.size_shared(value) * word} end)

      union = :erts_debug.size_shared(values) * word

      send(
        owner,
        {:checkpoint,
         %{
           "stage" => stage,
           "before_gc" => before_gc,
           "after_gc" => after_gc,
           "term_heap_bytes" => sizes,
           "combined_terms_heap_bytes" => union,
           "container_counts" =>
             Map.new(values, fn {k, v} ->
               {k,
                cond do
                  k == "path_values" and is_map(v) -> path_entry_count(v)
                  is_map(v) -> map_size(v)
                  is_list(v) -> length(v)
                  true -> :null
                end}
             end),
           "path_cache_breakdown" => path_breakdown(values["path_values"]),
           "process_dictionary_heap_bytes" => :erts_debug.size_shared(Process.get()) * word
         }}
      )
    end
  end

  defp path_entry_count(entries) do
    if partitioned?(entries),
      do: Enum.sum(for {_, rows} <- entries, do: map_size(rows)),
      else: map_size(entries)
  end

  defp partitioned?(entries), do: Enum.all?(entries, fn {k, v} -> is_binary(k) and is_map(v) end)

  defp path_breakdown(nil), do: :null

  defp path_breakdown(entries) do
    word = :erlang.system_info(:wordsize)

    entries =
      if partitioned?(entries),
        do: Enum.flat_map(entries, fn {_, rows} -> Map.to_list(rows) end),
        else: Map.to_list(entries)

    groups =
      Enum.group_by(entries, fn {key, _} ->
        if elem(key, 0) == :service_mode, do: "service_mode", else: elem(key, 1)
      end)

    Map.new(groups, fn {id, rows} ->
      keys = Enum.map(rows, &elem(&1, 0))
      results = Enum.map(rows, &elem(&1, 1))
      checks = Enum.map(results, fn r -> if is_map(r), do: r["checks"], else: nil end)
      metrics = Enum.map(results, fn r -> if is_map(r), do: r["metrics"], else: nil end)

      {id,
       %{
         "entries" => length(rows),
         "keys_heap_bytes" => :erts_debug.size_shared(keys) * word,
         "results_heap_bytes" => :erts_debug.size_shared(results) * word,
         "checks_heap_bytes" => :erts_debug.size_shared(checks) * word,
         "metrics_heap_bytes" => :erts_debug.size_shared(metrics) * word,
         "group_heap_bytes" => :erts_debug.size_shared(rows) * word
       }}
    end)
  end

  def memory(pid) do
    measured_at = System.monotonic_time(:microsecond)

    vm =
      :erlang.memory([:total, :processes, :processes_used, :system, :binary, :ets, :code, :atom])
      |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

    case Process.info(pid, [
           :memory,
           :total_heap_size,
           :heap_size,
           :stack_size,
           :garbage_collection,
           :current_stacktrace,
           :binary
         ]) do
      nil ->
        %{"vm" => vm, "worker" => :null}

      fields ->
        p = Map.new(fields)
        word = :erlang.system_info(:wordsize)
        binaries = Enum.uniq_by(p.binary, &elem(&1, 0))

        %{
          "vm" => vm,
          "vm_after_worker_info" =>
            :erlang.memory([:total, :processes, :processes_used, :system, :binary, :ets])
            |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end),
          "observation_duration_us" => System.monotonic_time(:microsecond) - measured_at,
          "worker" => %{
            "memory_bytes" => p.memory,
            "total_heap_bytes" => p.total_heap_size * word,
            "young_heap_bytes" => p.heap_size * word,
            "stack_bytes" => p.stack_size * word,
            "referenced_offheap_binary_bytes" => Enum.sum(for {_, n, _} <- binaries, do: n),
            "minor_gcs" => Keyword.get(p.garbage_collection, :minor_gcs),
            "stack" =>
              Enum.map(p.current_stacktrace, fn {m, f, a, _} -> "#{inspect(m)}.#{f}/#{a}" end)
          }
        }
    end
  end

  def run(dir, size, demand, mode) do
    unless mode in ["natural", "natural_gc", "retained"],
      do: raise("mode must be natural, natural_gc or retained")

    {mission, study} = ConstellationScaling.inputs!(size, demand)
    if File.exists?(dir), do: raise("fresh output directory required")
    File.mkdir_p!(dir)
    owner = self()
    original = instrument!()
    started = System.monotonic_time(:millisecond)

    try do
      task =
        Task.async(fn ->
          receive do
            :begin_profile -> :ok
          end

          Process.put(@key, %{owner: owner, mode: mode})
          checkpoint("preparation", fn -> %{"mission" => mission, "study" => study} end)

          {summary, report} =
            ConstellationBenchmark.run_case!(mission, study, size, include_samples: false)

          checkpoint("report_complete", fn -> report_terms(report) end)

          %{
            "summary" => summary,
            "path_rule_evaluation_count" =>
              get_in(report, ["attitude_planning", "path_constraints", "rule_evaluation_count"]) ||
                :null,
            "summary_sha256" => Snapshot.digest(Map.delete(summary, "timings"))
          }
        end)

      if mode == "natural_gc",
        do: :erlang.trace(task.pid, true, [:garbage_collection, :monotonic_timestamp])

      send(task.pid, :begin_profile)

      result =
        monitor(task, started, %{
          stage: "preparation",
          samples: [],
          checkpoints: [],
          next_sample: started + 500,
          gc_active: nil,
          gc_counts: %{},
          gc_largest: []
        })

      result =
        Map.merge(result, %{
          "format" => "planning_memory_profile.v1",
          "mode" => mode,
          "asset_count" => size,
          "request_count" => demand,
          "input_sha256" => Snapshot.digest(%{"mission" => mission, "study" => study}),
          "runtime" => %{
            "elixir" => System.version(),
            "otp" => System.otp_release(),
            "word_bytes" => :erlang.system_info(:wordsize)
          },
          "limits" => [
            "Diagnostic runs perturb timing; retained mode forces GC and traverses terms, changing heap behavior. Use natural mode for sampled peaks.",
            "Term heap sizes preserve sharing within each measured term; component sizes overlap and must not be summed. Off-heap binary bodies are excluded from term heap sizes.",
            "GC measures worker liveness at instrumented boundaries, not total bytes allocated over time. Hooks can affect compiler liveness. VM memory is not RSS.",
            "natural_gc additionally traces worker GC with monotonic VM timestamps and brackets worker reads with VM snapshots; tracing perturbs execution. Heap block sizes in GC events are words.",
            "Natural samples every 500 ms may miss short peaks; 8 GB VM / 900 second guards are sampled, not hard OS quotas."
          ]
        })

      File.write!(Path.join(dir, "profile.json"), :json.encode(result), [:exclusive])

      unless result["status"] == "completed",
        do: raise("memory profile failed; inspect saved evidence")

      IO.puts(
        "#{mode} #{size}/#{demand}: #{result["status"]}; peak #{result["peak"]["vm"]["total"]} bytes"
      )
    after
      Enum.each(original, fn {path, source} -> Code.compile_string(source, path) end)
    end
  end

  defp report_terms(r) do
    a = r["attitude_planning"]

    %{
      "report" => r,
      "analyses" => r["analyses"],
      "opportunities" => r["opportunities"],
      "decisions" => r["selection_decisions"],
      "activities" => r["activities"],
      "attitude_planning" => a,
      "resources" => a["resource_feasibility"],
      "horizon" => a["horizon_coverage"],
      "transitions" => a["transitions"]
    }
  end

  defp monitor(task, start, acc) do
    receive do
      {:stage, stage} ->
        monitor(task, start, %{acc | stage: stage})

      {:trace_ts, pid, event, info, timestamp} when pid == task.pid ->
        monitor(task, start, gc_event(acc, event, info, timestamp, start))

      {:checkpoint, row} ->
        monitor(task, start, %{acc | checkpoints: [row | acc.checkpoints]})

      {ref, value} when ref == task.ref ->
        Process.demonitor(ref, [:flush])
        finish("completed", acc, value)

      {:DOWN, ref, :process, _, reason} when ref == task.ref ->
        finish("failed", acc, %{"error" => inspect(reason)})
    after
      max(0, acc.next_sample - System.monotonic_time(:millisecond)) ->
        row =
          memory(task.pid)
          |> Map.merge(%{
            "stage" => acc.stage,
            "elapsed_ms" => System.monotonic_time(:millisecond) - start
          })

        acc = %{
          acc
          | samples: [row | acc.samples],
            next_sample: System.monotonic_time(:millisecond) + 500
        }

        cond do
          row["vm"]["total"] > 8_000_000_000 ->
            Task.shutdown(task, :brutal_kill)
            finish("memory_budget_exceeded", acc, %{})

          row["elapsed_ms"] > 900_000 ->
            Task.shutdown(task, :brutal_kill)
            finish("timeout", acc, %{})

          true ->
            monitor(task, start, acc)
        end
    end
  end

  defp gc_event(acc, event, info, timestamp, start) do
    t = System.convert_time_unit(timestamp, :native, :microsecond) - start * 1000
    info = Map.new(info, fn {k, v} -> {Atom.to_string(k), v} end)

    case event do
      e when e in [:gc_minor_start, :gc_major_start] ->
        %{
          acc
          | gc_active: %{
              "type" => Atom.to_string(e),
              "starts_at_us" => t,
              "start" => info,
              "stage" => acc.stage
            }
        }

      e when e in [:gc_minor_end, :gc_major_end] ->
        counts = Map.update(acc.gc_counts, Atom.to_string(e), 1, &(&1 + 1))

        expected = e |> Atom.to_string() |> String.replace("_end", "_start")

        if acc.gc_active && acc.gc_active["type"] == expected do
          row =
            Map.merge(acc.gc_active, %{
              "ends_at_us" => t,
              "duration_us" => t - acc.gc_active["starts_at_us"],
              "end" => info
            })

          largest =
            [row | acc.gc_largest]
            |> Enum.sort_by(fn r ->
              -(r["start"]["heap_block_size"] + r["start"]["old_heap_block_size"])
            end)
            |> Enum.take(20)

          %{acc | gc_active: nil, gc_counts: counts, gc_largest: largest}
        else
          %{acc | gc_counts: counts}
        end

      _ ->
        acc
    end
  end

  defp finish(status, acc, extra) do
    samples = Enum.reverse(acc.samples)
    peak = Enum.max_by(samples, & &1["vm"]["total"], fn -> memory(self()) end)

    Map.merge(extra, %{
      "gc_counts" => acc.gc_counts,
      "largest_gc_events" => acc.gc_largest,
      "status" => status,
      "peak" => peak,
      "samples" => samples,
      "checkpoints" => Enum.reverse(acc.checkpoints)
    })
  end

  defp instrument! do
    patches = [
      {"lib/orbital_dynamics/mission_analysis.ex",
       [
         {"      pairs = for asset <- assets, request <- requests, do: {asset, request}",
          "      pairs = for asset <- assets, request <- requests, do: {asset, request}\n      PlanningMemoryProbe.checkpoint(\"opportunity_generation\", fn -> %{\"assets\" => assets, \"requests\" => requests, \"pairs\" => pairs, \"refinement\" => refinement} end)"},
         {"                   {:ok, reports, sessions}",
          "                   PlanningMemoryProbe.checkpoint(\"opportunities_complete\", fn -> %{\"reports\" => reports, \"sessions\" => sessions} end)\n                   {:ok, reports, sessions}"},
         {"          opportunities = Enum.flat_map(reports, & &1[\"opportunities\"])",
          "          PlanningMemoryProbe.checkpoint(\"schedule_complete\", fn -> %{\"reports\" => reports, \"activities\" => activities, \"decisions\" => decisions, \"attitude_report\" => attitude_report} end)\n          opportunities = Enum.flat_map(reports, & &1[\"opportunities\"])"}
       ]},
      {"lib/orbital_dynamics/mission_analysis/attitude/evaluator.ex",
       [
         {"          finish_paths(\n",
          "          PlanningMemoryProbe.checkpoint(\"candidate_search_complete\", fn -> %{\"activities\" => activities, \"decisions\" => decisions, \"cache\" => cache, \"pointing_cache\" => cache.values, \"path_cache\" => cache.path, \"path_values\" => cache.path.values, \"resource_runtime\" => cache.resource} end)\n          finish_paths(\n"},
         {"           ResourceRunner.finish(assets, result.activities, policy, state_at, cache) do\n      {:ok, result.activities,",
          "           ResourceRunner.finish(assets, result.activities, policy, state_at, cache) do\n      PlanningMemoryProbe.checkpoint(\"attitude_complete\", fn -> %{\"resources\" => resources, \"horizon\" => result.horizon, \"transitions\" => result.transitions, \"cache\" => cache, \"pointing_cache\" => cache.values, \"path_values\" => cache.path.values, \"decisions\" => result.decisions} end)\n      {:ok, result.activities,"}
       ]},
      {"lib/orbital_dynamics/mission_analysis/resource/runner.ex",
       [
         {"  def finish(assets, activities, policy, state_at, cache) do\n    Enum.reduce_while",
          "  def finish(assets, activities, policy, state_at, cache) do\n    PlanningMemoryProbe.checkpoint(\"resource_replay_start\", fn -> %{\"cache\" => cache, \"pointing_cache\" => cache.values, \"path_values\" => cache.path.values} end)\n    Enum.reduce_while"},
         {"      {:ok, reports, cache} ->\n        {:ok,",
          "      {:ok, reports, cache} ->\n        PlanningMemoryProbe.checkpoint(\"resource_replay_complete\", fn -> %{\"resource_reports\" => reports, \"cache\" => cache, \"pointing_cache\" => cache.values, \"path_values\" => cache.path.values} end)\n        {:ok,"}
       ]}
    ]

    originals = Enum.map(patches, fn {file, _} -> {Path.expand(file), File.read!(file)} end)
    previous = Code.compiler_options(ignore_module_conflict: true)

    try do
      Enum.each(patches, fn {file, edits} ->
        source =
          Enum.reduce(edits, File.read!(file), fn {needle, replacement}, code ->
            unless length(:binary.matches(code, needle)) == 1,
              do: raise("instrumentation anchor changed: #{file}: #{needle}")

            String.replace(code, needle, replacement, global: false)
          end)

        Code.compile_string(source, Path.expand(file))
      end)
    after
      Code.compiler_options(previous)
    end

    originals
  end
end

[dir, size, demand, mode] = System.argv()
PlanningMemoryProbe.run(dir, String.to_integer(size), String.to_integer(demand), mode)
