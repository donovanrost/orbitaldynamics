defmodule OrbitalDynamics.CandidateRefresh.DownlinkObjectiveBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "applies refresh downlink completion objectives to refreshed downlink evidence" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 720.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 720.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 0.5
    assert downlink["selected_downlink_shortfall_mb"] == 360.0
    assert downlink["downlink_requirement_status"] == "shortfall"

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert downlink["score_terms"]["downlink_completion_value"] == 25.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies nested-station refresh downlink completion objectives to refreshed downlinks" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "station" => %{"id" => "equator_prime"},
              "required_downlink_mb" => 720.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["ground_station_id"] == "equator_prime"
    assert downlink["required_downlink_mb"] == 720.0
    assert downlink["downlink_completion_ratio"] == 0.5

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "accumulates multiple matching downlink completion objectives for refreshed downlinks" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 300.0
            },
            %{
              "type" => "required_downlink_completion",
              "station_id" => "equator_prime",
              "required_data_volume_mb" => 420.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 720.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 0.5
    assert downlink["selected_downlink_shortfall_mb"] == 360.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert get_in(downlink, ["throughput_model", "required_downlink_mb"]) == 720.0
    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 720.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "scopes downlink completion objective demand by spacecraft identity" do
    refresh =
      refresh_request()
      |> put_in(["accepted_planning_state", "spacecraft_states"], [
        %{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"},
        %{"spacecraft_id" => "sat_2", "scenario_id" => "leo_2"}
      ])
      |> Map.put("objectives", [
        %{
          "type" => "downlink_completion",
          "ground_station_id" => "equator_prime",
          "spacecraft_id" => "sat_1",
          "required_downlink_mb" => 720.0
        }
      ])

    artifact =
      result_set_with_same_station_different_spacecraft_nonoverlapping_contacts()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlinks =
      artifact["candidate_activities"]
      |> Enum.filter(&(&1["type"] == "downlink"))
      |> Enum.sort_by(& &1["scenario_id"])

    assert [
             %{
               "scenario_id" => "leo_1",
               "required_downlink_mb" => 720.0,
               "downlink_completion_source" => "candidate_refresh.objectives.downlink_completion"
             },
             %{"scenario_id" => "leo_2"} = leo_2_downlink
           ] = downlinks

    refute Map.has_key?(leo_2_downlink, "required_downlink_mb")
    refute Map.has_key?(leo_2_downlink["throughput_model"], "required_downlink_mb")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "mission-state spacecraft identity takes precedence over accepted state for objectives" do
    refresh =
      refresh_request()
      |> put_in(["accepted_planning_state", "spacecraft_states"], [
        %{"spacecraft_id" => "sat_stale", "scenario_id" => "leo_1"}
      ])
      |> Map.put("mission_state", %{
        "spacecraft_states" => [%{"spacecraft_id" => "sat_live", "scenario_id" => "leo_1"}]
      })
      |> Map.put("objectives", [
        %{
          "type" => "downlink_completion",
          "ground_station_id" => "equator_prime",
          "spacecraft_id" => "sat_live",
          "required_downlink_mb" => 720.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert %{
             "scenario_id" => "leo_1",
             "required_downlink_mb" => 720.0,
             "downlink_completion_source" => "candidate_refresh.objectives.downlink_completion"
           } = downlink

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "scopes downlink completion objectives with nested spacecraft identity" do
    refresh =
      refresh_request()
      |> put_in(["accepted_planning_state", "spacecraft_states"], [
        %{"spacecraft" => %{"id" => "sat_1"}, "scenario_id" => "leo_1"},
        %{"satellite" => %{"satellite_id" => "sat_2"}, "scenario_id" => "leo_2"}
      ])
      |> Map.put("objectives", [
        %{
          "type" => "downlink_completion",
          "ground_station_id" => "equator_prime",
          "spacecraft" => %{"id" => "sat_1"},
          "required_downlink_mb" => 720.0
        }
      ])

    artifact =
      result_set_with_same_station_different_spacecraft_nonoverlapping_contacts()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlinks =
      artifact["candidate_activities"]
      |> Enum.filter(&(&1["type"] == "downlink"))
      |> Enum.sort_by(& &1["scenario_id"])

    assert [
             %{
               "scenario_id" => "leo_1",
               "required_downlink_mb" => 720.0,
               "downlink_completion_source" => "candidate_refresh.objectives.downlink_completion"
             },
             %{"scenario_id" => "leo_2"} = leo_2_downlink
           ] = downlinks

    refute Map.has_key?(leo_2_downlink, "required_downlink_mb")
    refute Map.has_key?(leo_2_downlink["throughput_model"], "required_downlink_mb")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies collection latency objectives to refreshed downlink demand" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "latency:collection_alpha",
              "type" => "collection_latency",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_alpha",
              "max_latency_s" => 900.0,
              "required_downlink_mb" => 180.0
            },
            %{
              "id" => "latency:other_station",
              "type" => "collection_latency",
              "ground_station_id" => "polar_station",
              "required_downlink_mb" => 500.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 1.0
    assert downlink["selected_downlink_shortfall_mb"] == 0.0
    assert downlink["downlink_requirement_status"] == "satisfied"

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.collection_latency"

    assert get_in(downlink, ["throughput_model", "required_downlink_mb"]) == 180.0
    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 180.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies collection latency objectives to refreshed observation candidates" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "latency:collection_alpha",
              "type" => "collection_latency",
              "target_id" => "target_a",
              "spacecraft_id" => "sat_1",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_alpha",
              "product_ids" => ["image_l0", "image_l1"],
              "payload_id" => "camera_a",
              "instrument_id" => "imager",
              "max_latency_s" => 900.0,
              "required_downlink_mb" => 180.0
            },
            %{
              "id" => "latency:other_target",
              "type" => "collection_latency",
              "target_id" => "target_b",
              "spacecraft_id" => "sat_2",
              "required_downlink_mb" => 500.0
            }
          ])
          |> put_in(["scoring_policy", "collection_latency_observation_weight"], 35.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "collection_latency_objective_count" => 1,
             "collection_latency_objective_ids" => ["latency:collection_alpha"],
             "collection_latency_objective_types" => ["collection_latency"],
             "collection_latency_objective_source" =>
               "candidate_refresh.objectives.collection_latency",
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "max_latency_s" => 900.0,
             "required_downlink_mb" => 180.0,
             "score_terms" => %{
               "target_value" => 240.0,
               "collection_latency_observation_value" => 35.0
             },
             "activity_context" => %{
               "collection_latency_objective_count" => 1,
               "collection_latency_objective_ids" => ["latency:collection_alpha"],
               "collection_latency_objective_types" => ["collection_latency"],
               "collection_id" => "collection_alpha",
               "product_ids" => ["image_l0", "image_l1"],
               "payload_id" => "camera_a",
               "instrument_id" => "imager",
               "max_latency_s" => 900.0,
               "required_downlink_mb" => 180.0
             }
           } = observe

    assert observe["score"] == 275.0

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0

    assert {:ok, schema} = Schema.json_schema("candidate_activity.v1")

    assert get_in(schema, [
             "properties",
             "collection_latency_objective_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "max_latency_s",
             "minimum"
           ]) == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "combines downlink completion and collection latency demand objectives" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 120.0
            },
            %{
              "type" => "collection_downlink_latency",
              "station_id" => "equator_prime",
              "required_data_volume_mb" => 240.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 360.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion_and_latency"

    assert downlink["downlink_completion_sources"] == [
             "candidate_refresh.objectives.collection_latency",
             "candidate_refresh.objectives.downlink_completion"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "adds operational feedback and objective downlink demand for refreshed downlinks" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "downlink_demand_mb" => %{"equator_prime" => 120.0},
            "downlink_demand_context" => %{
              "equator_prime" => %{
                "collection_id" => "collection_alpha",
                "product_ids" => ["image_l0", "image_l1"],
                "payload_id" => "camera_a",
                "instrument_id" => "imager",
                "target_id" => "target_a",
                "source_activity_ids" => ["observe_sat_1_target_a_1"],
                "objective_id" => "latency:collection_alpha",
                "objective_type" => "collection_latency",
                "latency_objective" => true,
                "max_latency_s" => 900.0,
                "planned_latency_s" => 540.0,
                "feedback_source" => "cadence.timeline_feedback",
                "feedback_scope" => "station_downlink_gap",
                "trust_boundary" => "cadence_operational_feedback"
              }
            }
          })
          |> Map.put("objectives", [
            %{
              "id" => "latency:collection_alpha",
              "type" => "collection_latency",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 180.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert downlink["required_downlink_mb"] == 300.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 1.0
    assert downlink["selected_downlink_shortfall_mb"] == 0.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.downlink_demand.objectives_and_operational_feedback"

    assert downlink["downlink_completion_sources"] == [
             "candidate_refresh.objectives.collection_latency",
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert get_in(downlink, ["throughput_model", "required_downlink_mb"]) == 300.0
    assert get_in(downlink, ["throughput_model", "candidate_downlink_mb"]) == 360.0
    assert get_in(downlink, ["throughput_model", "downlink_completion_ratio"]) == 1.0
    assert get_in(downlink, ["throughput_model", "selected_downlink_shortfall_mb"]) == 0.0
    assert get_in(downlink, ["throughput_model", "downlink_requirement_status"]) == "satisfied"

    assert get_in(downlink, ["throughput_model", "downlink_completion_source"]) ==
             "candidate_refresh.downlink_demand.objectives_and_operational_feedback"

    assert get_in(downlink, ["throughput_model", "downlink_completion_sources"]) == [
             "candidate_refresh.objectives.collection_latency",
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 300.0
    assert get_in(downlink, ["activity_context", "candidate_downlink_mb"]) == 360.0
    assert get_in(downlink, ["activity_context", "downlink_completion_ratio"]) == 1.0
    assert get_in(downlink, ["activity_context", "selected_downlink_shortfall_mb"]) == 0.0
    assert get_in(downlink, ["activity_context", "downlink_requirement_status"]) == "satisfied"

    assert get_in(downlink, ["activity_context", "downlink_completion_source"]) ==
             "candidate_refresh.downlink_demand.objectives_and_operational_feedback"

    assert get_in(downlink, ["activity_context", "downlink_completion_sources"]) == [
             "candidate_refresh.objectives.collection_latency",
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert %{
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "target_id" => "target_a",
             "source_activity_ids" => ["observe_sat_1_target_a_1"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "feedback_source" => "cadence.timeline_feedback",
             "feedback_scope" => "station_downlink_gap",
             "trust_boundary" => "cadence_operational_feedback"
           } = downlink

    downlink_lineage =
      Enum.find(
        artifact["source_window_lineage"],
        &(&1["candidate_activity_id"] == downlink["id"])
      )

    assert %{
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "target_id" => "target_a",
             "source_activity_ids" => ["observe_sat_1_target_a_1"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied",
             "source_window" => %{
               "collection_id" => "collection_alpha",
               "product_ids" => ["image_l0", "image_l1"],
               "target_id" => "target_a",
               "source_activity_ids" => ["observe_sat_1_target_a_1"],
               "required_downlink_mb" => 300.0,
               "candidate_downlink_mb" => 360.0,
               "downlink_completion_ratio" => 1.0
             }
           } = downlink_lineage

    diff_downlink =
      Enum.find(
        artifact["candidate_diff_report"]["new_candidates"],
        &(&1["id"] == downlink["id"])
      )

    assert %{
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "target_id" => "target_a",
             "source_activity_ids" => ["observe_sat_1_target_a_1"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied"
           } = diff_downlink

    assert downlink_lineage["selected_downlink_shortfall_mb"] == 0.0
    assert diff_downlink["selected_downlink_shortfall_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "accepts campaign-compatible downlink demand aliases in refresh objectives" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "ground_station_id" => "equator_prime",
              "min_downlink_mb" => 120.0
            },
            %{
              "type" => "collection_latency",
              "station_id" => "equator_prime",
              "required_volume_mb" => 90.0
            },
            %{
              "type" => "collection_latency",
              "station_id" => "equator_prime",
              "required_throughput_mb" => 30.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 240.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion_and_latency"

    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 240.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff records operational feedback changes for retained downlinks" do
    refresh =
      refresh_request()
      |> Map.put("prior_candidate_activities", [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "estimated_throughput_mb" => 360.0,
          "contact_success_factor" => 1.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
          "throughput_model" => %{
            "station_capacity_fraction" => 1.0,
            "station_throughput_factor" => 1.0
          }
        }
      ])
      |> put_in(["operational_feedback"], %{
        "station_throughput_factor" => %{"equator_prime" => 0.5},
        "contact_success_rate" => %{"equator_prime" => 0.4}
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
               "semantic_change_reasons" => semantic_change_reasons
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert "estimated_throughput_mb_changed" in semantic_change_reasons
    assert "contact_success_factor_changed" in semantic_change_reasons
    assert "station_capacity_fraction_changed" in semantic_change_reasons
    assert "station_throughput_factor_changed" in semantic_change_reasons

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not double apply station throughput feedback already encoded in ground network" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "station_throughput_factor" => %{"equator_prime" => 0.5}
      })
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "capacity_fraction" => 0.5,
          "provenance" => %{"station_throughput_factor_source" => "operational_feedback"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["estimated_throughput_mb"] == 180.0
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert get_in(downlink, ["throughput_model", "declared_station_capacity_fraction"]) == 0.5
    assert get_in(downlink, ["throughput_model", "station_throughput_factor"]) == 1.0
    refute Map.has_key?(downlink["throughput_model"], "station_throughput_factor_source")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp result_set_with_same_station_different_spacecraft_nonoverlapping_contacts do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :leo_2,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(450.0, :tdb),
              ends_at: Epoch.new!(570.0, :tdb),
              metadata: %{
                max_elevation_deg: 72.0,
                minimum_elevation_deg: 6.0,
                sample_count: 4
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end
end
