defmodule Mix.Tasks.OrbitalDynamics.Mission.PredictState do
  use Mix.Task
  @shortdoc "Generate a synthetic state update from saved motion and exact battery samples"
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Prediction, Files}
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [baseline: [:string, :keep], at: [:float, :keep], output_dir: [:string, :keep]]
      )

    unless rest == [] and invalid == [] and
             Enum.sort(Keyword.keys(opts)) == [:at, :baseline, :output_dir],
           do:
             Mix.raise(
               "required: --baseline PATH --at SECONDS_SINCE_J2000 --output-dir DIRECTORY"
             )

    path = Path.expand(opts[:baseline])
    snapshot = Snapshot.read!(path)
    update = Prediction.update!(snapshot, opts[:at])
    dir = Files.directory!(opts[:output_dir], ~w(state_update.json README.md), [path])
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "state_update.json"), [:json.encode(update), "\n"], [:exclusive])

    File.write!(
      Path.join(dir, "README.md"),
      "# Synthetic predicted state\n\nBaseline: `#{snapshot["snapshot_id"]}`. Epoch: #{opts[:at]} UTC seconds since J2000.\n\nGenerated from saved motion and exact finest-cadence supported battery samples. Past planned services are assumed executed as planned for this synthetic fixture. This is not telemetry or independent validation. Review the declarations before using them as an advance input.\n",
      [:exclusive]
    )

    Mix.shell().info("Synthetic state update written to #{Path.join(dir, "state_update.json")}")
  end
end
