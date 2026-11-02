defmodule Mix.Tasks.OrbitalDynamics.Mission.Verify do
  use Mix.Task
  @shortdoc "Verify the frozen reference mission numerical baseline offline"
  @impl true
  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output_dir: :string])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output_dir],
      do: Mix.raise("required: --output-dir DIRECTORY")

    Mix.Task.run("app.start")

    case OrbitalDynamics.MissionAnalysis.VerificationBaseline.verify() do
      {:ok, report} ->
        dir = Path.expand(opts[:output_dir])
        File.mkdir_p!(dir)
        File.write!(Path.join(dir, "report.json"), [:json.encode(report), "\n"])

        File.write!(
          Path.join(dir, "README.md"),
          OrbitalDynamics.MissionAnalysis.VerificationBaseline.markdown(report)
        )

        Mix.shell().info(
          "Reference numerical baseline: #{report["status"]}. #{Path.join(dir, "README.md")}"
        )

        if report["status"] != "pass",
          do: Mix.raise("baseline failed; inspect report.json discrepancies")

      {:error, reason} ->
        Mix.raise(inspect(reason))
    end
  end
end
