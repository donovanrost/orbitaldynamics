defmodule Mix.Tasks.OrbitalDynamics.Policy.Export do
  @moduledoc """
  Exports built-in OrbitalDynamics policy bundles as lintable JSON artifacts.

  Usage:

      mix orbital_dynamics.policy.export --bundle operator_review_queue_authority_v1 --output study_results/policy_bundle_operator_review_queue_authority_v1.json
      mix orbital_dynamics.policy.export --all --directory study_results
  """

  use Mix.Task

  alias OrbitalDynamics.Policy

  @shortdoc "Exports OrbitalDynamics built-in policy bundles"

  @legacy_fixture_names %{
    "mission_ops_escalation_v1" => "policy_bundle_v1.json"
  }

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    written_paths = export!(opts)

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics policy bundle export")

    Enum.each(written_paths, fn written_path ->
      Mix.shell().info("wrote: #{written_path}")
    end)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          all: :boolean,
          bundle: :string,
          directory: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid policy export arguments: #{inspect(rest ++ invalid)}")
    end

    if Keyword.get(parsed, :all, false) do
      if Keyword.has_key?(parsed, :bundle) or Keyword.has_key?(parsed, :output) do
        Mix.raise("--bundle and --output are only supported when --all is not set")
      end

      unless Keyword.has_key?(parsed, :directory) do
        Mix.raise("--directory is required when --all is set")
      end

      parsed
    else
      if Keyword.has_key?(parsed, :directory) do
        Mix.raise("--directory is only supported with --all")
      end

      unless Keyword.has_key?(parsed, :bundle) do
        Mix.raise("--bundle is required unless --all is set")
      end

      unless Keyword.has_key?(parsed, :output) do
        Mix.raise("--output is required")
      end

      parsed
    end
  end

  defp export!(opts) do
    if Keyword.get(opts, :all, false) do
      directory = Keyword.fetch!(opts, :directory)

      Policy.bundle_artifacts()
      |> Enum.map(fn bundle ->
        write_bundle!(bundle, Path.join(directory, fixture_name(bundle["id"])))
      end)
    else
      bundle =
        opts
        |> Keyword.fetch!(:bundle)
        |> Policy.bundle_artifact!()

      [write_bundle!(bundle, Keyword.fetch!(opts, :output))]
    end
  end

  defp fixture_name(bundle_id) do
    Map.get(@legacy_fixture_names, bundle_id, "policy_bundle_#{bundle_id}.json")
  end

  defp write_bundle!(bundle, path) do
    json =
      bundle
      |> :json.encode()
      |> IO.iodata_to_binary()

    OrbitalDynamics.Release.SafeOutput.write!(path, json <> "\n")
  end
end
