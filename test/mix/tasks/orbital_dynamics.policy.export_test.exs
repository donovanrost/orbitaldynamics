defmodule Mix.Tasks.OrbitalDynamics.Policy.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.{Policy, Schema}

  test "exports a single built-in policy bundle artifact" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_policy_export_single_#{System.unique_integer([:positive])}"
      )

    output_path =
      Path.join([output_root, "nested", "policy_bundle_operator_review_queue_authority_v1.json"])

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.policy.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.policy.export", [
          "--bundle",
          "operator_review_queue_authority_v1",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics policy bundle export"
    assert output =~ "wrote: #{output_path}"

    expected_bundle = Policy.bundle_artifact!("operator_review_queue_authority_v1")
    assert File.read!(output_path) == json_bytes(expected_bundle)
    assert_no_temp_residue!(Path.dirname(output_path))

    assert Policy.bundle_artifact!("operator_review_queue_authority_v1") ==
             output_path |> File.read!() |> :json.decode()

    assert {:ok, %{"schema_contract" => "policy_bundle.v1"}} =
             Schema.lint_file(output_path, schema_contract: "policy_bundle.v1")
  end

  test "replaces an existing single policy bundle artifact" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_policy_export_replace_#{System.unique_integer([:positive])}"
      )

    output_path = Path.join(output_root, "policy_bundle_operator_review_queue_authority_v1.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.policy.export")
    end)

    File.mkdir_p!(output_root)
    File.write!(output_path, "stale policy\n")

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.policy.export", [
        "--bundle",
        "operator_review_queue_authority_v1",
        "--output",
        output_path
      ])
    end)

    assert File.read!(output_path) ==
             json_bytes(Policy.bundle_artifact!("operator_review_queue_authority_v1"))

    assert_no_temp_residue!(output_root)
  end

  test "rejects policy output below a regular file parent" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_policy_export_missing_parent_#{System.unique_integer([:positive])}"
      )

    file_parent = Path.join(output_root, "not_a_directory")
    output_path = Path.join(file_parent, "policy_bundle_operator_review_queue_authority_v1.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.policy.export")
    end)

    File.mkdir_p!(output_root)
    File.write!(file_parent, "not a directory\n")

    assert_raise ArgumentError, ~r/unsupported_ancestor.*regular/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.policy.export", [
          "--bundle",
          "operator_review_queue_authority_v1",
          "--output",
          output_path
        ])
      end)
    end

    assert File.read!(file_parent) == "not a directory\n"
    assert_no_temp_residue!(output_root)
  end

  test "exports all built-in policy bundle artifacts to a directory" do
    output_dir =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_policy_export_#{System.unique_integer([:positive])}"
      )

    on_exit(fn ->
      File.rm_rf(output_dir)
      Mix.Task.reenable("orbital_dynamics.policy.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.policy.export", ["--all", "--directory", output_dir])
    end)

    assert File.exists?(Path.join(output_dir, "policy_bundle_v1.json"))

    assert File.exists?(
             Path.join(output_dir, "policy_bundle_operator_review_queue_authority_v1.json")
           )

    exported_ids =
      output_dir
      |> Path.join("policy_bundle_*.json")
      |> Path.wildcard()
      |> Enum.map(fn path ->
        path |> File.read!() |> :json.decode() |> Map.fetch!("id")
      end)
      |> Enum.sort()

    assert exported_ids == Policy.bundles() |> Enum.map(& &1["id"]) |> Enum.sort()

    exported_bytes_by_id =
      output_dir
      |> Path.join("policy_bundle_*.json")
      |> Path.wildcard()
      |> Map.new(fn path ->
        artifact = path |> File.read!() |> :json.decode()
        {Map.fetch!(artifact, "id"), File.read!(path)}
      end)

    Enum.each(Policy.bundle_artifacts(), fn bundle ->
      assert Map.fetch!(exported_bytes_by_id, bundle["id"]) == json_bytes(bundle)
    end)

    assert_no_temp_residue!(output_dir)
  end

  test "rejects incomplete policy export arguments" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.policy.export") end)

    assert_raise Mix.Error, ~r/--output is required/, fn ->
      Mix.Task.run("orbital_dynamics.policy.export", [
        "--bundle",
        "operator_review_queue_authority_v1"
      ])
    end
  end

  defp json_bytes(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  defp assert_no_temp_residue!(directory) do
    assert Path.wildcard(Path.join(directory, ".orbital_dynamics-safe-output-*.tmp")) == []
  end
end
