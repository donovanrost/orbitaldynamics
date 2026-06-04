defmodule Mix.Tasks.OrbitalDynamics.Schema.Export do
  @moduledoc """
  Exports OrbitalDynamics executable contracts as machine-readable JSON Schema.

  Usage:

      mix orbital_dynamics.schema.export --contract campaign_plan.v1 --output schemas/campaign_plan.v1.schema.json
      mix orbital_dynamics.schema.export --all --output schemas/orbital_dynamics.schema_bundle.v1.json
      mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json
  """

  use Mix.Task

  alias OrbitalDynamics.Schema

  @shortdoc "Exports OrbitalDynamics artifact schemas"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)

    written_paths =
      if Keyword.get(opts, :all, false) do
        export_all!(opts)
      else
        [
          Schema.write_json_schema!(
            Keyword.fetch!(opts, :contract),
            Keyword.fetch!(opts, :output)
          )
        ]
      end

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics schema export")

    Enum.each(written_paths, fn written_path ->
      Mix.shell().info("wrote: #{written_path}")
    end)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          all: :boolean,
          contract: :string,
          directory: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid schema export arguments: #{inspect(rest ++ invalid)}")
    end

    if Keyword.get(parsed, :all, false) do
      unless Keyword.has_key?(parsed, :output) or Keyword.has_key?(parsed, :directory) do
        Mix.raise("--output or --directory is required when --all is set")
      end

      parsed
    else
      if Keyword.has_key?(parsed, :directory) do
        Mix.raise("--directory is only supported with --all")
      end

      unless Keyword.has_key?(parsed, :output) do
        Mix.raise("--output is required")
      end

      unless Keyword.has_key?(parsed, :contract) do
        Mix.raise("--contract is required unless --all is set")
      end

      parsed
    end
  end

  defp export_all!(opts) do
    individual_paths =
      case Keyword.get(opts, :directory) do
        nil -> []
        directory -> Schema.write_json_schema_files!(directory)
      end

    bundle_paths =
      case Keyword.get(opts, :output) do
        nil -> []
        output_path -> [Schema.write_json_schema_bundle!(output_path)]
      end

    individual_paths ++ bundle_paths
  end
end
