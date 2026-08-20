defmodule OrbitalDynamics.Schema.ValidationEvidenceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Communications.StationCalendar, OperationalReadiness, Schema, Validation}

  test "exports nested validation reference fixture report schemas" do
    assert {:ok, schema} = Schema.json_schema("validation_reference_fixture_report.v1")

    report_schema = get_in(schema, ["properties", "reports", "items"])

    assert get_in(schema, ["properties", "fixture_count", "minimum"]) == 0

    assert get_in(schema, ["properties", "status_counts", "propertyNames", "enum"]) == [
             "pass",
             "fail"
           ]

    assert get_in(schema, ["properties", "status_counts", "additionalProperties", "minimum"]) == 0

    assert report_schema["required"] == [
             "schema_contract",
             "fixture_id",
             "model_id",
             "validation_level",
             "status",
             "checks"
           ]

    assert get_in(report_schema, ["properties", "schema_contract", "const"]) ==
             "validation_reference_report.v1"

    assert get_in(report_schema, ["properties", "status_counts", "propertyNames", "enum"]) == [
             "pass",
             "fail"
           ]

    assert get_in(report_schema, ["properties", "fixture_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    check_schema = get_in(report_schema, ["properties", "checks", "items"])

    assert check_schema["required"] == ["field", "status", "expected", "observed", "tolerance"]
    assert get_in(check_schema, ["properties", "status", "enum"]) == ["pass", "fail"]
    assert get_in(check_schema, ["properties", "error", "type"]) == "number"
  end

  test "validates standalone validation evidence fixtures" do
    validation_check = read_json!("study_results/validation_check_v1.json")
    validation_report = read_json!("study_results/validation_reference_report_v1.json")
    validation_record = read_json!("study_results/validation_record_v1.json")
    validation_fixtures = read_json!("study_results/validation_reference_fixtures.json")

    assert {:ok, %{"schema_contract" => "validation_check.v1"}} =
             Schema.validate_artifact(validation_check)

    assert {:ok, %{"schema_contract" => "validation_reference_report.v1"}} =
             Schema.validate_artifact(validation_report)

    assert validation_report["status_counts"] == %{"pass" => length(validation_report["checks"])}

    invalid_validation_report_level =
      Map.put(validation_report, "validation_level", "stale_validation_level")

    assert {:error, invalid_validation_report_level_report} =
             Schema.validate_artifact(invalid_validation_report_level)

    assert Enum.any?(
             invalid_validation_report_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )

    assert {:ok, %{"schema_contract" => "validation_record.v1"}} =
             Schema.validate_artifact(validation_record)

    invalid_validation_record_level =
      Map.put(validation_record, "validation_level", "stale_validation_level")

    assert {:error, invalid_validation_record_level_report} =
             Schema.validate_artifact(invalid_validation_record_level)

    assert Enum.any?(
             invalid_validation_record_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )

    stale_validation_record_model =
      Map.put(validation_record, "model", "stale_validation_record_model")

    assert {:error, stale_validation_record_model_report} =
             Schema.validate_artifact(stale_validation_record_model)

    assert Enum.any?(
             stale_validation_record_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    external_validation_record =
      validation_record
      |> Map.put("id", "external.validation_record")
      |> Map.put("model", "external_model")
      |> Map.put("known_limits", ["external validation record remains extensible"])

    assert {:ok, %{"schema_contract" => "validation_record.v1"}} =
             Schema.validate_artifact(external_validation_record)

    assert {:ok, validation_record_schema} = Schema.json_schema("validation_record.v1")

    assert Enum.any?(
             validation_record_schema["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) == "propagator.two_body" and
                 get_in(&1, ["then", "properties", "model", "const"]) == "point_mass_two_body")
           )

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             Schema.validate_artifact(validation_fixtures)

    assert validation_fixtures["fixture_count"] == map_size(Validation.reference_fixtures())

    assert validation_fixtures["status_counts"] == %{
             "pass" => validation_fixtures["fixture_count"]
           }

    assert Enum.map(validation_fixtures["reports"], & &1["fixture_id"]) ==
             Validation.reference_fixtures()
             |> Map.keys()
             |> Enum.sort()

    reports_by_fixture_id = Map.new(validation_fixtures["reports"], &{&1["fixture_id"], &1})

    Enum.each(
      [
        {"fixture.artifact.schema_migration_report.deprecated_campaign_plan",
         [
           "deprecated_contract_count",
           "deprecated_contracts",
           "replacement_contracts",
           "row_derived_status_counts",
           "row_derived_migration_action_counts"
         ]},
        {"fixture.artifact.schema_migration_report.future_campaign_plan",
         [
           "future_contract_count",
           "row_derived_status_counts",
           "row_derived_migration_action_counts"
         ]}
      ],
      fn {fixture_id, expected_fields} ->
        assert %{
                 "model_id" => "artifact.schema_migration_report.v1",
                 "status" => "pass",
                 "checks" => checks
               } = Map.fetch!(reports_by_fixture_id, fixture_id)

        checks_by_field = Map.new(checks, &{&1["field"], &1})

        Enum.each(expected_fields, fn field ->
          assert %{"status" => "pass"} = Map.fetch!(checks_by_field, field)
        end)
      end
    )

    invalid_check = Map.put(validation_check, "status", "unknown")

    assert {:error, check_report} = Schema.validate_artifact(invalid_check)
    assert Enum.any?(check_report["errors"], &(&1["path"] == "$.status"))

    invalid_record = put_in(validation_record, ["evidence"], ["ok", 42])

    assert {:error, record_report} = Schema.validate_artifact(invalid_record)
    assert Enum.any?(record_report["errors"], &(&1["path"] == "$.evidence[1]"))
  end

  test "validates reference fixture reports" do
    observations_by_fixture =
      "study_results/validation_reference_fixtures.json"
      |> read_json!()
      |> reference_fixture_report_observations()
      |> Map.merge(%{
        "fixture.artifact.campaign_plan.leo_constellation_v1" =>
          campaign_plan_fixture_observations(),
        "fixture.artifact.campaign_repair.leo_constellation_v2" =>
          campaign_repair_fixture_observations(),
        "fixture.artifact.campaign_strategy.leo_constellation_v3" =>
          campaign_strategy_fixture_observations(),
        "fixture.artifact.candidate_refresh.v1" => candidate_refresh_fixture_observations(),
        "fixture.artifact.score_term_report.v1" => score_term_report_fixture_observations(),
        "fixture.artifact.timeline_lifecycle_state_summary.v1" =>
          timeline_lifecycle_state_summary_fixture_observations(),
        "fixture.artifact.model_acceptance_report.operational_import" =>
          Validation.artifact_observations(
            "model_acceptance_report.v1",
            Validation.model_acceptance_report(
              [
                "orbit_data.simple_json",
                "event.access_windows",
                "propagator.two_body",
                "missing.model"
              ],
              intended_use: :operational_import
            )
          ),
        "fixture.artifact.validation_safety_case_summary.v1" =>
          validation_safety_case_summary_fixture_observations(),
        "fixture.artifact.operator_review_package.v1" =>
          operator_review_package_fixture_observations(),
        "fixture.artifact.operational_readiness_report.v1" =>
          operational_readiness_report_fixture_observations(),
        "fixture.artifact.provider_counteroffer_report.v1" =>
          provider_counteroffer_report_fixture_observations(),
        "fixture.artifact.quality_gate_report.v1" => quality_gate_report_fixture_observations(),
        "fixture.artifact.schema_validation_batch_report.v1" =>
          schema_validation_batch_report_fixture_observations(),
        "fixture.artifact.schema_validation_report.v1" =>
          schema_validation_report_fixture_observations(),
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" =>
          station_calendar_report_fixture_observations(),
        "fixture.event.access.equator_overhead_120s" => %{
          "window_count" => 1,
          "first_window_starts_at_s" => 0.0,
          "first_window_ends_at_s" => 89.45807391804992,
          "first_window_duration_s" => 89.45807391804992,
          "first_window_sample_count" => 2,
          "first_window_max_elevation_deg" => 90.0
        },
        "fixture.event.eclipse.cylindrical_shadow_120s" => %{
          "interval_count" => 1,
          "first_interval_starts_at_s" => 0.0,
          "first_interval_ends_at_s" => 88.8684602035115,
          "first_interval_duration_s" => 88.8684602035115,
          "first_interval_sample_count" => 2,
          "first_interval_minimum_shadow_axis_distance_km" => 0.0,
          "first_interval_maximum_shadow_margin_km" => 6378.1363
        },
        "fixture.event.target_visibility.equator_overhead_120s" => %{
          "window_count" => 1,
          "first_window_starts_at_s" => 0.0,
          "first_window_ends_at_s" => 89.45807391804992,
          "first_window_duration_s" => 89.45807391804992,
          "first_window_sample_count" => 2,
          "first_window_max_elevation_deg" => 90.0,
          "target_priority" => 4.0
        },
        "fixture.event.ground_track.latitude_equator_60s" => %{
          "crossing_count" => 1,
          "first_crossing_epoch_s" => 30.0,
          "first_crossing_target_deg" => 0.0,
          "first_crossing_direction" => "northbound"
        },
        "fixture.j2.circular_leo_600s" => %{
          "sample_count" => 6,
          "final_epoch_s" => 600.0,
          "final_position_km" => [5584.070997735894, 4217.992693724331, 0.0],
          "final_velocity_km_s" => [-4.554400191561496, 6.019254825378945, 0.0]
        },
        "fixture.propagator.j2_drag.earth_400km_24h_step_convergence" =>
          Validation.reference_fixtures()
          |> Map.fetch!("fixture.propagator.j2_drag.earth_400km_24h_step_convergence")
          |> Map.fetch!("expected"),
        "fixture.two_body.circular_leo_600s" => %{
          "sample_count" => 6,
          "final_epoch_s" => 600.0,
          "final_position_km" => [5586.094941787218, 4218.4764189319985, 0.0],
          "final_velocity_km_s" => [-4.54754969549011, 6.021852873409085, 0.0]
        }
      })

    report = Validation.reference_fixture_report(observations_by_fixture)

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "validation_reference_fixture_report.v1"
             )

    assert report["status"] == "pass"
    assert report["status_counts"] == %{"pass" => report["fixture_count"]}
  end

  defp campaign_plan_fixture_observations do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    Validation.artifact_observations("campaign_plan.v1", artifact)
  end

  defp campaign_repair_fixture_observations do
    "study_results/leo_constellation_campaign_repair_v2.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_repair.v2", &1))
  end

  defp campaign_strategy_fixture_observations do
    "study_results/leo_constellation_campaign_strategy_v3.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_strategy.v3", &1))
  end

  defp candidate_refresh_fixture_observations do
    "study_results/candidate_refresh_v1.json"
    |> read_json!()
    |> Map.fetch!("candidate_refresh")
    |> then(&Validation.artifact_observations("candidate_refresh.v1", &1))
  end

  defp score_term_report_fixture_observations do
    "study_results/score_term_report_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("score_term_report.v1", &1))
  end

  defp timeline_lifecycle_state_summary_fixture_observations do
    "study_results/timeline_lifecycle_state_summary_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("timeline_lifecycle_state_summary.v1", &1))
  end

  defp schema_validation_report_fixture_observations do
    "study_results/schema_validation_report_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("schema_validation_report.v1", &1))
  end

  defp schema_validation_batch_report_fixture_observations do
    "study_results/schema_validation_batch_report_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("schema_validation_batch_report.v1", &1))
  end

  defp validation_safety_case_summary_fixture_observations do
    "study_results/validation_safety_case_summary_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("validation_safety_case_summary.v1", &1))
  end

  defp operator_review_package_fixture_observations do
    "study_results/operator_review_package_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  defp operational_readiness_report_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_report_fixture())
  end

  defp operational_readiness_report_fixture do
    OperationalReadiness.report(%{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "cadence_import_manifest_fixture",
      "manifest_id" => "manifest_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "import_replacement_activity",
          "import_status" => "ready_for_import",
          "cadence_import_status" => "present"
        }
      ]
    })
  end

  defp quality_gate_report_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_report_fixture())
  end

  defp quality_gate_report_fixture do
    operational_readiness_report_fixture()
    |> OperationalReadiness.quality_gate_report()
  end

  defp provider_counteroffer_report_fixture_observations do
    "provider_counteroffer_report.v1"
    |> Validation.artifact_observations(provider_counteroffer_report_fixture())
  end

  defp provider_counteroffer_report_fixture do
    StationCalendar.report(
      [
        %{
          id: :dl_counteroffer,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          starts_at_s: 100.0,
          ends_at_s: 140.0
        }
      ],
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :ops_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :provider_counteroffer_window,
            station_id: :equator_prime,
            availability: :available,
            directions: [:downlink],
            start_s: 130.0,
            end_s: 170.0,
            counteroffer_id: :provider_offer_1,
            counteroffer_status: :proposed,
            counteroffer_reason_code: :provider_shifted_window,
            counteroffer_cost_delta: 125.5,
            schedule_lock_deadline_s: 150.0,
            counteroffer_start_s: 130.0,
            counteroffer_end_s: 170.0
          }
        ]
      }
    )
    |> StationCalendar.provider_counteroffer_report()
  end

  defp station_calendar_report_fixture_observations do
    "station_calendar_report.v1"
    |> Validation.artifact_observations(station_calendar_report_fixture())
  end

  defp station_calendar_report_fixture do
    StationCalendar.report(
      [
        %{
          id: :dl_hold,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          starts_at_s: 120.0,
          ends_at_s: 160.0
        }
      ],
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :ops_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :provider_downlink_hold,
            station_id: :equator_prime,
            availability: :reservation_hold,
            directions: [:downlink],
            start_s: 100.0,
            end_s: 200.0,
            hold_id: :provider_hold_1,
            hold_expires_at_s: 95.0,
            held_by: :ops_calendar,
            hold_status: :tentative_hold
          }
        ]
      },
      source: "stale_provider_calendar"
    )
  end

  defp reference_fixture_report_observations(%{"reports" => reports}) do
    Map.new(reports, fn report ->
      observations =
        report
        |> Map.fetch!("checks")
        |> Map.new(fn check -> {check["field"], check["observed"]} end)

      {report["fixture_id"], observations}
    end)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
