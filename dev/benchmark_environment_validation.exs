defmodule ValidationReuseBenchmark do
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def run(baseline_source, dir) do
    if File.exists?(dir), do: raise("fresh output directory required")
    File.mkdir_p!(dir)
    source = "lib/orbital_dynamics/environment/campaign_environment_provider.ex" |> Path.expand()
    implementations = %{"baseline" => File.read!(baseline_source), "reuse" => File.read!(source)}
    previous = Code.compiler_options(ignore_module_conflict: true)

    try do
      m = ReferenceMission.load!("studies/small_constellation.json")
      s = ReferenceMission.load!("studies/small_constellation_planning.json")

      runs =
        for repeat <- 1..2,
            mode <- if(repeat == 1, do: ~w(baseline reuse), else: ~w(reuse baseline)) do
          # Reload before the clock, with the real filename so __DIR__ is identical.
          Code.compile_string(implementations[mode], source)
          IO.puts("#{mode} repeat #{repeat}")
          :erlang.garbage_collect()
          started = System.monotonic_time(:microsecond)
          {summary, report} = ConstellationBenchmark.run_case!(m, s, 6)
          artifact_started = System.monotonic_time(:microsecond)
          bytes = IO.iodata_to_binary(:json.encode(report))
          name = "#{mode}-#{repeat}-report.json.gz"
          File.write!(Path.join(dir, name), :zlib.gzip(bytes), [:exclusive])
          sha = Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

          summary =
            Map.merge(summary, %{
              "mode" => mode,
              "repeat" => repeat,
              "input_sha256" => Snapshot.digest(%{"mission" => m, "study" => s}),
              "report_sha256" => sha,
              "report_bytes" => byte_size(bytes),
              "report_file" => name,
              "artifact_ms" => (System.monotonic_time(:microsecond) - artifact_started) / 1000,
              "workflow_total_ms" => (System.monotonic_time(:microsecond) - started) / 1000
            })

          unless summary["planning_status"] == "supported" and
                   summary["resource_status"] == "supported",
                 do: raise("unsupported benchmark plan")

          File.write!(Path.join(dir, "#{mode}-#{repeat}-summary.json"), :json.encode(summary), [
            :exclusive
          ])

          summary
        end

      File.write!(
        Path.join(dir, "summary.json"),
        :json.encode(%{
          "format" => "validation_reuse_benchmark.v1",
          "runs" => runs,
          "runtime" => %{
            "elixir" => System.version(),
            "otp" => System.otp_release(),
            "schedulers_online" => System.schedulers_online()
          },
          "scope" =>
            "Original six-spacecraft/nine-request study; compilation excluded; two alternating-order repeats. Planning and persisted-report clocks measured separately."
        }),
        [:exclusive]
      )
    after
      Code.compile_string(implementations["reuse"], source)
      Code.compiler_options(previous)
    end
  end
end

[baseline_source, dir] = System.argv()
ValidationReuseBenchmark.run(baseline_source, dir)
