defmodule OrbitalDynamics.Validation.ReadinessQualityFixtureCoverageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  @artifact_model_prefix "artifact."
  @family_contract_prefixes ~w(
    model_acceptance_
    operational_execution_boundary_
    operational_import_eligibility_
    operational_quality_gate_
    operational_readiness_
    quality_gate_
    schema_validation_
    validation_safety_case_
  )
  @import_readiness_suffix "_import_readiness_summary.v1"

  test "every registered readiness/quality artifact contract has a curated reference fixture" do
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
           "registered readiness/quality contracts missing curated artifact fixtures: #{inspect(missing_contracts)}"
  end

  test "family scope includes specialized import readiness without absorbing adjacent contracts" do
    assert family_contract?("provider_counteroffer_import_readiness_summary.v1")
    assert family_contract?("station_reservation_hold_import_readiness_summary.v1")
    refute family_contract?("backend_acceptance_policy.v1")
    refute family_contract?("resource_projection_report.v1")
  end

  defp family_contract?(contract) do
    String.ends_with?(contract, @import_readiness_suffix) or
      Enum.any?(@family_contract_prefixes, &String.starts_with?(contract, &1))
  end
end
