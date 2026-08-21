Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContactContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.Schema

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

  test "rejects CampaignStrategy branch comparison combined source-branch drift", %{
    strategy: strategy
  } do
    row_index =
      Enum.find_index(
        strategy["branch_comparison_report"]["rows"],
        &Map.has_key?(&1, "combined_source_branch_ids")
      )

    invalid =
      update_in(
        strategy,
        [
          "branch_comparison_report",
          "rows",
          Access.at(row_index),
          "combined_source_branch_ids"
        ],
        &(&1 ++ ["stale_source_branch"])
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{row_index}].combined_source_branch_ids")
           )
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

  test "rejects CampaignStrategy branch comparison station reservation conflict drift", %{
    strategy: strategy
  } do
    conflict_fields = [
      "branch_station_reservation_conflict_contact_ids",
      "branch_station_reservation_conflict_reservation_ids",
      "branch_station_reservation_conflict_match_statuses"
    ]

    event_fallback_invalid =
      strategy
      |> update_in(
        ["branches", Access.at(1), "events", Access.at(0)],
        &Map.merge(&1, %{
          "contact_id" => "event_contact",
          "station_reservation_id" => "event_reservation",
          "station_reservation_match_status" => "unmatched-overlap"
        })
      )
      |> put_in(
        [
          "branch_comparison_report",
          "rows",
          Access.at(1),
          "branch_station_reservation_ids"
        ],
        ["event_reservation"]
      )
      |> put_in(
        [
          "branch_comparison_report",
          "rows",
          Access.at(1),
          "branch_station_reservation_match_statuses"
        ],
        ["unmatched-overlap"]
      )
      |> update_in(
        ["branch_comparison_report", "rows", Access.at(1)],
        &Map.merge(&1, %{
          "branch_station_reservation_conflict_contact_ids" => ["invented_contact"],
          "branch_station_reservation_conflict_reservation_ids" => ["invented_reservation"],
          "branch_station_reservation_conflict_match_statuses" => ["matched"]
        })
      )

    assert {:error, event_fallback_report} =
             Schema.validate_artifact(event_fallback_invalid)

    for field <- conflict_fields do
      assert Enum.any?(
               event_fallback_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end

    pressure_branch_index =
      Enum.find_index(
        strategy["branches"],
        &(&1["branch_id"] == "derived_downlink_constrained")
      )

    pressure_risk_index =
      strategy
      |> get_in(["branches", Access.at(pressure_branch_index), "risk_indicators"])
      |> Enum.find_index(&(&1["type"] == "downlink_completion_gap"))

    risk_override_invalid =
      strategy
      |> update_in(
        [
          "branches",
          Access.at(pressure_branch_index),
          "risk_indicators",
          Access.at(pressure_risk_index)
        ],
        &Map.merge(&1, %{
          "contact_id" => "risk_contact",
          "station_reservation_id" => "risk_reservation",
          "station_reservation_match_status" => "matched"
        })
      )
      |> update_in(
        ["branch_comparison_report", "rows", Access.at(pressure_branch_index)],
        &Map.merge(&1, %{
          "branch_station_reservation_conflict_contact_ids" => ["event_contact"],
          "branch_station_reservation_conflict_reservation_ids" => ["event_reservation"],
          "branch_station_reservation_conflict_match_statuses" => ["unmatched_overlap"]
        })
      )

    assert {:error, risk_override_report} = Schema.validate_artifact(risk_override_invalid)

    for field <- conflict_fields do
      assert Enum.any?(
               risk_override_report["errors"],
               &(&1["path"] ==
                   "$.branch_comparison_report.rows[#{pressure_branch_index}].#{field}")
             )
    end
  end

  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy branch comparison event quality context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "branch_image_quality_min_score" => 0.5,
      "branch_image_quality_statuses" => ["marginal"],
      "branch_image_quality_sources" => ["provider"],
      "branch_cloud_cover_max_fraction" => 0.5,
      "branch_blur_max_score" => 0.5
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

  test "rejects CampaignStrategy branch comparison event latency and downlink context drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "branch_max_latency_s" => 1.0,
      "branch_planned_latency_s" => 1.0,
      "branch_required_contacts" => 1,
      "branch_planned_contacts" => 1,
      "branch_required_downlink_mb" => 1.0,
      "branch_planned_downlink_mb" => 1.0,
      "branch_actual_downlink_completion_ratio" => 0.5
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

  test "rejects CampaignStrategy branch comparison capacity-pack aggregate drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "capacity_pack_group_ids" => ["invented_capacity_pack"],
      "capacity_pack_statuses" => ["invented_capacity_pack_status"],
      "capacity_pack_min_capacity_fraction" => 0.5,
      "capacity_pack_max_used_fraction" => 0.5,
      "capacity_pack_max_required_capacity_fraction" => 0.5,
      "capacity_pack_total_required_capacity_fraction" => 0.5,
      "capacity_pack_required_capacity_sources" => ["invented_capacity_source"]
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

  test "rejects CampaignStrategy branch comparison capacity-pack direction-map drift", %{
    strategy: strategy
  } do
    drift_values = %{
      "capacity_pack_contact_ids_by_direction" => %{"invented" => ["invented_contact"]},
      "capacity_pack_selected_contact_ids_by_direction" => %{
        "invented" => ["invented_selected_contact"]
      },
      "capacity_pack_deferred_contact_ids_by_direction" => %{
        "invented" => ["invented_deferred_contact"]
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{"invented" => 1.0},
      "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
        "invented" => 1.0
      },
      "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
        "invented" => 1.0
      }
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

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy operator-review package source drift", %{
    strategy: strategy
  } do
    shadow_strategies = [
      {put_in(strategy, ["recommendation", "reason"], "schema_valid_drift"),
       "campaign_strategy.recommendation"},
      {update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(0), "score"],
         &(&1 + 1)
       ), "campaign_strategy.branch_comparison_report.rows"},
      {update_in(
         strategy,
         ["ranking_comparison_report", "rows", Access.at(0), "right_value"],
         &(&1 + 1)
       ), "campaign_strategy.ranking_comparison_report.rows"},
      {update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "objective_values", "score"],
         &(&1 + 1)
       ), "campaign_strategy.pareto_frontier_report.rows"},
      {update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "value"],
         &(&1 + 1)
       ), "campaign_strategy.score_term_report.rows"},
      {update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       ), "campaign_strategy.objective_tradeoff_report.tradeoffs"},
      {update_in(
         strategy,
         ["branches", Access.at(0), "warnings"],
         &(&1 ++ ["schema valid drift"])
       ), "campaign_strategy.branches.warnings"}
    ]

    for {shadow, source} <- shadow_strategies do
      invalid =
        Map.put(
          strategy,
          "operator_review_package",
          OperatorReview.from_strategy_artifact(shadow)
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(validation_report["errors"], fn issue ->
               String.starts_with?(issue["path"], "$.operator_review_package.rows") and
                 String.contains?(issue["message"], source)
             end)
    end
  end

  test "rejects CampaignStrategy Cadence import manifest source drift", %{
    strategy: strategy
  } do
    shadow_strategies = [
      {put_in(strategy, ["recommendation", "reason"], "schema_valid_drift"),
       "CampaignStrategy recommendation"},
      {update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(0), "score"],
         &(&1 + 1)
       ), "CampaignStrategy branch comparison"},
      {update_in(
         strategy,
         ["ranking_comparison_report", "rows", Access.at(0), "right_value"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "objective_values", "score"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "value"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["branches", Access.at(0), "warnings"],
         &(&1 ++ ["schema valid drift"])
       ), "CampaignStrategy operator-review"}
    ]

    for {shadow, source} <- shadow_strategies do
      shadow =
        Map.put(
          shadow,
          "operator_review_package",
          OperatorReview.from_strategy_artifact(shadow)
        )

      invalid =
        Map.put(
          strategy,
          "cadence_import_manifest",
          CadenceImport.from_strategy_artifact(shadow)
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(validation_report["errors"], fn issue ->
               issue["path"] == "$.cadence_import_manifest.rows" and
                 String.contains?(issue["message"], source)
             end)
    end
  end
end
