defmodule OrbitalDynamics.CadenceImportWrappedLinkCapacityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped link-capacity reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_link_capacity_import:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "model" => "fixed_rate_downlink_capacity_summary",
          "rows" => [
            %{
              "ground_station_id" => "equator_prime",
              "contact_count" => 2,
              "ignored_contact_count" => 1,
              "ignored_contact_ids" => ["dl_rejected"],
              "selected_contact_count" => 1,
              "selected_contact_ids" => ["dl_selected"],
              "estimated_throughput_mb" => 160.0,
              "selected_estimated_throughput_mb" => 100.0,
              "capacity_adjusted_throughput_mb" => 128.0,
              "selected_capacity_adjusted_throughput_mb" => 80.0,
              "unused_capacity_adjusted_throughput_mb" => 48.0,
              "selected_downlink_shortfall_mb" => 40.0,
              "downlink_requirement_status" => "shortfall",
              "actual_throughput_mb" => 72.0,
              "actual_downlink_shortfall_mb" => 48.0,
              "actual_downlink_requirement_status" => "shortfall",
              "capacity_fraction_min" => 0.5,
              "capacity_fraction_max" => 0.8,
              "contact_ids" => ["dl_selected", "dl_rejected"],
              "approval_status" => "operator_review_required",
              "approval_requirements" => [
                %{
                  "activity_id" => "link_capacity:equator_prime",
                  "activity_type" => "link_capacity_summary",
                  "action" => "review_link_capacity_summary",
                  "requirement_type" => "contact_schedule_change"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "policy_bundle_id" => "ground_network_allocation_v1"
              }
            }
          ]
        }
      }
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_link_capacity_import:001",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_link_capacity" => 1},
             "source_review_type_counts" => %{"link_capacity_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_link_capacity",
               "source_review_type" => "link_capacity_review",
               "source_review_action" => "review_link_capacity_summary",
               "import_status" => "review_required_before_import",
               "approval_status" => "operator_review_required",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "contact_count" => 2,
               "ignored_contact_count" => 1,
               "ignored_contact_ids" => ["dl_rejected"],
               "selected_contact_count" => 1,
               "selected_contact_ids" => ["dl_selected"],
               "selected_capacity_adjusted_throughput_mb" => 80.0,
               "unused_capacity_adjusted_throughput_mb" => 48.0,
               "selected_downlink_shortfall_mb" => 40.0,
               "downlink_requirement_status" => "shortfall",
               "actual_throughput_mb" => 72.0,
               "actual_downlink_shortfall_mb" => 48.0,
               "actual_downlink_requirement_status" => "shortfall",
               "capacity_fraction_min" => 0.5,
               "capacity_fraction_max" => 0.8,
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "has_cadence_import" => false,
               "source_link_capacity" => %{
                 "ground_station_id" => "equator_prime",
                 "selected_downlink_shortfall_mb" => 40.0,
                 "policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 }
               },
               "source_review_row" => %{
                 "source" => "candidate_refresh.source_result_artifact.link_capacity_report.rows",
                 "review_type" => "link_capacity_review",
                 "source_link_capacity" => %{
                   "ground_station_id" => "equator_prime",
                   "actual_downlink_shortfall_mb" => 48.0
                 },
                 "source_policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves list-wrapped link-capacity reports" do
    source_row = %{
      "ground_station_id" => "polar_prime",
      "contact_count" => 3,
      "ignored_contact_count" => 1,
      "ignored_contact_ids" => ["dl_low_priority"],
      "selected_contact_count" => 2,
      "selected_contact_ids" => ["dl_primary", "dl_backup"],
      "estimated_throughput_mb" => 210.0,
      "selected_estimated_throughput_mb" => 150.0,
      "capacity_adjusted_throughput_mb" => 168.0,
      "selected_capacity_adjusted_throughput_mb" => 120.0,
      "unused_capacity_adjusted_throughput_mb" => 18.0,
      "selected_downlink_shortfall_mb" => 30.0,
      "downlink_requirement_status" => "shortfall",
      "actual_throughput_mb" => 96.0,
      "actual_downlink_shortfall_mb" => 54.0,
      "actual_downlink_requirement_status" => "shortfall",
      "capacity_fraction_min" => 0.6,
      "capacity_fraction_max" => 0.8,
      "contact_ids" => ["dl_primary", "dl_backup", "dl_low_priority"],
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "activity_id" => "link_capacity:polar_prime",
          "activity_type" => "link_capacity_summary",
          "action" => "review_link_capacity_summary",
          "requirement_type" => "contact_schedule_change"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "polar_link_capacity_guard_v1"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:list_wrapped_link_capacity_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "link_capacity_report" => %{
            "schema_contract" => "link_capacity_report.v1",
            "model" => "fixed_rate_downlink_capacity_summary",
            "rows" => [source_row]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:list_wrapped_link_capacity_import:001",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_link_capacity" => 1},
             "source_review_type_counts" => %{"link_capacity_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_link_capacity",
               "source_review_type" => "link_capacity_review",
               "source_review_action" => "review_link_capacity_summary",
               "import_status" => "review_required_before_import",
               "approval_status" => "operator_review_required",
               "subject_id" => "polar_prime",
               "ground_station_id" => "polar_prime",
               "contact_count" => 3,
               "ignored_contact_count" => 1,
               "ignored_contact_ids" => ["dl_low_priority"],
               "selected_contact_count" => 2,
               "selected_contact_ids" => ["dl_primary", "dl_backup"],
               "selected_capacity_adjusted_throughput_mb" => 120.0,
               "unused_capacity_adjusted_throughput_mb" => 18.0,
               "selected_downlink_shortfall_mb" => 30.0,
               "downlink_requirement_status" => "shortfall",
               "actual_throughput_mb" => 96.0,
               "actual_downlink_shortfall_mb" => 54.0,
               "actual_downlink_requirement_status" => "shortfall",
               "capacity_fraction_min" => 0.6,
               "capacity_fraction_max" => 0.8,
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "polar_link_capacity_guard_v1",
               "has_cadence_import" => false,
               "source" =>
                 "candidate_refresh.source_result_artifact[0].link_capacity_report.rows",
               "source_link_capacity" => ^source_row,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].link_capacity_report.rows",
                 "review_type" => "link_capacity_review",
                 "source_link_capacity" => ^source_row,
                 "source_policy_decision" => %{
                   "policy_bundle_id" => "polar_link_capacity_guard_v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
