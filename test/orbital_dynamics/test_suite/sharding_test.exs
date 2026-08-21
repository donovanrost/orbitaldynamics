defmodule OrbitalDynamics.TestSuite.ShardingTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.TestSuite.Sharding

  test "assigns every file exactly once with deterministic duration weighting" do
    files = [
      profile_file("test/a_test.exs", 8_000_000, 8),
      profile_file("test/b_test.exs", 7_000_000, 7),
      profile_file("test/c_test.exs", 6_000_000, 6),
      profile_file("test/d_test.exs", 5_000_000, 5),
      profile_file("test/e_test.exs", 4_000_000, 4)
    ]

    profile_path = write_profile!(files)
    on_exit(fn -> File.rm(profile_path) end)

    manifest = Sharding.build!([profile_path], 2, Enum.map(files, & &1.path))

    assert manifest.file_count == 5
    assert manifest.test_count == 30

    assert [
             %{index: 1, duration_us: 17_000_000, files: shard_one},
             %{index: 2, duration_us: 13_000_000, files: shard_two}
           ] = manifest.shards

    assert shard_one == ["test/a_test.exs", "test/d_test.exs", "test/e_test.exs"]
    assert shard_two == ["test/b_test.exs", "test/c_test.exs"]

    assert manifest ==
             Sharding.build!([profile_path], 2, Enum.reverse(Enum.map(files, & &1.path)))

    assert Enum.sort(shard_one ++ shard_two) == Enum.sort(Enum.map(files, & &1.path))
  end

  test "rejects duplicate profile ownership" do
    file = profile_file("test/a_test.exs", 1, 1)
    first_path = write_profile!([file])
    second_path = write_profile!([file])
    on_exit(fn -> Enum.each([first_path, second_path], &File.rm/1) end)

    assert_raise ArgumentError, ~r/test file more than once/, fn ->
      Sharding.build!([first_path, second_path], 2, [file.path])
    end
  end

  test "rejects missing or unexpected files" do
    profile_path = write_profile!([profile_file("test/a_test.exs", 1, 1)])
    on_exit(fn -> File.rm(profile_path) end)

    assert_raise ArgumentError, ~r/missing=.*b_test/, fn ->
      Sharding.build!([profile_path], 2, ["test/a_test.exs", "test/b_test.exs"])
    end

    assert_raise ArgumentError, ~r/unexpected=.*a_test/, fn ->
      Sharding.build!([profile_path], 2, ["test/b_test.exs"])
    end
  end

  test "distributes zero-duration files deterministically" do
    files =
      Enum.map(~w(a b c d), fn name ->
        profile_file("test/#{name}_test.exs", 0, 0)
      end)

    profile_path = write_profile!(files)
    on_exit(fn -> File.rm(profile_path) end)

    assert [
             %{files: ["test/a_test.exs", "test/c_test.exs"]},
             %{files: ["test/b_test.exs", "test/d_test.exs"]}
           ] = Sharding.build!([profile_path], 2, Enum.map(files, & &1.path)).shards

    assert_raise ArgumentError, ~r/shard count 5 exceeds profiled test-file count 4/, fn ->
      Sharding.build!([profile_path], 5, Enum.map(files, & &1.path))
    end
  end

  defp profile_file(path, duration_us, tests) do
    %{path: path, duration_us: duration_us, tests: tests}
  end

  defp write_profile!(files) do
    path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_sharding_profile_#{System.unique_integer([:positive])}.json"
      )

    artifact = %{
      schema_contract: "test_suite_profile.v1",
      schema_version: 1,
      files: files
    }

    File.write!(path, artifact |> :json.encode() |> IO.iodata_to_binary())
    path
  end
end
