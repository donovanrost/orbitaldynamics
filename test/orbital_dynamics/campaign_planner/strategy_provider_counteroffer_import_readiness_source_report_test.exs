Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderCounterofferImportReadinessSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state provider-counteroffer import-readiness summaries into branch refresh requests" do
    import_readiness_summary = fn prefix, import_status, import_classification ->
      review_required? = import_status == "review_required_before_import"
      counteroffer_id = "#{prefix}_counteroffer"
      required_action = if(review_required?, do: "review_provider_counteroffer", else: "none")
      lock_status = if(review_required?, do: "active", else: "missing")
      cost_delta = if(review_required?, do: 75.0, else: 25.0)

      %{
        "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
        "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "import_readiness_status" =>
          if(review_required?, do: "review_required", else: "import_ready"),
        "import_classification" => import_classification,
        "counteroffer_count" => 1,
        "reviewable_count" => if(review_required?, do: 1, else: 0),
        "counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => cost_delta,
        "counteroffer_lock_deadline_count" => if(review_required?, do: 1, else: 0),
        "earliest_counteroffer_lock_deadline_s" => if(review_required?, do: 360.0, else: nil),
        "provider_counteroffer_import_status_counts" => %{import_status => 1},
        "counteroffer_lock_deadline_status_counts" => %{lock_status => 1},
        "counteroffer_ids_by_import_status" => %{import_status => [counteroffer_id]},
        "counteroffer_ids_by_required_import_action" => %{required_action => [counteroffer_id]},
        "counteroffer_ids_by_lock_deadline_status" => %{lock_status => [counteroffer_id]},
        "review_counteroffer_ids" => if(review_required?, do: [counteroffer_id], else: []),
        "no_import_required_counteroffer_ids" =>
          if(review_required?, do: [], else: [counteroffer_id]),
        "import_readiness_rows" => [
          %{
            "provider_counteroffer_id" => counteroffer_id,
            "provider_counteroffer_status" =>
              if(review_required?, do: "proposed", else: "accepted"),
            "provider_counteroffer_cost_delta" => cost_delta,
            "provider_counteroffer_lock_deadline_s" => if(review_required?, do: 360.0, else: nil),
            "provider_counteroffer_lock_deadline_status" => lock_status,
            "provider_counteroffer_import_status" => import_status,
            "import_readiness_status" => if(review_required?, do: "", else: nil),
            "import_classification" => if(review_required?, do: "", else: nil),
            "required_operator_action" => required_action,
            "reviewable" => review_required?,
            "trust_boundary" => "#{prefix}_provider_counteroffer_row_boundary"
          }
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Map.new()
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_provider_counteroffer_import_readiness_boundary"
        }
      }
    end

    direct_summary =
      import_readiness_summary.("direct", "review_required_before_import", "review_only")

    canonical_summary = import_readiness_summary.("canonical", "import_ready", "ready")

    wrapped_summary = import_readiness_summary.("wrapped", "import_ready", "ready")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_provider_counteroffer_import_readiness_summary", direct_summary)
      |> Map.put("provider_counteroffer_import_readiness_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "provider_counteroffer_import_readiness_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "wrapped_provider_counteroffer_import_readiness_boundary"
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
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

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    for source_path <- [
          "mission_state.source_provider_counteroffer_import_readiness_summary",
          "mission_state.provider_counteroffer_import_readiness_summary",
          "mission_state.source_result_artifact.provider_counteroffer_import_readiness_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_provider_counteroffer_reviewable_count" => 1,
             "source_report_provider_counteroffer_cost_delta_count" => 3,
             "source_report_provider_counteroffer_cost_delta_total" => 125.0,
             "source_report_provider_counteroffer_import_readiness_summary_count" => 3,
             "source_report_provider_counteroffer_import_readiness_status_counts" => %{
               "import_ready" => 2,
               "review_required" => 1
             },
             "source_report_provider_counteroffer_import_classification_counts" => %{
               "ready" => 2,
               "review_only" => 1
             },
             "source_report_provider_counteroffer_import_status_counts" => %{
               "import_ready" => 2,
               "review_required_before_import" => 1
             },
             "source_report_provider_counteroffer_counteroffer_ids_by_import_status" => %{
               "import_ready" => ["canonical_counteroffer", "wrapped_counteroffer"],
               "review_required_before_import" => ["direct_counteroffer"]
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => replay_source_paths,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 3,
             "counteroffer_cost_delta_total" => 125.0,
             "import_readiness_summary_count" => 3,
             "import_readiness_status_counts" => %{
               "import_ready" => 2,
               "review_required" => 1
             },
             "import_classification_counts" => %{"ready" => 2, "review_only" => 1},
             "provider_counteroffer_import_status_counts" => %{
               "import_ready" => 2,
               "review_required_before_import" => 1
             },
             "counteroffer_ids_by_import_status" => %{
               "import_ready" => ["canonical_counteroffer", "wrapped_counteroffer"],
               "review_required_before_import" => ["direct_counteroffer"]
             },
             "counteroffer_ids_by_required_import_action" => %{
               "none" => ["canonical_counteroffer", "wrapped_counteroffer"],
               "review_provider_counteroffer" => ["direct_counteroffer"]
             },
             "counteroffer_ids_by_lock_deadline_status" => %{
               "active" => ["direct_counteroffer"],
               "missing" => ["canonical_counteroffer", "wrapped_counteroffer"]
             },
             "review_counteroffer_ids" => ["direct_counteroffer"],
             "no_import_required_counteroffer_ids" => [
               "canonical_counteroffer",
               "wrapped_counteroffer"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_write" => "not_performed_by_summary",
               "schedule_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.provider_counteroffer_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.provider_counteroffer_import_readiness_summary",
             "mission_state.source_provider_counteroffer_import_readiness_summary",
             "mission_state.source_result_artifact.provider_counteroffer_import_readiness_summary"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_provider_counteroffer_import_readiness_boundary",
             "canonical_provider_counteroffer_row_boundary",
             "direct_provider_counteroffer_import_readiness_boundary",
             "direct_provider_counteroffer_row_boundary",
             "wrapped_provider_counteroffer_import_readiness_boundary",
             "wrapped_provider_counteroffer_row_boundary"
           ]

    direct_branch = branch(artifact, "derived_provider_counteroffer_pressure_direct_counteroffer")

    assert is_nil(
             branch(artifact, "derived_provider_counteroffer_pressure_canonical_counteroffer")
           )

    assert is_nil(branch(artifact, "derived_provider_counteroffer_pressure_wrapped_counteroffer"))

    assert %{
             "type" => "provider_counteroffer_pressure",
             "provider_counteroffer_id" => "direct_counteroffer",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_cost_delta" => 75.0,
             "provider_counteroffer_lock_deadline_s" => 360.0,
             "provider_counteroffer_lock_deadline_status" => "active",
             "provider_counteroffer_import_status" => "review_required_before_import",
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "required_operator_action" => "review_provider_counteroffer",
             "feedback_source" =>
               "mission_state.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "feedback_scope" => "provider_counteroffer",
             "trust_boundary" => "direct_provider_counteroffer_row_boundary",
             "derivation_reasons" => derivation_reasons,
             "assumptions" => %{
               "provider_write" => "not_performed_by_strategy_branch",
               "schedule_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch"
             }
           } = List.first(direct_branch["events"])

    assert "provider_counteroffer_import_readiness" in derivation_reasons
    assert "provider_counteroffer_cost_delta" in derivation_reasons
    assert "provider_counteroffer_lock_deadline" in derivation_reasons

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_pressure" and
                 &1["provider_counteroffer_import_status"] ==
                   "review_required_before_import" and
                 &1["import_classification"] == "review_only")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    provider_counteroffer_pressure_count =
      Enum.count(
        direct_branch["risk_indicators"],
        &(&1["feedback_scope"] == "provider_counteroffer")
      )

    assert provider_counteroffer_pressure_count == 1

    assert direct_branch["score_terms"]["provider_counteroffer_pressure_penalty"] ==
             -provider_counteroffer_pressure_count * risk_weight

    assert direct_branch["score_terms"]["risk_penalty"] ==
             -(length(direct_branch["risk_indicators"]) -
                 provider_counteroffer_pressure_count) *
               risk_weight

    assert "provider_counteroffer_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "derived_provider_counteroffer_pressure_direct_counteroffer" and
                 &1["term_key"] == "provider_counteroffer_pressure_penalty" and &1["value"] < 0.0)
           )

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_provider_counteroffer_pressure_direct_counteroffer")
      )

    assert "provider_counteroffer_pressure" in comparison_row["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores provider-counteroffer import-readiness rows when top-level fields are stale" do
    stale_summary = %{
      "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
      "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
      "source_artifact_type" => "provider_counteroffer_report.v1",
      "import_readiness_status" => "import_ready",
      "import_classification" => "ready",
      "counteroffer_count" => 1,
      "reviewable_count" => 0,
      "counteroffer_cost_delta_count" => 0,
      "counteroffer_cost_delta_total" => 0.0,
      "counteroffer_lock_deadline_count" => 0,
      "provider_counteroffer_import_status_counts" => %{"import_ready" => 99},
      "counteroffer_lock_deadline_status_counts" => %{"missing" => 99},
      "counteroffer_ids_by_import_status" => %{"import_ready" => ["stale_counteroffer"]},
      "counteroffer_ids_by_required_import_action" => %{"none" => ["stale_counteroffer"]},
      "counteroffer_ids_by_lock_deadline_status" => %{"missing" => ["stale_counteroffer"]},
      "review_counteroffer_ids" => [],
      "no_import_required_counteroffer_ids" => ["stale_counteroffer"],
      "import_readiness_rows" => [
        %{
          "provider_counteroffer_id" => "row_counteroffer",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_cost_delta" => 125.0,
          "provider_counteroffer_lock_deadline_s" => 420.0,
          "provider_counteroffer_lock_deadline_status" => "active",
          "provider_counteroffer_import_status" => "review_required_before_import",
          "import_readiness_status" => "",
          "import_classification" => "",
          "required_operator_action" => "review_provider_counteroffer",
          "reviewable" => true,
          "trust_boundary" => "row_counteroffer_import_readiness_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "stale_counteroffer_import_readiness_boundary"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_provider_counteroffer_import_readiness_summary", stale_summary),
        derive_branches?: true,
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
    candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "source_report_provider_counteroffer_reviewable_count" => 1,
             "source_report_provider_counteroffer_cost_delta_count" => 1,
             "source_report_provider_counteroffer_cost_delta_total" => 125.0,
             "source_report_provider_counteroffer_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "source_report_provider_counteroffer_import_readiness_status_counts" => %{
               "review_required" => 1
             },
             "source_report_provider_counteroffer_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_report_provider_counteroffer_counteroffer_ids_by_import_status" => %{
               "review_required_before_import" => ["row_counteroffer"]
             },
             "source_report_provider_counteroffer_counteroffer_ids_by_required_import_action" =>
               %{
                 "review_provider_counteroffer" => ["row_counteroffer"]
               },
             "source_report_provider_counteroffer_review_counteroffer_ids" => [
               "row_counteroffer"
             ]
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert Map.get(
             candidate_source["candidate_refresh_request_source_report_summary"],
             "source_report_provider_counteroffer_no_import_required_counteroffer_ids"
           ) in [nil, []]

    assert %{
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.0,
             "import_readiness_status_counts" => %{"review_required" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "provider_counteroffer_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "counteroffer_ids_by_import_status" => %{
               "review_required_before_import" => ["row_counteroffer"]
             },
             "counteroffer_ids_by_required_import_action" => %{
               "review_provider_counteroffer" => ["row_counteroffer"]
             },
             "counteroffer_ids_by_lock_deadline_status" => %{"active" => ["row_counteroffer"]},
             "review_counteroffer_ids" => ["row_counteroffer"],
             "branch_local_counteroffer_import_readiness_pressure" => true
           } = CandidateRefresh.provider_counteroffer_replay_summary(candidate_source)

    assert Map.get(
             CandidateRefresh.provider_counteroffer_replay_summary(candidate_source),
             "no_import_required_counteroffer_ids"
           ) in [nil, []]

    scored_branch = branch(artifact, "derived_provider_counteroffer_pressure_row_counteroffer")

    assert %{
             "type" => "provider_counteroffer_pressure",
             "provider_counteroffer_id" => "row_counteroffer",
             "provider_counteroffer_cost_delta" => 125.0,
             "provider_counteroffer_lock_deadline_s" => 420.0,
             "provider_counteroffer_lock_deadline_status" => "active",
             "provider_counteroffer_import_status" => "review_required_before_import",
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "required_operator_action" => "review_provider_counteroffer",
             "feedback_source" =>
               "mission_state.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "trust_boundary" => "row_counteroffer_import_readiness_boundary"
           } = List.first(scored_branch["events"])

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert scored_branch["score_terms"]["provider_counteroffer_pressure_penalty"] ==
             -risk_weight

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "derived_provider_counteroffer_pressure_row_counteroffer" and
                 &1["term_key"] == "provider_counteroffer_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
