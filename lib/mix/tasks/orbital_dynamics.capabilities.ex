defmodule Mix.Tasks.OrbitalDynamics.Capabilities do
  @moduledoc """
  Prints the public OrbitalDynamics capability catalog.

  Usage:

      mix orbital_dynamics.capabilities
      mix orbital_dynamics.capabilities --format json
      mix orbital_dynamics.capabilities --output study_results/capability_catalog.json
  """

  use Mix.Task

  @shortdoc "Prints the OrbitalDynamics capability catalog"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    format = Keyword.fetch!(opts, :format)
    catalog = OrbitalDynamics.capability_catalog()
    json_catalog = OrbitalDynamics.capability_catalog_artifact()

    maybe_write_catalog(json_catalog, Keyword.get(opts, :output))
    print_catalog(catalog, json_catalog, format)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args, strict: [format: :string, output: :string])

    unless rest == [] and invalid == [] do
      Mix.raise("invalid capabilities arguments: #{inspect(rest ++ invalid)}")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    Keyword.put(parsed, :format, format)
  end

  defp maybe_write_catalog(_catalog, nil), do: :ok

  defp maybe_write_catalog(catalog, output_path) when is_binary(output_path) do
    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      catalog
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(output_path, json <> "\n")
  end

  defp print_catalog(_catalog, json_catalog, "json") do
    json_catalog
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_catalog(catalog, _json_catalog, "text") do
    schema = catalog.validation.schema
    cadence_import = catalog.operations.cadence_import
    operator_review = catalog.operations.operator_review

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics capability catalog")
    Mix.shell().info("artifact contracts: #{schema.artifact_contract_count}")
    Mix.shell().info("schema compatibility policy: #{schema.compatibility_policy_version}")
    Mix.shell().info("schema identity policy: #{schema.identity_policy_version}")
    Mix.shell().info("cadence import sources: #{length(cadence_import.supported_sources)}")
    Mix.shell().info("cadence import actions: #{length(cadence_import.import_actions)}")
    Mix.shell().info("operator review sources: #{length(operator_review.source_artifact_types)}")
    Mix.shell().info("operator review types: #{length(operator_review.review_types)}")

    Mix.shell().info(
      "propagators: #{catalog.analysis.propagators |> Map.keys() |> Enum.sort() |> Enum.join(",")}"
    )
  end
end
