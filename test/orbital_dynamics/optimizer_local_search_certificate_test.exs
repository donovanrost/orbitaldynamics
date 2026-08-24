defmodule OrbitalDynamics.OptimizerLocalSearchCertificateTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.{Optimizer, Schema}
  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.Schema.JsonSafety

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
  @max_float 1.7976931348623157e308

  test "capability artifact advertises the bounded certificate without stringifying booleans" do
    artifact = OrbitalDynamics.capability_catalog_artifact()
    optimizer = get_in(artifact, ["planning", "optimizer"])
    certificate_capability = optimizer["local_search_optimization_certificate"]

    assert optimizer["public_facades"] == [
             "explainable_local_search",
             "certified_local_search",
             "verify_local_search_certificate"
           ]

    assert certificate_capability["artifact_contract"] ==
             "local_search_optimization_certificate.v1"

    assert certificate_capability["global_optimality_claimed"] === false
    assert certificate_capability["mode"] == "opt_in_exact_finite_neighborhood_enumeration"
    assert get_in(artifact, ["validation", "schema", "artifact_contract_count"]) == 128

    assert "local_search_optimization_certificate.v1" in get_in(artifact, [
             "validation",
             "schema",
             "artifact_contracts"
           ])

    assert_json_total(artifact)
  end

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
    assert schema["additionalProperties"] == false
    assert get_in(schema, ["properties", "claim", "additionalProperties"]) == false
    assert get_in(schema, ["properties", "global_optimality_claimed", "const"]) == false

    assert get_in(schema, [
             "properties",
             "evaluator_execution_policy",
             "additionalProperties"
           ]) == false

    assert_typed_schema_error(Map.put(build_certificate(), "unexpected", true), "$")

    assert {:ok, legacy_schema} = Schema.json_schema("optimizer_contract.v1")
    assert legacy_schema["additionalProperties"] == true

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

  test "public schema rejects every reproduced malformed nested certificate mutation" do
    certificate = build_certificate()

    mutations = [
      {"$.evaluations[0].eligible",
       &put_in(&1, ["evaluations", Access.at(0), "eligible"], "true")},
      {"$.evaluations[0].alternative_id",
       &put_in(&1, ["evaluations", Access.at(0), "alternative_id"], 7)},
      {"$.evaluations[0].score", &put_in(&1, ["evaluations", Access.at(0), "score"], "1")},
      {"$.evaluations[0].source_evidence_identity",
       &put_in(&1, ["evaluations", Access.at(0), "source_evidence_identity"], "sha256")},
      {"$.evaluations[0]", &put_in(&1, ["evaluations", Access.at(0)], true)},
      {"$.search_space.candidates[0]",
       &put_in(&1, ["search_space", "candidates", Access.at(0)], true)},
      {"$.search_space.step_parameters", &put_in(&1, ["search_space", "step_parameters"], "x")},
      {"$.source_evidence_registry.entries[0]",
       &put_in(&1, ["source_evidence_registry", "entries", Access.at(0)], true)},
      {"$.source_evidence_registry.entries",
       &put_in(&1, ["source_evidence_registry", "entries"], "entries")}
    ]

    Enum.each(mutations, fn {path, mutate} ->
      mutated = mutate.(certificate)
      assert_public_boundary_schema_errors(mutated, [path, "$.id"])

      reidentified =
        Map.put(
          mutated,
          "id",
          LocalSearchCertificate.certificate_id(Map.delete(mutated, "id"))
        )

      report = assert_public_boundary_schema_errors(reidentified, [path])
      refute Enum.any?(report["errors"], &(&1["path"] == "$.id"))
    end)
  end

  test "public schema rejects improper mixed-key and non-JSON nested certificate terms" do
    certificate = build_certificate()
    first_evaluation = hd(certificate["evaluations"])

    mutations = [
      {"$.evaluations", &Map.put(&1, "evaluations", [first_evaluation | :improper])},
      {"$.evaluations[0].rejection_reasons",
       &put_in(
         &1,
         ["evaluations", Access.at(0), "rejection_reasons"],
         ["reason" | :improper]
       )},
      {"$.evaluations[0]",
       &put_in(
         &1,
         ["evaluations", Access.at(0)],
         Map.put(first_evaluation, :eligible, true)
       )},
      {"$.evaluations[0].score_terms",
       &put_in(
         &1,
         ["evaluations", Access.at(0), "score_terms"],
         %{"value" => 1, value: 1}
       )},
      {"$.evaluations[0].score_terms",
       &put_in(&1, ["evaluations", Access.at(0), "score_terms"], %{1 => 1})},
      {"$.search_space.seed_parameters",
       &put_in(&1, ["search_space", "seed_parameters"], %{"x\n" => 1})},
      {"$.search_space.seed_parameters.<invalid_utf8_key>",
       &put_in(&1, ["search_space", "seed_parameters"], %{<<255>> => 1})},
      {"$.evaluations[0].score",
       &put_in(&1, ["evaluations", Access.at(0), "score"], {:not, "json"})},
      {"$.evaluations[0].score", &put_in(&1, ["evaluations", Access.at(0), "score"], self())},
      {"$.evaluations[0].score", &put_in(&1, ["evaluations", Access.at(0), "score"], make_ref())},
      {"$.evaluations[0].score",
       &put_in(&1, ["evaluations", Access.at(0), "score"], fn -> :not_json end)},
      {"$.evaluations[0].score",
       &put_in(&1, ["evaluations", Access.at(0), "score"], %URI{host: "example.test"})},
      {"$.evaluations[0].score", &put_in(&1, ["evaluations", Access.at(0), "score"], :not_json)},
      {"$.evaluations[0].alternative_id",
       &put_in(&1, ["evaluations", Access.at(0), "alternative_id"], <<255>>)}
    ]

    Enum.each(mutations, fn {path, mutate} ->
      assert_public_boundary_schema_errors(mutate.(certificate), [path])
    end)
  end

  test "eligible_ids_by_rank improper lists return a typed JSON-total schema failure" do
    certificate =
      Map.put(build_certificate(), "eligible_ids_by_rank", ["certificate:seed" | :bad])

    assert_typed_schema_error(certificate, "$.eligible_ids_by_rank")
  end

  test "deterministic_ordering improper lists return a typed JSON-total schema failure" do
    certificate =
      Map.put(build_certificate(), "deterministic_ordering", ["evaluation order" | :bad])

    assert_typed_schema_error(certificate, "$.deterministic_ordering")
  end

  test "model_limits improper lists return a typed JSON-total schema failure" do
    certificate = Map.put(build_certificate(), "model_limits", ["bounded" | :bad])

    assert_typed_schema_error(certificate, "$.model_limits")
  end

  test "every other list-bearing certificate location rejects improper lists before semantics" do
    certificate = build_certificate()

    mutations = [
      {"$.evaluations", &Map.put(&1, "evaluations", [hd(&1["evaluations"]) | :bad])},
      {"$.search_space.step_parameters",
       &put_in(&1, ["search_space", "step_parameters"], ["x" | :bad])},
      {"$.search_space.candidates",
       &put_in(
         &1,
         ["search_space", "candidates"],
         [hd(&1["search_space"]["candidates"]) | :bad]
       )},
      {"$.search_space.generation_rejected_moves",
       &put_in(
         &1,
         ["search_space", "generation_rejected_moves"],
         [hd(&1["search_space"]["generation_rejected_moves"]) | :bad]
       )},
      {"$.source_evidence_registry.entries",
       &put_in(
         &1,
         ["source_evidence_registry", "entries"],
         [hd(&1["source_evidence_registry"]["entries"]) | :bad]
       )},
      {"$.evaluations[0].rejection_reasons",
       &put_in(&1, ["evaluations", Access.at(0), "rejection_reasons"], ["bad" | :bad])}
    ]

    Enum.each(mutations, fn {path, mutate} ->
      assert_typed_schema_error(mutate.(certificate), path)
    end)
  end

  test "finite score terms whose sum overflows return a typed schema failure" do
    certificate =
      build_certificate()
      |> put_in(
        ["evaluations", Access.at(0), "score_terms"],
        %{"large_a" => @max_float, "large_b" => @max_float}
      )
      |> put_in(["evaluations", Access.at(0), "score"], @max_float)

    assert_typed_schema_error(certificate, "$.evaluations[0].score")
  end

  test "finite local-neighborhood operands whose addition or subtraction overflows fail typed" do
    Enum.each([@max_float, -@max_float], fn seed_value ->
      certificate =
        build_certificate()
        |> put_in(["search_space", "seed_parameters", "x"], seed_value)
        |> put_in(["search_space", "steps", "x"], @max_float)

      assert_typed_schema_error(certificate, "$.search_space")
    end)
  end

  test "verifier contains evaluator errors in a typed JSON-total failure" do
    evaluator = fn _parameters, _evidence -> raise "evaluator error" end

    assert_replay_failure(evaluator, "error", "evaluator error")
  end

  test "verifier contains evaluator exits in a typed JSON-total failure" do
    evaluator = fn _parameters, _evidence -> exit(:evaluator_exit) end

    assert_replay_failure(evaluator, "exit", ":evaluator_exit")
  end

  test "verifier contains evaluator throws in a typed JSON-total failure" do
    evaluator = fn _parameters, _evidence -> throw({:evaluator_throw, self()}) end

    assert_replay_failure(evaluator, "throw", ":evaluator_throw")
  end

  test "untrusted non-JSON certificate IDs never enter verification failure reports" do
    certificate = build_certificate()

    Enum.each([fn -> :id end, self(), make_ref(), :certificate_id, <<255>>], fn unsafe_id ->
      assert {:error, report} =
               Optimizer.verify_local_search_certificate(
                 Map.put(certificate, "id", unsafe_id),
                 @seed,
                 source_evidence(@candidate_ids),
                 &evaluator/2,
                 @opts
               )

      assert report["reason"] == "certificate_schema_invalid"
      assert report["certificate_id"] == :null
      assert_json_total(report)
    end)
  end

  test "newline-terminated source IDs are rejected by producer and executable schema" do
    evidence =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "id"], "source:certificate:seed\n")

    assert_raise ArgumentError, ~r/must be a stable identity/, fn ->
      Optimizer.certified_local_search(@seed, evidence, &evaluator/2, @opts)
    end

    certificate =
      build_certificate()
      |> put_in(
        ["source_evidence_registry", "entries", Access.at(0), "source_id"],
        "source:certificate:seed\n"
      )

    assert_typed_schema_error(
      certificate,
      "$.source_evidence_registry.entries[0].source_id"
    )
  end

  test "newline-terminated source revisions are rejected by producer and executable schema" do
    evidence =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "revision"], "revision:1\n")

    assert_raise ArgumentError, ~r/must be a stable identity/, fn ->
      Optimizer.certified_local_search(@seed, evidence, &evaluator/2, @opts)
    end

    certificate =
      build_certificate()
      |> put_in(
        ["source_evidence_registry", "entries", Access.at(0), "source_revision"],
        "revision:1\n"
      )

    assert_typed_schema_error(
      certificate,
      "$.source_evidence_registry.entries[0].source_revision"
    )
  end

  test "newline-terminated stable IDs and local parameter names are rejected" do
    assert_raise ArgumentError, "id_prefix must be a stable identity", fn ->
      Optimizer.certified_local_search(
        @seed,
        source_evidence(@candidate_ids),
        &evaluator/2,
        Keyword.put(@opts, :id_prefix, "certificate\n")
      )
    end

    assert_raise ArgumentError, ~r/parameter and score-term names/, fn ->
      Optimizer.certified_local_search(
        @seed,
        source_evidence(@candidate_ids),
        &evaluator/2,
        Keyword.put(@opts, :steps, %{"x\n" => 1})
      )
    end
  end

  test "newline-terminated score-term names are rejected by producer and executable schema" do
    bad_evaluator = fn _parameters, _evidence ->
      %{"score_terms" => %{"value\n" => 1}, "eligible" => true, "rejection_reasons" => []}
    end

    assert {:error, failure} =
             Optimizer.certified_local_search(
               @seed,
               source_evidence(@candidate_ids),
               bad_evaluator,
               @opts
             )

    assert failure["reason"] == "evaluator_execution_failed"
    assert failure["details"]["failure_kind"] == "invalid_result"
    assert failure["details"]["detail"] =~ "supported names"
    assert_json_total(failure)

    certificate =
      build_certificate()
      |> put_in(
        ["evaluations", Access.at(0), "score_terms"],
        %{"value\n" => 1}
      )
      |> put_in(["evaluations", Access.at(0), "score"], 1)

    assert_typed_schema_error(certificate, "$.evaluations[0].score_terms")
  end

  test "exported certificate patterns require absolute string termination" do
    assert {:ok, schema} = Schema.json_schema("local_search_optimization_certificate.v1")

    certificate_id_pattern = get_in(schema, ["properties", "id", "pattern"])
    refute String.contains?(certificate_id_pattern, "$")

    assert_pattern_accepts_only_complete_string(
      certificate_id_pattern,
      "local_search_optimization_certificate:" <> String.duplicate("a", 64)
    )

    source_revision_pattern =
      get_in(schema, [
        "properties",
        "source_evidence_registry",
        "properties",
        "entries",
        "items",
        "properties",
        "source_revision",
        "pattern"
      ])

    refute String.contains?(source_revision_pattern, "$")
    assert_pattern_accepts_only_complete_string(source_revision_pattern, "stable:id")

    score_term_pattern =
      get_in(schema, [
        "properties",
        "evaluations",
        "items",
        "properties",
        "score_terms",
        "propertyNames",
        "pattern"
      ])

    refute String.contains?(score_term_pattern, "$")
    assert_pattern_accepts_only_complete_string(score_term_pattern, "score.term")

    sha256_pattern =
      get_in(schema, [
        "properties",
        "search_space",
        "properties",
        "identity",
        "properties",
        "sha256",
        "pattern"
      ])

    refute String.contains?(sha256_pattern, "$")
    assert_pattern_accepts_only_complete_string(sha256_pattern, String.duplicate("a", 64))
  end

  test "root global optimality is executable const false and certificate IDs are exact digests" do
    certificate = build_certificate()

    assert certificate["id"] ==
             LocalSearchCertificate.certificate_id(Map.delete(certificate, "id"))

    assert_typed_schema_error(
      Map.put(certificate, "global_optimality_claimed", true),
      "$.global_optimality_claimed"
    )

    Enum.each(
      [
        "local_search_optimization_certificate:" <> String.duplicate("a", 63),
        "local_search_optimization_certificate:" <> String.duplicate("A", 64),
        "wrong_prefix:" <> String.duplicate("a", 64),
        certificate["id"] <> "\n"
      ],
      fn invalid_id ->
        assert_typed_schema_error(Map.put(certificate, "id", invalid_id), "$.id")
      end
    )
  end

  test "timeout policy is versioned and bound into build and replay identity" do
    opts = Keyword.put(@opts, :evaluator_timeout_ms, 25)
    certificate = build_certificate(opts)
    default_certificate = build_certificate()

    assert certificate["evaluator_execution_policy"] ==
             LocalSearchCertificate.evaluator_execution_policy(25)

    refute certificate["id"] == default_certificate["id"]
    assert {:ok, %{"status" => "verified"}} = verify(certificate, &evaluator/2, opts)

    assert {:error, replay_report} =
             verify(certificate, &evaluator/2, Keyword.put(opts, :evaluator_timeout_ms, 26))

    assert replay_report["reason"] ==
             "certificate_does_not_match_replayed_source_evidence_and_evaluation"

    stale_identity =
      put_in(certificate, ["evaluator_execution_policy", "timeout_ms"], 26)

    assert_typed_schema_error(stale_identity, "$.id")

    independently_reidentified =
      Map.put(
        stale_identity,
        "id",
        LocalSearchCertificate.certificate_id(Map.delete(stale_identity, "id"))
      )

    assert {:ok, _report} = Schema.validate_artifact(independently_reidentified)
    assert {:error, mismatch_report} = verify(independently_reidentified, &evaluator/2, opts)

    assert mismatch_report["reason"] ==
             "certificate_does_not_match_replayed_source_evidence_and_evaluation"
  end

  test "build isolates sleeping and infinite evaluators and removes timed out workers" do
    Enum.each([:sleeping, :infinite], fn mode ->
      parent = self()
      tag = make_ref()

      evaluator = fn _parameters, _evidence ->
        send(parent, {tag, self()})

        case mode do
          :sleeping -> Process.sleep(250)
          :infinite -> wait_forever()
        end

        %{"score_terms" => %{"value" => 1}, "eligible" => true, "rejection_reasons" => []}
      end

      assert {:error, failure} =
               Optimizer.certified_local_search(
                 @seed,
                 source_evidence(@candidate_ids),
                 evaluator,
                 Keyword.put(@opts, :evaluator_timeout_ms, 25)
               )

      assert failure["reason"] == "evaluator_execution_failed"
      assert failure["details"]["failure_kind"] == "timeout"
      assert failure["details"]["timeout_ms"] == 25
      assert_receive {^tag, worker}
      assert Process.alive?(self())
      assert_process_terminated(worker)
      assert_json_total(failure)
    end)
  end

  test "build isolates raise exit throw and self-kill without emitting a certificate" do
    parent = self()
    self_kill_tag = make_ref()

    evaluators = [
      {fn _parameters, _evidence -> raise "build evaluator error" end, "error"},
      {fn _parameters, _evidence -> exit(:build_evaluator_exit) end, "exit"},
      {fn _parameters, _evidence -> throw(:build_evaluator_throw) end, "throw"},
      {fn _parameters, _evidence ->
         send(parent, {self_kill_tag, self()})
         Process.exit(self(), :kill)
       end, "worker_exit"}
    ]

    Enum.each(evaluators, fn {evaluator, expected_kind} ->
      assert {:error, failure} =
               Optimizer.certified_local_search(
                 @seed,
                 source_evidence(@candidate_ids),
                 evaluator,
                 Keyword.put(@opts, :evaluator_timeout_ms, 50)
               )

      assert failure["reason"] == "evaluator_execution_failed"
      assert failure["details"]["failure_kind"] == expected_kind
      assert Process.alive?(self())
      assert_json_total(failure)
    end)

    assert_receive {^self_kill_tag, killed_worker}
    assert_process_terminated(killed_worker)
  end

  test "verifier isolates timeout and self-kill evaluators and preserves its caller" do
    certificate = build_certificate()
    parent = self()

    Enum.each([:infinite, :self_kill], fn mode ->
      tag = make_ref()

      evaluator = fn _parameters, _evidence ->
        send(parent, {tag, self()})

        case mode do
          :infinite -> wait_forever()
          :self_kill -> Process.exit(self(), :kill)
        end
      end

      assert {:error, report} =
               verify(
                 certificate,
                 evaluator,
                 Keyword.put(@opts, :evaluator_timeout_ms, 25)
               )

      assert report["reason"] == "replay_evaluator_execution_failed"
      assert_receive {^tag, worker}
      assert Process.alive?(self())
      assert_process_terminated(worker)
      assert_json_total(report)
    end)
  end

  test "caller cancellation kills the unlinked evaluator worker" do
    parent = self()
    tag = make_ref()

    caller =
      spawn(fn ->
        evaluator = fn _parameters, _evidence ->
          send(parent, {tag, self()})
          wait_forever()
        end

        Optimizer.certified_local_search(
          @seed,
          source_evidence(@candidate_ids),
          evaluator,
          Keyword.put(@opts, :evaluator_timeout_ms, 5_000)
        )
      end)

    caller_ref = Process.monitor(caller)
    assert_receive {^tag, worker}, 1_000
    Process.exit(caller, :kill)
    assert_receive {:DOWN, ^caller_ref, :process, ^caller, :killed}, 1_000
    assert_process_terminated(worker)
    assert Process.alive?(self())
  end

  test "source capture accepts only strict JSON inputs and rejects BEAM aliases" do
    nil_evidence =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "payload", "nullable"], nil)

    assert %{} =
             Optimizer.certified_local_search(@seed, nil_evidence, &evaluator/2, @opts)

    unsafe_values = [
      :atom_value,
      :null,
      {:tuple, "value"},
      self(),
      make_ref(),
      fn -> :value end,
      ["proper_head" | :improper_tail],
      %URI{scheme: "https", host: "example.test"},
      <<255>>
    ]

    Enum.each(unsafe_values, fn unsafe_value ->
      evidence =
        @candidate_ids
        |> source_evidence()
        |> put_in(["certificate:seed", "payload", "unsafe"], unsafe_value)

      assert_raise ArgumentError, fn ->
        Optimizer.certified_local_search(@seed, evidence, &evaluator/2, @opts)
      end
    end)

    unsafe_maps = [
      %{atom_key: "value"},
      %{"alias" => "string", alias: "atom"},
      %{1 => "non-string"},
      %{<<255>> => "invalid-key"}
    ]

    Enum.each(unsafe_maps, fn unsafe_map ->
      evidence =
        @candidate_ids
        |> source_evidence()
        |> put_in(["certificate:seed", "payload", "unsafe_map"], unsafe_map)

      assert_raise ArgumentError, fn ->
        Optimizer.certified_local_search(@seed, evidence, &evaluator/2, @opts)
      end
    end)
  end

  test "canonical JSON source identity is invariant to object insertion order" do
    ascending_payload = Map.new(1..40, &{"field_#{&1}", &1})
    descending_payload = Map.new(40..1//-1, &{"field_#{&1}", &1})

    ascending =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "payload", "ordered"], ascending_payload)

    descending =
      @candidate_ids
      |> source_evidence()
      |> put_in(["certificate:seed", "payload", "ordered"], descending_payload)

    assert build_with_evidence(ascending) == build_with_evidence(descending)
  end

  test "finite evaluator operands whose score sum overflows fail typed" do
    evaluator = fn _parameters, _evidence ->
      %{
        "score_terms" => %{"large_a" => @max_float, "large_b" => @max_float},
        "eligible" => true,
        "rejection_reasons" => []
      }
    end

    assert {:error, failure} =
             Optimizer.certified_local_search(
               @seed,
               source_evidence(@candidate_ids),
               evaluator,
               @opts
             )

    assert failure["reason"] == "evaluator_execution_failed"
    assert failure["details"]["failure_kind"] == "invalid_result"
    assert failure["details"]["detail"] =~ "finite score"
    assert_json_total(failure)
  end

  defp build_certificate(opts \\ @opts) do
    Optimizer.certified_local_search(
      @seed,
      source_evidence(@candidate_ids),
      &evaluator/2,
      opts
    )
  end

  defp build_with_evidence(evidence) do
    Optimizer.certified_local_search(@seed, evidence, &evaluator/2, @opts)
  end

  defp verify(certificate, evaluator_fun, opts) do
    Optimizer.verify_local_search_certificate(
      certificate,
      @seed,
      source_evidence(@candidate_ids),
      evaluator_fun,
      opts
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

  defp assert_typed_schema_error(certificate, expected_path) do
    assert {:error, report} = Schema.validate_artifact(certificate)
    assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    assert_json_total(report)
  end

  defp assert_public_boundary_schema_errors(certificate, expected_paths) do
    assert {:error, report} =
             Schema.validate_artifact(certificate,
               schema_contract: "local_search_optimization_certificate.v1"
             )

    Enum.each(expected_paths, fn expected_path ->
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path)),
             "expected a typed schema error at #{expected_path}, got: #{inspect(report["errors"])}"
    end)

    assert_json_total(report)
    report
  end

  defp assert_replay_failure(evaluator_fun, expected_kind, expected_detail) do
    certificate = build_certificate()

    assert {:error, report} =
             Optimizer.verify_local_search_certificate(
               certificate,
               @seed,
               source_evidence(@candidate_ids),
               evaluator_fun,
               @opts
             )

    assert report["reason"] == "replay_evaluator_execution_failed"
    assert report["certificate_id"] == certificate["id"]

    evaluator_failure = report["details"]["evaluator_failure"]
    assert evaluator_failure["reason"] == "evaluator_execution_failed"
    assert evaluator_failure["details"]["failure_kind"] == expected_kind
    assert evaluator_failure["details"]["detail"] =~ expected_detail
    assert_json_total(report)
  end

  defp assert_json_total(value) do
    assert JsonSafety.errors(value) == []
    encoded = value |> :json.encode() |> IO.iodata_to_binary()
    assert :json.decode(encoded) == value
  end

  defp assert_process_terminated(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 1_000
  end

  defp wait_forever do
    receive do
    after
      :infinity -> :unreachable
    end
  end

  defp assert_pattern_accepts_only_complete_string(pattern, accepted) do
    assert {:ok, regex} = Regex.compile(pattern)
    assert Regex.match?(regex, accepted)
    refute Regex.match?(regex, accepted <> "\n")
  end
end
