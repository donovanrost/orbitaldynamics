defmodule OpportunityRetentionVerification do
  alias OrbitalDynamics.MissionAnalysis.{ConstellationScaling, ConstellationBenchmark}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def run(dir) do
    if File.exists?(dir), do: raise("fresh output directory required")
    File.mkdir_p!(dir)
    {mission, study} = ConstellationScaling.inputs!(6)

    runs =
      for full? <- [true, false] do
        Task.async(fn ->
          {summary, report} =
            ConstellationBenchmark.run_case!(mission, study, 6, include_samples: full?)

          unless summary["planning_status"] == "supported" and
                   summary["resource_status"] == "supported",
                 do: raise("unsupported retention verification plan")

          %{
            "mode" => if(full?, do: "full", else: "compact"),
            "summary" => summary,
            "summary_sha256" => Snapshot.digest(Map.delete(summary, "timings")),
            "outcome_projection_sha256" => Snapshot.digest(project(report)),
            "encoded_report_bytes" => IO.iodata_length(:json.encode(report)),
            "retained_model_samples" =>
              Enum.sum(for a <- report["analyses"], do: length(a["samples"] || [])),
            "retained_function_observations" =>
              Enum.sum(
                for a <- report["analyses"],
                    do:
                      length(
                        get_in(a, [
                          "opportunity_evidence",
                          "event_search",
                          "function_observations"
                        ]) || []
                      )
              ),
            "input_sha256" => Snapshot.digest(%{"mission" => mission, "study" => study})
          }
        end)
        |> Task.await(120_000)
      end

    [full, compact] = runs
    same? = full["outcome_projection_sha256"] == compact["outcome_projection_sha256"]

    result = %{
      "format" => "opportunity_retention_verification.v1",
      "outcome_projection_equal" => same?,
      "projection_scope" =>
        "Entire report except analysis.samples, event scan_samples/function_observations, event controls.include_samples and diagnostic_retention metadata. Includes all windows, events, unknown intervals, failure counts, work counters, activities and complete attitude/path/resource evidence.",
      "runs" => runs
    }

    File.write!(Path.join(dir, "verification.json"), :json.encode(result), [:exclusive])
    unless same?, do: raise("retention changed outcome projection")
    IO.puts("Full/compact outcome projection matched: #{full["outcome_projection_sha256"]}")
  end

  defp project(report) do
    Map.update!(report, "analyses", fn analyses ->
      Enum.map(analyses, fn a ->
        a
        |> Map.delete("samples")
        |> Map.update!("opportunity_evidence", fn evidence ->
          evidence
          |> Map.delete("diagnostic_retention")
          |> Map.update!("event_search", fn search ->
            search
            |> Map.delete("function_observations")
            |> Map.update!("controls", &Map.delete(&1, "include_samples"))
            |> Map.update!("results", &Enum.map(&1, fn r -> Map.delete(r, "scan_samples") end))
          end)
        end)
      end)
    end)
  end
end

[dir] = System.argv()
OpportunityRetentionVerification.run(dir)
