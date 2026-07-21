defmodule OrbitalDynamics.Validation.ArtifactFixtureCoverageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  @artifact_model_prefix "artifact."
  @bootstrap_contracts ~w(validation_reference_fixture_report.v1)

  test "every non-bootstrap artifact contract has a curated reference fixture" do
    registered_contracts = registered_contracts()
    fixture_contracts = fixture_contracts()

    required_contracts = MapSet.difference(registered_contracts, MapSet.new(@bootstrap_contracts))

    missing_contracts =
      required_contracts
      |> MapSet.difference(fixture_contracts)
      |> MapSet.to_list()
      |> Enum.sort()

    assert missing_contracts == [],
           "registered artifact contracts missing curated fixtures: #{inspect(missing_contracts)}"
  end

  test "every curated artifact fixture model names a registered contract" do
    stale_fixture_contracts =
      fixture_contracts()
      |> MapSet.difference(registered_contracts())
      |> MapSet.to_list()
      |> Enum.sort()

    assert stale_fixture_contracts == [],
           "curated artifact fixture models without registered contracts: #{inspect(stale_fixture_contracts)}"
  end

  test "the self-describing fixture report remains the sole bootstrap exclusion" do
    assert @bootstrap_contracts == ["validation_reference_fixture_report.v1"]
    assert MapSet.subset?(MapSet.new(@bootstrap_contracts), registered_contracts())
    refute MapSet.member?(fixture_contracts(), "validation_reference_fixture_report.v1")
  end

  defp registered_contracts do
    Schema.contracts()
    |> Map.keys()
    |> MapSet.new()
  end

  defp fixture_contracts do
    Validation.reference_fixtures()
    |> Map.values()
    |> Enum.map(&Map.fetch!(&1, "model_id"))
    |> Enum.filter(&String.starts_with?(&1, @artifact_model_prefix))
    |> Enum.map(&String.replace_prefix(&1, @artifact_model_prefix, ""))
    |> MapSet.new()
  end
end
