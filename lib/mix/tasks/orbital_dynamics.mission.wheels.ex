defmodule Mix.Tasks.OrbitalDynamics.Mission.Wheels do
  use Mix.Task
  @shortdoc "Run the three-wheel slew, saturation and external-unload reference cases"
  alias OrbitalDynamics.MissionAnalysis.ReactionWheelQualityCases
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Files

  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output_dir: [:string, :keep]])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output_dir],
      do: Mix.raise("required: --output-dir DIRECTORY")

    names = ~w(feasible_slew.json saturated.json unloaded.json comparison.json README.md)

    dir =
      Files.directory!(opts[:output_dir], names, [
        "studies/wheel_momentum_reference.json",
        "studies/wheel_momentum_planning.json"
      ])

    Mix.Task.run("app.start")
    File.mkdir_p!(dir)

    result =
      ReactionWheelQualityCases.run!(fn name, r ->
        File.write!(Path.join(dir, name), [:json.encode(r), "\n"], [:exclusive])
      end)

    File.write!(Path.join(dir, "comparison.json"), [:json.encode(result), "\n"], [:exclusive])

    rows =
      for c <- result["cases"],
          do:
            "| #{c["id"]} | #{c["planning_status"]} | #{c["expected_final_wheel_3_nms"]} | #{Enum.join(c["scheduled_request_ids"], ", ")} |\n"

    File.write!(
      Path.join(dir, "README.md"),
      [
        "# Three-wheel reference cases\n\nVerification: **#{result["status"]}**. Synthetic assumptions; no actual spacecraft specifications.\n\n| Case | Plan status | Expected final wheel 3 (Nms) | Scheduled |\n| --- | --- | --- | --- |\n",
        rows,
        "\nThe saturated case intentionally has no usable plan. Unloading uses external torque during a costed activity; no momentum reset. See comparison.json for all tested cadences and each report for full evidence.\n"
      ],
      [:exclusive]
    )

    Mix.shell().info("Wheel reference cases #{result["status"]}: #{Path.join(dir, "README.md")}")
    if result["status"] != "passed", do: Mix.raise("wheel reference cases failed")
  end
end
