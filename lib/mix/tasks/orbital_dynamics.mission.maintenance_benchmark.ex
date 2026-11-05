defmodule Mix.Tasks.OrbitalDynamics.Mission.MaintenanceBenchmark do
  use Mix.Task

  @shortdoc "Benchmark total joint-maintenance work on one/two spacecraft with shared budget stops"
  alias OrbitalDynamics.MissionAnalysis.{MaintenanceWorkBenchmark, PlanRevision.Files}

  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output_dir: [:string, :keep]])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output_dir],
      do: Mix.raise("required: --output-dir DIRECTORY")

    names =
      ~w(fleet_1.json fleet_1_limited.json fleet_2.json fleet_2_limited.json benchmark.json README.md)

    dir =
      Files.directory!(opts[:output_dir], names, [
        "studies/automatic_wheel_maintenance.json",
        "studies/automatic_wheel_maintenance_planning.json"
      ])

    File.mkdir_p!(dir)

    result =
      MaintenanceWorkBenchmark.run!(fn name, r ->
        File.write!(Path.join(dir, name), [:json.encode(r), "\n"], [:exclusive])
      end)

    File.write!(Path.join(dir, "benchmark.json"), [:json.encode(result), "\n"], [:exclusive])

    rows =
      for r <- result["rows"],
          do:
            "| #{r["asset_count"]} | #{r["cap"]} | #{r["planning_status"]} | #{r["work_accounting"]["total_evaluations"]} | #{r["service_value"]} |\n"

    File.write!(
      Path.join(dir, "README.md"),
      [
        "# Maintenance work benchmark\n\nStatus: **#{result["status"]}**.\n\n| Assets | Callback cap | Result | Callbacks | Value |\n| --- | --- | --- | --- | --- |\n",
        rows,
        "\n",
        result["limits"],
        "\n"
      ],
      [:exclusive]
    )

    Mix.shell().info(
      "Maintenance work benchmark #{result["status"]}: #{Path.join(dir, "README.md")}"
    )

    if result["status"] != "passed", do: Mix.raise("maintenance work benchmark failed")
  end
end
