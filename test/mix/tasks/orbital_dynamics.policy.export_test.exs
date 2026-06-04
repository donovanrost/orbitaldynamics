defmodule Mix.Tasks.OrbitalDynamics.Policy.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.{Policy, Schema}

  test "exports a single built-in policy bundle artifact" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "policy_bundle_operator_review_queue_authority_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
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

    assert Policy.bundle_artifact!("operator_review_queue_authority_v1") ==
             output_path |> File.read!() |> :json.decode()

    assert {:ok, %{"schema_contract" => "policy_bundle.v1"}} =
             Schema.lint_file(output_path, schema_contract: "policy_bundle.v1")
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
end
