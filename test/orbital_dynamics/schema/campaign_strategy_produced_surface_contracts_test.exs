Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContractsTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts

  @produced_fields ~w(
    source_repair_id
    score_term_report
    objective_tradeoff_report
    pareto_frontier_report
    operational_feedback_provenance
    cadence_import_manifest
  )

  test "validates the complete checked V3 produced top-level surface", %{strategy: strategy} do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    declared_fields = schema["properties"] |> Map.keys() |> MapSet.new()

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(strategy)

    assert strategy
           |> Map.keys()
           |> MapSet.new()
           |> MapSet.subset?(declared_fields)
  end

  test "keeps produced-surface fields optional for older strategies", %{strategy: strategy} do
    artifact = Map.drop(strategy, @produced_fields)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects CampaignStrategy branch metadata drift", %{strategy: strategy} do
    nonbaseline_branch_id =
      strategy["branches"]
      |> Enum.find(&(&1["branch_id"] != "baseline"))
      |> Map.fetch!("branch_id")

    invalid_cases = [
      {"$.strategy_metadata.branch_count",
       put_in(strategy, ["strategy_metadata", "branch_count"], 0)},
      {"$.strategy_metadata.baseline_branch_id",
       put_in(
         strategy,
         ["strategy_metadata", "baseline_branch_id"],
         nonbaseline_branch_id
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy ranked branch eligibility drift", %{strategy: strategy} do
    ranked_branch_ids = strategy["recommendation"]["ranked_branch_ids"]

    blocked_branch_id =
      strategy["branches"]
      |> Enum.find(&(&1["approval_status"] == "blocked_by_policy"))
      |> Map.fetch!("branch_id")

    invalid_cases = [
      ranked_branch_ids ++ [blocked_branch_id],
      Enum.drop(ranked_branch_ids, -1),
      ranked_branch_ids ++ [List.last(ranked_branch_ids)],
      [hd(ranked_branch_ids) | Enum.reverse(tl(ranked_branch_ids))]
    ]

    for invalid_ranked_branch_ids <- invalid_cases do
      invalid =
        put_in(
          strategy,
          ["recommendation", "ranked_branch_ids"],
          invalid_ranked_branch_ids
        )

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.recommendation.ranked_branch_ids")
             )
    end
  end

  test "keeps the producer all-blocked ranking fallback" do
    artifact = %{
      "branches" => [
        %{"branch_id" => "branch:first", "approval_status" => "blocked_by_policy"},
        %{"branch_id" => "branch:second", "approval_status" => "blocked_by_policy"}
      ],
      "recommendation" => %{
        "ranked_branch_ids" => ["branch:first", "branch:second"]
      }
    }

    assert [] == CampaignStrategyProducedSurfaceContracts.validate([], artifact)
  end

  test "rejects CampaignStrategy recommended branch evidence drift", %{strategy: strategy} do
    approval_status_drift =
      strategy
      |> put_in(["recommendation", "approval_status"], "blocked_by_policy")
      |> update_in(["recommendation", "requires_approval"], fn rows ->
        Enum.map(rows, &Map.put(&1, "policy_classification", "blocked_by_policy"))
      end)

    invalid_cases = [
      {"$.recommendation.reason",
       put_in(strategy, ["recommendation", "reason"], "schema_valid_drift")},
      {"$.recommendation.risks_remaining",
       update_in(strategy, ["recommendation", "risks_remaining"], &tl/1)},
      {"$.recommendation.requires_approval",
       put_in(strategy, ["recommendation", "requires_approval"], [])},
      {"$.recommendation.approval_status", approval_status_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "accepts every producer recommendation reason" do
    cases = [
      {"auto_approvable", "best_expected_score_within_auto_approval_policy"},
      {"operator_review_required", "best_expected_score_requiring_operator_review"},
      {"blocked_by_policy", "all_branches_blocked_highest_score_reported_for_review"}
    ]

    for {approval_status, reason} <- cases do
      artifact = %{
        "branches" => [
          %{
            "branch_id" => "branch:selected",
            "approval_status" => approval_status,
            "risk_indicators" => [],
            "approval_requirements" => []
          }
        ],
        "recommendation" => %{
          "recommended_branch_id" => "branch:selected",
          "ranked_branch_ids" => ["branch:selected"],
          "approval_status" => approval_status,
          "reason" => reason,
          "risks_remaining" => [],
          "requires_approval" => []
        }
      }

      assert [] == CampaignStrategyProducedSurfaceContracts.validate([], artifact)
    end
  end

  test "keeps additive CampaignStrategy source provenance copies optional", %{
    strategy: strategy
  } do
    older =
      strategy
      |> update_in(["provenance"], &Map.delete(&1, "source_plan_id"))
      |> update_in(
        ["operator_review_package", "provenance"],
        &Map.delete(&1, "source_plan_id")
      )
      |> update_in(
        ["cadence_import_manifest", "provenance"],
        &Map.delete(&1, "source_plan_id")
      )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(older)
  end

  test "rejects CampaignStrategy source provenance drift", %{strategy: strategy} do
    invalid_cases = [
      {"$.provenance.source_plan_id",
       put_in(strategy, ["provenance", "source_plan_id"], "campaign_plan:drift")},
      {"$.operator_review_package.provenance.source_plan_id",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_plan_id"],
         "campaign_plan:drift"
       )},
      {"$.operator_review_package.provenance.source_planner",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_planner"],
         "OrbitalDynamics.CampaignPlanner.Drift"
       )},
      {"$.operator_review_package.provenance.source_plan_generated_at",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_plan_generated_at"],
         "2026-05-15T00:00:00Z"
       )},
      {"$.operator_review_package.provenance.source_provenance",
       update_in(
         strategy,
         ["operator_review_package", "provenance", "source_provenance"],
         &Map.put(&1, "run_id", "drift")
       )},
      {"$.cadence_import_manifest.provenance.source_plan_id",
       put_in(
         strategy,
         ["cadence_import_manifest", "provenance", "source_plan_id"],
         "campaign_plan:drift"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects produced-surface drift at nested paths", %{strategy: strategy} do
    invalid =
      strategy
      |> Map.put("source_repair_id", "not a stable id")
      |> put_in(["score_term_report", "schema_contract"], "score_term_report.v0")
      |> put_in(
        ["objective_tradeoff_report", "schema_contract"],
        "objective_tradeoff_report.v0"
      )
      |> put_in(["pareto_frontier_report", "schema_contract"], "pareto_frontier_report.v0")
      |> put_in(["operational_feedback_provenance", "source_count"], 2)
      |> put_in(["cadence_import_manifest", "schema_contract"], "cadence_import_manifest.v0")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    expected_paths = [
      "$.source_repair_id",
      "$.score_term_report.schema_contract",
      "$.objective_tradeoff_report.schema_contract",
      "$.pareto_frontier_report.schema_contract",
      "$.operational_feedback_provenance.source_count",
      "$.cadence_import_manifest.schema_contract"
    ]

    for expected_path <- expected_paths do
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports direct schemas for every produced-surface report" do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    properties = schema["properties"]

    assert properties["source_repair_id"]["type"] == ["string", "null"]

    assert get_in(properties, ["score_term_report", "properties", "schema_contract", "const"]) ==
             "score_term_report.v1"

    assert get_in(properties, [
             "objective_tradeoff_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "objective_tradeoff_report.v1"

    assert get_in(properties, [
             "pareto_frontier_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "pareto_frontier_report.v1"

    assert get_in(properties, [
             "cadence_import_manifest",
             "properties",
             "schema_contract",
             "const"
           ]) == "cadence_import_manifest.v1"

    assert get_in(properties, [
             "operational_feedback_provenance",
             "properties",
             "source_count"
           ]) == %{"minimum" => 0, "type" => "integer"}
  end

  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy score-term evidence drift", %{strategy: strategy} do
    row = hd(strategy["score_term_report"]["rows"])

    coherent_identity_drift =
      strategy
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "id"],
        "score_term:stale_branch:1:stale_term"
      )
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "scenario_id"],
        "stale_branch"
      )
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "branch_id"],
        "stale_branch"
      )

    coherent_term_key_drift =
      strategy
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "term_key"],
        "stale_term"
      )
      |> update_in(["score_term_report", "score_term_keys"], fn keys ->
        ["stale_term" | keys] |> Enum.uniq() |> Enum.sort()
      end)

    reordered =
      update_in(strategy, ["score_term_report", "rows"], fn [first, second | rest] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.score_term_report.model",
       put_in(strategy, ["score_term_report", "model"], "ranked_timeline_score_terms")},
      {"$.score_term_report.source",
       put_in(strategy, ["score_term_report", "source"], "schema_valid_drift")},
      {"$.score_term_report.assumptions.policy",
       update_in(
         strategy,
         ["score_term_report", "assumptions", "policy", "risk_weight"],
         &(&1 + 1)
       )},
      {"$.score_term_report.assumptions.scenario_id_represents",
       put_in(
         strategy,
         ["score_term_report", "assumptions", "scenario_id_represents"],
         "stale_identity"
       )},
      {"$.score_term_report.assumptions.score_term_source",
       put_in(
         strategy,
         ["score_term_report", "assumptions", "score_term_source"],
         "stale_source"
       )},
      {"$.score_term_report.rows[0].id", coherent_identity_drift},
      {"$.score_term_report.rows[0].rank",
       update_in(strategy, ["score_term_report", "rows", Access.at(0), "rank"], &(&1 + 1))},
      {"$.score_term_report.rows[0].term_key", coherent_term_key_drift},
      {"$.score_term_report.rows[0].value",
       update_in(strategy, ["score_term_report", "rows", Access.at(0), "value"], &(&1 + 1))},
      {"$.score_term_report.rows[0].timeline_score",
       update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "timeline_score"],
         &(&1 + 1)
       )},
      {"$.score_term_report.rows[0].selected",
       update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "selected"],
         &(!&1)
       )},
      {"$.score_term_report.rows[0].id", reordered}
    ]

    assert row["selected"]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy objective-tradeoff evidence drift", %{strategy: strategy} do
    row = hd(strategy["objective_tradeoff_report"]["tradeoffs"])
    score_term_key = row["score_terms"] |> Map.keys() |> hd()

    coherent_identity_drift =
      strategy
      |> put_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "scenario_id"],
        "stale_branch"
      )
      |> put_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "branch_id"],
        "stale_branch"
      )

    coherent_activity_drift =
      strategy
      |> update_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_ids"],
        &(&1 ++ ["stale_activity"])
      )
      |> update_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_count"],
        &(&1 + 1)
      )

    reordered =
      update_in(strategy, ["objective_tradeoff_report", "tradeoffs"], fn [
                                                                           first,
                                                                           second
                                                                           | rest
                                                                         ] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.objective_tradeoff_report.model",
       put_in(
         strategy,
         ["objective_tradeoff_report", "model"],
         "ranked_timeline_score_term_tradeoffs"
       )},
      {"$.objective_tradeoff_report.objective",
       put_in(strategy, ["objective_tradeoff_report", "objective"], "schema valid drift")},
      {"$.objective_tradeoff_report.policy",
       update_in(
         strategy,
         ["objective_tradeoff_report", "policy", "risk_weight"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.assumptions.source",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "source"],
         "schema_valid_drift"
       )},
      {"$.objective_tradeoff_report.assumptions.scenario_id_represents",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "scenario_id_represents"],
         "stale_identity"
       )},
      {"$.objective_tradeoff_report.assumptions.score_delta_from_selected",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "score_delta_from_selected"],
         "stale_formula"
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].scenario_id", coherent_identity_drift},
      {"$.objective_tradeoff_report.tradeoffs[0].rank",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "rank"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_delta_from_selected",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_delta_from_selected"
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].activity_count", coherent_activity_drift},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_observation_count",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "selected_observation_count"
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_contact_count",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "selected_contact_count"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_terms",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_terms",
           score_term_key
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "selected"],
         &(!&1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].rank", reordered}
    ]

    assert row["selected"]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner.BranchComparisonReport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy branch comparison resource impact drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "fuel_margin" => 0.19,
      "power_margin" => 0.1,
      "storage_margin" => 0.17,
      "downlink_capacity_margin" => 0.63,
      "thermal_margin_c" => 1.0,
      "spacecraft_availability" => 0.51,
      "payload_availability" => 0.99,
      "antenna_availability" => 0.99,
      "resource_score_adjustment" => -73.0,
      "fuel_preservation_mode" => true
    }

    for {field, drift} <- drift_values do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison resource projection summary drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "resource_projection_spacecraft_count" => 2,
      "resource_projection_flow_count" => 4,
      "resource_projection_warning_count" => 3,
      "resource_source_quality_counts" => %{"operator_supplied" => 2},
      "resource_trust_boundary_status_counts" => %{"missing" => 2}
    }

    for {field, drift} <- drift_values do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison resource projection aggregate drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "projected_storage_margin" => 0.17,
      "projected_storage_remaining_mb" => 1.0,
      "projected_downlink_margin" => 0.63,
      "projected_downlink_remaining_mb" => 1.0,
      "projected_power_margin" => 0.1,
      "projected_storage_overflow_mb" => 1.0,
      "projected_downlink_shortfall_mb" => 1.0,
      "projected_battery_overuse_wh" => 1.0,
      "storage_limited_downlinked_mb" => 1.0,
      "unused_downlink_capacity_mb" => 1.0
    }

    for {field, drift} <- drift_values do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison resource projection availability drift", %{
    strategy: strategy
  } do
    count_fields = ~w(
      resource_projection_unavailable_spacecraft_count
      resource_projection_payload_unavailable_count
      resource_projection_degraded_payload_unavailable_count
      resource_projection_antenna_unavailable_count
      resource_projection_activity_type_suppressed_count
      resource_projection_activity_type_incompatible_count
    )

    id_fields = ~w(
      resource_projection_unavailable_spacecraft_ids
      resource_projection_payload_unavailable_spacecraft_ids
      resource_projection_degraded_payload_unavailable_spacecraft_ids
      resource_projection_antenna_unavailable_spacecraft_ids
      resource_projection_activity_type_suppressed_spacecraft_ids
      resource_projection_activity_type_incompatible_spacecraft_ids
    )

    drift_values =
      Enum.map(count_fields, &{&1, 1}) ++
        Enum.map(id_fields, &{&1, ["leo_1"]}) ++
        [{"resource_projection_availability_pressure_types", ["payload_unavailable"]}]

    for {field, drift} <- drift_values do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison resource projection peak drift", %{
    strategy: strategy
  } do
    fields = ~w(
      resource_projection_peak_storage_overflow_mb
      resource_projection_peak_downlink_shortfall_mb
      resource_projection_peak_battery_overuse_wh
      resource_projection_peak_unused_downlink_capacity_mb
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          1.0
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end

    coherent =
      strategy
      |> put_in(
        [
          "branches",
          Access.at(1),
          "resource_projection_report",
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "unused_downlink_capacity_mb"
        ],
        1.0
      )
      |> put_in(
        [
          "branch_comparison_report",
          "rows",
          Access.at(1),
          "resource_projection_peak_unused_downlink_capacity_mb"
        ],
        1.0
      )

    coherent =
      put_in(
        coherent,
        ["pareto_frontier_report"],
        BranchComparisonReport.pareto_frontier_report(coherent["branch_comparison_report"])
      )

    coherent =
      Map.put(
        coherent,
        "operator_review_package",
        OperatorReview.from_strategy_artifact(coherent)
      )

    coherent =
      Map.put(
        coherent,
        "cadence_import_manifest",
        CadenceImport.from_strategy_artifact(coherent)
      )

    assert {:ok, _validation_report} = Schema.validate_artifact(coherent)
  end

  test "rejects CampaignStrategy branch comparison first resource pressure context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "first_resource_pressure_activity_id" => "drift",
      "first_resource_pressure_activity_type" => "downlink",
      "first_resource_pressure_kind" => "downlink_shortfall",
      "first_resource_pressure_starts_at_s" => 1.0,
      "first_resource_pressure_direction" => "downlink",
      "first_resource_pressure_ground_station_id" => "drift",
      "first_resource_pressure_station_calendar_entry_id" => "drift",
      "first_resource_pressure_station_calendar_provider_id" => "drift",
      "first_resource_pressure_station_calendar_provider_entry_id" => "drift",
      "first_resource_pressure_station_calendar_directions" => ["downlink"]
    }

    for {field, drift} <- drift_values do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end
end
