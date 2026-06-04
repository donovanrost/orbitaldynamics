defmodule Mix.Tasks.OrbitalDynamics.Manifest.Schema.Export do
  @moduledoc """
  Exports the OrbitalDynamics study manifest shape as JSON Schema.

  Usage:

      mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json
  """

  use Mix.Task

  alias OrbitalDynamics.Study.Manifest

  @shortdoc "Exports the study manifest JSON Schema"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    output_path = Keyword.fetch!(opts, :output)

    written_path = Manifest.write_json_schema!(output_path)

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics manifest schema export")
    Mix.shell().info("wrote: #{written_path}")
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} = OptionParser.parse(args, strict: [output: :string])

    unless rest == [] and invalid == [] do
      Mix.raise("invalid manifest schema export arguments: #{inspect(rest ++ invalid)}")
    end

    unless Keyword.has_key?(parsed, :output) do
      Mix.raise("--output is required")
    end

    parsed
  end
end
