defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContractsTest do
  use ExUnit.Case, async: true

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

  setup_all do
    %{strategy: read_json!("study_results/leo_constellation_campaign_strategy_v3.json")}
  end

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

  test "rejects CampaignStrategy branch comparison identity drift", %{strategy: strategy} do
    report = strategy["branch_comparison_report"]
    [first, second, third | rest] = report["rows"]

    reordered =
      put_in(
        strategy,
        ["branch_comparison_report", "rows"],
        [first, third, second | rest]
      )

    alternate_recommended_branch_id = second["branch_id"]
    alternate_recommended_score = second["score"]

    alternate_report =
      report
      |> Map.put("recommended_branch_id", alternate_recommended_branch_id)
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("selected", row["branch_id"] == alternate_recommended_branch_id)
          |> Map.put(
            "score_delta_from_recommended",
            row["score"] - alternate_recommended_score
          )
        end)
      end)

    invalid_cases = [
      {"$.branch_comparison_report.rows", reordered},
      {"$.branch_comparison_report.recommended_branch_id",
       Map.put(strategy, "branch_comparison_report", alternate_report)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy branch comparison target identity drift", %{
    strategy: strategy
  } do
    for field <- ~w(target_branch_base_id target_branch_identity) do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          "drift"
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison event summary drift", %{
    strategy: strategy
  } do
    row_path = ["branch_comparison_report", "rows", Access.at(1)]

    count_drift =
      strategy
      |> put_in(row_path ++ ["branch_event_count"], 2)
      |> put_in(
        row_path ++ ["branch_event_trust_boundary_status_counts"],
        %{"missing" => 2}
      )

    invalid_cases = [
      {"branch_event_count", count_drift},
      {"branch_event_types",
       put_in(strategy, row_path ++ ["branch_event_types"], ["ground_station_outage"])},
      {"branch_event_trust_boundary_status_counts",
       put_in(
         strategy,
         row_path ++ ["branch_event_trust_boundary_status_counts"],
         %{"declared" => 1}
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison event temporal envelope drift", %{
    strategy: strategy
  } do
    outage_index =
      Enum.find_index(
        strategy["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "operator_station_outage")
      )

    for {field, drift} <- [
          {"branch_earliest_starts_at_s", 700.0},
          {"branch_latest_ends_at_s", 1700.0}
        ] do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(outage_index), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] ==
                   "$.branch_comparison_report.rows[#{outage_index}].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison event routing context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "branch_station_availabilities" => ["reserved"],
      "branch_station_contention_statuses" => ["reserved_overlap"],
      "branch_ground_station_ids" => ["equator_prime"],
      "branch_directions" => ["uplink"]
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

  test "rejects CampaignStrategy branch comparison station calendar context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "branch_station_calendar_entry_ids" => ["entry"],
      "branch_station_calendar_provider_ids" => ["provider"],
      "branch_station_calendar_provider_entry_ids" => ["provider_entry"],
      "branch_station_calendar_directions" => ["uplink"],
      "branch_station_calendar_statuses" => ["reserved"],
      "branch_station_calendar_trust_boundary_statuses" => ["declared"]
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

  test "rejects CampaignStrategy branch comparison station reservation context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "branch_station_reservation_ids" => ["reservation"],
      "branch_station_reserved_by" => ["team"],
      "branch_station_reservation_statuses" => ["confirmed"],
      "branch_station_reservation_match_statuses" => ["unmatched_overlap"],
      "branch_station_reservation_expiration_statuses" => ["expired"]
    }

    for {field, drift} <- drift_values do
      source_strategy =
        if field == "branch_station_reservation_expiration_statuses" do
          update_in(
            strategy,
            ["branches", Access.at(1), "events", Access.at(0)],
            &Map.put(&1, "station_reservation_expiration_status", "active")
          )
        else
          strategy
        end

      invalid =
        put_in(
          source_strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end

    pressure_override_invalid =
      strategy
      |> update_in(
        ["branches", Access.at(1), "events", Access.at(0)],
        &Map.put(&1, "station_reservation_expiration_status", "active")
      )
      |> update_in(
        ["branches", Access.at(1), "risk_indicators", Access.at(0)],
        &Map.put(&1, "station_reservation_expiration_status", "expired")
      )
      |> put_in(
        [
          "branch_comparison_report",
          "rows",
          Access.at(1),
          "branch_station_reservation_expiration_statuses"
        ],
        ["active"]
      )

    assert {:error, pressure_override_report} =
             Schema.validate_artifact(pressure_override_invalid)

    assert Enum.any?(
             pressure_override_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[1].branch_station_reservation_expiration_statuses")
           )
  end

  test "rejects CampaignStrategy branch comparison score evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    score_drift =
      strategy
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "score"],
        row["score"] + 1
      )
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "score_delta_from_recommended"],
        row["score_delta_from_recommended"] + 1
      )

    invalid_cases = [
      {"score", score_drift},
      {"raw_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "raw_score"],
         row["raw_score"] + 1
       )},
      {"branch_probability",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "branch_probability"],
         0.5
       )},
      {"expected_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "expected_score"],
         row["expected_score"] + 1
       )},
      {"score_terms",
       update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "score_terms"],
         &Map.update!(&1, "raw_score", fn value -> value + 1 end)
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison operational evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    invalid_cases = [
      {"approval_status",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "approval_status"],
         "auto_approvable"
       )},
      {"risk_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "risk_count"],
         row["risk_count"] + 1
       )},
      {"approval_requirement_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "approval_requirement_count"],
         row["approval_requirement_count"] + 1
       )},
      {"candidate_activity_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "candidate_activity_count"],
         row["candidate_activity_count"] + 1
       )},
      {"repair_delta_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_delta_count"],
         row["repair_delta_count"] + 1
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison risk classification drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "risk_types",
      "high_risk_types",
      "feedback_risk_types",
      "resource_risk_types"
    ]

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["schema_valid_drift" | tl(row[field])]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison feedback evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "feedback_score_adjustment",
      "contact_success_factor",
      "contact_success_factor_source",
      "contact_success_factor_activity_source",
      "observation_success_factor",
      "observation_success_factor_source",
      "observation_success_factor_activity_source",
      "station_throughput_factor",
      "station_throughput_factor_source",
      "station_throughput_factor_activity_source"
    ]

    for field <- fields do
      value = row[field]
      drift = if is_number(value), do: value + 0.01, else: value <> ".schema_valid_drift"

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

  test "rejects CampaignStrategy branch comparison priority commitment drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    put_row = fn artifact, field, value ->
      put_in(
        artifact,
        ["branch_comparison_report", "rows", Access.at(1), field],
        value
      )
    end

    coherent_required_drift =
      strategy
      |> put_row.(
        "priority_commitment_required_target_ids",
        row["priority_commitment_required_target_ids"] ++ ["target_schema_valid_drift"]
      )
      |> put_row.(
        "priority_commitment_required_target_count",
        row["priority_commitment_required_target_count"] + 1
      )

    coherent_satisfied_drift =
      strategy
      |> put_row.(
        "priority_commitment_satisfied_target_ids",
        row["priority_commitment_satisfied_target_ids"] ++ ["target_schema_valid_drift"]
      )
      |> put_row.(
        "priority_commitment_satisfied_target_count",
        row["priority_commitment_satisfied_target_count"] + 1
      )

    coherent_missed_drift =
      strategy
      |> put_row.("priority_commitment_missed_target_ids", ["target_schema_valid_drift"])
      |> put_row.("priority_commitment_missed_target_count", 1)

    invalid_cases = [
      {[
         "priority_commitment_required_target_count",
         "priority_commitment_required_target_ids"
       ], coherent_required_drift},
      {[
         "priority_commitment_satisfied_target_count",
         "priority_commitment_satisfied_target_ids"
       ], coherent_satisfied_drift},
      {[
         "priority_commitment_missed_target_count",
         "priority_commitment_missed_target_ids"
       ], coherent_missed_drift},
      {["priority_commitment_required_target_ids"],
       put_row.(
         strategy,
         "priority_commitment_required_target_ids",
         ["target_schema_valid_drift"]
       )},
      {["priority_commitment_satisfied_target_ids"],
       put_row.(
         strategy,
         "priority_commitment_satisfied_target_ids",
         ["target_schema_valid_drift"]
       )},
      {["priority_commitment_required_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_required_observation_count",
         row["priority_commitment_required_observation_count"] + 1
       )},
      {["priority_commitment_planned_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_planned_observation_count",
         row["priority_commitment_planned_observation_count"] + 1
       )},
      {["priority_commitment_missing_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_missing_observation_count",
         row["priority_commitment_missing_observation_count"] + 1
       )},
      {["priority_commitment_ratio"], put_row.(strategy, "priority_commitment_ratio", 0.99)}
    ]

    for {expected_fields, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      for field <- expected_fields do
        assert Enum.any?(
                 validation_report["errors"],
                 &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
               )
      end
    end
  end

  test "rejects CampaignStrategy branch comparison downlink completion drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "downlink_completion_required_contacts",
      "downlink_completion_planned_contacts",
      "downlink_completion_planned_downlink_mb",
      "downlink_completion_ratio"
    ]

    for field <- fields do
      value = row[field]
      drift = if field == "downlink_completion_ratio", do: 0.1, else: value + 1

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

  test "rejects CampaignStrategy branch comparison coverage and revisit drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    for field <- ["coverage_observed_target_count", "revisit_count"] do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          row[field] + 1
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

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

  test "rejects CampaignStrategy branch comparison repair score evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    coherent_score_term_count_drift =
      strategy
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "repair_score_term_count"],
        row["repair_score_term_count"] + 1
      )
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "repair_score_term_keys"],
        row["repair_score_term_keys"] ++ ["schema_valid_drift"]
      )

    replacement_score_term_keys =
      ["schema_valid_drift" | tl(row["repair_score_term_keys"])]

    invalid_cases = [
      {"repair_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_score"],
         row["repair_score"] + 1
       )},
      {"repair_score_term_count", coherent_score_term_count_drift},
      {"repair_score_term_keys",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_score_term_keys"],
         replacement_score_term_keys
       )},
      {"repair_activity_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_activity_score"],
         row["repair_activity_score"] + 1
       )},
      {"repair_schedule_churn_penalty",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_schedule_churn_penalty"],
         -1
       )},
      {"repair_schedule_move_penalty",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_schedule_move_penalty"],
         -1
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison repair link selection evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "repair_link_contact_count",
      "repair_link_selected_contact_count",
      "repair_link_selected_estimated_throughput_mb",
      "repair_link_selected_capacity_adjusted_throughput_mb"
    ]

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          row[field] + 1
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison repair constraint evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    invalid_cases = [
      {"repair_constraint_count", row["repair_constraint_count"] + 1},
      {"repair_constraint_row_count", row["repair_constraint_row_count"] + 1},
      {"repair_constraint_status", "warning"},
      {"repair_constraint_pass_count", row["repair_constraint_pass_count"] + 1},
      {"repair_constraint_warning_count", row["repair_constraint_warning_count"] + 1},
      {"repair_constraint_fail_count", row["repair_constraint_fail_count"] + 1},
      {"repair_constraint_failed_ids", ["campaign:schema_valid_drift"]},
      {"repair_constraint_warning_ids", ["campaign:schema_valid_drift"]}
    ]

    for {field, value} <- invalid_cases do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          value
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
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

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
