defmodule Mix.Tasks.OrbitalDynamics.Mission.CheckBaseline do
  use Mix.Task
  @shortdoc "Compare the pinned reference baseline against independent Orekit results"
  @impl true
  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output: :string])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output],
      do: Mix.raise("required: --output PATH")

    Mix.Task.run("app.start")

    case OrbitalDynamics.MissionAnalysis.BaselineCheck.verify() do
      {:ok, report} ->
        File.mkdir_p!(Path.dirname(opts[:output]))
        File.write!(opts[:output], [:json.encode(report), "\n"])

        if report["status"] != "pass",
          do: Mix.raise("baseline comparison failed: #{opts[:output]}")

        Mix.shell().info(
          "Orekit baseline: #{report["status"]}; #{report["sample_count"]} samples. #{opts[:output]}"
        )

      {:error, reason} ->
        Mix.raise(inspect(reason))
    end
  end
end
