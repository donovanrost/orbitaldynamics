defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportCliTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema

  test "exports a single contract schema" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_single_#{System.unique_integer([:positive])}"
      )

    output_path = Path.join([output_root, "nested", "campaign_plan.v1.schema.json"])

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--contract",
          "campaign_plan.v1",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics schema export"
    assert output =~ "wrote: #{output_path}"

    assert {:ok, expected_schema} = Schema.json_schema("campaign_plan.v1")
    assert File.read!(output_path) == json_bytes(expected_schema)
    assert_no_temp_residue!(Path.dirname(output_path))

    assert %{
             "$schema" => "https://json-schema.org/draft/2020-12/schema",
             "required" => required,
             "properties" => %{"schema_version" => %{"const" => 1}},
             "x-orbital-dynamics" => %{"schema_contract" => "campaign_plan.v1"}
           } = output_path |> File.read!() |> :json.decode()

    assert "plan_id" in required
  end

  test "replaces an existing single contract schema export" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_replace_#{System.unique_integer([:positive])}"
      )

    output_path = Path.join(output_root, "campaign_plan.v1.schema.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    File.mkdir_p!(output_root)
    File.write!(output_path, "stale schema\n")

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", [
        "--contract",
        "campaign_plan.v1",
        "--output",
        output_path
      ])
    end)

    assert {:ok, expected_schema} = Schema.json_schema("campaign_plan.v1")
    assert File.read!(output_path) == json_bytes(expected_schema)
    assert_no_temp_residue!(output_root)
  end

  test "rejects a single contract schema symlink output target" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_target_symlink_#{System.unique_integer([:positive])}"
      )

    real_path = Path.join(output_root, "real.json")
    symlink_path = Path.join(output_root, "linked.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    File.mkdir_p!(output_root)
    File.write!(real_path, "original\n")
    File.ln_s!(real_path, symlink_path)

    assert_raise ArgumentError, ~r/unsafe_symlink.*target/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--contract",
          "campaign_plan.v1",
          "--output",
          symlink_path
        ])
      end)
    end

    assert File.read!(real_path) == "original\n"
    assert_no_temp_residue!(output_root)
  end

  test "rejects a single contract schema symlink output ancestor" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_ancestor_symlink_#{System.unique_integer([:positive])}"
      )

    real_parent = Path.join(output_root, "real_parent")
    symlink_parent = Path.join(output_root, "linked_parent")
    output_path = Path.join(symlink_parent, "campaign_plan.v1.schema.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    File.mkdir_p!(real_parent)
    File.ln_s!(real_parent, symlink_parent)

    assert_raise ArgumentError, ~r/unsafe_symlink.*ancestor/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--contract",
          "campaign_plan.v1",
          "--output",
          output_path
        ])
      end)
    end

    refute File.exists?(Path.join(real_parent, "campaign_plan.v1.schema.json"))
    assert_no_temp_residue!(real_parent)
  end

  test "raises ArgumentError for an invalid single contract schema export destination" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.schema.export") end)

    invalid_output_path = "bad" <> <<0>> <> "path.json"

    assert_raise ArgumentError, ~r/invalid_path.*nul_byte/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--contract",
          "campaign_plan.v1",
          "--output",
          invalid_output_path
        ])
      end)
    end
  end

  test "requires either a contract or all flag" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.schema.export") end)

    assert_raise Mix.Error, ~r/--contract is required/, fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--output", "unused.json"])
    end
  end

  @tag timeout: 120_000
  test "exports all individual contract schemas to a directory" do
    output_dir =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_#{System.unique_integer([:positive])}"
      )

    bundle_path = Path.join(output_dir, "orbital_dynamics.schema_bundle.v1.json")

    on_exit(fn ->
      File.rm_rf(output_dir)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--all",
          "--directory",
          output_dir,
          "--output",
          bundle_path
        ])
      end)

    expected_contracts =
      Schema.contracts()
      |> Map.keys()
      |> Enum.sort()

    assert output =~ "OrbitalDynamics schema export"
    assert output =~ "wrote: #{bundle_path}"

    Enum.each(expected_contracts, fn contract ->
      schema_path = Path.join(output_dir, "#{contract}.schema.json")

      assert output =~ "wrote: #{schema_path}"
      assert File.exists?(schema_path)

      assert get_in(schema_path |> File.read!() |> :json.decode(), [
               "x-orbital-dynamics",
               "schema_contract"
             ]) == contract
    end)

    assert File.exists?(bundle_path)

    assert %{"schema_count" => count, "schemas" => schemas} =
             bundle_path |> File.read!() |> :json.decode()

    assert count == length(expected_contracts)
    assert schemas |> Map.keys() |> Enum.sort() == expected_contracts
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
