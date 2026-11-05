defmodule Mix.Tasks.OrbitalDynamics.Mission.Assessment do
  use Mix.Task
  @shortdoc "Run bounded integrated reference-mission operations and sensitivity cases"
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [assessment: [:string, :keep], output_dir: [:string, :keep]]
      )

    unless rest == [] and invalid == [] and
             Enum.sort(Keyword.keys(opts)) == [:assessment, :output_dir],
           do: Mix.raise("required: --assessment PATH --output-dir DIRECTORY")

    path = Path.expand(opts[:assessment])
    config = OrbitalDynamics.MissionAnalysis.ReferenceMission.load!(path)
    Mix.Task.run("app.start")

    report =
      OrbitalDynamics.MissionAnalysis.ConstellationAssessment.run!(
        config,
        path,
        opts[:output_dir]
      )

    Mix.shell().info(
      "Reference assessment #{report["status"]}: #{Path.join(Path.expand(opts[:output_dir]), "README.md")}"
    )

    if report["status"] != "expectations_met",
      do: Mix.raise("reference assessment expectations failed; inspect assessment.json")
  end
end
