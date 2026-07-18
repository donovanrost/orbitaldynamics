defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportCliTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema

  test "exports a single contract schema" do
    output_path = Path.join(System.tmp_dir!(), "campaign_plan.v1.schema.json")

    on_exit(fn ->
      File.rm(output_path)
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

    assert %{
             "$schema" => "https://json-schema.org/draft/2020-12/schema",
             "required" => required,
             "properties" => %{"schema_version" => %{"const" => 1}},
             "x-orbital-dynamics" => %{"schema_contract" => "campaign_plan.v1"}
           } = output_path |> File.read!() |> :json.decode()

    assert "plan_id" in required
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
end
