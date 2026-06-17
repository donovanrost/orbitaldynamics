Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReviewImportSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state review and import source reports into branch refresh requests" do
    schema_validation_report =
      %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => "artifact_file",
        "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "fail",
        "error_count" => 1,
        "warning_count" => 0,
        "errors" => [
          %{
            "severity" => "error",
            "path" => "candidate_refresh_targets",
            "message" => "must include at least one target"
          }
        ],
        "warnings" => [],
        "remediation_count" => 1,
        "remediation" => [
          %{
            "path" => "candidate_refresh_targets",
            "category" => "missing_required_field",
            "action" => "Populate this required field"
          }
        ],
        "provenance" => %{"trust_boundary" => "mission_state_schema_validation_report"}
      }

    contact_intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "contact_intent:mission_review_blocked",
      "activity_id" => "dl_mission_review_blocked",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 700.0,
      "ends_at_s" => 760.0,
      "estimated_throughput_mb" => 37.0,
      "approval_status" => "blocked_by_policy",
      "station_calendar_status" => "reserved",
      "trust_boundary" => "mission_state_contact_intent_review"
    }

    review_package =
      OperatorReview.from_schema_validation_report(schema_validation_report)
      |> merge_artifact_rows(OperatorReview.from_contact_intent(contact_intent))

    import_manifest =
      CadenceImport.from_schema_validation_report(schema_validation_report)
      |> merge_artifact_rows(CadenceImport.from_contact_intent(contact_intent))

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(
        :source_operator_review_package,
        review_package
      )
      |> Map.put(
        :source_cadence_import_manifest,
        import_manifest
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")
    candidate_source = get_in(urgent, ["assumptions", "candidate_source"])

    for source_path <- [
          "mission_state.source_operator_review_package.rows.source_schema_validation_report",
          "mission_state.source_cadence_import_manifest.rows.source_schema_validation_report",
          "mission_state.source_operator_review_package.rows.source_contact_intent[0]",
          "mission_state.source_cadence_import_manifest.rows.source_contact_intent[0]"
        ] do
      assert source_path in get_in(urgent, [
               "assumptions",
               "candidate_source",
               "source_report_input_paths"
             ])

      assert source_path in get_in(urgent, [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ])
    end

    schema_validation_replay_summary =
      CandidateRefresh.schema_validation_replay_summary(candidate_source)

    assert %{
             "contract" => "schema_validation_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => schema_validation_source_paths,
             "status_counts" => %{"fail" => 2},
             "validated_contract_counts" => %{"candidate_refresh.v1" => 2},
             "validation_mode_counts" => %{"artifact_file" => 2},
             "error_count" => 2,
             "warning_count" => 0,
             "remediation_count" => 2,
             "remediation_category_counts" => %{"missing_required_field" => 2},
             "remediation_path_counts" => %{"candidate_refresh_targets" => 2},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_schema_validation_report"],
             "branch_local_validation_pressure" => true,
             "branch_local_schema_error_pressure" => true,
             "branch_local_schema_warning_pressure" => false,
             "branch_local_remediation_pressure" => true
           } = schema_validation_replay_summary

    assert Enum.sort(schema_validation_source_paths) == [
             "mission_state.source_cadence_import_manifest.rows.source_schema_validation_report",
             "mission_state.source_operator_review_package.rows.source_schema_validation_report"
           ]

    assert %{
             "contract" => "contact_intent.v1",
             "count" => 2,
             "row_count" => 2,
             "station_feedback_count" => 2,
             "station_calendar_status_counts" => %{"reserved" => 2},
             "cadence_import_status_counts" => %{"present" => 2},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_contact_intent_review"]
           } =
             contact_intent_summary =
             get_in(urgent, [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_summary",
               "source_reports",
               "contact_intent"
             ])

    assert Enum.sort(contact_intent_summary["paths"]) == [
             "mission_state.source_cadence_import_manifest.rows.source_contact_intent[0]",
             "mission_state.source_operator_review_package.rows.source_contact_intent[0]"
           ]

    contact_intent_replay_summary =
      CandidateRefresh.contact_intent_replay_summary(candidate_source)

    contact_intent_source_paths = contact_intent_replay_summary["source_report_paths"]

    assert Map.take(contact_intent_replay_summary, [
             "contract",
             "source_report_count",
             "source_report_row_count",
             "source_report_paths",
             "station_feedback_count",
             "station_calendar_status_counts",
             "cadence_import_status_counts",
             "trust_boundary_status",
             "trust_boundaries",
             "branch_local_contact_intent_pressure",
             "branch_local_station_feedback_pressure",
             "branch_local_capacity_pack_pressure",
             "direction_routing"
           ]) == %{
             "contract" => "contact_intent.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 1,
             "source_report_paths" => contact_intent_source_paths,
             "station_feedback_count" => 2,
             "station_calendar_status_counts" => %{"reserved" => 2},
             "cadence_import_status_counts" => %{"present" => 2},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_contact_intent_review"],
             "branch_local_contact_intent_pressure" => true,
             "branch_local_station_feedback_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "direction_routing" => %{
               "downlink" => %{
                 "capacity_pack_contact_ids" => [],
                 "contact_count" => 1,
                 "contact_ids" => ["contact_intent:mission_review_blocked"],
                 "contact_ids_by_ground_station" => %{
                   "equator_prime" => ["contact_intent:mission_review_blocked"]
                 },
                 "ground_station_ids" => ["equator_prime"]
               }
             }
           }

    assert Enum.sort(contact_intent_source_paths) == [
             "mission_state.source_cadence_import_manifest.rows.source_contact_intent[0]",
             "mission_state.source_operator_review_package.rows.source_contact_intent[0]"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp merge_artifact_rows(left, right) do
    left
    |> Map.update(
      "rows",
      Map.get(right, "rows", []),
      &(List.wrap(&1) ++ Map.get(right, "rows", []))
    )
  end
end
