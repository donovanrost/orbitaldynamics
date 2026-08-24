defmodule OrbitalDynamics.Validation.LocalSearchOptimizationCertificateFixtureTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.Schema.JsonSafety
  alias OrbitalDynamics.{Schema, Validation}

  alias OrbitalDynamics.Validation.ArtifactObservations.LocalSearchOptimizationCertificate,
    as: CertificateObservations

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

    assert_hostile_observation_failures(certificate)
    assert_multi_corruption_observation_failure(certificate)
  end

  defp assert_hostile_observation_failures(certificate) do
    parent = self()
    hostile = fn -> send(parent, :hostile_observation_term_executed) end

    deep =
      Enum.reduce(1..70, :null, fn index, nested -> %{Integer.to_string(index) => nested} end)

    cases = [
      {"non-map root", hostile, "$"},
      {"improper root", ["root" | :tail], "$"},
      {"PID root", self(), "$"},
      {"nested improper model limits", Map.put(certificate, "model_limits", ["limit" | :tail]),
       "$.model_limits"},
      {"invalid UTF-8 value", Map.put(certificate, "objective", <<255>>), "$.objective"},
      {"unsafe numeric atom", Map.put(certificate, "selected_score", :nan), "$.selected_score"},
      {"struct carrier", Map.put(certificate, "claim", %URI{scheme: "https"}), "$.claim"},
      {"atom/string alias collision", Map.put(certificate, :objective, "alias"), "$"},
      {"deep carrier", Map.put(certificate, "deep", deep), "$.deep"},
      {"oversized carrier", Map.put(certificate, "oversized", List.duplicate(0, 2_049)),
       "$.oversized"}
    ]

    Enum.each(cases, fn {label, artifact, expected_path_prefix} ->
      direct = CertificateObservations.build(artifact)
      validation_facade = Validation.artifact_observations(@contract, artifact)
      public_facade = OrbitalDynamics.validation_artifact_observations(@contract, artifact)

      assert direct == validation_facade, label
      assert validation_facade == public_facade, label
      assert direct["status"] == "error", label
      assert direct["reason"] == "artifact_observation_input_invalid", label
      assert direct["contract"] == @contract, label
      assert length(direct["errors"]) <= JsonSafety.limits()["max_issues"], label

      assert Enum.any?(
               direct["errors"],
               &String.starts_with?(&1["path"], expected_path_prefix)
             ),
             label

      assert JsonSafety.errors(direct) == [], label
      assert is_binary(direct |> :json.encode() |> IO.iodata_to_binary()), label
      assert direct == CertificateObservations.build(artifact), label
    end)

    refute_received :hostile_observation_term_executed
  end

  defp assert_multi_corruption_observation_failure(certificate) do
    corrupted =
      certificate
      |> Map.put("objective", <<255>>)
      |> Map.put("model_limits", ["limit" | :tail])
      |> Map.put("selected_score", :infinity)
      |> Map.put("claim", %URI{scheme: "https"})

    first = Validation.artifact_observations(@contract, corrupted)
    second = Validation.artifact_observations(@contract, corrupted)

    assert first == second
    assert first["status"] == "error"
    assert JsonSafety.errors(first) == []

    assert first["errors"] ==
             Enum.sort_by(first["errors"], &{&1["path"], &1["message"], &1["severity"]})

    Enum.each(["$.claim", "$.id", "$.model_limits", "$.objective", "$.selected_score"], fn path ->
      assert Enum.any?(first["errors"], &(&1["path"] == path)),
             "expected a typed observation error at #{path}: #{inspect(first)}"
    end)
  end
end
