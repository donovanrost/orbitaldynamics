defmodule Mix.Tasks.OrbitalDynamics.Manifest.Lint do
  @moduledoc """
  Validates OrbitalDynamics study manifests without running the study.

  Usage:

      mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json
      mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json --format json
      mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json --output study_results/manifest_lint_report.json
  """

  use Mix.Task

  alias OrbitalDynamics.Study.Manifest

  @shortdoc "Validates OrbitalDynamics study manifests"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    manifest_path = Keyword.fetch!(opts, :manifest)
    format = Keyword.fetch!(opts, :format)
    report = Manifest.validation_report(manifest_path)

    maybe_write_report(report, Keyword.get(opts, :output))
    print_report(report, format)

    if report["status"] == "fail" do
      Mix.raise("manifest lint failed for #{manifest_path}")
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          manifest: :string,
          format: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid manifest lint arguments: #{inspect(rest ++ invalid)}")
    end

    unless Keyword.has_key?(parsed, :manifest) do
      Mix.raise("--manifest is required")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    Keyword.put(parsed, :format, format)
  end

  defp maybe_write_report(_report, nil), do: :ok

  defp maybe_write_report(report, output_path) when is_binary(output_path) do
    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      report
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(output_path, json <> "\n")
  end

  defp print_report(report, "json") do
    report
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_report(report, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics manifest lint")
    Mix.shell().info("manifest: #{report["manifest"]["path"]}")
    Mix.shell().info("status: #{report["status"]}")
    Mix.shell().info("errors: #{report["error_count"]}")
    Mix.shell().info("warnings: #{report["warning_count"]}")

    if report["status"] == "pass" do
      Mix.shell().info("study: #{report["study_id"]}")
      Mix.shell().info("scenarios: #{report["scenario_count"]}")

      Mix.shell().info("outputs: #{Enum.join(report["outputs"], ",")}")
    end

    for error <- report["errors"] do
      Mix.shell().info("error: #{error["code"]} #{error["path"]} #{error["message"]}")
    end
  end
end
