defmodule OrbitalDynamics.Validation.ResourceContactFixtureCoverageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  @artifact_model_prefix "artifact."
  @family_contract_prefixes ~w(
    contact_
    resource_
    station_
    link_capacity_
    relay_data_path_
    provider_counteroffer_
  )
  @explicit_family_contracts ~w(
    proposed_contact.v1
    operational_quality_gate_unavailable_resource_summary.v1
  )

  test "every registered resource/contact artifact contract has a curated reference fixture" do
    family_contracts =
      Schema.contracts()
      |> Map.keys()
      |> Enum.filter(&family_contract?/1)
      |> Enum.sort()

    fixture_contracts =
      Validation.reference_fixtures()
      |> Map.values()
      |> Enum.map(&Map.fetch!(&1, "model_id"))
      |> Enum.filter(&String.starts_with?(&1, @artifact_model_prefix))
      |> Enum.map(&String.replace_prefix(&1, @artifact_model_prefix, ""))
      |> MapSet.new()

    missing_contracts =
      Enum.reject(family_contracts, &MapSet.member?(fixture_contracts, &1))

    assert family_contracts != []

    assert missing_contracts == [],
           "registered resource/contact contracts missing curated artifact fixtures: #{inspect(missing_contracts)}"
  end

  defp family_contract?(contract) do
    contract in @explicit_family_contracts or
      Enum.any?(@family_contract_prefixes, &String.starts_with?(contract, &1))
  end
end
