Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceRepairContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase,
    async: true,
    group: :campaign_strategy_produced_surface

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts

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

  test "rejects CampaignStrategy branch comparison repair link completion evidence drift" do
    link_capacity_details = %{
      "required_downlink_mb" => 120.0,
      "selected_downlink_shortfall_mb" => 80.0,
      "downlink_requirement_status" => "shortfall",
      "actual_throughput_mb" => 15.0,
      "actual_downlink_completion_ratio" => 0.25,
      "actual_downlink_shortfall_mb" => 105.0,
      "actual_downlink_requirement_status" => "shortfall"
    }

    row =
      link_capacity_details
      |> Map.new(fn {field, value} -> {"repair_link_#{field}", value} end)
      |> Map.put("branch_id", "branch:repair_link")

    artifact = %{
      "branches" => [
        %{
          "branch_id" => "branch:repair_link",
          "repair_result" => %{"link_capacity_report" => link_capacity_details}
        }
      ],
      "branch_comparison_report" => %{"rows" => [row]}
    }

    assert [] == CampaignStrategyProducedSurfaceContracts.validate([], artifact)

    for {field, value} <- link_capacity_details do
      drift = if is_number(value), do: value + 1.0, else: "schema_valid_drift"
      row_field = "repair_link_#{field}"

      invalid =
        put_in(
          artifact,
          ["branch_comparison_report", "rows", Access.at(0), row_field],
          drift
        )

      issues = CampaignStrategyProducedSurfaceContracts.validate([], invalid)

      assert Enum.any?(
               issues,
               &(&1["path"] == "$.branch_comparison_report.rows[0].#{row_field}" and
                   &1["message"] ==
                     "must match the enclosing branch repair link_capacity_report.#{field}")
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
end
