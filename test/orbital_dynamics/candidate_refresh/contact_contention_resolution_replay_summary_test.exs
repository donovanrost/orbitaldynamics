defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  alias OrbitalDynamics.Communications.ContactContention

  test "contact contention resolution replay preserves direct compact summaries as source provenance" do
    resolution_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "model" => "artifact_only_contact_contention_resolution_summary",
      "source_artifact_type" => "contact_contention_resolution_report.v1",
      "policy" => %{"selection_rule" => "highest_score_earliest_start"},
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendation_group_ids" => ["station:equator_prime:contention:1"],
      "review_group_ids" => ["station:equator_prime:contention:1"],
      "selected_contact_ids" => ["selected_contact"],
      "selected_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["selected_contact"]
      },
      "deferred_contact_ids" => ["deferred_contact"],
      "deferred_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["deferred_contact"]
      },
      "ambiguous_group_ids" => [],
      "ambiguous_duplicate_contact_ids" => [],
      "ambiguous_duplicate_contact_ids_by_group_id" => %{},
      "review_contact_ids" => ["deferred_contact", "selected_contact"],
      "review_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["deferred_contact", "selected_contact"]
      },
      "review_recommendation_count" => 1,
      "resource_scope_counts" => %{"ground_station" => 1},
      "selected_contact_ids_by_resource_scope" => %{"ground_station" => ["selected_contact"]},
      "deferred_contact_ids_by_resource_scope" => %{"ground_station" => ["deferred_contact"]},
      "review_contact_ids_by_resource_scope" => %{
        "ground_station" => ["deferred_contact", "selected_contact"]
      },
      "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
      "selected_contact_ids_by_selection_reason" => %{
        "highest_score_earliest_start" => ["selected_contact"]
      },
      "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
      "review_contact_ids_by_action" => %{
        "recommend_preferred_contact_for_operator_review" => [
          "deferred_contact",
          "selected_contact"
        ]
      },
      "capacity_pack_required_capacity_fraction" => 0.55,
      "capacity_pack_selected_required_capacity_fraction" => 0.2,
      "capacity_pack_deferred_required_capacity_fraction" => 0.35,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred" => 0.35,
        "selected" => 0.2
      },
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.55
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.2
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.35
      },
      "required_capacity_fraction_source_counts" => %{
        "source_contact_candidate.required_capacity_fraction" => 2
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "source_contact_candidate.required_capacity_fraction" => [
          "deferred_contact",
          "selected_contact"
        ]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "candidate_mutation" => "none",
        "operator_authority" => "not_granted_by_summary",
        "source" => "contact_contention_resolution_report.v1"
      },
      "provenance" => %{"trust_boundary" => "ops_resolution_summary"}
    }

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(resolution_summary)

    assert :contact_contention_resolution_summary in ContactContention.capabilities().public_facades

    refresh = %{
      "accepted_planning_state" => %{
        "contact_contention_resolution_summary" => resolution_summary
      },
      "mission_state" => %{
        "source_contact_contention_resolution_summary" => resolution_summary
      },
      "source_contact_contention_resolution_summary" => resolution_summary,
      "source_result_artifact" => %{
        "schema_contract" => "candidate_refresh.v1",
        "contact_contention_resolution_summary" => resolution_summary,
        "provenance" => %{"trust_boundary" => "artifact_resolution_summary"}
      }
    }

    assert %{
             "source_report_contact_contention_resolution_recommendation_count" => 4,
             "source_report_contact_contention_resolution_conflict_group_count" => 4,
             "source_report_contact_contention_resolution_review_recommendation_count" => 4,
             "source_report_contact_contention_resolution_source_summary_model_counts" => %{
               "artifact_only_contact_contention_resolution_summary" => 4
             },
             "source_report_contact_contention_resolution_source_summary_schema_contract_counts" =>
               %{
                 "contact_contention_resolution_summary.v1" => 4
               },
             "source_report_contact_contention_resolution_source_artifact_type_counts" => %{
               "contact_contention_resolution_report.v1" => 4
             },
             "source_report_contact_contention_resolution_recommendation_group_ids" => [
               "station:equator_prime:contention:1"
             ],
             "source_report_contact_contention_resolution_review_group_ids" => [
               "station:equator_prime:contention:1"
             ],
             "source_report_contact_contention_resolution_deferred_contact_count" => 4,
             "source_report_contact_contention_resolution_selected_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_contention_resolution_selected_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_deferred_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["deferred_contact"]
             },
             "source_report_contact_contention_resolution_review_contact_ids" => [
               "deferred_contact",
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_resource_scope_counts" => %{
               "ground_station" => 4
             },
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score_earliest_start" => 4
             },
             "source_report_contact_contention_resolution_selected_contact_ids_by_selection_reason" =>
               %{
                 "highest_score_earliest_start" => ["selected_contact"]
               },
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 4
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 2.2,
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
               0.8,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               1.4,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 2.2},
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status" =>
               %{"deferred" => 1.4, "selected" => 0.8},
             "source_reports" => %{
               "contact_contention_resolution_report" => resolution_source_summary
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert resolution_source_summary["contract"] == "contact_contention_resolution_summary.v1"
    assert resolution_source_summary["count"] == 4
    assert resolution_source_summary["row_count"] == 4

    assert resolution_source_summary["paths"] == [
             "accepted_planning_state.contact_contention_resolution_summary",
             "mission_state.source_contact_contention_resolution_summary",
             "source_contact_contention_resolution_summary",
             "source_result_artifact.contact_contention_resolution_summary"
           ]

    assert resolution_source_summary["trust_boundary_status"] == "declared"
    assert resolution_source_summary["trust_boundaries"] == ["ops_resolution_summary"]

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["contract"] == "contact_contention_resolution_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["source_report_paths"] == resolution_source_summary["paths"]

    assert replay_summary["source_summary_model_counts"] == %{
             "artifact_only_contact_contention_resolution_summary" => 4
           }

    assert replay_summary["source_summary_schema_contract_counts"] == %{
             "contact_contention_resolution_summary.v1" => 4
           }

    assert replay_summary["conflict_group_count"] == 4
    assert replay_summary["recommendation_count"] == 4
    assert replay_summary["review_recommendation_count"] == 4
    assert replay_summary["deferred_contact_count"] == 4
    assert replay_summary["recommendation_group_ids"] == ["station:equator_prime:contention:1"]
    assert replay_summary["review_group_ids"] == ["station:equator_prime:contention:1"]
    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]
    assert replay_summary["review_contact_ids"] == ["deferred_contact", "selected_contact"]
    assert replay_summary["resource_scope_counts"] == %{"ground_station" => 4}

    assert replay_summary["selected_contact_ids_by_selection_reason"] == %{
             "highest_score_earliest_start" => ["selected_contact"]
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "recommend_preferred_contact_for_operator_review" => 4
           }

    assert replay_summary["capacity_pack_required_capacity_fraction"] == 2.2
    assert replay_summary["capacity_pack_selected_required_capacity_fraction"] == 0.8
    assert replay_summary["capacity_pack_deferred_required_capacity_fraction"] == 1.4

    assert replay_summary["capacity_pack_required_capacity_fraction_by_status"] == %{
             "deferred" => 1.4,
             "selected" => 0.8
           }

    assert replay_summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 2.2
           }

    assert replay_summary["trust_boundaries"] == ["ops_resolution_summary"]
    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]
    assert replay_summary["branch_local_capacity_pack_pressure"]
    assert replay_summary["branch_local_contact_contention_resolution_action_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.contact_contention_resolution_replay_summary(artifact) ==
             replay_summary
  end

  test "contact contention resolution replay treats preserved ID maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "paths" => ["provenance.source_reports.contact_contention_resolution_report"],
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "row_count" => 0,
            "recommendation_count" => 0,
            "deferred_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_required_capacity_fraction" => 0.0,
            "capacity_pack_deferred_required_capacity_fraction" => 0.0,
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "selected_contact_ids" => ["selected_contact"],
            "deferred_contact_ids" => ["deferred_contact"],
            "selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "required_operator_action_counts" => %{
              "review_contact_contention_resolution" => 1
            },
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contention_resolution"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["recommendation_count"] == 0
    assert summary["deferred_contact_count"] == 0
    assert summary["selected_contact_ids"] == ["selected_contact"]
    assert summary["deferred_contact_ids"] == ["deferred_contact"]

    assert summary["selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert summary["deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert summary["branch_local_contact_contention_resolution_pressure"]
    assert summary["branch_local_deferred_contact_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_contact_contention_resolution_action_pressure"]
  end

  test "contact contention resolution replay filters phantom group lineage" do
    resolution_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "recommendation_group_ids" => ["real_contention_group"],
      "review_group_ids" => ["phantom_review_group"],
      "ambiguous_group_ids" => ["phantom_ambiguous_group"],
      "selected_contact_ids" => ["selected_contact"],
      "deferred_contact_ids" => ["deferred_contact"],
      "review_contact_ids" => ["deferred_contact", "selected_contact"],
      "ambiguous_duplicate_contact_ids" => ["duplicate_contact"],
      "selected_contact_ids_by_group_id" => %{
        "phantom_decision_group" => ["selected_contact"]
      },
      "deferred_contact_ids_by_group_id" => %{
        "phantom_decision_group" => ["deferred_contact"]
      },
      "review_contact_ids_by_group_id" => %{
        "phantom_review_group" => ["deferred_contact", "selected_contact"]
      },
      "ambiguous_duplicate_contact_ids_by_group_id" => %{
        "phantom_ambiguous_group" => ["duplicate_contact"]
      }
    }

    refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_contact_contention_resolution_summary" => resolution_summary
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary["source_report_contact_contention_resolution_recommendation_group_ids"] ==
             ["real_contention_group"]

    assert List.wrap(
             source_summary["source_report_contact_contention_resolution_review_group_ids"]
           ) == []

    assert Map.get(
             source_summary,
             "source_report_contact_contention_resolution_selected_contact_ids_by_group_id",
             %{}
           ) == %{}

    assert Map.get(
             source_summary,
             "source_report_contact_contention_resolution_deferred_contact_ids_by_group_id",
             %{}
           ) == %{}

    assert Map.get(
             source_summary,
             "source_report_contact_contention_resolution_review_contact_ids_by_group_id",
             %{}
           ) == %{}

    assert Map.get(
             source_summary,
             "source_report_contact_contention_resolution_ambiguous_duplicate_contact_ids_by_group_id",
             %{}
           ) == %{}

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["recommendation_group_ids"] == ["real_contention_group"]
    assert List.wrap(replay_summary["review_group_ids"]) == []
    assert List.wrap(replay_summary["ambiguous_group_ids"]) == []
    assert Map.get(replay_summary, "selected_contact_ids_by_group_id", %{}) == %{}
    assert Map.get(replay_summary, "deferred_contact_ids_by_group_id", %{}) == %{}
    assert Map.get(replay_summary, "review_contact_ids_by_group_id", %{}) == %{}
    assert Map.get(replay_summary, "ambiguous_duplicate_contact_ids_by_group_id", %{}) == %{}
    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]
    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]

    preserved_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" =>
            Map.put(resolution_summary, "contract", "contact_contention_resolution_summary.v1")
        }
      }
    }

    preserved_replay =
      CandidateRefresh.contact_contention_resolution_replay_summary(preserved_artifact)

    assert preserved_replay["recommendation_group_ids"] == ["real_contention_group"]
    assert List.wrap(preserved_replay["review_group_ids"]) == []
    assert List.wrap(preserved_replay["ambiguous_group_ids"]) == []
    assert Map.get(preserved_replay, "selected_contact_ids_by_group_id", %{}) == %{}
    assert Map.get(preserved_replay, "deferred_contact_ids_by_group_id", %{}) == %{}
    assert Map.get(preserved_replay, "review_contact_ids_by_group_id", %{}) == %{}

    assert Map.get(preserved_replay, "ambiguous_duplicate_contact_ids_by_group_id", %{}) ==
             %{}
  end

  test "contact contention resolution replay filters phantom categorical routing" do
    resolution_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "recommendation_count" => 1,
      "conflict_group_count" => 1,
      "selected_contact_ids" => ["selected_contact"],
      "deferred_contact_ids" => ["deferred_contact"],
      "review_contact_ids" => ["deferred_contact", "selected_contact"],
      "resource_scope_counts" => %{"ground_station" => 1, "zero_scope" => 0},
      "selection_reason_counts" => %{"highest_score" => 1, "zero_reason" => 0},
      "action_counts" => %{
        "review_contact_contention_resolution" => 1,
        "zero_action" => 0
      },
      "selected_contact_ids_by_resource_scope" => %{
        "phantom_scope" => ["selected_contact"],
        "zero_scope" => ["selected_contact"]
      },
      "deferred_contact_ids_by_resource_scope" => %{
        "phantom_scope" => ["deferred_contact"],
        "zero_scope" => ["deferred_contact"]
      },
      "review_contact_ids_by_resource_scope" => %{
        "phantom_scope" => ["deferred_contact", "selected_contact"],
        "zero_scope" => ["deferred_contact", "selected_contact"]
      },
      "selected_contact_ids_by_selection_reason" => %{
        "phantom_reason" => ["selected_contact"],
        "zero_reason" => ["selected_contact"]
      },
      "review_contact_ids_by_action" => %{
        "phantom_action" => ["deferred_contact", "selected_contact"],
        "zero_action" => ["deferred_contact", "selected_contact"]
      }
    }

    refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_contact_contention_resolution_summary" => resolution_summary
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary["source_report_contact_contention_resolution_selected_contact_ids"] ==
             ["selected_contact"]

    assert source_summary["source_report_contact_contention_resolution_deferred_contact_ids"] ==
             ["deferred_contact"]

    assert source_summary["source_report_contact_contention_resolution_review_contact_ids"] ==
             ["deferred_contact", "selected_contact"]

    assert source_summary["source_report_contact_contention_resolution_resource_scope_counts"] ==
             %{"ground_station" => 1, "zero_scope" => 0}

    assert source_summary[
             "source_report_contact_contention_resolution_selection_reason_counts"
           ] == %{"highest_score" => 1, "zero_reason" => 0}

    assert source_summary[
             "source_report_contact_contention_resolution_required_operator_action_counts"
           ] == %{"review_contact_contention_resolution" => 1, "zero_action" => 0}

    for field <- [
          "selected_contact_ids_by_resource_scope",
          "deferred_contact_ids_by_resource_scope",
          "review_contact_ids_by_resource_scope",
          "selected_contact_ids_by_selection_reason",
          "review_contact_ids_by_action"
        ] do
      assert Map.get(
               source_summary,
               "source_report_contact_contention_resolution_#{field}",
               %{}
             ) == %{}
    end

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]
    assert replay_summary["review_contact_ids"] == ["deferred_contact", "selected_contact"]
    assert replay_summary["resource_scope_counts"] == %{"ground_station" => 1, "zero_scope" => 0}

    assert replay_summary["selection_reason_counts"] == %{
             "highest_score" => 1,
             "zero_reason" => 0
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "review_contact_contention_resolution" => 1,
             "zero_action" => 0
           }

    for field <- [
          "selected_contact_ids_by_resource_scope",
          "deferred_contact_ids_by_resource_scope",
          "review_contact_ids_by_resource_scope",
          "selected_contact_ids_by_selection_reason",
          "review_contact_ids_by_action"
        ] do
      assert Map.get(replay_summary, field, %{}) == %{}
    end

    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]

    preserved_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" =>
            Map.put(resolution_summary, "contract", "contact_contention_resolution_summary.v1")
        }
      }
    }

    preserved_replay =
      CandidateRefresh.contact_contention_resolution_replay_summary(preserved_artifact)

    assert preserved_replay["selected_contact_ids"] == ["selected_contact"]
    assert preserved_replay["deferred_contact_ids"] == ["deferred_contact"]

    for field <- [
          "selected_contact_ids_by_resource_scope",
          "deferred_contact_ids_by_resource_scope",
          "review_contact_ids_by_resource_scope",
          "selected_contact_ids_by_selection_reason",
          "review_contact_ids_by_action"
        ] do
      assert Map.get(preserved_replay, field, %{}) == %{}
    end
  end
end
