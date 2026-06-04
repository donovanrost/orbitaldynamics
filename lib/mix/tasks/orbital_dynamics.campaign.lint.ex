defmodule Mix.Tasks.OrbitalDynamics.Campaign.Lint do
  @moduledoc """
  Validates campaign repair or strategy request JSON without running planning.

  Usage:

      mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json
      mix orbital_dynamics.campaign.lint --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --format json
      mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/campaign_request_lint_v1.json
      mix orbital_dynamics.campaign.lint --type strategy --request /tmp/request.json --base-path /tmp
  """

  use Mix.Task

  @shortdoc "Validates campaign repair or strategy JSON requests"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    type = Keyword.fetch!(opts, :type)
    request_path = Keyword.fetch!(opts, :request)
    format = Keyword.fetch!(opts, :format)

    report =
      OrbitalDynamics.campaign_request_validation_report(
        type,
        request_path,
        Keyword.take(opts, [:base_path])
      )

    maybe_write_report(report, Keyword.get(opts, :output))
    print_report(report, format)

    if report["status"] == "fail" do
      Mix.raise("campaign request lint failed for #{request_path}")
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          type: :string,
          request: :string,
          base_path: :string,
          format: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid campaign lint arguments: #{inspect(rest ++ invalid)}")
    end

    for required <- [:type, :request], not Keyword.has_key?(parsed, required) do
      Mix.raise("--#{required |> Atom.to_string() |> String.replace("_", "-")} is required")
    end

    type = Keyword.fetch!(parsed, :type)

    unless type in ["repair", "strategy"] do
      Mix.raise("--type must be repair or strategy")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    parsed
    |> Keyword.put(:type, type)
    |> Keyword.put(:format, format)
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
    Mix.shell().info("OrbitalDynamics campaign request lint")
    Mix.shell().info("type: #{report["type"]}")
    Mix.shell().info("request: #{report["request"]["path"]}")
    Mix.shell().info("status: #{report["status"]}")
    Mix.shell().info("errors: #{report["error_count"]}")

    if report["status"] == "pass" do
      Mix.shell().info("source plan: #{report["source_plan"]["plan_id"]}")
      Mix.shell().info("source contract: #{report["source_plan"]["schema_contract"]}")
    end

    for error <- report["errors"] do
      Mix.shell().info("error: #{error["code"]} #{error["path"]} #{error["message"]}")
    end
  end
end
