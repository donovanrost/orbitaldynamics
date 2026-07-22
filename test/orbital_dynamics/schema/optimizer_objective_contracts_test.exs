defmodule OrbitalDynamics.Schema.OptimizerObjectiveContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports optimizer and environment capability array item schemas" do
    assert {:ok, optimizer_schema} = Schema.json_schema("optimizer_contract.v1")

    assert get_in(optimizer_schema, [
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(optimizer_schema, ["properties", "candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(optimizer_schema, ["properties", "ranked_timeline_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(optimizer_schema, ["properties", "selected_activity_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(optimizer_schema, [
             "properties",
             "candidate_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(optimizer_schema, [
             "properties",
             "ranked_scenario_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(optimizer_schema, ["properties", "score_term_keys", "items", "type"]) ==
             "string"

    assert get_in(optimizer_schema, ["properties", "deterministic_ordering", "items", "type"]) ==
             "string"

    assert get_in(optimizer_schema, ["properties", "preserved_lineage_fields", "items", "type"]) ==
             "string"

    assert get_in(optimizer_schema, ["properties", "known_limits", "items", "type"]) ==
             "string"

    assert {:ok, model_schema} = Schema.json_schema("environment_model_capability.v1")

    assert get_in(model_schema, ["properties", "supported_bodies", "items", "type"]) ==
             "string"

    assert get_in(model_schema, ["properties", "source", "type"]) == "string"
    assert get_in(model_schema, ["properties", "known_limits", "items", "type"]) == "string"

    assert {:ok, provider_schema} = Schema.json_schema("environment_provider_capability.v1")

    assert "model" in provider_schema["required"]
    assert get_in(provider_schema, ["properties", "model", "type"]) == "string"
    assert get_in(provider_schema, ["properties", "source", "type"]) == "string"
    assert get_in(provider_schema, ["properties", "outputs", "items", "type"]) == "string"
    assert get_in(provider_schema, ["properties", "parameters", "type"]) == "object"
    assert get_in(provider_schema, ["properties", "trust_boundary", "type"]) == "string"
    assert get_in(provider_schema, ["properties", "provenance", "type"]) == "object"

    assert get_in(provider_schema, ["properties", "supported_bodies", "items", "type"]) ==
             "string"

    assert get_in(provider_schema, ["properties", "known_limits", "items", "type"]) == "string"

    assert {:ok, subsystem_schema} = Schema.json_schema("subsystem_model_capability.v1")

    assert "fidelity_tier" in subsystem_schema["required"]
    assert get_in(subsystem_schema, ["properties", "subsystem", "type"]) == "string"
    assert get_in(subsystem_schema, ["properties", "fidelity_tier", "type"]) == "string"

    assert get_in(subsystem_schema, ["properties", "validation_level", "enum"]) == [
             "analysis",
             "artifact_contract",
             "assumption_declared",
             "educational",
             "validated"
           ]

    assert get_in(subsystem_schema, ["properties", "state_variables", "items", "type"]) ==
             "string"

    assert get_in(subsystem_schema, ["properties", "activity_effects", "type"]) == "object"
    assert get_in(subsystem_schema, ["properties", "parameters", "type"]) == "object"

    assert Enum.any?(
             subsystem_schema["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) ==
                 "subsystem.power.battery.energy_storage.planning_grade" and
                 get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                   [
                     "selected_activity_sequence_only",
                     "declared_energy_hints_only",
                     "no_continuous_power_bus_or_thermal_coupling",
                     "no_battery_degradation_or_charge_dynamics"
                   ])
           )

    assert Enum.any?(
             subsystem_schema["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) ==
                 "subsystem.data_recorder.storage_buffer.planning_grade" and
                 get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                   [
                     "selected_activity_sequence_only",
                     "declared_data_volume_hints_only",
                     "storage_limited_downlink_arithmetic_only",
                     "no_partition_priority_deletion_or_latency_model"
                   ])
           )
  end

  test "validates checked-in optimizer and objective explanation examples" do
    optimizer_contract = read_json!("study_results/optimizer_contract_v1.json")
    ranking_comparison_report = read_json!("study_results/ranking_comparison_report_v1.json")
    pareto_frontier_report = read_json!("study_results/pareto_frontier_report_v1.json")
    score_term_report = read_json!("study_results/score_term_report_v1.json")
    tradeoff_report = read_json!("study_results/objective_tradeoff_report_v1.json")
    satisfaction_report = read_json!("study_results/objective_satisfaction_report_v1.json")
    branch_comparison_report = read_json!("study_results/branch_comparison_report_v1.json")

    assert {:ok, %{"schema_contract" => "optimizer_contract.v1"}} =
             Schema.validate_artifact(optimizer_contract)

    invalid_optimizer_count = Map.put(optimizer_contract, "candidate_count", 1.0)

    assert {:error, optimizer_count_report} = Schema.validate_artifact(invalid_optimizer_count)
    assert Enum.any?(optimizer_count_report["errors"], &(&1["path"] == "$.candidate_count"))

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(ranking_comparison_report)

    invalid_ranking_model =
      Map.put(ranking_comparison_report, "model", "stale_ranking_comparison_model")

    assert {:error, ranking_model_report} = Schema.validate_artifact(invalid_ranking_model)

    assert Enum.any?(
             ranking_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"scenario_ranking_pairwise_delta\"")
           )

    invalid_ranking_count = Map.put(ranking_comparison_report, "left_count", -1)

    assert {:error, ranking_count_report} = Schema.validate_artifact(invalid_ranking_count)
    assert Enum.any?(ranking_count_report["errors"], &(&1["path"] == "$.left_count"))

    stale_ranking_limits = Map.put(ranking_comparison_report, "model_limits", ["stale_limit"])

    assert {:error, ranking_limits_report} = Schema.validate_artifact(stale_ranking_limits)
    assert Enum.any?(ranking_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(pareto_frontier_report)

    invalid_pareto_model =
      Map.put(pareto_frontier_report, "model", "stale_pareto_frontier_model")

    assert {:error, pareto_model_report} = Schema.validate_artifact(invalid_pareto_model)

    assert Enum.any?(
             pareto_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"objective_vector_pareto_frontier\"")
           )

    invalid_pareto_count = Map.put(pareto_frontier_report, "frontier_count", 1.0)

    assert {:error, pareto_count_report} = Schema.validate_artifact(invalid_pareto_count)
    assert Enum.any?(pareto_count_report["errors"], &(&1["path"] == "$.frontier_count"))

    stale_pareto_limits = Map.put(pareto_frontier_report, "model_limits", ["stale_limit"])

    assert {:error, pareto_limits_report} = Schema.validate_artifact(stale_pareto_limits)
    assert Enum.any?(pareto_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_pareto_values =
      put_in(
        pareto_frontier_report,
        ["rows", Access.at(0), "objective_values", "coverage"],
        "high"
      )

    assert {:error, pareto_values_report} = Schema.validate_artifact(invalid_pareto_values)

    assert Enum.any?(
             pareto_values_report["errors"],
             &(&1["path"] == "$.rows[0].objective_values.coverage")
           )

    invalid_pareto_ids =
      put_in(pareto_frontier_report, ["rows", Access.at(0), "dominates_ids"], ["bad id"])

    assert {:error, pareto_ids_report} = Schema.validate_artifact(invalid_pareto_ids)

    assert Enum.any?(
             pareto_ids_report["errors"],
             &(&1["path"] == "$.rows[0].dominates_ids[0]")
           )

    assert %{
             "selected_activity_ids" => ["leo_1_observe_target_a_1"],
             "known_limits" => [
               "greedy_per_scenario_selection",
               "no_cross_scenario_resource_allocation",
               "no_milp_or_cp_sat_solver",
               "pareto_frontier_summary_not_solver_search",
               "ranking_comparison_not_solver_search",
               "explainable_score_terms_only"
             ]
           } = optimizer_contract

    assert %{
             "model" => "scenario_ranking_pairwise_delta",
             "matched_count" => 1,
             "left_only_count" => 1,
             "right_only_count" => 1,
             "row_count" => 3
           } = ranking_comparison_report

    assert %{
             "model" => "objective_vector_pareto_frontier",
             "frontier_count" => 3,
             "dominated_count" => 1,
             "frontier_ids" => ["balanced", "coverage_leader", "ignored_no_numeric"]
           } = pareto_frontier_report

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(score_term_report)

    invalid_score_model = Map.put(score_term_report, "model", "stale_score_model")

    assert {:error, score_model_report} = Schema.validate_artifact(invalid_score_model)
    assert Enum.any?(score_model_report["errors"], &(&1["path"] == "$.model"))

    invalid_score_count = Map.put(score_term_report, "row_count", -1)

    assert {:error, score_count_report} = Schema.validate_artifact(invalid_score_count)
    assert Enum.any?(score_count_report["errors"], &(&1["path"] == "$.row_count"))

    stale_score_limits = Map.put(score_term_report, "model_limits", ["stale_limit"])

    assert {:error, score_limits_report} = Schema.validate_artifact(stale_score_limits)
    assert Enum.any?(score_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    assert %{
             "row_count" => 7,
             "rows" => [
               %{
                 "id" => "score_term:leo_1:1:activity_count_penalty",
                 "term_key" => "activity_count_penalty",
                 "selected" => true
               }
               | _
             ]
           } = score_term_report

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(tradeoff_report)

    invalid_tradeoff_model = Map.put(tradeoff_report, "model", "stale_objective_tradeoff_model")

    assert {:error, tradeoff_model_report} = Schema.validate_artifact(invalid_tradeoff_model)

    assert Enum.any?(
             tradeoff_model_report["errors"],
             &(&1["path"] == "$.model" and String.starts_with?(&1["message"], "must be one of"))
           )

    stale_tradeoff_limits = Map.put(tradeoff_report, "model_limits", ["stale_limit"])

    assert {:error, tradeoff_limits_report} = Schema.validate_artifact(stale_tradeoff_limits)
    assert Enum.any?(tradeoff_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_tradeoff_count = Map.put(tradeoff_report, "ranking_count", 1.0)

    assert {:error, tradeoff_count_report} = Schema.validate_artifact(invalid_tradeoff_count)
    assert Enum.any?(tradeoff_count_report["errors"], &(&1["path"] == "$.ranking_count"))

    invalid_tradeoff =
      put_in(tradeoff_report, ["tradeoffs", Access.at(0), "score_terms", "target_value"], "high")

    assert {:error, tradeoff_validation_report} = Schema.validate_artifact(invalid_tradeoff)

    assert Enum.any?(
             tradeoff_validation_report["errors"],
             &(&1["path"] == "$.tradeoffs[0].score_terms.target_value")
           )

    assert %{
             "ranking_count" => 1,
             "tradeoffs" => [
               %{
                 "scenario_id" => "leo_1",
                 "activity_ids" => ["leo_1_observe_target_a_1"],
                 "score_delta_from_selected" => 0
               }
             ]
           } = tradeoff_report

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(satisfaction_report)

    invalid_satisfaction_model =
      Map.put(satisfaction_report, "model", "stale_objective_satisfaction_model")

    assert {:error, satisfaction_model_report} =
             Schema.validate_artifact(invalid_satisfaction_model)

    assert Enum.any?(
             satisfaction_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"campaign_v1_selected_activity_objective_summary\"")
           )

    stale_satisfaction_limits = Map.put(satisfaction_report, "model_limits", ["stale_limit"])

    assert {:error, satisfaction_limits_report} =
             Schema.validate_artifact(stale_satisfaction_limits)

    assert Enum.any?(satisfaction_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_satisfaction_count = Map.put(satisfaction_report, "objective_count", -1)

    assert {:error, satisfaction_count_report} =
             Schema.validate_artifact(invalid_satisfaction_count)

    assert Enum.any?(
             satisfaction_count_report["errors"],
             &(&1["path"] == "$.objective_count")
           )

    assert %{
             "objective_count" => 4,
             "rows" => [
               %{
                 "objective" => "target_coverage",
                 "status" => "partial",
                 "selected_target_ids" => ["target_a"]
               }
               | _
             ]
           } = satisfaction_report

    invalid_satisfaction =
      put_in(satisfaction_report, ["rows", Access.at(0), "selected_target_ids"], ["bad target"])

    assert {:error, satisfaction_validation_report} =
             Schema.validate_artifact(invalid_satisfaction)

    assert Enum.any?(
             satisfaction_validation_report["errors"],
             &(&1["path"] == "$.rows[0].selected_target_ids[0]")
           )

    invalid_satisfaction_count_shape =
      put_in(satisfaction_report, ["rows", Access.at(0), "required_count"], 1.0)

    assert {:error, satisfaction_count_shape_report} =
             Schema.validate_artifact(invalid_satisfaction_count_shape)

    assert Enum.any?(
             satisfaction_count_shape_report["errors"],
             &(&1["path"] == "$.rows[0].required_count")
           )

    invalid_satisfaction_negative_count =
      put_in(satisfaction_report, ["rows", Access.at(0), "selected_count"], -1)

    assert {:error, satisfaction_negative_count_report} =
             Schema.validate_artifact(invalid_satisfaction_negative_count)

    assert Enum.any?(
             satisfaction_negative_count_report["errors"],
             &(&1["path"] == "$.rows[0].selected_count")
           )

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1"}} =
             Schema.validate_artifact(branch_comparison_report)

    invalid_branch_model =
      Map.put(branch_comparison_report, "model", "stale_branch_comparison_model")

    assert {:error, branch_model_report} = Schema.validate_artifact(invalid_branch_model)
    assert Enum.any?(branch_model_report["errors"], &(&1["path"] == "$.model"))

    invalid_branch_source =
      Map.put(branch_comparison_report, "source", "campaign_strategy.legacy_branches")

    assert {:error, branch_source_report} = Schema.validate_artifact(invalid_branch_source)
    assert Enum.any?(branch_source_report["errors"], &(&1["path"] == "$.source"))

    invalid_branch_count = Map.put(branch_comparison_report, "branch_count", 99)

    assert {:error, branch_count_report} = Schema.validate_artifact(invalid_branch_count)
    assert Enum.any?(branch_count_report["errors"], &(&1["path"] == "$.branch_count"))

    invalid_branch_count_shape =
      Map.put(
        branch_comparison_report,
        "branch_count",
        branch_comparison_report["branch_count"] * 1.0
      )

    assert {:error, branch_count_shape_report} =
             Schema.validate_artifact(invalid_branch_count_shape)

    assert Enum.any?(branch_count_shape_report["errors"], &(&1["path"] == "$.branch_count"))

    invalid_branch_row_counts =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "risk_count"], 1.0)
      |> put_in(["rows", Access.at(0), "resource_projection_warning_count"], -1)

    assert {:error, branch_row_count_report} =
             Schema.validate_artifact(invalid_branch_row_counts)

    assert Enum.any?(
             branch_row_count_report["errors"],
             &(&1["path"] == "$.rows[0].risk_count")
           )

    assert Enum.any?(
             branch_row_count_report["errors"],
             &(&1["path"] == "$.rows[0].resource_projection_warning_count")
           )

    invalid_branch_downlink_contact_counts =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "downlink_completion_required_contacts"], 1.0)
      |> put_in(["rows", Access.at(0), "downlink_completion_planned_contacts"], -1)

    assert {:error, branch_downlink_contact_count_report} =
             Schema.validate_artifact(invalid_branch_downlink_contact_counts)

    assert Enum.any?(
             branch_downlink_contact_count_report["errors"],
             &(&1["path"] == "$.rows[0].downlink_completion_required_contacts")
           )

    assert Enum.any?(
             branch_downlink_contact_count_report["errors"],
             &(&1["path"] == "$.rows[0].downlink_completion_planned_contacts")
           )

    invalid_branch_downlink_probability =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "downlink_completion_ratio"], 1.2)
      |> put_in(["rows", Access.at(0), "observation_success_factor"], -0.1)

    assert {:error, branch_downlink_probability_report} =
             Schema.validate_artifact(invalid_branch_downlink_probability)

    assert Enum.any?(
             branch_downlink_probability_report["errors"],
             &(&1["path"] == "$.rows[0].downlink_completion_ratio")
           )

    assert Enum.any?(
             branch_downlink_probability_report["errors"],
             &(&1["path"] == "$.rows[0].observation_success_factor")
           )

    invalid_recommended_branch =
      Map.put(branch_comparison_report, "recommended_branch_id", "missing_branch")

    assert {:error, recommended_branch_report} =
             Schema.validate_artifact(invalid_recommended_branch)

    assert Enum.any?(
             recommended_branch_report["errors"],
             &(&1["path"] in ["$.recommended_branch_id", "$.selected_branch_ids"])
           )

    stale_branch_limits =
      Map.put(branch_comparison_report, "model_limits", ["stale_branch_comparison_boundary"])

    assert {:error, branch_limits_report} = Schema.validate_artifact(stale_branch_limits)
    assert Enum.any?(branch_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_branch_comparison =
      put_in(
        branch_comparison_report,
        ["rows", Access.at(0), "score_terms", "activity_score"],
        "high"
      )

    assert {:error, branch_comparison_validation_report} =
             Schema.validate_artifact(invalid_branch_comparison)

    assert Enum.any?(
             branch_comparison_validation_report["errors"],
             &(&1["path"] == "$.rows[0].score_terms.activity_score")
           )

    invalid_branch_risk_context =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "risk_types"], ["spacecraft_availability_low", 42])
      |> put_in(["rows", Access.at(0), "high_risk_types"], ["activity_type_incompatible"])
      |> put_in(["rows", Access.at(0), "resource_pressure_statuses"], ["pressure", 42])
      |> put_in(["rows", Access.at(0), "resource_pressure_types"], ["storage_overflow"])
      |> put_in(["rows", Access.at(0), "first_resource_pressure_kinds"], [
        "storage_overflow"
      ])
      |> put_in(["rows", Access.at(0), "first_resource_pressure_activity_id"], "bad id")

    assert {:error, branch_risk_context_report} =
             Schema.validate_artifact(invalid_branch_risk_context)

    assert Enum.any?(
             branch_risk_context_report["errors"],
             &(&1["path"] == "$.rows[0].risk_types[1]")
           )

    assert Enum.any?(
             branch_risk_context_report["errors"],
             &(&1["path"] == "$.rows[0].resource_pressure_statuses[1]")
           )

    assert Enum.any?(
             branch_risk_context_report["errors"],
             &(&1["path"] == "$.rows[0].first_resource_pressure_activity_id")
           )

    invalid_branch_event_count =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "branch_event_count"], 2)
      |> put_in(
        ["rows", Access.at(0), "branch_event_trust_boundary_status_counts"],
        %{"declared" => 1}
      )

    assert {:error, branch_event_count_report} =
             Schema.validate_artifact(invalid_branch_event_count)

    assert Enum.any?(
             branch_event_count_report["errors"],
             &(&1["path"] == "$.rows[0].branch_event_trust_boundary_status_counts")
           )

    invalid_negative_branch_event_count =
      put_in(branch_comparison_report, ["rows", Access.at(0), "branch_event_count"], -1)

    assert {:error, negative_branch_event_count_report} =
             Schema.validate_artifact(invalid_negative_branch_event_count)

    assert Enum.any?(
             negative_branch_event_count_report["errors"],
             &(&1["path"] == "$.rows[0].branch_event_count")
           )

    invalid_branch_target_id =
      put_in(
        branch_comparison_report,
        ["rows", Access.at(0), "priority_commitment_required_target_ids"],
        ["target with spaces"]
      )

    assert {:error, branch_target_id_report} = Schema.validate_artifact(invalid_branch_target_id)

    assert Enum.any?(
             branch_target_id_report["errors"],
             &(&1["path"] == "$.rows[0].priority_commitment_required_target_ids[0]")
           )

    invalid_branch_station_calendar_provider =
      put_in(
        branch_comparison_report,
        ["rows", Access.at(0), "branch_station_calendar_provider_ids"],
        ["provider with spaces"]
      )

    assert {:error, branch_station_calendar_provider_report} =
             Schema.validate_artifact(invalid_branch_station_calendar_provider)

    assert Enum.any?(
             branch_station_calendar_provider_report["errors"],
             &(&1["path"] == "$.rows[0].branch_station_calendar_provider_ids[0]")
           )

    invalid_branch_window_context =
      branch_comparison_report
      |> put_in(
        ["rows", Access.at(0), "branch_source_window_ids"],
        ["window_b", "window_a"]
      )
      |> put_in(["rows", Access.at(0), "branch_earliest_starts_at_s"], 200.0)
      |> put_in(["rows", Access.at(0), "branch_latest_ends_at_s"], 100.0)

    assert {:error, branch_window_context_report} =
             Schema.validate_artifact(invalid_branch_window_context)

    assert Enum.any?(
             branch_window_context_report["errors"],
             &(&1["path"] == "$.rows[0].branch_source_window_ids")
           )

    assert Enum.any?(
             branch_window_context_report["errors"],
             &(&1["path"] == "$.rows[0].branch_latest_ends_at_s")
           )

    for {field, value} <- [
          {"branch_earliest_starts_at_s", 100.0},
          {"branch_latest_ends_at_s", 200.0}
        ] do
      partial_branch_window_context =
        put_in(branch_comparison_report, ["rows", Access.at(0), field], value)

      assert {:ok, _partial_branch_window_context} =
               Schema.validate_artifact(partial_branch_window_context)
    end

    invalid_source_window_bounds =
      branch_comparison_report
      |> put_in(
        ["rows", Access.at(0), "branch_source_window_ids"],
        ["window_a", "window_b"]
      )
      |> put_in(
        ["rows", Access.at(0), "branch_source_window_bounds"],
        [
          %{
            "source_window_id" => "window_b",
            "earliest_starts_at_s" => 200.0,
            "latest_ends_at_s" => 100.0
          },
          %{"source_window_id" => "window_a"}
        ]
      )

    assert {:error, source_window_bounds_report} =
             Schema.validate_artifact(invalid_source_window_bounds)

    for path <- [
          "$.rows[0].branch_source_window_bounds",
          "$.rows[0].branch_source_window_bounds[0].latest_ends_at_s",
          "$.rows[0].branch_source_window_bounds[1]"
        ] do
      assert Enum.any?(source_window_bounds_report["errors"], &(&1["path"] == path))
    end

    unreferenced_source_window_bound =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "branch_source_window_ids"], ["window_a"])
      |> put_in(
        ["rows", Access.at(0), "branch_source_window_bounds"],
        [%{"source_window_id" => "window_b", "earliest_starts_at_s" => 100.0}]
      )

    assert {:error, unreferenced_source_window_bound_report} =
             Schema.validate_artifact(unreferenced_source_window_bound)

    assert Enum.any?(
             unreferenced_source_window_bound_report["errors"],
             &(&1["path"] == "$.rows[0].branch_source_window_bounds")
           )

    invalid_capacity_pack_pressure =
      branch_comparison_report
      |> put_in(["rows", Access.at(0), "capacity_pack_max_required_capacity_fraction"], 1.1)
      |> put_in(["rows", Access.at(0), "capacity_pack_total_required_capacity_fraction"], -0.1)
      |> put_in(["rows", Access.at(0), "capacity_pack_required_capacity_sources"], [42])

    assert {:error, capacity_pack_pressure_report} =
             Schema.validate_artifact(invalid_capacity_pack_pressure)

    assert Enum.any?(
             capacity_pack_pressure_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_pack_max_required_capacity_fraction")
           )

    assert Enum.any?(
             capacity_pack_pressure_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_pack_total_required_capacity_fraction")
           )

    assert Enum.any?(
             capacity_pack_pressure_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_pack_required_capacity_sources[0]")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
