Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContactQualityContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

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
end
