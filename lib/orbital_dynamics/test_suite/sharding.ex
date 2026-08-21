defmodule OrbitalDynamics.TestSuite.Sharding do
  @moduledoc """
  Builds deterministic duration-weighted test-file shards from profile artifacts.

  Files are assigned longest-runtime first to the currently lightest shard. File
  paths break duration ties and shard indexes break load ties, so the same profile
  data always produces the same manifest.
  """

  @schema_contract "test_suite_profile.v1"

  @doc """
  Loads one or more disjoint profile artifacts and builds a shard manifest.

  The union of profiled paths must exactly match every current `*_test.exs` file.
  """
  def build!(profile_paths, shard_count, test_files \\ discover_test_files())

  def build!(profile_paths, shard_count, test_files)
      when is_list(profile_paths) and is_integer(shard_count) and shard_count > 0 do
    if profile_paths == [], do: raise(ArgumentError, "at least one profile path is required")

    profile_paths = Enum.sort(profile_paths)
    entries = load_entries!(profile_paths)
    expected_files = normalize_test_files!(test_files)
    validate_exact_coverage!(entries, expected_files)

    shards =
      entries
      |> Enum.sort_by(fn entry -> {-entry.duration_us, entry.path} end)
      |> Enum.reduce(empty_shards(shard_count), &assign_file/2)
      |> Enum.map(fn shard -> %{shard | files: Enum.sort(shard.files)} end)

    %{
      schema_contract: "test_suite_shards.v1",
      schema_version: 1,
      algorithm: "longest_processing_time_first",
      profile_basis: "sum_of_exunit_test_runtime_us_by_source_file",
      profile_paths: profile_paths,
      shard_count: shard_count,
      file_count: length(entries),
      test_count: Enum.sum(Enum.map(entries, & &1.tests)),
      duration_us: Enum.sum(Enum.map(entries, & &1.duration_us)),
      shards: shards
    }
  end

  def build!(_profile_paths, shard_count, _test_files) do
    raise ArgumentError, "shard count must be a positive integer, got: #{inspect(shard_count)}"
  end

  @doc "Returns the sorted test-file set owned by the default Mix test suite."
  def discover_test_files do
    "test/**/*_test.exs"
    |> Path.wildcard()
    |> Enum.sort()
  end

  @doc "Writes a shard manifest as JSON."
  def write_manifest!(path, manifest) do
    path = Path.expand(path)
    File.mkdir_p!(Path.dirname(path))
    json = manifest |> :json.encode() |> IO.iodata_to_binary()
    File.write!(path, json <> "\n")
  end

  defp load_entries!(profile_paths) do
    {entries, _seen} =
      Enum.reduce(profile_paths, {[], MapSet.new()}, fn profile_path, {entries, seen} ->
        artifact = profile_path |> File.read!() |> :json.decode()
        validate_profile!(artifact, profile_path)

        Enum.reduce(artifact["files"], {entries, seen}, fn file, {entries, seen} ->
          entry = profile_entry!(file, profile_path)

          if MapSet.member?(seen, entry.path) do
            raise ArgumentError,
                  "profile inputs contain test file more than once: #{entry.path}"
          end

          {[entry | entries], MapSet.put(seen, entry.path)}
        end)
      end)

    entries
  end

  defp validate_profile!(artifact, profile_path) do
    unless is_map(artifact) and artifact["schema_contract"] == @schema_contract and
             artifact["schema_version"] == 1 and is_list(artifact["files"]) do
      raise ArgumentError, "invalid test suite profile: #{profile_path}"
    end
  end

  defp profile_entry!(file, profile_path) do
    path = file["path"]
    duration_us = file["duration_us"]
    tests = file["tests"]

    unless is_binary(path) and is_integer(duration_us) and duration_us >= 0 and
             is_integer(tests) and tests >= 0 do
      raise ArgumentError, "invalid file entry in test suite profile: #{profile_path}"
    end

    %{path: normalize_test_file!(path), duration_us: duration_us, tests: tests}
  end

  defp normalize_test_files!(test_files) do
    normalized = Enum.map(test_files, &normalize_test_file!/1)

    if length(normalized) != MapSet.size(MapSet.new(normalized)) do
      raise ArgumentError, "expected test-file list contains duplicates"
    end

    Enum.sort(normalized)
  end

  defp normalize_test_file!(path) when is_binary(path) do
    normalized = path |> Path.expand() |> Path.relative_to_cwd()

    if Path.type(path) == :absolute or normalized == ".." or
         String.starts_with?(normalized, "../") do
      raise ArgumentError, "test file must be relative to the project: #{inspect(path)}"
    end

    normalized
  end

  defp validate_exact_coverage!(entries, expected_files) do
    profiled_files = entries |> Enum.map(& &1.path) |> Enum.sort()
    missing = expected_files -- profiled_files
    unexpected = profiled_files -- expected_files

    if missing != [] or unexpected != [] do
      raise ArgumentError,
            "profile coverage does not match the current suite; " <>
              "missing=#{inspect(missing)}, unexpected=#{inspect(unexpected)}"
    end
  end

  defp empty_shards(shard_count) do
    Enum.map(1..shard_count, fn index ->
      %{
        index: index,
        assignment_weight_us: 0,
        duration_us: 0,
        test_count: 0,
        file_count: 0,
        files: []
      }
    end)
  end

  defp assign_file(entry, shards) do
    lightest = Enum.min_by(shards, &{&1.assignment_weight_us, &1.index})

    updated = %{
      lightest
      | assignment_weight_us: lightest.assignment_weight_us + max(entry.duration_us, 1),
        duration_us: lightest.duration_us + entry.duration_us,
        test_count: lightest.test_count + entry.tests,
        file_count: lightest.file_count + 1,
        files: [entry.path | lightest.files]
    }

    List.replace_at(shards, lightest.index - 1, updated)
  end
end
