defmodule OrbitalDynamics.OperatorReview.LinkCapacityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source link capacity reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:link_capacity_review:001",
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "model" => "fixed_rate_downlink_capacity_summary",
        "source" => "mission_state.source_link_capacity_report",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "contact_count" => 2,
            "ignored_contact_count" => 1,
            "ignored_contact_ids" => ["dl_rejected"],
            "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
            "selected_contact_count" => 1,
            "ignored_selected_contact_count" => 0,
            "ignored_selected_contact_ids" => [],
            "estimated_throughput_mb" => 160.0,
            "selected_estimated_throughput_mb" => 100.0,
            "capacity_adjusted_throughput_mb" => 128.0,
            "selected_capacity_adjusted_throughput_mb" => 80.0,
            "unused_capacity_adjusted_throughput_mb" => 48.0,
            "selected_capacity_utilization_fraction" => 0.625,
            "selection_utilization_status" => "under_utilized",
            "required_downlink_mb" => 120.0,
            "required_downlink_contact_count" => 1,
            "required_downlink_contact_ids" => ["dl_selected"],
            "selected_downlink_shortfall_mb" => 40.0,
            "downlink_requirement_status" => "shortfall",
            "downlink_completion_source" => "source_link_capacity_report",
            "actual_throughput_mb" => 72.0,
            "actual_throughput_contact_count" => 1,
            "actual_throughput_contact_ids" => ["dl_selected"],
            "actual_downlink_shortfall_mb" => 48.0,
            "actual_downlink_requirement_status" => "shortfall",
            "capacity_fraction_min" => 0.5,
            "capacity_fraction_max" => 0.8,
            "contact_ids" => ["dl_selected", "dl_rejected"],
            "selected_contact_ids" => ["dl_selected"],
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "link_capacity:equator_prime",
                "activity_type" => "link_capacity_summary",
                "action" => "review_link_capacity_summary",
                "requirement_type" => "contact_schedule_change",
                "policy_classification" => "operator_review_required"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "classification" => "operator_review_required",
              "policy_bundle_id" => "ground_network_allocation_v1"
            }
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:link_capacity_review:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" => "candidate_refresh.source_link_capacity_report.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
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
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               },
               "source_link_capacity" => %{
                 "ground_station_id" => "equator_prime",
                 "selected_downlink_shortfall_mb" => 40.0
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact link capacity reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_link_capacity_review:001",
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

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_link_capacity_review:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" => "candidate_refresh.source_result_artifact.link_capacity_report.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
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
               "source_link_capacity" => %{
                 "ground_station_id" => "equator_prime",
                 "selected_downlink_shortfall_mb" => 40.0
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state link capacity summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_link_capacity_summary:001",
      "accepted_planning_state" => %{
        "source_link_capacity_summary" => study_result_fixture("link_capacity_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_link_capacity_summary:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1,
             "review_type_counts" => %{"link_capacity_review" => 1},
             "required_operator_action_counts" => %{"review_link_capacity_summary" => 1}
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_link_capacity_summary.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
               "selected_downlink_shortfall_mb" => +0.0,
               "actual_downlink_shortfall_mb" => 10.0,
               "selected_contact_ids" => ["science_downlink"],
               "actual_throughput_contact_ids" => ["science_downlink"],
               "source_link_capacity" => %{
                 "source_summary_schema_contract" => "link_capacity_summary.v1",
                 "source_summary_model" => "artifact_only_link_capacity_summary",
                 "source_link_capacity_summary" => %{
                   "schema_contract" => "link_capacity_summary.v1",
                   "model" => "artifact_only_link_capacity_summary",
                   "assumptions" => %{
                     "execution_boundary" =>
                       "artifact_only_no_provider_reservation_or_schedule_mutation",
                     "operator_authority" => "not_granted_by_summary"
                   }
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_link_capacity_summary:001",
             "row_count" => 1,
             "source_review_type_counts" => %{"link_capacity_review" => 1},
             "import_action_counts" => %{"review_link_capacity" => 1}
           } = manifest

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_link_capacity_summary.rows",
               "source_link_capacity" => %{
                 "source_link_capacity_summary" => %{
                   "schema_contract" => "link_capacity_summary.v1"
                 }
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state relay data path summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_relay_data_path_summary:001",
      "mission_state" => %{
        "relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_relay_data_path_summary:001",
             "review_count" => 2,
             "link_capacity_review_count" => 2,
             "review_type_counts" => %{"link_capacity_review" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.relay_data_path_summary.rows",
             "candidate_refresh.mission_state.relay_data_path_summary.rows"
           ]

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.mission_state.relay_data_path_summary.rows",
             "subject_id" => "dss_14",
             "ground_station_id" => "dss_14",
             "source_link_capacity" => %{
               "route_id" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "source_summary_schema_contract" => "relay_data_path_summary.v1",
               "source_link_capacity_summary" => %{
                 "schema_contract" => "relay_data_path_summary.v1",
                 "route_count" => 2,
                 "relay_route_count" => 1
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] ==
                   "relay_data_path:sat_a:downlink_1:54b7e7ff594c")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh relay data path summaries become link capacity review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:relay_data_path_review:001",
      "source_relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:relay_data_path_review:001",
             "review_count" => 2,
             "link_capacity_review_count" => 2
           } = package

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.source_relay_data_path_summary.rows",
             "subject_id" => "dss_14",
             "ground_station_id" => "dss_14",
             "required_operator_action" => "review_link_capacity_summary",
             "source_link_capacity" => %{
               "route_id" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "source_spacecraft_id" => "sat_a",
               "source_summary_schema_contract" => "relay_data_path_summary.v1",
               "source_link_capacity_summary" => %{
                 "route_count" => 2,
                 "relay_route_count" => 1,
                 "route_ids_by_ground_station_id" => %{
                   "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
                 }
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] ==
                   "relay_data_path:sat_a:downlink_1:54b7e7ff594c")
             )

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.source_relay_data_path_summary.rows",
             "subject_id" => "dss_35",
             "ground_station_id" => "dss_35",
             "source_link_capacity" => %{
               "route_id" => "route_direct",
               "latency_status" => "exceeds_limit",
               "risk_status" => "high",
               "source_link_capacity_summary" => %{
                 "risk_status_counts" => %{"high" => 1, "nominal" => 1}
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] == "route_direct")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact relay data path summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_relay_data_path_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_relay_data_path_summary" =>
            study_result_fixture("relay_data_path_summary_v1.json")
        },
        %{
          "schema_contract" => "result_artifact.v1",
          "relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_relay_data_path_review:001",
             "review_count" => 4,
             "link_capacity_review_count" => 4
           } = package

    assert %{
             "review_type" => "link_capacity_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_relay_data_path_summary.rows",
             "source_link_capacity" => %{
               "source_summary_schema_contract" => "relay_data_path_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_relay_data_path_summary.rows")
             )

    assert %{
             "review_type" => "link_capacity_review",
             "source" =>
               "candidate_refresh.source_result_artifact[1].relay_data_path_summary.rows",
             "source_link_capacity" => %{
               "source_summary_model" => "artifact_only_relay_data_path_summary"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[1].relay_data_path_summary.rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end

  test "builds review package from standalone link capacity report rows" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "model" => "fixed_rate_downlink_capacity_summary",
      "source" => "campaign_plan.candidate_activities",
      "contact_count" => 1,
      "selected_contact_count" => 0,
      "estimated_throughput_mb" => 345.4,
      "selected_estimated_throughput_mb" => 0.0,
      "capacity_adjusted_throughput_mb" => 172.7,
      "selected_capacity_adjusted_throughput_mb" => 0.0,
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "ignored_contact_count" => 1,
          "ignored_contact_ids" => ["leo_1_rejected_downlink"],
          "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "selected_contact_count" => 0,
          "ignored_selected_contact_count" => 1,
          "ignored_selected_contact_ids" => ["leo_1_rejected_downlink"],
          "ignored_selected_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "estimated_throughput_mb" => 345.4,
          "selected_estimated_throughput_mb" => 0.0,
          "capacity_adjusted_throughput_mb" => 172.7,
          "selected_capacity_adjusted_throughput_mb" => 0.0,
          "capacity_fraction_min" => 0.5,
          "capacity_fraction_max" => 0.5,
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "link_capacity:equator_prime",
              "activity_type" => "link_capacity_summary",
              "action" => "review_link_capacity_summary",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "severe_capacity_reduction_review",
              "classification" => "operator_review_required",
              "station_availability" => "reduced_capacity",
              "capacity_fraction" => 0.5
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_matches" => [
              %{
                "rule_id" => "severe_capacity_reduction_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "unmatched_link_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "severe_capacity_reduction_review",
                "required_authority" => "ground_network_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "link_capacity",
                "escalation_role" => "link_budget_analyst",
                "sla_s" => 900
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          },
          "contact_ids" => ["leo_1_downlink_equator_prime_1", "leo_1_rejected_downlink"],
          "selected_contact_ids" => []
        }
      ],
      "assumptions" => %{"link_budget_model" => "none"}
    }

    package = OperatorReview.from_link_capacity_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "link_capacity_report.v1",
             "source_artifact_id" => "campaign_plan.candidate_activities",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "link_capacity_report.rows",
             "subject_id" => "equator_prime",
             "ground_station_id" => "equator_prime",
             "required_operator_action" => "review_link_capacity_summary",
             "contact_count" => 2,
             "ignored_contact_count" => 1,
             "ignored_contact_ids" => ["leo_1_rejected_downlink"],
             "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
             "selected_contact_count" => 0,
             "ignored_selected_contact_count" => 1,
             "ignored_selected_contact_ids" => ["leo_1_rejected_downlink"],
             "ignored_selected_contact_reason_counts" => %{"approval_status_rejected" => 1},
             "capacity_fraction_min" => 0.5,
             "capacity_fraction_max" => 0.5,
             "contact_ids" => ["leo_1_downlink_equator_prime_1", "leo_1_rejected_downlink"],
             "selected_contact_ids" => [],
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "ground_network_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "severe_capacity_reduction_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "link_capacity",
             "escalation_role" => "link_budget_analyst",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "severe_capacity_reduction_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "severe_capacity_reduction_review",
               "escalation_queue" => "link_capacity"
             },
             "source_link_capacity" => %{"ground_station_id" => "equator_prime"}
           } = first_row

    assert first_row["selected_estimated_throughput_mb"] == 0.0
    assert first_row["selected_capacity_adjusted_throughput_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("ignored_selected_contact_count", 2)
          |> Map.put("ground_station_id", "stale_station")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_selected_contact_count" and
                 &1["message"] == "must equal length of ignored_selected_contact_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_link_capacity.ground_station_id")
           )
  end

  test "link capacity report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "link-capacity:report"} =
             OperatorReview.from_link_capacity_report(%{
               id: :"link-capacity:report",
               rows: []
             })

    assert %{"source_artifact_id" => "link-capacity:source"} =
             OperatorReview.from_link_capacity_report(%{
               source: :"link-capacity:source",
               rows: []
             })

    assert %{"source_artifact_id" => "link_capacity_report"} =
             OperatorReview.from_link_capacity_report(%{rows: []})
  end
end
