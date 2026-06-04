defmodule Mix.Tasks.OrbitalDynamics.Campaign.Run do
  @moduledoc """
  Runs a campaign repair or strategy request file and writes a compact artifact.

  Usage:

      mix orbital_dynamics.campaign.run --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/leo_constellation_campaign_repair_v2.json
      mix orbital_dynamics.campaign.run --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output study_results/leo_constellation_campaign_strategy_v3.json
      mix orbital_dynamics.campaign.run --type strategy --request /tmp/request.json --output /tmp/strategy.json --base-path /tmp
      mix orbital_dynamics.campaign.run --type repair --request studies/leo_constellation_campaign_repair_v2.json --output /tmp/repair.json --format json
  """

  use Mix.Task

  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.Schema

  @shortdoc "Runs a campaign repair or strategy JSON request"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    request_path = Keyword.fetch!(opts, :request)
    output_path = Keyword.fetch!(opts, :output)
    type = Keyword.fetch!(opts, :type)
    request_opts = Keyword.take(opts, [:base_path])
    format = Keyword.fetch!(opts, :format)

    validate_request!(type, request_path, request_opts, format)

    artifact =
      type
      |> run_request!(request_path, request_opts)
      |> validate_artifact!()

    Artifact.write_json!(artifact, output_path)
    print_summary(artifact, request_path, output_path, type, format)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          type: :string,
          request: :string,
          output: :string,
          base_path: :string,
          format: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid campaign run arguments: #{inspect(rest ++ invalid)}")
    end

    for required <- [:type, :request, :output], not Keyword.has_key?(parsed, required) do
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

    Keyword.put(parsed, :format, format)
  end

  defp run_request!("repair", request_path, opts),
    do: OrbitalDynamics.campaign_repair_from_file!(request_path, opts)

  defp run_request!("strategy", request_path, opts),
    do: OrbitalDynamics.campaign_strategy_from_file!(request_path, opts)

  defp validate_request!(type, request_path, opts, format) do
    report = OrbitalDynamics.campaign_request_validation_report(type, request_path, opts)

    if report["status"] == "fail" do
      print_lint_report(report, format)
      Mix.raise("campaign request lint failed for #{request_path}")
    end

    :ok
  end

  defp validate_artifact!(artifact) do
    case Schema.validate_artifact(artifact) do
      {:ok, _report} ->
        artifact

      {:error, %{"errors" => errors}} ->
        Enum.each(errors, fn error ->
          Mix.shell().info("error #{error["path"]}: #{error["message"]}")
        end)

        Mix.raise("campaign artifact failed schema validation")
    end
  end

  defp print_summary(artifact, request_path, output_path, type, format) do
    {:ok, report} = Schema.validate_artifact(artifact)
    summary = summary(artifact, request_path, output_path, type, report)

    print_summary(summary, format)
  end

  defp print_summary(summary, "json") do
    summary
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_summary(summary, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics campaign run")
    Mix.shell().info("type: #{summary["type"]}")
    Mix.shell().info("request: #{summary["request"]}")
    Mix.shell().info("artifact: #{summary["artifact_id"]}")
    Mix.shell().info("contract: #{summary["schema_contract"]}")
    Mix.shell().info("status: #{summary["status"]}")
    Mix.shell().info("warnings: #{summary["warning_count"]}")
    Mix.shell().info("wrote: #{summary["output"]}")
  end

  defp print_lint_report(report, "json") do
    report
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_lint_report(report, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics campaign request lint")
    Mix.shell().info("type: #{report["type"]}")
    Mix.shell().info("request: #{report["request"]["path"]}")
    Mix.shell().info("status: #{report["status"]}")
    Mix.shell().info("errors: #{report["error_count"]}")

    for error <- report["errors"] do
      Mix.shell().info("error: #{error["code"]} #{error["path"]} #{error["message"]}")
    end
  end

  defp summary(artifact, request_path, output_path, type, report) do
    %{
      "type" => type,
      "request" => request_path,
      "output" => output_path,
      "artifact_id" => artifact_id(artifact),
      "schema_contract" => report["schema_contract"],
      "status" => report["status"],
      "warning_count" => length(report["warnings"])
    }
  end

  defp artifact_id(artifact) do
    ["repair_id", "strategy_id", "plan_id", "source_repair_id", "source_plan_id"]
    |> Enum.map(&Map.get(artifact, &1))
    |> Enum.find("unknown", &(is_binary(&1) and &1 != ""))
  end
end
