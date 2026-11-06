defmodule NativeResultsVerification do
  alias OrbitalDynamics.MissionAnalysis.{ConstellationScaling, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def run(baseline_dir, dir) do
    if File.exists?(dir), do: raise("fresh output directory required")
    File.mkdir_p!(dir)

    files =
      Path.wildcard(Path.join(baseline_dir, "lib/**/*.ex"))
      |> Enum.map(&Path.relative_to(&1, baseline_dir))
      |> Enum.filter(&(File.read!(&1) != File.read!(Path.join(baseline_dir, &1))))
      |> Enum.sort_by(fn file ->
        {if(String.ends_with?(file, "/path/check.ex"), do: 0, else: 1), file}
      end)

    current = Enum.map(files, &{Path.expand(&1), File.read!(&1)})
    baseline = Enum.map(files, &{Path.expand(&1), File.read!(Path.join(baseline_dir, &1))})
    options = Code.compiler_options(ignore_module_conflict: true)
    {m, s} = ConstellationScaling.inputs!(6)

    try do
      outcomes =
        for {mode, implementation} <- [{"baseline", baseline}, {"native", current}] do
          Enum.each(implementation, fn {file, code} -> Code.compile_string(code, file) end)

          {summary, report, report_bytes} =
            Task.async(fn ->
              {summary, report} =
                ConstellationBenchmark.run_case!(m, s, 6, include_samples: false)

              {summary, report, :erts_debug.size_shared(report) * :erlang.system_info(:wordsize)}
            end)
            |> Task.await(120_000)

          unless summary["planning_status"] == "supported" and
                   summary["resource_status"] == "supported",
                 do: raise("unsupported verification case")

          {%{
             "mode" => mode,
             "summary" => summary,
             "report_heap_bytes" => report_bytes,
             "report_sha256" => Snapshot.digest(report),
             "source_sha256" =>
               Map.new(implementation, fn {f, code} ->
                 {f, Base.encode16(:crypto.hash(:sha256, code), case: :lower)}
               end)
           }, report}
        end

      [{before, old}, {after_row, new}] = outcomes
      equal? = old === new

      result = %{
        "format" => "native_results_verification.v1",
        "entire_reports_exactly_equal" => equal?,
        "input_sha256" => Snapshot.digest(%{"mission" => m, "study" => s}),
        "runs" => [before, after_row],
        "scope" =>
          "Whole six-spacecraft compact-opportunity report; all fields, histories and evaluation counters participate. Report encoding is included in planner time. Not independent physical validation."
      }

      File.write!(Path.join(dir, "verification.json"), :json.encode(result), [:exclusive])
      unless equal?, do: raise("native result migration changed complete report; inspect digests")
      IO.puts("Complete reports exactly equal: #{before["report_sha256"]}")
    after
      Enum.each(current, fn {f, code} -> Code.compile_string(code, f) end)
      Code.compiler_options(options)
    end
  end
end

[baseline_dir, dir] = System.argv()
NativeResultsVerification.run(baseline_dir, dir)
