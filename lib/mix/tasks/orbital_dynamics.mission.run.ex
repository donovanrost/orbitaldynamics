defmodule Mix.Tasks.OrbitalDynamics.Mission.Run do
  use Mix.Task
  @shortdoc "Run an analysis-only configurable reference mission"
  @moduledoc """
  Run `mix orbital_dynamics.mission.run --manifest PATH --output PATH`.
  The standalone mission_analysis.v1 report is not an executable campaign plan.
  """
  @impl true
  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [manifest: :string, output: :string])

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == [:manifest, :output],
      do: Mix.raise("required: --manifest PATH --output PATH")

    Mix.Task.run("app.start")
    config = OrbitalDynamics.MissionAnalysis.ReferenceMission.load!(opts[:manifest])
    report = OrbitalDynamics.MissionAnalysis.ReferenceMission.run!(config)
    path = Path.expand(opts[:output])
    if path == Path.expand(opts[:manifest]), do: Mix.raise("output must differ from manifest")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, [:json.encode(report), "\n"])

    Mix.shell().info(
      "#{length(report["activities"])}/#{length(report["requests"])} requests scheduled; #{length(report["opportunities"])} sampled opportunities. Analysis: #{path}"
    )
  end
end
