defmodule OrbitalDynamics.OptimizerHardFeasibilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Optimizer
  alias OrbitalDynamics.Optimizer.CandidateBinding
  alias OrbitalDynamics.Optimizer.HardFeasibility
  alias OrbitalDynamics.Search.Local

  test "an infeasible higher score cannot outrank a lower-score feasible candidate" do
    config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(
          candidate,
          ["downlink_threshold", "required_volume_mb"],
          10.0
        )
      end)

    result = run_search(config)

    assert result["selected_id"] == "hard:seed"
    assert result["selected_score"] == 0.0
    assert result["eligible_count"] == 2
    assert result["infeasible_count"] == 1

    assert candidate(result, "hard:x:increase")["score"] == 1.0
    assert candidate(result, "hard:x:increase")["rank"] == nil
    assert candidate(result, "hard:x:increase")["selected"] == false

    assert candidate(result, "hard:x:increase")["selection_explanation"] ==
             "ineligible_hard_feasibility"

    assert Enum.map(Enum.take(result["alternatives"], 2), & &1["id"]) == [
             "hard:seed",
             "hard:x:decrease"
           ]
  end

  test "resource and link thresholds emit stable blocker reasons with source values" do
    resource_config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(
          candidate,
          ["resource_threshold", "threshold"],
          0.9
        )
      end)

    resource_evaluation =
      resource_config
      |> run_search()
      |> feasibility("hard:x:increase")

    assert resource_evaluation["blocker_reasons"] == ["resource_threshold_not_met"]

    assert %{
             "reason" => "resource_threshold_not_met",
             "metric" => "minimum_battery_state_of_charge",
             "actual" => 0.8,
             "operator" => "greater_than_or_equal",
             "threshold" => 0.9
           } = hd(resource_evaluation["blockers"])

    link_config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(
          candidate,
          ["downlink_threshold", "required_volume_mb"],
          10.0
        )
      end)

    link_evaluation = link_config |> run_search() |> feasibility("hard:x:increase")

    assert link_evaluation["blocker_reasons"] == ["downlink_threshold_not_met"]

    assert %{
             "reason" => "downlink_threshold_not_met",
             "metric" => "completion_fraction",
             "actual" => 0.75,
             "threshold" => 1.0
           } = hd(link_evaluation["blockers"])
  end

  test "all-infeasible hard search returns a typed outcome without an incumbent" do
    config =
      hard_config()
      |> update_all_candidates(fn candidate ->
        put_in(
          candidate,
          ["resource_threshold", "threshold"],
          0.9
        )
      end)

    result = run_search(config)

    assert result["selected_id"] == nil
    assert result["selected_score"] == nil
    assert result["improvement_from_seed"] == nil
    assert result["improved"] == false
    assert result["feasibility_transition"] == nil
    assert result["eligible_count"] == 0
    assert result["infeasible_count"] == 3
    assert Enum.all?(result["alternatives"], &is_nil(&1["rank"]))

    assert result["recommendation_outcome"] == %{
             "schema_contract" => "local_search_recommendation_outcome.v1",
             "mode" => "hard",
             "status" => "no_recommendable_alternative",
             "selected_incumbent_id" => nil,
             "reason" => "all_alternatives_infeasible",
             "eligible_count" => 0,
             "infeasible_count" => 3
           }
  end

  test "an ineligible seed has no comparable score improvement" do
    config =
      hard_config()
      |> update_candidate("hard:seed", fn candidate ->
        put_in(candidate, ["resource_threshold", "threshold"], 0.9)
      end)

    result = run_search(config)

    assert result["selected_id"] == "hard:x:increase"
    assert result["improvement_from_seed"] == nil
    assert result["improved"] == false

    assert result["feasibility_transition"] == %{
             "schema_contract" => "local_search_feasibility_transition.v1",
             "status" => "seed_ineligible_selected_feasible",
             "from_alternative_id" => "hard:seed",
             "to_alternative_id" => "hard:x:increase",
             "score_improvement_comparable" => false,
             "reason" => "seed_is_not_in_the_ranked_feasible_set"
           }
  end

  test "candidate evaluations preserve combined resource and link reasons" do
    config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        candidate
        |> put_in(["resource_threshold", "threshold"], 0.9)
        |> put_in(["downlink_threshold", "required_volume_mb"], 10.0)
      end)

    result = run_search(config)
    evaluation = feasibility(result, "hard:x:increase")

    assert evaluation["schema_contract"] == "candidate_feasibility.v1"
    assert evaluation["status"] == "infeasible"
    assert evaluation["eligible"] == false

    assert evaluation["blocker_reasons"] == [
             "resource_threshold_not_met",
             "downlink_threshold_not_met"
           ]

    assert Enum.map(evaluation["threshold_evaluations"], &{&1["type"], &1["status"]}) == [
             {"resource_state_threshold", "fail"},
             {"downlink_threshold", "fail"}
           ]

    assert Enum.find(
             result["candidate_feasibility_evaluations"],
             &(&1["alternative_id"] == "hard:x:increase")
           ) == evaluation
  end

  test "source artifacts bound to a stale parameter revision fail closed" do
    result = hard_config() |> Map.put(:parameter_revision, "parameters-r2") |> run_search()

    assert result["selected_id"] == nil

    assert Enum.all?(result["candidate_feasibility_evaluations"], fn evaluation ->
             evaluation["blocker_reasons"] == [
               "resource_state_trace_candidate_binding_mismatch",
               "downlink_link_budget_candidate_binding_mismatch"
             ]
           end)
  end

  test "cross-alternative and stale parameter-content evidence reuse fail closed" do
    base = hard_config()
    seed = candidate_config(base, "hard:seed")

    cross_reused =
      update_candidate(base, "hard:x:increase", fn candidate ->
        candidate
        |> Map.put("resource_state_trace", seed["resource_state_trace"])
        |> Map.put("downlink_link_budget", seed["downlink_link_budget"])
      end)
      |> run_search()

    assert cross_reused["selected_id"] == "hard:seed"

    assert feasibility(cross_reused, "hard:x:increase")["blocker_reasons"] == [
             "resource_state_trace_candidate_binding_mismatch",
             "downlink_link_budget_candidate_binding_mismatch"
           ]

    stale_binding = CandidateBinding.build("hard:x:increase", "parameters-r1", %{"x" => 0.5})

    stale_content =
      hard_config()
      |> update_candidate("hard:x:increase", &replace_sources(&1, stale_binding))
      |> run_search()

    assert stale_content["selected_id"] == "hard:seed"

    assert feasibility(stale_content, "hard:x:increase")["blocker_reasons"] == [
             "resource_state_trace_candidate_binding_mismatch",
             "downlink_link_budget_candidate_binding_mismatch"
           ]
  end

  test "source artifacts carry typed candidate bindings accepted by their semantic paths" do
    alternatives =
      Local.neighborhood(%{x: 0.0}, steps: %{x: 1.0}, id_prefix: "hard")["alternatives"]

    assert {:hard, prepared} =
             HardFeasibility.prepare([hard_feasibility: hard_config()], alternatives)

    evidence = prepared.candidates["hard:x:increase"]
    trace = evidence["resource_state_trace"]
    budget = evidence["downlink_link_budget"]

    assert {:ok, _report} =
             OrbitalDynamics.Schema.validate_artifact(trace,
               schema_contract: "resource_state_trace.v1"
             )

    assert :ok =
             OrbitalDynamics.Communications.DownlinkLinkBudget.validate_artifact(budget)

    assert get_in(trace, ["provenance", "caller", "candidate_binding"]) ==
             budget["candidate_binding"]

    assert budget["candidate_binding"] ==
             CandidateBinding.build(
               "hard:x:increase",
               "parameters-r1",
               %{"x" => 1.0}
             )
  end

  test "missing source candidate bindings fail closed after semantic validation" do
    config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        trace_core =
          candidate["resource_state_trace"]
          |> update_in(["provenance", "caller"], &Map.delete(&1, "candidate_binding"))
          |> Map.delete("id")

        trace =
          Map.put(
            trace_core,
            "id",
            OrbitalDynamics.ResourceStateTrace.artifact_id(trace_core)
          )

        budget_core =
          candidate["downlink_link_budget"]
          |> Map.delete("candidate_binding")
          |> Map.delete("id")

        budget =
          Map.put(
            budget_core,
            "id",
            OrbitalDynamics.Communications.DownlinkLinkBudget.artifact_id(budget_core)
          )

        candidate
        |> Map.put("resource_state_trace", trace)
        |> Map.put("downlink_link_budget", budget)
      end)

    result = run_search(config)

    assert result["selected_id"] == "hard:seed"

    assert feasibility(result, "hard:x:increase")["blocker_reasons"] == [
             "resource_state_trace_candidate_binding_missing_or_malformed",
             "downlink_link_budget_candidate_binding_missing_or_malformed"
           ]
  end

  test "missing and malformed evidence cannot become eligible" do
    missing = hard_config() |> Map.put(:candidates, []) |> run_search()

    assert missing["selected_id"] == nil

    assert Enum.all?(missing["candidate_feasibility_evaluations"], fn evaluation ->
             evaluation["blocker_reasons"] == ["missing_candidate_evidence"]
           end)

    malformed_config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        core =
          candidate["resource_state_trace"]
          |> put_in(["final_state", "battery_state_of_charge"], "opaque")
          |> Map.delete("id")

        forged =
          Map.put(core, "id", OrbitalDynamics.ResourceStateTrace.artifact_id(core))

        Map.put(candidate, "resource_state_trace", forged)
      end)

    malformed = run_search(malformed_config)

    assert malformed["selected_id"] == "hard:seed"

    assert feasibility(malformed, "hard:x:increase")["blocker_reasons"] == [
             "malformed_resource_state_trace"
           ]

    unsafe =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["resource_state_trace", "provenance", "caller", "unsafe"], self())
      end)

    assert_raise ArgumentError, ~r/unsupported non-JSON-safe value/, fn ->
      run_search(unsafe)
    end
  end

  test "rehashed resource-state arithmetic forgery fails semantic validation" do
    config =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        core =
          candidate["resource_state_trace"]
          |> put_in(["final_state", "battery_state_of_charge"], 0.1)
          |> Map.delete("id")

        forged = Map.put(core, "id", OrbitalDynamics.ResourceStateTrace.artifact_id(core))
        Map.put(candidate, "resource_state_trace", forged)
      end)

    result = run_search(config)

    assert result["selected_id"] == "hard:seed"

    assert feasibility(result, "hard:x:increase")["blocker_reasons"] == [
             "malformed_resource_state_trace"
           ]
  end

  test "physical threshold domains fail closed with stable reasons" do
    resource_low =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["resource_threshold", "threshold"], -0.01)
      end)
      |> run_search()

    resource_high =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["resource_threshold", "threshold"], 1.01)
      end)
      |> run_search()

    completion_high =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["downlink_threshold", "threshold"], 1.01)
      end)
      |> run_search()

    completion_low =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["downlink_threshold", "threshold"], -0.01)
      end)
      |> run_search()

    shortfall_negative =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        candidate
        |> put_in(["downlink_threshold", "metric"], "shortfall_mb")
        |> put_in(["downlink_threshold", "operator"], "less_than_or_equal")
        |> put_in(["downlink_threshold", "threshold"], -0.01)
      end)
      |> run_search()

    non_positive_volume =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["downlink_threshold", "required_volume_mb"], 0.0)
      end)
      |> run_search()

    for result <- [resource_low, resource_high] do
      assert feasibility(result, "hard:x:increase")["blocker_reasons"] == [
               "resource_threshold_out_of_domain"
             ]
    end

    for result <- [completion_low, completion_high, shortfall_negative, non_positive_volume] do
      assert feasibility(result, "hard:x:increase")["blocker_reasons"] == [
               "downlink_threshold_out_of_domain"
             ]
    end

    malformed =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(candidate, ["resource_threshold", "threshold"], :infinity)
      end)
      |> run_search()

    assert feasibility(malformed, "hard:x:increase")["blocker_reasons"] == [
             "malformed_resource_threshold"
           ]
  end

  test "inclusive threshold boundaries remain supported" do
    config =
      hard_config()
      |> update_all_candidates(fn candidate ->
        candidate
        |> put_in(["resource_threshold", "threshold"], 0.0)
        |> put_in(["downlink_threshold", "metric"], "shortfall_mb")
        |> put_in(["downlink_threshold", "operator"], "less_than_or_equal")
        |> put_in(["downlink_threshold", "threshold"], 0.0)
      end)

    result = run_search(config)

    assert result["eligible_count"] == 3
    assert result["selected_id"] == "hard:x:increase"
  end

  test "unknown modes, duplicate normalized keys, and unsupported thresholds are rejected" do
    assert_raise ArgumentError, ~r/hard_feasibility.mode/, fn ->
      hard_config() |> Map.put(:mode, :soft) |> run_search()
    end

    duplicate_mode = %{
      :mode => :hard,
      "mode" => "hard",
      parameter_revision: "parameters-r1",
      candidates: []
    }

    assert_raise ArgumentError, ~r/duplicate keys after key normalization/, fn ->
      run_search(duplicate_mode)
    end

    unsupported =
      hard_config()
      |> update_candidate("hard:x:increase", fn candidate ->
        put_in(
          candidate,
          ["resource_threshold", "metric"],
          "hidden_thermal_margin"
        )
      end)
      |> run_search()

    assert unsupported["selected_id"] == "hard:seed"

    assert feasibility(unsupported, "hard:x:increase")["blocker_reasons"] == [
             "unsupported_resource_threshold"
           ]
  end

  test "hard evaluation and ordering are deterministic across evidence input order" do
    config = hard_config()
    reversed = Map.update!(config, :candidates, &Enum.reverse/1)

    first = run_search(config)
    second = run_search(reversed)

    assert first == second
    assert first["selected_id"] == "hard:x:increase"

    assert Enum.map(first["alternatives"], &{&1["id"], &1["rank"]}) == [
             {"hard:x:increase", 1},
             {"hard:seed", 2},
             {"hard:x:decrease", 3}
           ]
  end

  test "absence of hard mode preserves the legacy result contract and limits" do
    result =
      Optimizer.explainable_local_search(%{x: 0.0}, &%{objective: &1["x"]},
        steps: %{x: 1.0},
        id_prefix: "hard"
      )

    assert result["selected_id"] == "hard:x:increase"
    assert result["selected_score"] == 1.0
    assert result["evaluated_count"] == 3
    assert result["model_limits"] == Optimizer.local_search_model_limits()
    assert "no_constraint_or_feasibility_evaluation_beyond_bounds" in result["model_limits"]

    assert result
           |> :erlang.term_to_binary([:deterministic])
           |> then(&:crypto.hash(:sha256, &1))
           |> Base.encode16(case: :lower) ==
             "2423de6ab2d8d5162687c963e7808077e54b90c381bee887ced6be1b3ba5d535"

    refute Map.has_key?(result, "feasibility_mode")
    refute Map.has_key?(result, "recommendation_outcome")
    refute Enum.any?(result["alternatives"], &Map.has_key?(&1, "candidate_feasibility"))
  end

  defp run_search(config) do
    Optimizer.explainable_local_search(%{x: 0.0}, &%{objective: &1["x"]},
      steps: %{x: 1.0},
      id_prefix: "hard",
      hard_feasibility: config
    )
  end

  defp hard_config do
    candidates =
      Local.neighborhood(%{x: 0.0}, steps: %{x: 1.0}, id_prefix: "hard")
      |> Map.fetch!("alternatives")
      |> Enum.map(fn alternative ->
        binding =
          CandidateBinding.build(
            alternative["id"],
            "parameters-r1",
            alternative["parameters"]
          )

        %{
          "alternative_id" => alternative["id"],
          "resource_state_trace" => resource_trace(binding),
          "resource_threshold" => %{
            "metric" => "minimum_battery_state_of_charge",
            "operator" => "greater_than_or_equal",
            "threshold" => 0.5
          },
          "downlink_link_budget" => downlink_budget(binding),
          "downlink_threshold" => %{
            "metric" => "completion_fraction",
            "operator" => "greater_than_or_equal",
            "threshold" => 1.0,
            "required_volume_mb" => 5.0
          }
        }
      end)

    %{mode: :hard, parameter_revision: "parameters-r1", candidates: candidates}
  end

  defp update_candidate(config, id, update) do
    Map.update!(config, :candidates, fn candidates ->
      Enum.map(candidates, fn candidate ->
        if candidate["alternative_id"] == id, do: update.(candidate), else: candidate
      end)
    end)
  end

  defp update_all_candidates(config, update),
    do: Map.update!(config, :candidates, &Enum.map(&1, update))

  defp candidate_config(config, id),
    do: Enum.find(config.candidates, &(&1["alternative_id"] == id))

  defp replace_sources(candidate, binding) do
    candidate
    |> Map.put("resource_state_trace", resource_trace(binding))
    |> Map.put("downlink_link_budget", downlink_budget(binding))
  end

  defp candidate(result, id), do: Enum.find(result["alternatives"], &(&1["id"] == id))
  defp feasibility(result, id), do: candidate(result, id)["candidate_feasibility"]

  defp resource_trace(binding) do
    OrbitalDynamics.resource_state_trace([], initial_resource_summary(),
      provenance: %{
        resource_state_trace_revision: "trace-r1",
        candidate_binding: binding
      }
    )
  end

  defp initial_resource_summary do
    %{
      spacecraft_id: "sc_1",
      battery_capacity_wh: 100.0,
      battery_energy_used_wh: 20.0,
      storage_capacity_mb: 100.0,
      storage_used_mb: 40.0,
      assumptions: %{initial_state: :operator_declared},
      provenance: %{
        source_quality: :operator_supplied,
        trust_boundary: :operator_declared
      }
    }
  end

  defp downlink_budget(binding) do
    OrbitalDynamics.downlink_link_budget(
      %{
        id: "dl_1",
        type: "downlink",
        spacecraft_id: "sc_1",
        ground_station_id: "gs_1",
        direction: "downlink",
        mode: "fixed_single_carrier",
        starts_at_s: 100.0,
        ends_at_s: 220.0,
        source_window_id: "access_1",
        source_window_revision: "window-r7"
      },
      Map.put(downlink_parameters(), :candidate_binding, binding)
    )
  end

  defp downlink_parameters do
    %{
      source: "mission_rf_configuration",
      source_revision: "rf-config-r4",
      access_window: %{
        id: "access_1",
        revision: "window-r7",
        spacecraft_id: "sc_1",
        ground_station_id: "gs_1",
        starts_at_s: 90.0,
        ends_at_s: 230.0,
        source: "access_windows.v1",
        source_revision: "trajectory-r12"
      },
      geometry: %{
        slant_range: %{value: 1_000.0, unit: "km"},
        elevation: %{value: 30.0, unit: "deg"},
        sample_at: %{value: 160.0, unit: "s"}
      },
      spacecraft_terminal: %{
        id: "sc_terminal_1",
        spacecraft_id: "sc_1",
        source: "spacecraft_terminal_catalog",
        revision: "sc-terminal-r3",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        transmit_power: %{value: 20.0, unit: "W"},
        transmit_antenna_gain: %{value: 5.0, unit: "dBi"}
      },
      ground_terminal: %{
        id: "gs_terminal_1",
        ground_station_id: "gs_1",
        source: "ground_terminal_catalog",
        revision: "gs-terminal-r9",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        receive_antenna_gain: %{value: 35.0, unit: "dBi"},
        system_noise_temperature: %{value: 500.0, unit: "K"}
      },
      rf_link: %{
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        occupied_bandwidth: %{value: 1.0e6, unit: "Hz"},
        explicit_losses: %{value: 3.0, unit: "dB"},
        coding_efficiency: %{value: 0.5, unit: "ratio"},
        modulation_efficiency: %{value: 1.0, unit: "bit/s/Hz"}
      },
      margin_policy: %{
        minimum_elevation: %{value: 10.0, unit: "deg"},
        required_eb_n0: %{value: 3.0, unit: "dB"},
        required_margin: %{value: 2.0, unit: "dB"}
      }
    }
  end
end
