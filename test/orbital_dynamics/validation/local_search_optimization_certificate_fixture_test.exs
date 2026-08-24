defmodule OrbitalDynamics.Validation.LocalSearchOptimizationCertificateFixtureTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.Level5ContractFixtures,
    only: [
      local_search_optimization_certificate_fixture: 0,
      local_search_optimization_certificate_fixture_observations: 0
    ]

  @fixture_id "fixture.artifact.local_search_optimization_certificate.v1"
  @contract "local_search_optimization_certificate.v1"

  test "canonical bounded certificate fixture is stable, unique, and executable" do
    assert {:ok, fixture} = Validation.reference_fixture(@fixture_id)
    assert fixture["id"] == @fixture_id
    assert fixture["model_id"] == "artifact.#{@contract}"

    assert [@fixture_id] ==
             Validation.reference_fixtures()
             |> Map.keys()
             |> Enum.filter(&(&1 == @fixture_id))

    certificate = local_search_optimization_certificate_fixture()
    replayed_certificate = local_search_optimization_certificate_fixture()

    assert certificate == replayed_certificate
    assert certificate["id"] =~ ~r/\Alocal_search_optimization_certificate:[0-9a-f]{64}\z/

    assert certificate["id"] ==
             certificate
             |> Map.delete("id")
             |> LocalSearchCertificate.certificate_id()

    assert certificate["global_optimality_claimed"] === false
    assert certificate["search_space_exhausted"] === true
    assert certificate["budget_limited"] === false
    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(certificate)
    assert {:ok, schema} = Schema.json_schema(@contract)
    assert schema["additionalProperties"] === false

    observations = local_search_optimization_certificate_fixture_observations()

    assert {:ok, %{"status" => "pass", "fixture_id" => @fixture_id}} =
             Validation.verify_reference_fixture(@fixture_id, observations)

    assert {:ok, %{"status" => "fail"}} =
             Validation.verify_reference_fixture(
               @fixture_id,
               Map.put(observations, "id", "local_search_optimization_certificate:stale")
             )

    assert certificate |> :json.encode() |> IO.iodata_to_binary() ==
             replayed_certificate |> :json.encode() |> IO.iodata_to_binary()
  end
end
