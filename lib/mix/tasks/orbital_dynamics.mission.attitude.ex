defmodule Mix.Tasks.OrbitalDynamics.Mission.Attitude do
  use Mix.Task

  @shortdoc "Plan acquisition, sampled tracking and activity transitions with explicit attitude limits"
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Reference, Report}
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [study: :string, output_dir: :string])

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == [:output_dir, :study],
      do: Mix.raise("required: --study PATH --output-dir DIRECTORY")

    Mix.Task.run("app.start")
    study = ReferenceMission.load!(opts[:study])
    mission_path = Path.expand(study["mission_manifest"], Path.dirname(Path.expand(opts[:study])))
    mission = ReferenceMission.load!(mission_path)
    report = Reference.run!(mission, study)
    directory = Path.expand(opts[:output_dir])

    outputs = [
      {"report.json", [:json.encode(report), "\n"]},
      {"README.md", Report.markdown(report)}
    ]

    for {name, _} <- outputs do
      if Path.join(directory, name) in [Path.expand(opts[:study]), mission_path],
        do: Mix.raise("output must not overwrite input files")
    end

    File.mkdir_p!(directory)
    Enum.each(outputs, fn {name, bytes} -> File.write!(Path.join(directory, name), bytes) end)

    Mix.shell().info(
      "#{length(report["activities"])}/#{length(report["requests"])} requests scheduled with attitude evidence. #{Path.join(directory, "README.md")}"
    )
  end
end
