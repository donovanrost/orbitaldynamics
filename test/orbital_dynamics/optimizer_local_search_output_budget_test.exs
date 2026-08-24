defmodule OrbitalDynamics.OptimizerLocalSearchOutputBudgetTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.{Optimizer, Schema}
  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.Optimizer.LocalSearchCertificate.JsonSafetyLimitClassifier

  alias OrbitalDynamics.Schema.{
    ArtifactValidationRouter,
    JsonSafety,
    LocalSearchOptimizationCertificateContracts
  }

  alias OrbitalDynamics.Search.Local

  @contract "local_search_optimization_certificate.v1"
  @seed %{"x" => 1, "y" => 0}
  @steps %{"x" => 1, "y" => 1}
  @opts [
    steps: @steps,
    bounds: %{"x" => {0, 2}, "y" => {0, 2}},
    id_prefix: "certificate"
  ]
  @candidate_ids [
    "certificate:seed",
    "certificate:x:decrease",
    "certificate:x:increase",
    "certificate:y:increase"
  ]

  @facades [
    {"direct builder", LocalSearchCertificate, :build},
    {"optimizer router", Optimizer, :certified_local_search},
    {"public facade", OrbitalDynamics, :certified_local_search}
  ]

  test "JSON safety limit classifier exact-matches all published resource messages" do
    limits = JsonSafety.limits()

    cases = [
      {"exceeds maximum JSON nesting depth of #{limits["max_depth"]}",
       {"max_depth", limits["max_depth"]}},
      {"exceeds maximum JSON node budget of #{limits["max_nodes"]}",
       {"max_nodes", limits["max_nodes"]}},
      {"exceeds maximum JSON collection size of #{limits["max_collection_items"]}",
       {"max_collection_items", limits["max_collection_items"]}},
      {"exceeds maximum aggregate JSON string byte budget of #{limits["max_aggregate_bytes"]}",
       {"max_aggregate_bytes", limits["max_aggregate_bytes"]}}
    ]

    Enum.each(cases, fn {message, expected} ->
      issue = %{"severity" => "error", "path" => "$.projection", "message" => message}
      assert JsonSafetyLimitClassifier.classify(issue) == expected

      {kind, limit} = expected
      assert_json_total(%{"kind" => kind, "limit" => limit})
    end)
  end

  test "JSON safety limit classifier fails closed for every unknown or hostile issue shape" do
    limits = JsonSafety.limits()
    parent = self()
    exact_nodes_message = "exceeds maximum JSON node budget of #{limits["max_nodes"]}"

    hostile_fun = fn ->
      send(parent, :hostile_classifier_value_executed)
      exact_nodes_message
    end

    valid_issue = %{
      "severity" => "error",
      "path" => "$.projection",
      "message" => exact_nodes_message
    }

    cases = [
      %{
        "severity" => "error",
        "path" => "$.projection",
        "message" => "exceeds maximum JSON node budget of 7"
      },
      %{
        "severity" => "error",
        "path" => "$.projection",
        "message" => "JSON node budget exceeded at #{limits["max_nodes"]} nodes"
      },
      %{"severity" => "error", "path" => "$.projection", "message" => nil},
      %{"severity" => "error", "path" => "$.projection", "message" => 7},
      %{"severity" => "error", "path" => nil, "message" => exact_nodes_message},
      %{"severity" => "error", "path" => <<255>>, "message" => exact_nodes_message},
      %{"severity" => "error", "path" => "$.projection", "message" => <<255>>},
      %{
        "severity" => "error",
        "path" => "$.projection",
        "message" => String.duplicate("x", limits["max_aggregate_bytes"] + 1)
      },
      %{"severity" => "error", "path" => "$.projection", "message" => hostile_fun},
      %{"severity" => "error", "path" => hostile_fun, "message" => exact_nodes_message},
      Map.put(valid_issue, "hostile_extra", hostile_fun),
      Map.delete(valid_issue, "severity"),
      %{severity: "error", path: "$.projection", message: exact_nodes_message},
      URI.parse("https://example.invalid/resource-limit"),
      [valid_issue | :improper],
      {:issue, valid_issue},
      exact_nodes_message,
      20_000,
      nil,
      self(),
      make_ref(),
      hostile_fun
    ]

    Enum.each(cases, fn issue ->
      assert {"strict_json", nil} = JsonSafetyLimitClassifier.classify(issue)
      assert_json_total(%{"kind" => "strict_json", "limit" => :null})
    end)

    refute_received :hostile_classifier_value_executed
  end

  for {label, module, function} <- @facades do
    test "#{label} rejects an exact-ceiling objective before callback one" do
      facade = {unquote(module), unquote(function)}
      counter = :atomics.new(1, [])
      evaluator = counted_evaluator(counter)
      objective = String.duplicate("o", JsonSafety.limits()["max_aggregate_bytes"])

      assert {:error, failure} =
               invoke(
                 facade,
                 @seed,
                 source_evidence(@candidate_ids),
                 evaluator,
                 Keyword.put(@opts, :objective, objective)
               )

      assert :atomics.get(counter, 1) == 0

      assert_output_budget_failure(
        failure,
        "preflight_certificate_envelope",
        0,
        0,
        "max_aggregate_bytes"
      )
    end

    test "#{label} stops before the next callback when retained result growth consumes the budget" do
      facade = {unquote(module), unquote(function)}
      oversized_counter = :atomics.new(1, [])

      oversized_score_term =
        String.duplicate("s", JsonSafety.limits()["max_aggregate_bytes"] - 500)

      oversized_evaluator = fn _parameters, _evidence ->
        :atomics.add(oversized_counter, 1, 1)

        %{
          "score_terms" => %{oversized_score_term => 1},
          "eligible" => true,
          "rejection_reasons" => []
        }
      end

      assert {:error, oversized_failure} =
               invoke(
                 facade,
                 @seed,
                 source_evidence(@candidate_ids),
                 oversized_evaluator,
                 @opts
               )

      assert :atomics.get(oversized_counter, 1) == 1

      assert_output_budget_failure(
        oversized_failure,
        "incremental_after_evaluator",
        0,
        1,
        "max_aggregate_bytes"
      )

      assert oversized_failure["details"]["projected_aggregate_string_bytes"] >
               JsonSafety.limits()["max_aggregate_bytes"]

      counter = :atomics.new(1, [])
      score_term = String.duplicate("s", 4_189_500)

      evaluator = fn _parameters, _evidence ->
        :atomics.add(counter, 1, 1)

        %{
          "score_terms" => %{score_term => 1},
          "eligible" => true,
          "rejection_reasons" => []
        }
      end

      assert {:error, failure} =
               invoke(facade, @seed, source_evidence(@candidate_ids), evaluator, @opts)

      assert :atomics.get(counter, 1) == 1

      assert_output_budget_failure(
        failure,
        "incremental_before_evaluator",
        1,
        2,
        "max_aggregate_bytes"
      )

      assert failure["details"]["previously_admitted_aggregate_string_bytes"] <=
               JsonSafety.limits()["max_aggregate_bytes"]

      assert failure["details"]["projected_aggregate_string_bytes"] >
               JsonSafety.limits()["max_aggregate_bytes"]
    end

    test "#{label} reports the cumulative JSON node limit without re-evaluating candidates" do
      facade = {unquote(module), unquote(function)}
      {seed, evidence, opts, candidate_ids} = cumulative_node_budget_inputs()
      counters = :atomics.new(length(candidate_ids), [])
      index_by_id = candidate_ids |> Enum.with_index(1) |> Map.new()

      score_terms =
        Map.new(0..999, fn index ->
          name = "s" <> String.pad_leading(Integer.to_string(index, 36), 3, "0")
          {name, 1}
        end)

      assert Enum.all?(Map.keys(score_terms), &(byte_size(&1) == 4))

      evaluator = fn _parameters, evidence_entry ->
        alternative_id = evidence_entry["payload"]["candidate_id"]
        :atomics.add(counters, Map.fetch!(index_by_id, alternative_id), 1)

        %{
          "score_terms" => score_terms,
          "eligible" => true,
          "rejection_reasons" => []
        }
      end

      assert {:error, failure} = invoke(facade, seed, evidence, evaluator, opts)

      assert Enum.all?(1..10, &(:atomics.get(counters, &1) == 1))
      assert :atomics.get(counters, 11) == 0
      assert_output_budget_failure(failure, "incremental_after_evaluator", 9, 10, "max_nodes")

      details = failure["details"]
      issue = details["json_safety_issue"]

      assert details["projected_aggregate_string_bytes"] <
               JsonSafety.limits()["max_aggregate_bytes"]

      assert issue["severity"] == "error"
      assert String.starts_with?(issue["path"], "$.evaluations[9].score_terms")

      assert issue["message"] ==
               "exceeds maximum JSON node budget of #{JsonSafety.limits()["max_nodes"]}"
    end

    test "#{label} admits and accounts for the complete 65-candidate boundary" do
      facade = {unquote(module), unquote(function)}
      {seed, evidence, opts, candidate_ids} = maximum_neighborhood_inputs()
      counters = :atomics.new(length(candidate_ids), [])
      index_by_id = candidate_ids |> Enum.with_index(1) |> Map.new()

      evaluator = fn parameters, evidence_entry ->
        alternative_id = evidence_entry["payload"]["candidate_id"]
        :atomics.add(counters, Map.fetch!(index_by_id, alternative_id), 1)

        %{
          "score_terms" => %{"value" => Enum.sum(Map.values(parameters))},
          "eligible" => true,
          "rejection_reasons" => []
        }
      end

      certificate = invoke(facade, seed, evidence, evaluator, opts)

      assert Enum.all?(1..65, &(:atomics.get(counters, &1) == 1))
      assert certificate["search_space"]["candidate_count"] == 65
      assert certificate["evaluated_count"] == 65
      assert certificate["search_space_exhausted"] === true
      assert certificate["global_optimality_claimed"] === false
      assert_certificate_routes(certificate)
    end

    test "#{label} rejects improper, open, and duplicate options without callbacks" do
      facade = {unquote(module), unquote(function)}

      malformed_options = [
        [{:steps, @steps} | :improper],
        @opts ++ [unsupported_output_policy: true],
        [steps: @steps, steps: @steps]
      ]

      Enum.each(malformed_options, fn opts ->
        counter = :atomics.new(1, [])

        assert {:error, failure} =
                 invoke(
                   facade,
                   @seed,
                   source_evidence(@candidate_ids),
                   counted_evaluator(counter),
                   opts
                 )

        assert :atomics.get(counter, 1) == 0
        assert failure["reason"] == "builder_input_invalid"
        assert Enum.any?(failure["details"]["errors"], &(&1["path"] == "$.options"))
        assert_json_total(failure)
      end)
    end

    test "#{label} preserves fresh deterministic certificate identity and validation routes" do
      facade = {unquote(module), unquote(function)}
      counter = :atomics.new(1, [])
      evaluator = counted_evaluator(counter)
      evidence = source_evidence(@candidate_ids)

      first = invoke(facade, @seed, evidence, evaluator, @opts)
      second = invoke(facade, @seed, Map.new(Enum.reverse(evidence)), evaluator, @opts)

      assert :atomics.get(counter, 1) == 8
      assert first == second

      assert first["id"] ==
               first
               |> Map.delete("id")
               |> LocalSearchCertificate.certificate_id()

      assert_certificate_routes(first)
    end
  end

  defp invoke({module, function}, seed, evidence, evaluator, opts),
    do: apply(module, function, [seed, evidence, evaluator, opts])

  defp counted_evaluator(counter) do
    fn parameters, _evidence ->
      :atomics.add(counter, 1, 1)

      %{
        "score_terms" => %{"value" => Enum.sum(Map.values(parameters))},
        "eligible" => true,
        "rejection_reasons" => []
      }
    end
  end

  defp source_evidence(ids) do
    Map.new(ids, fn id ->
      {id,
       %{
         "id" => "source:#{id}",
         "revision" => "revision:1",
         "payload" => %{"candidate_id" => id}
       }}
    end)
  end

  defp maximum_neighborhood_inputs do
    parameter_names =
      Enum.map(1..32, &("p" <> String.pad_leading(Integer.to_string(&1), 2, "0")))

    seed = Map.new(parameter_names, &{&1, 0})
    steps = Map.new(parameter_names, &{&1, 1})
    bounds = Map.new(parameter_names, &{&1, {-1, 1}})

    opts = [
      steps: steps,
      bounds: bounds,
      id_prefix: "limit",
      evaluation_budget: 65
    ]

    neighborhood =
      Local.neighborhood(seed,
        steps: steps,
        bounds: bounds,
        id_prefix: "limit",
        max_alternatives: 65
      )

    candidate_ids = Enum.map(neighborhood["alternatives"], & &1["id"])
    {seed, source_evidence(candidate_ids), opts, candidate_ids}
  end

  defp cumulative_node_budget_inputs do
    parameter_names = Enum.map(1..5, &"p#{&1}")
    seed = Map.new(parameter_names, &{&1, 0})
    steps = Map.new(parameter_names, &{&1, 1})
    bounds = Map.new(parameter_names, &{&1, {-1, 1}})

    opts = [
      steps: steps,
      bounds: bounds,
      id_prefix: "nodes",
      evaluation_budget: 11
    ]

    neighborhood =
      Local.neighborhood(seed,
        steps: steps,
        bounds: bounds,
        id_prefix: "nodes",
        max_alternatives: 11
      )

    candidate_ids = Enum.map(neighborhood["alternatives"], & &1["id"])
    {seed, source_evidence(candidate_ids), opts, candidate_ids}
  end

  defp assert_output_budget_failure(
         failure,
         phase,
         retained_count,
         projected_count,
         expected_limit_kind
       ) do
    assert failure["status"] == "rejected"
    assert failure["reason"] == "certificate_output_budget_exceeded"
    assert failure["details"]["phase"] == phase
    assert failure["details"]["retained_evaluation_count"] == retained_count
    assert failure["details"]["projected_evaluation_count"] == projected_count

    assert failure["details"]["aggregate_string_byte_limit"] ==
             JsonSafety.limits()["max_aggregate_bytes"]

    assert failure["details"]["json_safety_limit_kind"] == expected_limit_kind

    assert failure["details"]["json_safety_limit"] ==
             JsonSafety.limits()[expected_limit_kind]

    assert failure["details"]["json_safety_issue"]["severity"] == "error"
    assert is_binary(failure["details"]["json_safety_issue"]["path"])
    assert is_binary(failure["details"]["json_safety_issue"]["message"])

    assert failure["details"]["resource_scope"] ==
             "complete_local_search_optimization_certificate"

    assert_json_total(failure)
  end

  defp assert_certificate_routes(certificate) do
    assert LocalSearchOptimizationCertificateContracts.validate([], "$", certificate) == []
    assert {:ok, contract} = Schema.contract(@contract)
    assert ArtifactValidationRouter.validate(@contract, contract, certificate) == []
    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(certificate)
    assert {:ok, %{"status" => "pass"}} = OrbitalDynamics.validate_artifact(certificate)
    assert_json_total(certificate)
  end

  defp assert_json_total(value) do
    assert JsonSafety.errors(value) == []
    encoded = value |> :json.encode() |> IO.iodata_to_binary()
    assert :json.decode(encoded) == value
  end
end
