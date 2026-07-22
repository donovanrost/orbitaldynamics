defmodule OrbitalDynamics.Schema.OperatorReviewContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates checked-in operator review package example" do
    package = read_json!("study_results/operator_review_package_v1.json")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert %{
             "source_artifact_type" => "timeline_feedback_report.v1",
             "review_count" => 8,
             "approval_requirement_count" => 1,
             "contention_review_count" => 0,
             "policy_escalation_count" => 1,
             "contact_suppression_count" => 1,
             "resource_projection_review_count" => 1,
             "resource_suppression_count" => 1,
             "command_window_count" => 0,
             "station_calendar_review_count" => 0,
             "link_capacity_review_count" => 1,
             "timeline_diff_count" => 1,
             "maneuver_review_count" => 0,
             "realized_feedback_count" => 1,
             "rows" => [
               %{"review_type" => "approval_requirement"},
               %{
                 "review_type" => "policy_escalation",
                 "required_authority" => "contact_schedule_authority"
               },
               %{
                 "review_type" => "realized_feedback",
                 "activity_id" => "downlink_equator",
                 "throughput_delta_mb" => -48.0
               },
               %{
                 "review_type" => "resource_suppression",
                 "activity_id" => "leo_1_observe_target_a_1",
                 "source_resource_suppression" => %{
                   "suppressed_reason" => "payload_unavailable"
                 }
               },
               %{
                 "review_type" => "resource_projection_review",
                 "spacecraft_id" => "leo_1",
                 "projected_storage_margin" => 0.75,
                 "source_resource_projection" => %{"spacecraft_id" => "leo_1"}
               },
               %{
                 "review_type" => "contact_suppression",
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "source_contact_suppression" => %{
                   "suppressed_reason" => "ground_station_unavailable"
                 }
               },
               %{
                 "review_type" => "link_capacity_review",
                 "ground_station_id" => "equator_prime",
                 "source_link_capacity" => %{"ground_station_id" => "equator_prime"}
               },
               %{
                 "review_type" => "timeline_diff_review",
                 "timeline_id" => "timeline:downlink_equator",
                 "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
                 "source_timeline_diff" => %{
                   "requires_operator_review" => true
                 }
               }
             ]
           } = package

    assert package["rows"]
           |> Enum.find(&(&1["review_type"] == "link_capacity_review"))
           |> Map.fetch!("selected_estimated_throughput_mb") == 0.0

    link_capacity_review_index =
      Enum.find_index(package["rows"], &(&1["review_type"] == "link_capacity_review"))

    invalid_link_capacity_review_capacity_range =
      package
      |> put_in(["rows", Access.at(link_capacity_review_index), "capacity_fraction_min"], -0.1)
      |> put_in(["rows", Access.at(link_capacity_review_index), "capacity_fraction_max"], 1.2)

    assert {:error, link_capacity_review_capacity_range_report} =
             Schema.validate_artifact(invalid_link_capacity_review_capacity_range)

    assert Enum.any?(
             link_capacity_review_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[#{link_capacity_review_index}].capacity_fraction_min")
           )

    assert Enum.any?(
             link_capacity_review_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[#{link_capacity_review_index}].capacity_fraction_max")
           )

    invalid_dependency_id =
      put_in(
        package,
        ["rows", Access.at(2), "dependency_activity_ids"],
        ["dependency with spaces"]
      )

    assert {:error, dependency_id_report} = Schema.validate_artifact(invalid_dependency_id)

    assert Enum.any?(
             dependency_id_report["errors"],
             &(&1["path"] == "$.rows[2].dependency_activity_ids[0]")
           )

    invalid_timeline_link =
      put_in(package, ["rows", Access.at(0), "timeline_link"], %{
        "source_timeline_id" => "timeline with spaces"
      })

    assert {:error, timeline_link_report} = Schema.validate_artifact(invalid_timeline_link)

    assert Enum.any?(
             timeline_link_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_link.source_timeline_id")
           )

    invalid_source_timeline_id =
      put_in(package, ["rows", Access.at(0), "source_timeline_id"], "timeline with spaces")

    assert {:error, source_timeline_id_report} =
             Schema.validate_artifact(invalid_source_timeline_id)

    assert Enum.any?(
             source_timeline_id_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_id")
           )

    invalid_timeline_protection =
      put_in(package, ["rows", Access.at(0), "source_timeline_protection"], %{
        "changed_executed_count" => -1
      })

    assert {:error, timeline_protection_report} =
             Schema.validate_artifact(invalid_timeline_protection)

    assert Enum.any?(
             timeline_protection_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_protection.changed_executed_count")
           )

    invalid_source_window =
      package
      |> put_in(["rows", Access.at(2), "source_window_id"], "window_1")
      |> put_in(["rows", Access.at(2), "source_window"], %{"id" => "window with spaces"})

    assert {:error, source_window_report} = Schema.validate_artifact(invalid_source_window)

    assert Enum.any?(
             source_window_report["errors"],
             &(&1["path"] == "$.rows[2].source_window.id")
           )

    invalid_source_window_lineage =
      package
      |> put_in(["rows", Access.at(2), "source_window_id"], "window_1")
      |> put_in(["rows", Access.at(2), "source_window_lineage"], %{
        "candidate_activity_id" => "activity with spaces",
        "source_window_id" => "window_1",
        "source_window_type" => "downlink",
        "scenario_id" => "leo_1"
      })

    assert {:error, source_window_lineage_report} =
             Schema.validate_artifact(invalid_source_window_lineage)

    assert Enum.any?(
             source_window_lineage_report["errors"],
             &(&1["path"] == "$.rows[2].source_window_lineage.candidate_activity_id")
           )

    invalid_battery_handoff =
      package
      |> put_in(["rows", Access.at(4), "total_battery_energy_consumed_wh"], "twenty")
      |> put_in(["rows", Access.at(4), "source_resource_projection"], %{
        "spacecraft_id" => "leo_1",
        "total_battery_energy_generated_wh" => "five"
      })

    assert {:error, battery_handoff_report} =
             Schema.validate_artifact(invalid_battery_handoff)

    assert Enum.any?(
             battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[4].total_battery_energy_consumed_wh")
           )

    assert Enum.any?(
             battery_handoff_report["errors"],
             &(&1["path"] ==
                 "$.rows[4].source_resource_projection.total_battery_energy_generated_wh")
           )

    invalid_source_delta =
      put_in(package, ["rows", Access.at(0), "source_delta"], %{
        "activity_id" => "activity with spaces",
        "activity_type" => "downlink",
        "status" => "changed",
        "repair_action" => "moved"
      })

    assert {:error, source_delta_report} = Schema.validate_artifact(invalid_source_delta)

    assert Enum.any?(
             source_delta_report["errors"],
             &(&1["path"] == "$.rows[0].source_delta.activity_id")
           )

    invalid_source_requirement =
      put_in(package, ["rows", Access.at(0), "source_requirement", "activity_id"], "bad id")

    assert {:error, source_requirement_report} =
             Schema.validate_artifact(invalid_source_requirement)

    assert Enum.any?(
             source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].source_requirement.activity_id")
           )

    invalid_source_policy_decision =
      put_in(
        package,
        ["rows", Access.at(1), "source_policy_decision", "classification"],
        "maybe"
      )

    assert {:error, source_policy_decision_report} =
             Schema.validate_artifact(invalid_source_policy_decision)

    assert Enum.any?(
             source_policy_decision_report["errors"],
             &(&1["path"] == "$.rows[1].source_policy_decision.classification")
           )

    invalid_source_policy_escalation =
      put_in(
        package,
        ["rows", Access.at(1), "source_policy_escalation", "rule_id"],
        "rule with spaces"
      )

    assert {:error, source_policy_escalation_report} =
             Schema.validate_artifact(invalid_source_policy_escalation)

    assert Enum.any?(
             source_policy_escalation_report["errors"],
             &(&1["path"] == "$.rows[1].source_policy_escalation.rule_id")
           )

    invalid_source_resource_suppression =
      put_in(
        package,
        ["rows", Access.at(3), "source_resource_suppression", "id"],
        "resource suppression with spaces"
      )

    assert {:error, source_resource_suppression_report} =
             Schema.validate_artifact(invalid_source_resource_suppression)

    assert Enum.any?(
             source_resource_suppression_report["errors"],
             &(&1["path"] == "$.rows[3].source_resource_suppression.id")
           )

    invalid_source_contact_suppression =
      put_in(
        package,
        ["rows", Access.at(5), "source_contact_suppression", "source_window_id"],
        "window with spaces"
      )

    assert {:error, source_contact_suppression_report} =
             Schema.validate_artifact(invalid_source_contact_suppression)

    assert Enum.any?(
             source_contact_suppression_report["errors"],
             &(&1["path"] == "$.rows[5].source_contact_suppression.source_window_id")
           )

    invalid_source_resource_projection =
      put_in(
        package,
        ["rows", Access.at(4), "source_resource_projection", "spacecraft_id"],
        "spacecraft with spaces"
      )

    assert {:error, source_resource_projection_report} =
             Schema.validate_artifact(invalid_source_resource_projection)

    assert Enum.any?(
             source_resource_projection_report["errors"],
             &(&1["path"] == "$.rows[4].source_resource_projection.spacecraft_id")
           )

    invalid_source_link_capacity =
      put_in(
        package,
        ["rows", Access.at(6), "source_link_capacity", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_link_capacity_report} =
             Schema.validate_artifact(invalid_source_link_capacity)

    assert Enum.any?(
             source_link_capacity_report["errors"],
             &(&1["path"] == "$.rows[6].source_link_capacity.ground_station_id")
           )

    invalid_source_timeline_diff =
      put_in(
        package,
        ["rows", Access.at(7), "source_timeline_diff", "timeline_id"],
        "timeline with spaces"
      )

    assert {:error, source_timeline_diff_report} =
             Schema.validate_artifact(invalid_source_timeline_diff)

    assert Enum.any?(
             source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[7].source_timeline_diff.timeline_id")
           )

    command_window_row =
      read_json!("study_results/command_window_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_command_window_source =
      put_in(package, ["rows", Access.at(0), "source_command_window"], command_window_row)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_command_window_source)

    invalid_source_command_window =
      put_in(
        package_with_command_window_source,
        ["rows", Access.at(0), "source_command_window", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_command_window_report} =
             Schema.validate_artifact(invalid_source_command_window)

    assert Enum.any?(
             source_command_window_report["errors"],
             &(&1["path"] == "$.rows[0].source_command_window.ground_station_id")
           )

    maneuver_review_row =
      read_json!("study_results/maneuver_review_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_maneuver_review_source =
      put_in(package, ["rows", Access.at(0), "source_maneuver_review"], maneuver_review_row)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_maneuver_review_source)

    invalid_source_maneuver_review =
      put_in(
        package_with_maneuver_review_source,
        ["rows", Access.at(0), "source_maneuver_review", "maneuver_id"],
        "maneuver with spaces"
      )

    assert {:error, source_maneuver_review_report} =
             Schema.validate_artifact(invalid_source_maneuver_review)

    assert Enum.any?(
             source_maneuver_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_maneuver_review.maneuver_id")
           )

    ranking_comparison_row =
      read_json!("study_results/ranking_comparison_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_ranking_comparison_source =
      put_in(
        package,
        ["rows", Access.at(0), "source_ranking_comparison"],
        ranking_comparison_row
      )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_ranking_comparison_source)

    invalid_source_ranking_comparison =
      put_in(
        package_with_ranking_comparison_source,
        ["rows", Access.at(0), "source_ranking_comparison", "scenario_id"],
        "scenario with spaces"
      )

    assert {:error, source_ranking_comparison_report} =
             Schema.validate_artifact(invalid_source_ranking_comparison)

    assert Enum.any?(
             source_ranking_comparison_report["errors"],
             &(&1["path"] == "$.rows[0].source_ranking_comparison.scenario_id")
           )

    contention_group =
      read_json!("study_results/contact_contention_report_v1.json")
      |> Map.fetch!("conflict_groups")
      |> List.first()

    package_with_contention_group_source =
      put_in(package, ["rows", Access.at(0), "source_contention_group"], contention_group)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_contention_group_source)

    invalid_source_contention_group =
      put_in(
        package_with_contention_group_source,
        ["rows", Access.at(0), "source_contention_group", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_contention_group_report} =
             Schema.validate_artifact(invalid_source_contention_group)

    assert Enum.any?(
             source_contention_group_report["errors"],
             &(&1["path"] == "$.rows[0].source_contention_group.ground_station_id")
           )

    station_calendar_contact =
      read_json!("study_results/station_calendar_report_v1.json")
      |> Map.fetch!("affected_contacts")
      |> List.first()

    package_with_station_calendar_source =
      put_in(
        package,
        ["rows", Access.at(0), "source_station_calendar_review"],
        station_calendar_contact
      )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_station_calendar_source)

    invalid_source_station_calendar_review =
      put_in(
        package_with_station_calendar_source,
        ["rows", Access.at(0), "source_station_calendar_review", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_station_calendar_review_report} =
             Schema.validate_artifact(invalid_source_station_calendar_review)

    assert Enum.any?(
             source_station_calendar_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_review.ground_station_id")
           )

    invalid_required_scalar_count = Map.put(package, "review_count", 8.0)

    assert {:error, required_scalar_count_report} =
             Schema.validate_artifact(invalid_required_scalar_count)

    assert Enum.any?(
             required_scalar_count_report["errors"],
             &(&1["path"] == "$.review_count")
           )

    invalid_optional_scalar_count = Map.put(package, "command_window_count", 1.0)

    assert {:error, optional_scalar_count_report} =
             Schema.validate_artifact(invalid_optional_scalar_count)

    assert Enum.any?(
             optional_scalar_count_report["errors"],
             &(&1["path"] == "$.command_window_count")
           )

    invalid_negative_scalar_count = Map.put(package, "link_capacity_review_count", -1)

    assert {:error, negative_scalar_count_report} =
             Schema.validate_artifact(invalid_negative_scalar_count)

    assert Enum.any?(
             negative_scalar_count_report["errors"],
             &(&1["path"] == "$.link_capacity_review_count")
           )

    invalid_row_contact_count =
      put_in(package, ["rows", Access.at(6), "contact_count"], 1.0)

    assert {:error, row_contact_count_report} =
             Schema.validate_artifact(invalid_row_contact_count)

    assert Enum.any?(
             row_contact_count_report["errors"],
             &(&1["path"] == "$.rows[6].contact_count")
           )

    invalid_row_observation_count =
      put_in(package, ["rows", Access.at(4), "observation_count"], -1)

    assert {:error, row_observation_count_report} =
             Schema.validate_artifact(invalid_row_observation_count)

    assert Enum.any?(
             row_observation_count_report["errors"],
             &(&1["path"] == "$.rows[4].observation_count")
           )

    invalid_row_overlap_count =
      package
      |> put_in(["rows", Access.at(0), "max_concurrent_contacts"], 1.0)
      |> put_in(["rows", Access.at(0), "overlap_contact_pair_count"], -1)

    assert {:error, row_overlap_count_report} =
             Schema.validate_artifact(invalid_row_overlap_count)

    assert Enum.any?(
             row_overlap_count_report["errors"],
             &(&1["path"] == "$.rows[0].max_concurrent_contacts")
           )

    assert Enum.any?(
             row_overlap_count_report["errors"],
             &(&1["path"] == "$.rows[0].overlap_contact_pair_count")
           )

    invalid_row_activity_count =
      put_in(package, ["rows", Access.at(4), "effective_activity_count"], 1.0)

    assert {:error, row_activity_count_report} =
             Schema.validate_artifact(invalid_row_activity_count)

    assert Enum.any?(
             row_activity_count_report["errors"],
             &(&1["path"] == "$.rows[4].effective_activity_count")
           )

    invalid_row_resource_flow_count =
      put_in(package, ["rows", Access.at(4), "resource_flow_count"], -1)

    assert {:error, row_resource_flow_count_report} =
             Schema.validate_artifact(invalid_row_resource_flow_count)

    assert Enum.any?(
             row_resource_flow_count_report["errors"],
             &(&1["path"] == "$.rows[4].resource_flow_count")
           )

    invalid_source_feedback =
      put_in(
        package,
        ["rows", Access.at(2), "source_feedback", "activity_id"],
        "activity with spaces"
      )

    assert {:error, source_feedback_report} = Schema.validate_artifact(invalid_source_feedback)

    assert Enum.any?(
             source_feedback_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.activity_id")
           )

    invalid_source_feedback_factor =
      put_in(package, ["rows", Access.at(2), "source_feedback", "contact_success_factor"], 1.5)

    assert {:error, source_feedback_factor_report} =
             Schema.validate_artifact(invalid_source_feedback_factor)

    assert Enum.any?(
             source_feedback_factor_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.contact_success_factor")
           )

    invalid_source_feedback_quality =
      put_in(package, ["rows", Access.at(2), "source_feedback", "blur_score"], 1.5)

    assert {:error, source_feedback_quality_report} =
             Schema.validate_artifact(invalid_source_feedback_quality)

    assert Enum.any?(
             source_feedback_quality_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.blur_score")
           )

    invalid_row_quality_fraction =
      put_in(package, ["rows", Access.at(2), "realized_cloud_cover_fraction"], 1.2)

    assert {:error, row_quality_fraction_report} =
             Schema.validate_artifact(invalid_row_quality_fraction)

    assert Enum.any?(
             row_quality_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].realized_cloud_cover_fraction")
           )

    invalid_row_image_quality_score =
      package
      |> put_in(["rows", Access.at(2), "image_quality_score"], 1.2)
      |> put_in(["rows", Access.at(2), "planned_image_quality_score"], -0.1)

    assert {:error, row_image_quality_score_report} =
             Schema.validate_artifact(invalid_row_image_quality_score)

    assert Enum.any?(
             row_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[2].image_quality_score")
           )

    assert Enum.any?(
             row_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[2].planned_image_quality_score")
           )

    invalid_row_observation_quality_handoff =
      package
      |> put_in(["rows", Access.at(2), "cloud_cover_fraction_delta"], "more")
      |> put_in(["rows", Access.at(2), "blur_score_delta"], "blurrier")
      |> put_in(["rows", Access.at(2), "planned_image_quality_status"], 42)
      |> put_in(["rows", Access.at(2), "image_quality_source"], 42)

    assert {:error, row_observation_quality_handoff_report} =
             Schema.validate_artifact(invalid_row_observation_quality_handoff)

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].cloud_cover_fraction_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].blur_score_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_image_quality_status")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].image_quality_source")
           )

    invalid_row_feedback_maneuver_handoff =
      package
      |> put_in(["rows", Access.at(2), "feedback_weight"], -0.1)
      |> put_in(["rows", Access.at(2), "feedback_weight_source"], 42)
      |> put_in(["rows", Access.at(2), "maneuver_success"], "yes")
      |> put_in(["rows", Access.at(2), "maneuver_result"], 42)
      |> put_in(["rows", Access.at(2), "maneuver_success_factor"], 1.2)
      |> put_in(["rows", Access.at(2), "maneuver_success_factor_source"], 42)

    assert {:error, row_feedback_maneuver_handoff_report} =
             Schema.validate_artifact(invalid_row_feedback_maneuver_handoff)

    for field <- [
          "feedback_weight",
          "feedback_weight_source",
          "maneuver_success",
          "maneuver_result",
          "maneuver_success_factor",
          "maneuver_success_factor_source"
        ] do
      assert Enum.any?(
               row_feedback_maneuver_handoff_report["errors"],
               &(&1["path"] == "$.rows[2].#{field}")
             )
    end

    invalid_row_completion_fraction =
      package
      |> put_in(["rows", Access.at(2), "completed_fraction"], 1.2)
      |> put_in(["rows", Access.at(2), "throughput_completion_fraction"], -0.1)

    assert {:error, row_completion_fraction_report} =
             Schema.validate_artifact(invalid_row_completion_fraction)

    assert Enum.any?(
             row_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].completed_fraction")
           )

    assert Enum.any?(
             row_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].throughput_completion_fraction")
           )

    invalid_row_eclipse_overlap_fraction =
      package
      |> put_in(["rows", Access.at(2), "eclipse_overlap_fraction"], 1.2)
      |> put_in(["rows", Access.at(2), "planned_eclipse_overlap_fraction"], -0.1)

    assert {:error, row_eclipse_overlap_fraction_report} =
             Schema.validate_artifact(invalid_row_eclipse_overlap_fraction)

    assert Enum.any?(
             row_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].eclipse_overlap_fraction")
           )

    assert Enum.any?(
             row_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].planned_eclipse_overlap_fraction")
           )

    invalid_row_eclipse_lighting_handoff =
      package
      |> put_in(["rows", Access.at(2), "eclipse_overlap_s"], "long")
      |> put_in(["rows", Access.at(2), "planned_lighting_condition"], 42)
      |> put_in(["rows", Access.at(2), "lighting_confidence"], %{"label" => "high"})

    assert {:error, row_eclipse_lighting_handoff_report} =
             Schema.validate_artifact(invalid_row_eclipse_lighting_handoff)

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].eclipse_overlap_s")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_lighting_condition")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].lighting_confidence")
           )

    invalid_row_link_error_rate =
      package
      |> put_in(["rows", Access.at(2), "bit_error_rate"], 1.2)
      |> put_in(["rows", Access.at(2), "realized_packet_loss_rate"], -0.1)

    assert {:error, row_link_error_rate_report} =
             Schema.validate_artifact(invalid_row_link_error_rate)

    assert Enum.any?(
             row_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[2].bit_error_rate")
           )

    assert Enum.any?(
             row_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[2].realized_packet_loss_rate")
           )

    invalid_row_link_handoff =
      package
      |> put_in(["rows", Access.at(2), "frequency_band"], 42)
      |> put_in(["rows", Access.at(2), "planned_link_margin_db"], "cold")
      |> put_in(["rows", Access.at(2), "realized_carrier_lock"], "lost")

    assert {:error, row_link_handoff_report} =
             Schema.validate_artifact(invalid_row_link_handoff)

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].frequency_band")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_link_margin_db")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].realized_carrier_lock")
           )

    invalid_row_attitude_confidence =
      put_in(package, ["rows", Access.at(2), "attitude_confidence"], 1.2)

    assert {:error, row_attitude_confidence_report} =
             Schema.validate_artifact(invalid_row_attitude_confidence)

    assert Enum.any?(
             row_attitude_confidence_report["errors"],
             &(&1["path"] == "$.rows[2].attitude_confidence")
           )

    invalid_row_thermal_handoff =
      package
      |> put_in(["rows", Access.at(2), "thermal_zone_id"], "payload deck")
      |> put_in(["rows", Access.at(2), "thermal_confidence"], 1.2)

    assert {:error, row_thermal_handoff_report} =
             Schema.validate_artifact(invalid_row_thermal_handoff)

    assert Enum.any?(
             row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].thermal_zone_id")
           )

    assert Enum.any?(
             row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].thermal_confidence")
           )

    invalid_review_counts =
      put_in(package, ["required_operator_action_counts", "review_contact_variance"], 99)

    assert {:error, review_counts_report} = Schema.validate_artifact(invalid_review_counts)

    assert Enum.any?(
             review_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    invalid_negative_review_counts =
      put_in(package, ["review_type_counts", "realized_feedback"], -1)

    assert {:error, negative_review_counts_report} =
             Schema.validate_artifact(invalid_negative_review_counts)

    assert Enum.any?(
             negative_review_counts_report["errors"],
             &(&1["path"] == "$.review_type_counts.realized_feedback")
           )

    for {field, key, counts} <- [
          {"calendar_entry_trust_boundary_status_counts", "declared", %{"declared" => -1}},
          {"station_reservation_match_status_counts", "overlap", %{"overlap" => -1}},
          {"station_reservation_expiration_status_counts", "declared", %{"declared" => -1}},
          {"resource_blocking_dimension_counts", "antenna", %{"antenna" => -1}},
          {"gate_status_counts", "review_required", %{"review_required" => -1}},
          {"gate_classification_counts", "review_only", %{"review_only" => -1}},
          {"required_capacity_fraction_source_counts", "capacity_model",
           %{"capacity_model" => -1}},
          {"provider_reservation_request_status_counts", "review_required",
           %{"review_required" => -1}},
          {"reduced_capacity_pack_status_counts", "capacity_limited",
           %{"capacity_limited" => -1}},
          {"station_pressure_contact_counts_by_availability", "reserved", %{"reserved" => -1}}
        ] do
      invalid_lifted_summary_counts = Map.put(package, field, counts)

      assert {:error, lifted_summary_counts_report} =
               Schema.validate_artifact(invalid_lifted_summary_counts)

      assert Enum.any?(
               lifted_summary_counts_report["errors"],
               &(&1["path"] == "$.#{field}.#{key}")
             )
    end

    invalid_provider_request_status =
      Map.put(package, "provider_reservation_request_status_counts", %{
        "request_dispatched" => 1
      })

    assert {:error, invalid_provider_request_status_report} =
             Schema.validate_artifact(invalid_provider_request_status)

    assert Enum.any?(
             invalid_provider_request_status_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_status_counts")
           )

    invalid_resource_blocked_ids =
      Map.put(package, "resource_blocked_contact_ids_by_blocking_dimension", %{
        "antenna" => ["bad id"]
      })

    assert {:error, resource_blocked_ids_report} =
             Schema.validate_artifact(invalid_resource_blocked_ids)

    assert Enum.any?(
             resource_blocked_ids_report["errors"],
             &(&1["path"] ==
                 "$.resource_blocked_contact_ids_by_blocking_dimension.antenna[0]")
           )

    invalid_station_pressure_ids =
      Map.put(package, "station_pressure_contact_ids_by_availability", %{
        "reserved" => ["bad id"]
      })

    assert {:error, station_pressure_ids_report} =
             Schema.validate_artifact(invalid_station_pressure_ids)

    assert Enum.any?(
             station_pressure_ids_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_availability.reserved[0]")
           )

    invalid_station_reservation_routing_ids =
      Map.put(package, "station_reservation_ids_by_match_status", %{
        "overlap" => ["bad id"]
      })

    assert {:error, station_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_station_reservation_routing_ids)

    assert Enum.any?(
             station_reservation_routing_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids_by_match_status.overlap[0]")
           )

    invalid_quality_gate_count =
      Map.put(package, "gate_count", -1)

    assert {:error, quality_gate_count_report} =
             Schema.validate_artifact(invalid_quality_gate_count)

    assert Enum.any?(
             quality_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    invalid_quality_gate_ids =
      Map.put(package, "review_required_gate_ids", ["bad id"])

    assert {:error, quality_gate_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_ids)

    assert Enum.any?(
             quality_gate_ids_report["errors"],
             &(&1["path"] == "$.review_required_gate_ids[0]")
           )

    invalid_quality_gate_routing_ids =
      Map.put(package, "quality_gate_row_ids_by_status", %{
        "review_required" => ["bad id"]
      })

    assert {:error, quality_gate_routing_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_routing_ids)

    assert Enum.any?(
             quality_gate_routing_ids_report["errors"],
             &(&1["path"] == "$.quality_gate_row_ids_by_status.review_required[0]")
           )

    invalid_capacity_pack_group_ids =
      Map.put(package, "capacity_pack_group_ids", ["bad id"])

    assert {:error, capacity_pack_group_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids)

    assert Enum.any?(
             capacity_pack_group_ids_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids[0]")
           )

    invalid_capacity_pack_group_ids_by_status =
      Map.put(package, "capacity_pack_group_ids_by_status", %{
        "capacity_limited" => ["bad id"]
      })

    assert {:error, capacity_pack_group_ids_by_status_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids_by_status)

    assert Enum.any?(
             capacity_pack_group_ids_by_status_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids_by_status.capacity_limited[0]")
           )

    invalid_required_capacity_source_ids =
      Map.put(package, "required_capacity_fraction_contact_ids_by_source", %{
        "capacity_model" => ["bad id"]
      })

    assert {:error, required_capacity_source_ids_report} =
             Schema.validate_artifact(invalid_required_capacity_source_ids)

    assert Enum.any?(
             required_capacity_source_ids_report["errors"],
             &(&1["path"] ==
                 "$.required_capacity_fraction_contact_ids_by_source.capacity_model[0]")
           )

    invalid_provider_reservation_count =
      Map.put(package, "provider_reservation_request_contact_count", -1)

    assert {:error, provider_reservation_count_report} =
             Schema.validate_artifact(invalid_provider_reservation_count)

    assert Enum.any?(
             provider_reservation_count_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_count")
           )

    invalid_provider_reservation_ids =
      Map.put(package, "provider_reservation_request_contact_ids", ["bad id"])

    assert {:error, provider_reservation_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_ids)

    assert Enum.any?(
             provider_reservation_ids_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids[0]")
           )

    invalid_provider_reservation_routing_ids =
      Map.put(package, "provider_reservation_request_ids_by_match_status", %{
        "matched" => ["bad id"]
      })

    assert {:error, provider_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_routing_ids)

    assert Enum.any?(
             provider_reservation_routing_ids_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_ids_by_match_status.matched[0]")
           )

    noncanonical_provider_reservation_routing_ids =
      Map.put(package, "provider_reservation_review_ids_by_match_status", %{
        "overlap" => ["reservation_z", "reservation_a", "reservation_z"]
      })

    assert {:error, noncanonical_provider_reservation_routing_ids_report} =
             Schema.validate_artifact(noncanonical_provider_reservation_routing_ids)

    assert Enum.any?(
             noncanonical_provider_reservation_routing_ids_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_review_ids_by_match_status.overlap")
           )

    invalid_provider_reservation_direction_station_ids =
      Map.put(
        package,
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        %{
          "downlink" => %{"equator_prime" => ["bad id"]}
        }
      )

    assert {:error, provider_reservation_direction_station_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_direction_station_ids)

    assert Enum.any?(
             provider_reservation_direction_station_ids_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_request_contact_ids_by_direction_and_ground_station_id.downlink.equator_prime[0]")
           )

    invalid_capacity_pack_demand =
      Map.put(package, "capacity_pack_required_capacity_fraction", -1.0)

    assert {:error, capacity_pack_demand_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand)

    assert Enum.any?(
             capacity_pack_demand_report["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction")
           )

    invalid_capacity_pack_demand_map =
      Map.put(package, "capacity_pack_required_capacity_fraction_by_status", %{
        "selected_by_reduced_station_capacity_pack" => -1.0
      })

    assert {:error, capacity_pack_demand_map_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand_map)

    assert Enum.any?(
             capacity_pack_demand_map_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_required_capacity_fraction_by_status.selected_by_reduced_station_capacity_pack")
           )

    invalid_capacity_pack_contact_ids =
      Map.put(package, "capacity_pack_contact_ids_by_status", %{
        "selected_by_reduced_station_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_contact_ids)

    assert Enum.any?(
             capacity_pack_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_contact_ids_by_status.selected_by_reduced_station_capacity_pack[0]")
           )

    invalid_capacity_pack_station_contact_ids =
      Map.put(package, "capacity_pack_selected_contact_ids_by_ground_station_id", %{
        "gs_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_station_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_station_contact_ids)

    assert Enum.any?(
             capacity_pack_station_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_selected_contact_ids_by_ground_station_id.gs_capacity_pack[0]")
           )

    invalid_reduced_capacity_packed_ids =
      Map.put(package, "reduced_capacity_packed_contact_ids", ["bad id"])

    assert {:error, reduced_capacity_packed_ids_report} =
             Schema.validate_artifact(invalid_reduced_capacity_packed_ids)

    assert Enum.any?(
             reduced_capacity_packed_ids_report["errors"],
             &(&1["path"] == "$.reduced_capacity_packed_contact_ids[0]")
           )
  end

  test "correlates provider-reservation contact and reservation match-status routes" do
    package = read_json!("study_results/operator_review_package_v1.json")

    contact_only =
      Map.put(package, "provider_reservation_request_contact_ids_by_match_status", %{
        "matched" => ["contact_a"]
      })

    assert {:ok, _package} = Schema.validate_artifact(contact_only)

    aligned_routes =
      Map.merge(package, %{
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["contact_a"],
          "owner_matched" => []
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["reservation_a"],
          "owner_matched" => ["reservation_owner"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(aligned_routes)

    overlap_request_routes =
      Map.merge(package, %{
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "overlap" => ["contact_a"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "overlap" => ["reservation_a"]
        }
      })

    assert {:error, overlap_request_routes_report} =
             Schema.validate_artifact(overlap_request_routes)

    for field <- [
          "provider_reservation_request_contact_ids_by_match_status",
          "provider_reservation_request_ids_by_match_status"
        ] do
      assert Enum.any?(
               overlap_request_routes_report["errors"],
               &(&1["path"] == "$.#{field}")
             )
    end

    unsupported_routes =
      Map.merge(package, %{
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "provider_review" => ["contact_a"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "provider_review" => ["reservation_a"]
        }
      })

    assert {:error, unsupported_routes_report} = Schema.validate_artifact(unsupported_routes)

    for field <- [
          "provider_reservation_request_contact_ids_by_match_status",
          "provider_reservation_request_ids_by_match_status"
        ] do
      assert Enum.any?(
               unsupported_routes_report["errors"],
               &(&1["path"] == "$.#{field}")
             )
    end

    mismatched_routes =
      Map.merge(package, %{
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["contact_a"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "owner_matched" => ["reservation_owner"]
        }
      })

    assert {:error, mismatched_routes_report} = Schema.validate_artifact(mismatched_routes)

    assert Enum.any?(
             mismatched_routes_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_ids_by_match_status")
           )
  end

  test "correlates provider-reservation status observations with contact evidence" do
    package = read_json!("study_results/operator_review_package_v1.json")

    for {status, contact_count_field} <- [
          {"request_ready", "provider_reservation_request_contact_count"},
          {"review_required", "provider_reservation_review_contact_count"}
        ] do
      legacy_status_only =
        Map.put(package, "provider_reservation_request_status_counts", %{
          "clear" => 1,
          status => 1
        })

      assert {:ok, _package} = Schema.validate_artifact(legacy_status_only)

      assert {:ok, _package} =
               legacy_status_only
               |> Map.put(contact_count_field, 1)
               |> Schema.validate_artifact()

      invalid_zero_evidence = Map.put(legacy_status_only, contact_count_field, 0)

      assert {:error, invalid_zero_evidence_report} =
               Schema.validate_artifact(invalid_zero_evidence)

      assert Enum.any?(
               invalid_zero_evidence_report["errors"],
               &(&1["path"] == "$.#{contact_count_field}")
             )
    end
  end

  test "preserves multi-window bounds on strategy comparison handoffs" do
    package = read_json!("study_results/operator_review_package_v1.json")

    source_window_bounds = [
      %{"source_window_id" => "window_a", "earliest_starts_at_s" => 100.0},
      %{"source_window_id" => "window_b", "latest_ends_at_s" => 200.0}
    ]

    strategy_tradeoff_row =
      package["rows"]
      |> hd()
      |> Map.merge(%{
        "review_type" => "strategy_tradeoff",
        "branch_source_window_ids" => ["window_a", "window_b", "window_c"],
        "branch_source_window_count" => 3,
        "branch_source_window_bounds" => source_window_bounds,
        "branch_source_window_bound_count" => 2,
        "branch_untimed_source_window_ids" => ["window_c"],
        "branch_untimed_source_window_count" => 1,
        "source_branch_comparison" => %{
          "branch_source_window_ids" => ["window_a", "window_b", "window_c"],
          "branch_source_window_count" => 3,
          "branch_source_window_bounds" => source_window_bounds,
          "branch_source_window_bound_count" => 2,
          "branch_untimed_source_window_ids" => ["window_c"],
          "branch_untimed_source_window_count" => 1
        }
      })

    strategy_package =
      package
      |> put_in(["rows", Access.at(0)], strategy_tradeoff_row)
      |> Map.put("approval_requirement_count", 0)
      |> Map.delete("tradeoff_count")
      |> Map.delete("review_type_counts")

    assert {:ok, _strategy_package} = Schema.validate_artifact(strategy_package)

    for field <- [
          "branch_source_window_count",
          "branch_source_window_bound_count",
          "branch_untimed_source_window_ids",
          "branch_untimed_source_window_count"
        ] do
      missing_coverage_field =
        update_in(
          strategy_package,
          ["rows", Access.at(0)],
          &Map.delete(&1, field)
        )

      assert {:error, missing_coverage_field_report} =
               Schema.validate_artifact(missing_coverage_field)

      assert Enum.any?(
               missing_coverage_field_report["errors"],
               &(&1["path"] == "$.rows[0].#{field}")
             )
    end

    missing_window_bounds =
      update_in(
        strategy_package,
        ["rows", Access.at(0)],
        &Map.delete(&1, "branch_source_window_bounds")
      )

    assert {:error, missing_window_bounds_report} =
             Schema.validate_artifact(missing_window_bounds)

    assert Enum.any?(
             missing_window_bounds_report["errors"],
             &(&1["path"] == "$.rows[0].branch_source_window_bounds")
           )

    stale_window_bounds =
      put_in(
        strategy_package,
        ["rows", Access.at(0), "branch_source_window_bounds", Access.at(1), "latest_ends_at_s"],
        201.0
      )

    assert {:error, stale_window_bounds_report} = Schema.validate_artifact(stale_window_bounds)

    assert Enum.any?(
             stale_window_bounds_report["errors"],
             &(&1["path"] == "$.rows[0].branch_source_window_bounds")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
