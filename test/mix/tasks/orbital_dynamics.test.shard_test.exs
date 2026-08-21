defmodule Mix.Tasks.OrbitalDynamics.Test.ShardTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "writes a machine-readable manifest for an exactly covered suite" do
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
  end
end
