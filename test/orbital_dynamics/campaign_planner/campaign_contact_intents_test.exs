defmodule OrbitalDynamics.CampaignPlanner.CampaignContactIntentsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "campaign contact intents preserve approval policy evidence" do
    result_set =
      campaign_result_set([
        access_result(:leo_1, :equator_prime, 100.0, 170.0)
      ])

    artifact =
      CampaignPlanner.build(result_set,
        campaign: %{
          "scoring_policy" => %{"contact_value_weight" => "0.2", "downlink_rate_mb_s" => "2.0"},
          "approval_policy" => %{"policy_bundle_id" => "command_contact_authority_v1"}
        },
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1",
               "direction" => "downlink",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "action" => "review_contact_intent",
                   "requirement_type" => "contact_schedule_change"
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "downlink_schedule_authority_review",
                   "required_authority" => "contact_schedule_authority"
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "command_contact_authority_v1",
                 "classification" => "operator_review_required"
               }
             }
           ] = artifact["contact_intents"]

    assert get_in(List.first(artifact["contact_intents"]), [
             "activity_context",
             "estimated_throughput_mb"
           ]) == 140.0

    assert get_in(List.first(artifact["contact_intents"]), [
             "activity_context",
             "score_terms",
             "contact_value"
           ]) == 14.0

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "contact_intent_review_count" => 1,
             "review_type_counts" => %{"contact_intent_review" => 1},
             "required_operator_action_counts" => %{"review_contact_intent" => 1},
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "contact_intent_review",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "required_operator_action" => "review_contact_intent",
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_contact_intent",
                 "requirement_type" => "contact_schedule_change"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "downlink_schedule_authority_review",
                 "required_authority" => "contact_schedule_authority"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "command_contact_authority_v1",
               "classification" => "operator_review_required"
             },
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1"
             }
           } = Enum.find(review_rows, &(&1["review_type"] == "contact_intent_review"))

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "import_action_counts" => %{
               "import_proposed_contact" => 1,
               "review_contact_intent" => 1,
               "review_operational_timeline" => 1,
               "review_contact_allocation" => 1
             },
             "rows" => import_rows
           } = artifact["cadence_import_manifest"]

    assert %{
             "import_action" => "review_contact_intent",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_intent_review",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "approval_status" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "downlink_schedule_authority_review",
                 "required_authority" => "contact_schedule_authority"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "command_contact_authority_v1",
               "classification" => "operator_review_required"
             },
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1"
             }
           } = Enum.find(import_rows, &(&1["import_action"] == "review_contact_intent"))

    assert {:ok, %{"schema_contract" => "campaign_plan.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "campaign access windows can opt into command tracking and health-check candidates" do
    result_set =
      campaign_result_set([
        access_result(:leo_1, :equator_prime, 100.0, 170.0)
      ])

    artifact =
      CampaignPlanner.build(result_set,
        campaign: %{
          "scoring_policy" => %{
            "contact_value_weight" => 0.2,
            "downlink_rate_mb_s" => 2.0,
            "contact_activity_types" => [
              "downlink",
              "command",
              "tracking",
              "health_check"
            ]
          }
        },
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_command_equator_prime_1",
             "leo_1_downlink_equator_prime_1",
             "leo_1_health_check_equator_prime_1",
             "leo_1_tracking_equator_prime_1"
           ]

    assert Enum.map(artifact["candidate_activities"], & &1["type"]) == [
             "command",
             "downlink",
             "health_check",
             "tracking"
           ]

    assert %{
             "direction" => "command",
             "cadence_import" => %{
               "activity_type" => "command",
               "external_id" => "leo_1_command_equator_prime_1"
             },
             "score_terms" => %{"contact_value" => 14.0},
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
           } =
             Enum.find(
               artifact["candidate_activities"],
               &(&1["id"] == "leo_1_command_equator_prime_1")
             )

    refute Map.has_key?(
             Enum.find(
               artifact["candidate_activities"],
               &(&1["id"] == "leo_1_tracking_equator_prime_1")
             ),
             "estimated_throughput_mb"
           )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "type" => "downlink",
               "direction" => "downlink",
               "estimated_throughput_mb" => 140.0
             }
           ] = artifact["proposed_contacts"]

    assert Enum.map(artifact["contact_intents"], &{&1["direction"], &1["activity_id"]}) == [
             {"command", "leo_1_command_equator_prime_1"},
             {"downlink", "leo_1_downlink_equator_prime_1"},
             {"health_check", "leo_1_health_check_equator_prime_1"},
             {"tracking", "leo_1_tracking_equator_prime_1"}
           ]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 4,
             "kept_candidate_count" => 4,
             "suppressed_candidate_count" => 0
           } = artifact["contact_filter_report"]
  end

  defp campaign_result_set(event_results) do
    ResultSet.new!(%{
      study_id: :campaign,
      trajectory_results: [],
      event_results: event_results,
      errors: [],
      assumptions: %{},
      metadata: %{}
    })
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
