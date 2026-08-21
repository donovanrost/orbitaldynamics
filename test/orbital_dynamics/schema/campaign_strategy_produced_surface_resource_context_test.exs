Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceResourceContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

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
