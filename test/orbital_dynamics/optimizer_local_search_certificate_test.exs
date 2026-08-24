defmodule OrbitalDynamics.OptimizerLocalSearchCertificateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Optimizer, Schema}
  alias OrbitalDynamics.Optimizer.LocalSearchCertificate

  @seed %{"x" => 1, "y" => 0}
  @opts [
    steps: %{"y" => 1, "x" => 1},
    bounds: %{"y" => {0, 2}, "x" => {0, 2}},
    id_prefix: "certificate"
  ]
  @candidate_ids [
    "certificate:seed",
    "certificate:x:decrease",
    "certificate:x:increase",
    "certificate:y:increase"
  ]

  test "certifies the best eligible alternative only after exact finite-space exhaustion" do
    certificate = build_certificate()

    assert certificate["schema_contract"] == "local_search_optimization_certificate.v1"
    assert certificate["model"] == LocalSearchCertificate.model()
    assert certificate["search_space"]["candidate_count"] == 4
    assert certificate["search_space"]["generation_attempt_count"] == 4
    assert certificate["search_space"]["generation_rejected_count"] == 1

    assert [
             %{
               "id" => "certificate:y:decrease",
               "generation_index" => 3,
               "reason" => "below_minimum_bound"
             }
           ] = certificate["search_space"]["generation_rejected_moves"]

    assert certificate["evaluated_count"] == 4
    assert certificate["eligible_count"] == 3
    assert certificate["rejected_count"] == 1
    assert certificate["unevaluated_count"] == 0
    assert certificate["search_space_exhausted"]
    refute certificate["budget_limited"]
    assert certificate["termination_reason"] == "search_space_exhausted"

    assert certificate["selected_alternative_id"] == "certificate:x:increase"
    assert certificate["selected_score"] == 2

    assert certificate["eligible_ids_by_rank"] == [
             "certificate:x:increase",
             "certificate:y:increase",
             "certificate:seed"
           ]

    assert certificate["claim"] == %{
             "status" => "supported",
             "type" => "best_eligible_alternative_in_enumerated_finite_neighborhood",
             "scope" => "enumerated_search_space_only",
             "selected_alternative_id" => "certificate:x:increase",
             "reason" => "search_space_exhausted_and_incumbent_ordering_applied",
             "global_optimality_claimed" => false
           }

    refute certificate["global_optimality_claimed"]
    assert {:ok, _report} = Schema.validate_artifact(certificate)

    round_tripped =
      certificate
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> :json.decode()

    assert round_tripped == certificate
    assert {:ok, _report} = Schema.validate_artifact(round_tripped)

    assert {:ok, verification} =
             Optimizer.verify_local_search_certificate(
               round_tripped,
               @seed,
               source_evidence(@candidate_ids),
               &evaluator/2,
               @opts
             )

    assert verification["status"] == "verified"
    assert verification["certificate_id"] == certificate["id"]
    assert verification["claim"] == certificate["claim"]
  end

  test "uses generation index and alternative identity as deterministic score tie breaks" do
    certificate = build_certificate()

    x_increase = evaluation(certificate, "certificate:x:increase")
    y_increase = evaluation(certificate, "certificate:y:increase")

    assert x_increase["score"] == y_increase["score"]
    assert x_increase["generation_index"] < y_increase["generation_index"]
    assert x_increase["rank"] == 1
    assert y_increase["rank"] == 2

    assert Enum.map(certificate["evaluations"], & &1["incumbent_after_evaluation_id"]) == [
             "certificate:seed",
             "certificate:seed",
             "certificate:x:increase",
             "certificate:x:increase"
           ]

    reversed_input_order =
      @candidate_ids
      |> Enum.reverse()
      |> source_evidence()

    assert Optimizer.certified_local_search(@seed, reversed_input_order, &evaluator/2, @opts) ==
             certificate
  end

  test "budget termination preserves the observed incumbent but makes no optimality claim" do
    opts = Keyword.put(@opts, :evaluation_budget, 2)

    certificate =
      Optimizer.certified_local_search(
        @seed,
        source_evidence(@candidate_ids),
        &evaluator/2,
        opts
      )

    assert certificate["evaluated_count"] == 2
    assert certificate["eligible_count"] == 1
    assert certificate["rejected_count"] == 1
    assert certificate["unevaluated_count"] == 2
    assert certificate["budget_used"] == 2
    assert certificate["budget_remaining"] == 0
    assert certificate["budget_limited"]
    refute certificate["search_space_exhausted"]
    assert certificate["termination_reason"] == "evaluation_budget_exhausted"
    assert certificate["selected_alternative_id"] == "certificate:seed"

    assert certificate["claim"] == %{
             "status" => "not_supported",
             "type" => "no_optimality_claim",
             "scope" => "enumerated_search_space_only",
             "selected_alternative_id" => :null,
             "reason" => "evaluation_budget_exhausted_before_search_space",
             "global_optimality_claimed" => false
           }

    assert {:ok, _report} = Schema.validate_artifact(certificate)

    assert {:ok, %{"status" => "verified"}} =
             Optimizer.verify_local_search_certificate(
               certificate,
               @seed,
               source_evidence(@candidate_ids),
               &evaluator/2,
               opts
             )
  end

  test "exhaustion can certify that the finite neighborhood has no eligible candidate" do
    reject_all = fn parameters, evidence ->
      %{
        "score_terms" => %{"value" => parameters["x"] + parameters["y"]},
        "eligible" => false,
        "rejection_reasons" => ["source_revision_not_eligible:#{evidence["revision"]}"]
      }
    end

    certificate =
      Optimizer.certified_local_search(
        @seed,
        source_evidence(@candidate_ids),
        reject_all,
        @opts
      )

    assert certificate["evaluated_count"] == 4
    assert certificate["eligible_count"] == 0
    assert certificate["rejected_count"] == 4
    assert certificate["selected_alternative_id"] == :null
    assert certificate["selected_score"] == :null
    assert certificate["eligible_ids_by_rank"] == []
    assert Enum.all?(certificate["evaluations"], &(&1["rank"] == :null))
    assert Enum.all?(certificate["evaluations"], &(&1["incumbent_after_evaluation_id"] == :null))

    assert certificate["claim"]["type"] ==
             "no_eligible_alternative_in_enumerated_finite_neighborhood"

    assert certificate["claim"]["status"] == "supported"
    assert {:ok, _report} = Schema.validate_artifact(certificate)
  end

  test "verification fails closed for certificate and trusted-source tampering" do
    certificate = build_certificate()
    tampered_certificate = put_in(certificate, ["evaluations", Access.at(0), "score"], 999)

    assert {:error, certificate_failure} =
             Optimizer.verify_local_search_certificate(
               tampered_certificate,
               @seed,
               source_evidence(@candidate_ids),
               &evaluator/2,
               @opts
             )

    assert certificate_failure["reason"] == "certificate_schema_invalid"

    malformed_certificate = Map.put(certificate, "evaluations", %{"not" => "a list"})

    assert {:error, malformed_report} = Schema.validate_artifact(malformed_certificate)
    assert malformed_report["status"] == "fail"

    tampered_evidence =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "payload", "quality"], "tampered")

    assert {:error, source_failure} =
             Optimizer.verify_local_search_certificate(
               certificate,
               @seed,
               tampered_evidence,
               &evaluator/2,
               @opts
             )

    assert source_failure["reason"] ==
             "certificate_does_not_match_replayed_source_evidence_and_evaluation"

    raising_evaluator = fn _parameters, _evidence -> raise "evaluator unavailable" end

    assert {:error, evaluator_failure} =
             Optimizer.verify_local_search_certificate(
               certificate,
               @seed,
               source_evidence(@candidate_ids),
               raising_evaluator,
               @opts
             )

    assert evaluator_failure["reason"] == "replay_input_or_source_evidence_invalid"
  end

  test "empty or incomplete finite-space evidence is rejected before evaluation" do
    assert_raise ArgumentError, "steps must be a non-empty map", fn ->
      Optimizer.certified_local_search(
        @seed,
        %{},
        &evaluator/2,
        Keyword.put(@opts, :steps, %{})
      )
    end

    assert_raise ArgumentError,
                 "source_evidence keys must exactly match every in-bounds search-space alternative ID",
                 fn ->
                   Optimizer.certified_local_search(@seed, %{}, &evaluator/2, @opts)
                 end
  end

  test "exports the executable certificate schema and preserves the default heuristic" do
    assert {:ok, schema} = Schema.json_schema("local_search_optimization_certificate.v1")
    assert schema["additionalProperties"] == true
    assert get_in(schema, ["properties", "claim", "additionalProperties"]) == false

    assert get_in(schema, ["properties", "model", "const"]) ==
             LocalSearchCertificate.model()

    assert get_in(schema, ["properties", "evaluation_budget"]) == %{
             "type" => "integer",
             "minimum" => 1,
             "maximum" => 65
           }

    assert get_in(schema, ["properties", "evaluations", "items", "required"]) ==
             ~w(
               alternative_id generation_index source_evidence_identity score_terms score eligible
               rejection_reasons incumbent_after_evaluation_id rank
             )

    heuristic =
      Optimizer.explainable_local_search(
        %{"x" => 1},
        fn parameters ->
          %{"value" => parameters["x"]}
        end,
        steps: %{"x" => 1}
      )

    assert heuristic["model"] == "deterministic_bounded_axis_step_local_search"
    refute Map.has_key?(heuristic, "schema_contract")
    refute Map.has_key?(heuristic, "claim")

    capabilities = Optimizer.capabilities()
    assert capabilities.local_search_models == ["deterministic_bounded_axis_step_local_search"]

    assert capabilities.local_search_optimization_certificate.artifact_contract ==
             "local_search_optimization_certificate.v1"
  end

  defp build_certificate do
    Optimizer.certified_local_search(
      @seed,
      source_evidence(@candidate_ids),
      &evaluator/2,
      @opts
    )
  end

  defp source_evidence(ids) do
    Map.new(ids, fn id ->
      {id,
       %{
         "id" => "source:#{id}",
         "revision" => "revision:1",
         "payload" => %{"quality" => "accepted", "candidate_id" => id}
       }}
    end)
  end

  defp evaluator(parameters, evidence) do
    eligible = parameters["x"] > 0

    %{
      "score_terms" => %{
        "parameter_value" => parameters["x"] + parameters["y"],
        "source_quality" => if(evidence["payload"]["quality"] == "accepted", do: 0, else: -100)
      },
      "eligible" => eligible,
      "rejection_reasons" => if(eligible, do: [], else: ["x_must_be_positive"])
    }
  end

  defp evaluation(certificate, id),
    do: Enum.find(certificate["evaluations"], &(&1["alternative_id"] == id))
end
