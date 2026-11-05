defmodule Mix.Tasks.OrbitalDynamics.Mission.Explain do
  use Mix.Task
  @shortdoc "Explain a request from a saved plan snapshot without rerunning planning"
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Files}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Explanation

  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          snapshot: [:string, :keep],
          request: [:string, :keep],
          output_dir: [:string, :keep]
        ]
      )

    unless rest == [] and invalid == [] and
             Enum.sort(Keyword.keys(opts)) == [:output_dir, :request, :snapshot],
           do: Mix.raise("required: --snapshot PATH --request ID --output-dir DIRECTORY")

    path = Path.expand(opts[:snapshot])
    snapshot = Snapshot.read!(path)
    explanation = Explanation.from_report!(snapshot["payload"]["report"], opts[:request])
    explanation = Map.put(explanation, "snapshot_id", snapshot["snapshot_id"])
    dir = Files.directory!(opts[:output_dir], ~w(explanation.json README.md), [path])
    File.mkdir_p!(dir)

    File.write!(Path.join(dir, "explanation.json"), [:json.encode(explanation), "\n"], [
      :exclusive
    ])

    File.write!(Path.join(dir, "README.md"), Explanation.markdown(explanation), [:exclusive])
    Mix.shell().info("Request evidence written to #{Path.join(dir, "README.md")}")
  end
end
