defmodule Mix.Tasks.OrbitalDynamics.Test.Shard do
  @moduledoc """
  Builds or runs deterministic duration-weighted test-file shards.

      mix orbital_dynamics.test.shard \
        --profile tmp/test-suite-profile/partition-1.json \
        --profile tmp/test-suite-profile/partition-2.json \
        --shards 4 \
        --manifest tmp/test-suite-profile/shards.json

      mix orbital_dynamics.test.shard \
        --profile tmp/test-suite-profile/partition-1.json \
        --profile tmp/test-suite-profile/partition-2.json \
        --shards 4 --shard 1 -- --seed 0 --timeout 120000

  Arguments after `--` are forwarded to `mix test` when `--shard` is present.
  """

  use Mix.Task

  alias OrbitalDynamics.TestSuite.Sharding

  @shortdoc "Builds or runs duration-weighted test-file shards"

  @switches [
    profile: :keep,
    shards: :integer,
    shard: :integer,
    manifest: :string,
    list: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {task_args, test_args} = split_test_args(args)
    {opts, rest, invalid} = OptionParser.parse(task_args, strict: @switches)

    unless rest == [] and invalid == [] do
      Mix.raise("invalid test shard arguments: #{inspect(rest ++ invalid)}")
    end

    profile_paths = Keyword.get_values(opts, :profile)
    shard_count = Keyword.get(opts, :shards, 4)
    manifest = Sharding.build!(profile_paths, shard_count)

    if manifest_path = opts[:manifest] do
      Sharding.write_manifest!(manifest_path, manifest)
    end

    print_summary(manifest)
    maybe_run_shard!(manifest, opts[:shard], opts[:list], test_args)
  rescue
    error in [ArgumentError, File.Error] -> Mix.raise(Exception.message(error))
  end

  defp split_test_args(args) do
    case Enum.split_while(args, &(&1 != "--")) do
      {task_args, []} -> {task_args, []}
      {task_args, ["--" | test_args]} -> {task_args, test_args}
    end
  end

  defp print_summary(manifest) do
    Mix.shell().info(
      "duration-weighted shards: #{manifest.file_count} files, " <>
        "#{manifest.test_count} tests, #{manifest.shard_count} shards"
    )

    Enum.each(manifest.shards, fn shard ->
      Mix.shell().info(
        "shard #{shard.index}: #{shard.file_count} files, #{shard.test_count} tests, " <>
          "profile weight #{format_seconds(shard.duration_us)}s"
      )
    end)
  end

  defp maybe_run_shard!(_manifest, nil, true, _test_args) do
    Mix.raise("--list requires --shard")
  end

  defp maybe_run_shard!(_manifest, nil, _list, test_args) when test_args != [] do
    Mix.raise("test arguments after -- require --shard")
  end

  defp maybe_run_shard!(_manifest, nil, _list, []), do: :ok

  defp maybe_run_shard!(manifest, shard_index, list?, test_args) do
    shard = Enum.find(manifest.shards, &(&1.index == shard_index))

    unless shard do
      Mix.raise("--shard must be between 1 and #{manifest.shard_count}")
    end

    if list? do
      Enum.each(shard.files, fn file -> Mix.shell().info(file) end)
    else
      Mix.Task.run("test", shard.files ++ test_args)
    end
  end

  defp format_seconds(duration_us) do
    duration_us
    |> Kernel./(1_000_000)
    |> Float.round(3)
  end
end
