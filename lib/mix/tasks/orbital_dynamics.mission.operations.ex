defmodule Mix.Tasks.OrbitalDynamics.Mission.Operations do
  use Mix.Task
  @shortdoc "Run a bounded scripted execution/replanning scenario with chronological evidence"
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Files
  alias OrbitalDynamics.MissionAnalysis.Operations.{Scenario, Report}
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [scenario: [:string, :keep], output_dir: [:string, :keep]])

    unless rest == [] and invalid == [] and
             Enum.sort(Keyword.keys(opts)) == [:output_dir, :scenario],
           do: Mix.raise("required: --scenario PATH --output-dir DIRECTORY")

    path = Path.expand(opts[:scenario])
    script = path |> ReferenceMission.load!() |> Scenario.validate!()
    mission_path = Path.expand(script["mission_manifest"], Path.dirname(path))
    study_path = Path.expand(script["planning_study"], Path.dirname(path))
    mission = ReferenceMission.load!(mission_path)
    study = ReferenceMission.load!(study_path)

    dir =
      Files.directory!(opts[:output_dir], Scenario.artifact_names(script), [
        path,
        mission_path,
        study_path
      ])

    Mix.Task.run("app.start")
    File.mkdir_p!(dir)

    emit = fn name, value ->
      File.write!(Path.join(dir, name), [:json.encode(value), "\n"], [:exclusive])
    end

    report = Scenario.run!(mission, study, script, emit)
    emit.("operations.json", report)
    File.write!(Path.join(dir, "README.md"), Report.markdown(report), [:exclusive])

    Mix.shell().info(
      "Operations scenario #{report["verification_status"]}, #{report["run_status"]}: #{Path.join(dir, "README.md")}"
    )

    if report["verification_status"] != "passed",
      do:
        Mix.raise(
          "operations scenario verification failed; inspect #{Path.join(dir, "README.md")}"
        )
  end
end
