defmodule OrbitalDynamics.CandidateRefresh.BuildResourceFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "uses mission-state spacecraft rows for resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["accepted_planning_state", "spacecraft_states"], [])
      |> Map.put("mission_state", %{
        "spacecraft_states" => [%{"scenario_id" => "leo_1", "spacecraft_id" => "sat_1"}],
        "resource_summaries" => [
          %{
            "spacecraft_id" => "sat_1",
            "payload_available" => false,
            "antenna_available" => true,
            "assumptions" => %{"model" => "mission_state_resource_summary"}
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_observe_target_a_1",
                 "spacecraft_id" => "sat_1",
                 "suppressed_reason" => "payload_unavailable"
               }
             ]
           } = artifact["resource_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses accepted planning-state resource summaries for resource filtering" do
    refresh =
      refresh_request()
      |> Map.delete("resource_summaries")
      |> put_in(["accepted_planning_state", "resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "payload_available" => false,
          "antenna_available" => true,
          "source_quality" => "accepted_planning_state",
          "provenance" => %{"trust_boundary" => "accepted_resource_snapshot"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_resource_source_quality_counts" => %{
               "accepted_planning_state" => 1
             },
             "suppressed_resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_observe_target_a_1",
                 "spacecraft_id" => "sat_1",
                 "suppressed_reason" => "payload_unavailable",
                 "resource_source_quality" => "accepted_planning_state",
                 "resource_trust_boundary" => "accepted_resource_snapshot",
                 "resource_trust_boundary_status" => "declared",
                 "source_resource_summary" => %{
                   "spacecraft_id" => "sat_1",
                   "payload_available" => false,
                   "antenna_available" => true,
                   "provenance" => %{
                     "trust_boundary" => "accepted_resource_snapshot"
                   }
                 }
               }
             ]
           } = artifact["resource_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "suppresses branch refresh candidates when resource summaries are ambiguous" do
    refresh =
      refresh_request()
      |> Map.put("resource_summaries", [
        %{
          "spacecraft_id" => "leo_1",
          "payload_available" => false,
          "source_quality" => "ops_console",
          "provenance" => %{"trust_boundary" => "operator_declared_resource_summary"}
        },
        %{
          "spacecraft_id" => "leo_1",
          "payload_available" => true,
          "source_quality" => "partner_report",
          "provenance" => %{"trust_boundary" => "partner_resource_report"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []
    assert artifact["contact_intents"] == []

    assert %{
             "suppressed_candidate_count" => 2,
             "suppressed_resource_source_quality_counts" => %{"ambiguous" => 2},
             "suppressed_candidates" => suppressed
           } = artifact["resource_filter_report"]

    assert Enum.map(suppressed, & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.all?(suppressed, fn row ->
             row["suppressed_reason"] == "ambiguous_resource_summary" and
               row["ambiguous_resource_summary"] == true and
               row["resource_summary_key"] == "leo_1" and
               row["resource_summary_count"] == 2 and
               row["resource_source_qualities"] == ["ops_console", "partner_report"]
           end)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters refreshed candidates outside the remaining horizon" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          put_in(refresh_request(), ["remaining_horizon"], %{
            "starts_at_s" => 300.0,
            "ends_at_s" => 500.0,
            "output_step_s" => 60.0
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]
  end

  test "filters refreshed candidates using resource summary availability" do
    refresh =
      put_in(refresh_request(), ["resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "payload_available" => false,
          "antenna_available" => true,
          "assumptions" => %{"model" => "operator_summary"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_observe_target_a_1",
                 "suppressed_reason" => "payload_unavailable",
                 "resource_blocking_dimension" => "payload"
               }
             ]
           } = artifact["resource_filter_report"]

    assert "resource summary filters suppressed refreshed candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters all refreshed spacecraft candidates using resource summary spacecraft availability" do
    refresh =
      put_in(refresh_request(), ["resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "spacecraft_available" => false,
          "payload_available" => true,
          "antenna_available" => true,
          "assumptions" => %{"model" => "operator_summary"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["spacecraft_available"] == false)
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false
             },
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "classifies antenna-unavailable refreshed downlinks through resource policy" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "degraded_payload_guard_v1"})
      |> put_in(["resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "payload_available" => true,
          "antenna_available" => false,
          "assumptions" => %{"model" => "operator_summary"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "antenna_unavailable",
                 "resource_blocking_dimension" => "antenna",
                 "antenna_available" => false,
                 "approval_status" => "blocked_by_policy",
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "antenna_unavailable_contact_block",
                     "antenna_available" => false
                   }
                 ],
                 "policy_decision" => %{
                   "classification" => "blocked_by_policy",
                   "rule_matches" => [
                     %{
                       "rule_id" => "antenna_unavailable_contact_block",
                       "antenna_available" => false
                     }
                   ]
                 }
               }
             ]
           } = artifact["resource_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies resource availability feedback to refreshed resource summaries" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{"payload_available" => "0"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_blocking_dimension" => "payload",
               "resource_source_quality" => "operational_feedback",
               "resource_trust_boundary" => "operational_feedback",
               "resource_trust_boundary_status" => "declared"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["resource_filter_report"]["resource_trust_boundary_status_counts"] == %{
             "declared" => 1,
             "missing" => 1
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies JSON-style boolean availability feedback before resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{
            "payload_available" => "false",
            "antenna_available" => "false",
            "degraded" => "true"
          }
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == false and &1["degraded"] == true and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_blocking_dimension" => "payload",
               "payload_available" => false,
               "degraded" => true,
               "resource_source_quality" => "operational_feedback"
             },
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "antenna_unavailable",
               "resource_blocking_dimension" => "antenna",
               "antenna_available" => false,
               "degraded" => true,
               "resource_source_quality" => "operational_feedback"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies provider status-word availability feedback before resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{
            "payload_status" => "Maintenance",
            "antenna_status" => "Outage"
          }
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == false and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "payload_unavailable",
               "payload_available" => false
             },
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "antenna_unavailable",
               "antenna_available" => false
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies resource availability feedback activity-type constraints before filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{
            "suppressed_activity_types" => [:observe],
            "incompatible_activity_types" => "downlink"
          }
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and
                 &1["suppressed_activity_types"] == ["observe"] and
                 &1["incompatible_activity_types"] == ["downlink"] and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "activity_type_suppressed_by_resource_summary",
               "resource_blocking_dimension" => "activity_type",
               "suppressed_activity_types" => ["observe"],
               "resource_source_quality" => "operational_feedback"
             },
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "activity_type_incompatible_with_resource_summary",
               "resource_blocking_dimension" => "activity_type",
               "incompatible_activity_types" => ["downlink"],
               "resource_source_quality" => "operational_feedback"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "resource feedback summaries preserve declared feedback trust boundary" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "trust_boundary" => "cadence_operational_feedback",
        "resource_availability_overrides" => %{
          "sat_1" => %{"payload_available" => false}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) ==
                   "cadence_operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_source_quality" => "operational_feedback",
               "resource_trust_boundary" => "cadence_operational_feedback",
               "resource_trust_boundary_status" => "declared"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert Enum.any?(
             review["rows"],
             &(&1["review_type"] == "resource_suppression" and
                 &1["resource_trust_boundary"] == "cadence_operational_feedback" and
                 get_in(&1, ["source_resource_suppression", "resource_trust_boundary"]) ==
                   "cadence_operational_feedback")
           )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert Enum.any?(
             manifest["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["resource_trust_boundary"] == "cadence_operational_feedback" and
                 get_in(&1, ["source_resource_suppression", "resource_trust_boundary"]) ==
                   "cadence_operational_feedback")
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1", "status" => "pass"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(manifest)
  end

  test "applies degraded resource availability feedback before resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{"mode" => "degraded"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["mode"] == "degraded" and
                 &1["degraded"] == true and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "spacecraft_degraded_payload_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "degraded" => true,
               "resource_source_quality" => "operational_feedback",
               "resource_trust_boundary" => "operational_feedback",
               "resource_trust_boundary_status" => "declared"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies spacecraft unavailable feedback before resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{
          "sat_1" => %{"spacecraft_availability" => "false"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == false and &1["degraded"] == true and
                 &1["spacecraft_available"] == false and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false,
               "payload_available" => false,
               "degraded" => true,
               "resource_source_quality" => "operational_feedback"
             },
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false,
               "antenna_available" => false,
               "degraded" => true,
               "resource_source_quality" => "operational_feedback"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    review = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert [
             %{
               "review_type" => "resource_suppression",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false,
               "source_resource_suppression" => %{
                 "suppressed_reason" => "spacecraft_unavailable",
                 "spacecraft_available" => false
               }
             },
             %{
               "review_type" => "resource_suppression",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false
             }
           ] =
             review["rows"]
             |> Enum.filter(&(&1["review_type"] == "resource_suppression"))
             |> Enum.sort_by(& &1["activity_id"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert [
             %{
               "import_action" => "review_resource_suppression",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false,
               "source_resource_suppression" => %{
                 "suppressed_reason" => "spacecraft_unavailable",
                 "spacecraft_available" => false
               }
             },
             %{
               "import_action" => "review_resource_suppression",
               "suppressed_reason" => "spacecraft_unavailable",
               "resource_blocking_dimension" => "spacecraft_health",
               "spacecraft_available" => false
             }
           ] =
             manifest["rows"]
             |> Enum.filter(&(&1["import_action"] == "review_resource_suppression"))
             |> Enum.sort_by(& &1["activity_id"])
  end

  test "merges availability override alias with canonical resource availability feedback" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "resource_availability_overrides" => %{},
        "availability_overrides" => %{
          "sat_1" => %{"payload_available" => false}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "suppressed_reason" => "payload_unavailable"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "canonicalizes struct-style availability feedback flags before resource filtering" do
    refresh =
      refresh_request()
      |> put_in(["operational_feedback"], %{
        "availability_overrides" => %{
          "sat_1" => %{payload_available?: false}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 not Map.has_key?(&1, "payload_available?"))
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "suppressed_reason" => "payload_unavailable"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses shared resource filter report shape when no resource summaries are supplied" do
    refresh =
      refresh_request()
      |> Map.put("resource_summaries", [])
      |> Map.put("resource_filter_policy", %{"min_downlink_margin" => 0.2})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "model" => "resource_summary_availability_and_margin_filter",
             "policy" => %{"min_downlink_margin" => 0.2},
             "model_limits" => model_limits,
             "resource_source_quality_counts" => %{},
             "resource_trust_boundary_status_counts" => %{},
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = artifact["resource_filter_report"]

    assert "externally_supplied_resource_summary" in model_limits
    assert "no_subsystem_simulation" in model_limits

    refute "resource summary filters suppressed refreshed candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "invalid resource summaries are review gated without filtering refreshed candidates" do
    refresh =
      refresh_request()
      |> Map.put("resource_summaries", [
        %{
          spacecraft_id: :leo_1,
          payload_available: false,
          power_margin: 1.2,
          source_quality: :operator_supplied
        },
        :bad_resource_summary
      ])
      |> Map.put("resource_filter_policy", %{"min_observe_power_margin" => 0.2})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["resource_summaries"] == []

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 0,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["leo_1", "resource_summary:2"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "leo_1",
                 "spacecraft_id" => "leo_1",
                 "required_operator_action" => "review_invalid_resource_filter_summary",
                 "invalid_resource_summary_input_reason" => "invalid_power_margin",
                 "source_resource_summary" => %{"power_margin" => 1.2}
               },
               %{
                 "resource_summary_id" => "resource_summary:2",
                 "invalid_resource_summary_input_reason" => "invalid_resource_summary_shape",
                 "source_resource_summary" => %{"raw_input" => "\"bad_resource_summary\""}
               }
             ],
             "resource_source_quality_counts" => %{},
             "resource_trust_boundary_status_counts" => %{},
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = artifact["resource_filter_report"]

    assert "resource summary inputs require operator review" in artifact["warnings"]
    refute "resource summary filters suppressed refreshed candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    review = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(
             review["rows"],
             &(&1["required_operator_action"] == "review_invalid_resource_filter_summary" and
                 &1["invalid_resource_summary_input_reason"] == "invalid_power_margin" and
                 get_in(&1, ["source_resource_summary", "power_margin"]) == 1.2)
           )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(
             manifest["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["invalid_resource_summary_input"] == true and
                 get_in(&1, ["source_resource_summary", "raw_input"]) ==
                   "\"bad_resource_summary\"")
           )
  end

  test "applies resource margin feedback to refreshed resource summaries" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_downlink_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"downlink_capacity_margin" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["downlink_margin"] == 0.05 and
                 not Map.has_key?(&1, "downlink_capacity_margin") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "downlink_margin_below_policy",
               "resource_blocking_dimension" => "downlink",
               "downlink_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies storage capacity margin feedback alias before resource filtering" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_storage_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"storage_capacity_margin" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["storage_margin"] == 0.05 and
                 not Map.has_key?(&1, "storage_capacity_margin") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "storage_margin_below_observe_policy",
               "resource_blocking_dimension" => "storage",
               "storage_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "invalid resource feedback overrides are review gated before filtering" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_power_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"power_margin" => 1.2}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    refute Enum.any?(artifact["resource_summaries"], &(&1["spacecraft_id"] == "sat_1"))

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 1,
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "sat_1",
                 "invalid_resource_summary_input_reason" => "invalid_power_margin",
                 "source_resource_summary" => %{
                   "power_margin" => 1.2,
                   "source_quality" => "operational_feedback",
                   "provenance" => %{
                     "resource_feedback_source" => "operational_feedback",
                     "trust_boundary" => "operational_feedback"
                   }
                 }
               }
             ],
             "suppressed_candidate_count" => 0
           } = artifact["resource_filter_report"]

    assert "resource summary inputs require operator review" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses battery state of charge feedback as refresh-local power margin" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_power_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"battery_soc" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["battery_state_of_charge"] == 0.05 and
                 &1["power_margin"] == 0.05 and
                 not Map.has_key?(&1, "battery_soc") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "power_margin_below_observe_policy",
               "resource_blocking_dimension" => "power",
               "power_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses thermal margin feedback as a refresh-local resource margin" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_activity_thermal_margin_c" => 2.0})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"thermal_margin_c" => "1.5"}
        },
        "trust_boundary" => "ops_thermal_feedback"
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["thermal_margin_c"] == 1.5 and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_thermal_feedback")
           )

    assert Enum.map(
             artifact["resource_filter_report"]["suppressed_candidates"],
             &{&1["id"], &1["suppressed_reason"], &1["resource_blocking_dimension"],
              &1["thermal_margin_c"]}
           ) == [
             {"leo_1_observe_target_a_1", "thermal_margin_below_policy", "thermal", 1.5},
             {"leo_1_downlink_equator_prime_1", "thermal_margin_below_policy", "thermal", 1.5}
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters refreshed candidates using resource margin policy thresholds" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "conservative_ops_v1"})
      |> Map.put("resource_filter_policy", %{
        "min_observe_storage_margin" => 0.2,
        "min_downlink_margin" => 0.2
      })
      |> put_in(["resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "fuel_margin" => 0.9,
          "power_margin" => 0.8,
          "storage_margin" => 0.05,
          "downlink_margin" => 0.05,
          "payload_available" => true,
          "antenna_available" => true,
          "assumptions" => %{"model" => "operator_summary"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []
    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "model" => "resource_summary_availability_and_margin_filter",
             "policy" => %{
               "min_observe_storage_margin" => 0.2,
               "min_downlink_margin" => 0.2
             },
             "input_candidate_count" => 2,
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 2
           } = artifact["resource_filter_report"]

    assert Enum.map(
             artifact["resource_filter_report"]["suppressed_candidates"],
             &{&1["id"], &1["spacecraft_id"], &1["suppressed_reason"], &1["approval_status"]}
           ) == [
             {"leo_1_observe_target_a_1", "sat_1", "storage_margin_below_observe_policy",
              "blocked_by_policy"},
             {"leo_1_downlink_equator_prime_1", "sat_1", "downlink_margin_below_policy",
              "blocked_by_policy"}
           ]

    assert Enum.all?(
             artifact["resource_filter_report"]["suppressed_candidates"],
             &(get_in(&1, ["policy_decision", "policy_bundle_id"]) == "conservative_ops_v1")
           )

    assert Enum.any?(
             List.first(artifact["resource_filter_report"]["suppressed_candidates"])[
               "approval_rule_matches"
             ],
             &(&1["rule_id"] == "resource_pressure_block" and
                 &1["risk_type"] == "storage_overflow")
           )

    assert "resource summary filters suppressed refreshed candidates" in artifact["warnings"]

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
