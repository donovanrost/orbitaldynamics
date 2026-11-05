defmodule Mix.Tasks.OrbitalDynamics.Mission.VerifyWheels do
  use Mix.Task
  @shortdoc "Compare production wheels against a frozen independent body-frame ODE reference"
  alias OrbitalDynamics.MissionAnalysis.{WheelCheck, PlanRevision.Files}

  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output_dir: [:string, :keep]])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output_dir],
      do: Mix.raise("required: --output-dir DIRECTORY")

    dir = Files.directory!(opts[:output_dir], ~w(report.json README.md), [])

    case WheelCheck.verify() do
      {:ok, result} ->
        File.mkdir_p!(dir)
        File.write!(Path.join(dir, "report.json"), [:json.encode(result), "\n"], [:exclusive])

        rows =
          for r <- result["rows"],
              do:
                "| #{r["case_id"]} | #{r["step_s"]} | #{r["momentum_error_nms"]} | #{r["motor_error_nm"]} | #{r["passed"]} |\n"

        File.write!(
          Path.join(dir, "README.md"),
          [
            "# Independent wheel numerical verification\n\nStatus: **#{result["status"]}**. Finite synthetic cases; no spacecraft validation.\n\n| Case | Step s | Momentum error Nms | Motor error Nm | Passed |\n| --- | --- | --- | --- | --- |\n",
            rows,
            "\n",
            Enum.map(result["limits"], &("- " <> &1 <> "\n"))
          ],
          [:exclusive]
        )

        Mix.shell().info(
          "Independent wheel verification #{result["status"]}: #{Path.join(dir, "README.md")}"
        )

        if result["status"] != "passed",
          do: Mix.raise("independent wheel numerical checks failed")

      {:error, reason} ->
        Mix.raise(inspect(reason))
    end
  end
end
