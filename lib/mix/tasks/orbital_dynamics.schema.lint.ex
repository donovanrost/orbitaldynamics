defmodule Mix.Tasks.OrbitalDynamics.Schema.Lint do
  @moduledoc """
  Validates saved OrbitalDynamics JSON artifacts against executable contracts.

  Usage:

      mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json
      mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign_repair_v2.json --contract campaign_repair.v2
      mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json --format json
      mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json --output study_results/schema_validation_report_v1.json
      mix orbital_dynamics.schema.lint --all --input-dir study_results
  """

  use Mix.Task

  alias OrbitalDynamics.Schema

  @shortdoc "Validates OrbitalDynamics JSON artifact contracts"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)

    if Keyword.get(opts, :all) do
      input_dir = Keyword.fetch!(opts, :input_dir)
      format = Keyword.fetch!(opts, :format)
      report = lint_directory_report(input_dir)

      maybe_write_report(report, Keyword.get(opts, :output))
      print_batch_report(report, format)

      if report["status"] == "fail" do
        Mix.raise("schema lint failed for #{input_dir}")
      end
    else
      input_path = Keyword.fetch!(opts, :input)
      format = Keyword.fetch!(opts, :format)
      report = Schema.lint_file_report(input_path, Keyword.take(opts, [:contract]))

      maybe_write_report(report, Keyword.get(opts, :output))
      print_report(input_path, report, format)

      if report["status"] == "fail" do
        Mix.raise("schema lint failed for #{input_path}")
      end
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          all: :boolean,
          input: :string,
          input_dir: :string,
          contract: :string,
          format: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid schema lint arguments: #{inspect(rest ++ invalid)}")
    end

    if Keyword.get(parsed, :all, false) and Keyword.has_key?(parsed, :input) do
      Mix.raise("--input cannot be used with --all")
    end

    if Keyword.get(parsed, :all, false) and Keyword.has_key?(parsed, :contract) do
      Mix.raise("--contract cannot be used with --all")
    end

    unless Keyword.get(parsed, :all, false) or Keyword.has_key?(parsed, :input) do
      Mix.raise("--input is required unless --all is used")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    parsed
    |> Keyword.put(:format, format)
    |> Keyword.put_new(:input_dir, "study_results")
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

  defp print_report(_path, report, "json") do
    report
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_report(path, report, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics schema lint")
    Mix.shell().info("artifact: #{path}")
    Mix.shell().info("contract: #{report["validated_contract"]}")
    Mix.shell().info("status: #{report["status"]}")
    Mix.shell().info("errors: #{report["error_count"]}")
    Mix.shell().info("warnings: #{report["warning_count"]}")

    Enum.each(report["errors"], fn error ->
      Mix.shell().info("error #{error["path"]}: #{error["message"]}")
    end)

    Enum.each(Map.get(report, "remediation", []), fn remediation ->
      Mix.shell().info("fix #{remediation["path"]}: #{remediation["action"]}")
    end)
  end

  defp lint_directory_report(input_dir) do
    lint_results =
      input_dir
      |> Path.join("*.json")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(fn path ->
        report = Schema.lint_file_report(path)

        case report["validated_contract"] do
          nil -> {:skipped, skipped_artifact(path, report)}
          _contract -> {:linted, %{"path" => path, "report" => report}}
        end
      end)

    reports =
      lint_results
      |> Enum.filter(&match?({:linted, _entry}, &1))
      |> Enum.map(fn {:linted, entry} -> entry end)

    skipped_artifacts =
      lint_results
      |> Enum.filter(&match?({:skipped, _entry}, &1))
      |> Enum.map(fn {:skipped, entry} -> entry end)

    error_count =
      reports
      |> Enum.map(&get_in(&1, ["report", "error_count"]))
      |> Enum.sum()

    warning_count =
      reports
      |> Enum.map(&get_in(&1, ["report", "warning_count"]))
      |> Enum.sum()

    remediation_count =
      reports
      |> Enum.map(&(get_in(&1, ["report", "remediation_count"]) || 0))
      |> Enum.sum()

    status_counts =
      reports
      |> Enum.map(&get_in(&1, ["report", "status"]))
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "model" => "executable_artifact_contract_batch_validation",
      "model_limits" => OrbitalDynamics.Schema.schema_validation_model_limits(),
      "validation_mode" => "artifact_directory",
      "input_dir" => input_dir,
      "file_count" => length(lint_results),
      "artifact_count" => length(reports),
      "skipped_count" => length(skipped_artifacts),
      "skipped_artifacts" => skipped_artifacts,
      "status" => if(error_count == 0, do: "pass", else: "fail"),
      "status_counts" => status_counts,
      "error_count" => error_count,
      "warning_count" => warning_count,
      "remediation_count" => remediation_count,
      "reports" => reports
    }
  end

  defp skipped_artifact(path, report) do
    reason =
      report
      |> Map.get("errors", [])
      |> List.first()
      |> case do
        %{"message" => message} -> message
        _error -> "not lintable by OrbitalDynamics.Schema"
      end

    %{
      "path" => path,
      "reason" => reason
    }
  end

  defp print_batch_report(report, "json") do
    report
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_batch_report(report, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics schema lint")
    Mix.shell().info("directory: #{report["input_dir"]}")
    Mix.shell().info("files: #{report["file_count"]}")
    Mix.shell().info("artifacts: #{report["artifact_count"]}")
    Mix.shell().info("skipped: #{report["skipped_count"]}")
    Mix.shell().info("status: #{report["status"]}")
    Mix.shell().info("errors: #{report["error_count"]}")
    Mix.shell().info("warnings: #{report["warning_count"]}")
    Mix.shell().info("remediation: #{report["remediation_count"]}")

    Enum.each(report["reports"], fn %{"path" => path, "report" => artifact_report} ->
      Mix.shell().info(
        "artifact #{path}: contract=#{artifact_report["validated_contract"]} status=#{artifact_report["status"]} errors=#{artifact_report["error_count"]} warnings=#{artifact_report["warning_count"]}"
      )
    end)

    Enum.each(report["skipped_artifacts"], fn %{"path" => path, "reason" => reason} ->
      Mix.shell().info("skipped #{path}: #{reason}")
    end)
  end
end
