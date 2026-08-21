defmodule Mix.Tasks.OrbitalDynamics.Test.ShardTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "writes a machine-readable manifest for an exactly covered suite" do
    assert OrbitalDynamics.MixProject.cli()[:preferred_envs][
             :"orbital_dynamics.test.shard"
           ] == :test

    root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_test_shard_task_#{System.unique_integer([:positive])}"
      )

    profile_path = Path.join(root, "profile.json")
    manifest_path = Path.join(root, "manifest.json")
    File.mkdir_p!(Path.join(root, "test"))
    File.write!(Path.join(root, "test/a_test.exs"), "")
    File.write!(Path.join(root, "test/b_test.exs"), "")

    profile = %{
      schema_contract: "test_suite_profile.v1",
      schema_version: 1,
      files: [
        %{path: "test/a_test.exs", duration_us: 3_000_000, tests: 3},
        %{path: "test/b_test.exs", duration_us: 2_000_000, tests: 2}
      ]
    }

    File.write!(profile_path, profile |> :json.encode() |> IO.iodata_to_binary())

    on_exit(fn ->
      Mix.Task.reenable("orbital_dynamics.test.shard")
      File.rm_rf(root)
    end)

    output =
      File.cd!(root, fn ->
        capture_io(fn ->
          Mix.Task.reenable("orbital_dynamics.test.shard")

          Mix.Task.run("orbital_dynamics.test.shard", [
            "--profile",
            profile_path,
            "--shards",
            "2",
            "--manifest",
            manifest_path
          ])
        end)
      end)

    assert output =~ "duration-weighted shards: 2 files, 5 tests, 2 shards"

    assert %{
             "schema_contract" => "test_suite_shards.v1",
             "file_count" => 2,
             "test_count" => 5,
             "shards" => [
               %{"index" => 1, "files" => ["test/a_test.exs"]},
               %{"index" => 2, "files" => ["test/b_test.exs"]}
             ]
           } = manifest_path |> File.read!() |> :json.decode()

    assert Path.wildcard(manifest_path <> ".tmp.*") == []

    output =
      File.cd!(root, fn ->
        capture_io(fn ->
          Mix.Task.reenable("orbital_dynamics.test.shard")

          Mix.Task.run("orbital_dynamics.test.shard", [
            "--profile",
            profile_path,
            "--shards",
            "2",
            "--shard",
            "1",
            "--list",
            "--",
            "--seed",
            "0",
            "--timeout",
            "120000"
          ])
        end)
      end)

    assert output =~ "test/a_test.exs"

    rejected_test_args = [
      ["test/a_test.exs"],
      ["--partitions", "2"],
      ["--failed"],
      ["--stale"],
      ["--repeat-until-failure", "2"],
      ["--exclude", "slow"],
      ["--max-failures", "1"],
      ["--formatter", "ExUnit.CLIFormatter"]
    ]

    Enum.each(rejected_test_args, fn rejected_args ->
      Mix.Task.reenable("orbital_dynamics.test.shard")

      assert_raise Mix.Error, ~r/only --seed and --timeout may follow --/, fn ->
        File.cd!(root, fn ->
          Mix.Task.run(
            "orbital_dynamics.test.shard",
            ["--profile", profile_path, "--shards", "2", "--shard", "1", "--"] ++
              rejected_args
          )
        end)
      end
    end)

    Mix.Task.reenable("orbital_dynamics.test.shard")

    assert_raise Mix.Error, ~r/test options may be given only once/, fn ->
      File.cd!(root, fn ->
        Mix.Task.run("orbital_dynamics.test.shard", [
          "--profile",
          profile_path,
          "--shards",
          "2",
          "--shard",
          "1",
          "--",
          "--seed",
          "0",
          "--seed",
          "1"
        ])
      end)
    end
  end
end
