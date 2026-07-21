Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairStationCalendarAnnotationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair annotates source candidates from repair-time station calendar updates" do
    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [
            downlink("dl_1", 100.0, 160.0),
            refreshed_downlink("dl_2", 500.0, 560.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        ground_network: [
          %{
            id: "equator_repair_capacity",
            ground_station_id: "equator_prime",
            status: "available",
            capacity_fraction: 0.4,
            starts_at_s: 490.0,
            ends_at_s: 570.0
          }
        ],
        scoring_policy: %{"risk_weight" => "2.0"}
      )

    assert [%{"id" => "dl_2", "repair" => %{"action" => "moved"}}] = artifact["activities"]

    assert %{
             "schema_contract" => "station_calendar_report.v1",
             "model" => "campaign_ground_network_interval_overlay",
             "input_contact_count" => 2,
             "calendar_entry_count" => 1,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_2",
                 "station_calendar_entry_id" => "equator_repair_capacity",
                 "station_availability" => "reduced_capacity",
                 "capacity_fraction" => 0.4
               }
             ],
             "assumptions" => %{"source" => "repair.ground_network"}
           } = artifact["source_station_calendar_report"]

    assert artifact["score_terms"]["station_calendar_pressure_penalty"] == -2.0
    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert [
             %{
               "term_key" => "station_calendar_pressure_penalty",
               "value" => -2.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "station_calendar_pressure_penalty")
             )

    assert [%{"id" => "dl_1"}, %{"id" => "dl_2"} = annotated] =
             artifact["source_candidate_activities"]

    assert annotated["station_availability"] == "reduced_capacity"
    assert annotated["station_capacity_fraction"] == 0.4
    assert get_in(annotated, ["throughput_model", "station_capacity_fraction"]) == 0.4

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair station calendar annotates planned-contact downlink source candidates" do
    planned_contact =
      downlink("planned_contact_dl", 500.0, 560.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("ground_station_id", "new_mexico")

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [
            downlink("dl_1", 100.0, 160.0),
            refreshed_downlink("dl_2", 500.0, 560.0),
            planned_contact
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        ground_network: [
          %{
            id: "new_mexico_repair_capacity",
            ground_station_id: "new_mexico",
            status: "available",
            capacity_fraction: 0.5,
            starts_at_s: 490.0,
            ends_at_s: 570.0
          }
        ]
      )

    assert %{
             "input_contact_count" => 3,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "planned_contact_dl",
                 "contact_type" => "planned_contact",
                 "direction" => "downlink",
                 "station_calendar_entry_id" => "new_mexico_repair_capacity",
                 "station_availability" => "reduced_capacity",
                 "capacity_fraction" => 0.5
               }
             ]
           } = artifact["source_station_calendar_report"]

    annotated =
      Enum.find(
        artifact["source_candidate_activities"],
        &(&1["id"] == "planned_contact_dl")
      )

    assert annotated["station_availability"] == "reduced_capacity"
    assert annotated["station_capacity_fraction"] == 0.5
    assert get_in(annotated, ["throughput_model", "station_capacity_fraction"]) == 0.5

    refute Map.has_key?(artifact["score_terms"], "station_calendar_pressure_penalty")

    refute "station_calendar_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair annotates reserved source candidates from repair-time station calendars" do
    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [
            downlink("dl_1", 100.0, 160.0),
            refreshed_downlink("dl_2", 500.0, 560.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        ground_network: [
          %{
            id: "equator_repair_capacity",
            ground_station_id: "equator_prime",
            status: "available",
            capacity_fraction: 0.4,
            starts_at_s: 490.0,
            ends_at_s: 570.0
          },
          %{
            id: "equator_repair_reserved",
            ground_station_id: "equator_prime",
            availability: "reserved",
            starts_at_s: 500.0,
            ends_at_s: 540.0,
            reservation_id: "reservation_repair",
            reserved_by: "ops_team_b"
          }
        ]
      )

    assert %{
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_2",
                 "station_calendar_entry_id" => "equator_repair_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_repair",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved"
               }
             ],
             "assumptions" => %{"source" => "repair.ground_network"}
           } = artifact["source_station_calendar_report"]

    assert artifact["score_terms"]["station_calendar_pressure_penalty"] == -1.0

    assert %{"station_calendar_review_count" => 1} = artifact["operator_review_package"]

    assert %{
             "review_type" => "station_calendar_review",
             "source" => "campaign_repair.source_station_calendar_report.affected_contacts",
             "subject_id" => "dl_2",
             "contact_id" => "dl_2",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_repair_reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_repair",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "reserved",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_calendar_review" => %{"contact_id" => "dl_2"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "station_calendar_review")
             )

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "contact_id" => "dl_2",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_repair_reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_repair",
             "source_station_calendar_review" => %{"contact_id" => "dl_2"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_station_calendar")
             )

    assert [%{"id" => "dl_1"}, %{"id" => "dl_2"} = annotated] =
             artifact["source_candidate_activities"]

    assert annotated["station_availability"] == "reserved"
    assert annotated["station_calendar_entry_id"] == "equator_repair_reserved"
    assert annotated["station_contention_status"] == "reserved_overlap"
    assert annotated["station_reservation_id"] == "reservation_repair"
    assert annotated["station_reserved_by"] == "ops_team_b"
    assert annotated["station_reservation_status"] == "reserved"

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end
end
