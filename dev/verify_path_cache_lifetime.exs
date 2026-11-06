# Compare only the path runner, horizon and evaluator from a supplied baseline
# source directory with current source. Recompilation is confined to this VM.
defmodule PathCacheLifetimeVerification do
  alias OrbitalDynamics.MissionAnalysis.{ConstellationScaling, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def run(baseline_dir, output_dir) do
    if File.exists?(output_dir), do: raise("fresh output directory required")
    File.mkdir_p!(output_dir)

    files = [
      {"path_runner.ex", "lib/orbital_dynamics/mission_analysis/path/runner.ex"},
      {"horizon.ex", "lib/orbital_dynamics/mission_analysis/attitude/horizon.ex"},
      {"evaluator.ex", "lib/orbital_dynamics/mission_analysis/attitude/evaluator.ex"}
    ]

    current = Enum.map(files, fn {_, file} -> {Path.expand(file), File.read!(file)} end)

    baseline =
      Enum.map(files, fn {name, file} ->
        {Path.expand(file), File.read!(Path.join(baseline_dir, name))}
      end)

    {mission, study} = ConstellationScaling.inputs!(6)
    previous = Code.compiler_options(ignore_module_conflict: true)

    try do
      outcomes =
        for {name, implementation} <- [{"baseline", baseline}, {"released", current}] do
          Enum.each(implementation, fn {file, source} -> Code.compile_string(source, file) end)

          {summary, report} =
            Task.async(fn ->
              ConstellationBenchmark.run_case!(mission, study, 6, include_samples: false)
            end)
            |> Task.await(120_000)

          unless summary["planning_status"] == "supported" and
                   summary["resource_status"] == "supported",
                 do: raise("unsupported verification plan")

          row = %{
            "implementation" => name,
            "summary" => summary,
            "summary_sha256" => Snapshot.digest(Map.delete(summary, "timings")),
            "full_report_sha256" => Snapshot.digest(report),
            "path_rule_evaluation_count" =>
              get_in(report, ["attitude_planning", "path_constraints", "rule_evaluation_count"]),
            "source_sha256" =>
              Map.new(implementation, fn {f, source} ->
                {f, Base.encode16(:crypto.hash(:sha256, source), case: :lower)}
              end)
          }

          {row, report}
        end

      [{before, old_report}, {after_row, new_report}] = outcomes
      identical? = old_report === new_report

      result = %{
        "format" => "path_cache_lifetime_verification.v1",
        "input_sha256" => Snapshot.digest(%{"mission" => mission, "study" => study}),
        "entire_reports_exactly_equal" => identical?,
        "runs" => [before, after_row],
        "scope" =>
          "Complete six-spacecraft compact-opportunity reports, without removing any report fields. Full attitude/path/horizon/resource histories and all counters participate. This is not independent physical validation."
      }

      File.write!(Path.join(output_dir, "verification.json"), :json.encode(result), [:exclusive])
      unless identical?, do: raise("path-cache lifetime changed complete planning report")
      IO.puts("Complete planning reports exactly equal: #{before["full_report_sha256"]}")
    after
      Enum.each(current, fn {file, source} -> Code.compile_string(source, file) end)
      Code.compiler_options(previous)
    end
  end
end

[baseline_dir, output_dir] = System.argv()
PathCacheLifetimeVerification.run(baseline_dir, output_dir)
