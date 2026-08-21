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

  Only one `--seed` and one `--timeout` may follow `--`. Test selectors,
  partitions, formatters, repetition, early-stop options, and positional paths
  are rejected so the manifest remains the sole owner of test-file selection.
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

  @test_switches [seed: :integer, timeout: :integer]

  @impl Mix.Task
  def run(args) do
    ensure_test_env!()
    {task_args, test_args} = split_test_args(args)
    {opts, rest, invalid} = OptionParser.parse(task_args, strict: @switches)

    unless rest == [] and invalid == [] do
      Mix.raise("invalid test shard arguments: #{inspect(rest ++ invalid)}")
    end

    test_args = parse_test_args!(test_args)
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

  defp parse_test_args!(args) do
    duplicate_options =
      [{"--seed", :seed}, {"--timeout", :timeout}]
      |> Enum.filter(fn {name, _key} ->
        Enum.count(args, &(&1 == name or String.starts_with?(&1, name <> "="))) > 1
      end)
      |> Enum.map(&elem(&1, 1))

    if duplicate_options != [] do
      Mix.raise("test options may be given only once: #{inspect(duplicate_options)}")
    end

    {opts, rest, invalid} = OptionParser.parse(args, strict: @test_switches)

    unless rest == [] and invalid == [] do
      Mix.raise("only --seed and --timeout may follow --; rejected: #{inspect(rest ++ invalid)}")
    end

    seed = Keyword.get(opts, :seed)
    timeout = Keyword.get(opts, :timeout)

    if seed != nil and seed < 0, do: Mix.raise("--seed must be non-negative")
    if timeout != nil and timeout <= 0, do: Mix.raise("--timeout must be positive")

    []
    |> maybe_put_test_option("--seed", seed)
    |> maybe_put_test_option("--timeout", timeout)
  end

  defp maybe_put_test_option(args, _name, nil), do: args
  defp maybe_put_test_option(args, name, value), do: args ++ [name, Integer.to_string(value)]

  defp ensure_test_env! do
    unless Mix.env() == :test do
      Mix.raise("orbital_dynamics.test.shard must run in MIX_ENV=test")
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

    if shard.files == [] do
      Mix.raise("refusing to run empty shard #{shard.index}")
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
