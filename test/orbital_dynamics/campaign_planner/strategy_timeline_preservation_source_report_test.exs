Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelinePreservationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{Schema, Timeline}

  test "strategy derives branch pressure from timeline preservation reports and statuses" do
    preservation_report = fn prefix, trust_boundary ->
      [
        %{
          id: :"#{prefix}_contact_locked",
          type: :contact,
          locked: true,
          approval_status: :pending,
          metadata: %{timeline_id: "timeline:#{prefix}:contact_locked"}
        },
        %{
          id: :"#{prefix}_obs_done",
          type: :observe,
          status: :completed,
          metadata: %{timeline_id: "timeline:#{prefix}:obs_done"}
        },
        %{id: :"#{prefix}_bad_missing_type", status: :planned}
      ]
      |> Timeline.preservation_report(source: "mission.#{prefix}.timeline")
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_report = preservation_report.("direct_preservation", "direct_preservation_boundary")
    canonical_report = preservation_report.("canonical_preservation", "canonical_boundary")

    wrapped_status =
      Timeline.preservation_status(%{
        id: :wrapped_cmd_approved,
        type: :command,
        approval_status: :approved,
        metadata: %{timeline_id: "timeline:wrapped:cmd_approved"}
      })
      |> Map.delete("provenance")

    assert {:ok, %{"schema_contract" => "timeline_preservation_report.v1"}} =
             Schema.validate_artifact(direct_report)

    assert {:ok, %{"schema_contract" => "timeline_preservation_status.v1"}} =
             Schema.validate_artifact(wrapped_status)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_preservation_report", direct_report)
      |> Map.put("timeline_preservation_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_preservation_status" => wrapped_status,
        "provenance" => %{"trust_boundary" => "wrapped_preservation_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      branch(
        artifact,
        "derived_timeline_preservation_pressure_direct_preservation_contact_locked"
      )

    assert %{
             "type" => "timeline_preservation_pressure",
             "activity_id" => "direct_preservation_contact_locked",
             "timeline_id" => "timeline:direct_preservation:contact_locked",
             "timeline_preservation_status" => "review_required",
             "requires_preservation" => false,
             "requires_operator_review" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "protection_reason" => "activity_locked_or_approved",
             "preserve_activity_count" => 2,
             "review_change_activity_count" => 1,
             "preserve_activity_ids" => [
               "direct_preservation_contact_locked",
               "direct_preservation_obs_done"
             ],
             "review_change_activity_ids" => ["direct_preservation_bad_missing_type"],
             "feedback_source" => "mission_state.source_timeline_preservation_report.rows[0]",
             "feedback_scope" => "timeline_preservation",
             "trust_boundary" => "direct_preservation_boundary",
             "required_operator_action" => "review_timeline_preservation",
             "derivation_reasons" => ["timeline_preservation_pressure"]
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "timeline_preservation_review" and
                 &1["protection_decision"] == "preserve" and
                 &1["feedback_source"] ==
                   "mission_state.source_timeline_preservation_report.rows[0]")
           )

    assert_timeline_preservation_pressure_score_terms(direct_branch, artifact)

    direct_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_preservation_pressure_direct_preservation_contact_locked")
      )

    assert direct_row["branch_timeline_preservation_activity_ids"] == [
             "direct_preservation_contact_locked"
           ]

    assert direct_row["branch_timeline_preservation_timeline_ids"] == [
             "timeline:direct_preservation:contact_locked"
           ]

    assert direct_row["branch_timeline_preservation_statuses"] == ["review_required"]
    assert direct_row["branch_timeline_preservation_protection_decisions"] == ["preserve"]

    assert direct_row["branch_timeline_preservation_protection_categories"] == [
             "locked_or_approved"
           ]

    assert direct_row["branch_timeline_preservation_preserve_activity_ids"] == [
             "direct_preservation_contact_locked",
             "direct_preservation_obs_done"
           ]

    assert direct_row["branch_timeline_preservation_review_change_activity_ids"] == [
             "direct_preservation_bad_missing_type"
           ]

    invalid_branch =
      branch(
        artifact,
        "derived_timeline_preservation_pressure_direct_preservation_bad_missing_type"
      )

    assert %{
             "activity_id" => "direct_preservation_bad_missing_type",
             "timeline_preservation_status" => "review_required",
             "requires_operator_review" => true,
             "protection_decision" => "review_change",
             "protection_category" => "invalid_activity_input",
             "protection_reason" => "missing_activity_type",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_type",
             "required_operator_action" => "review_invalid_activity_input"
           } = List.first(invalid_branch["events"])

    wrapped_branch =
      branch(
        artifact,
        "derived_timeline_preservation_pressure_wrapped_cmd_approved"
      )

    assert %{
             "activity_id" => "wrapped_cmd_approved",
             "timeline_id" => "timeline:wrapped:cmd_approved",
             "timeline_preservation_status" => "preservation_required",
             "requires_preservation" => true,
             "requires_operator_review" => false,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_preservation_status",
             "trust_boundary" => "wrapped_preservation_artifact_boundary"
           } = List.first(wrapped_branch["events"])

    invalid_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_preservation_pressure_direct_preservation_bad_missing_type")
      )

    assert invalid_row["branch_timeline_preservation_invalid_activity_input_reasons"] == [
             "missing_activity_type"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives timeline preservation pressure from row-local stale aggregate evidence" do
    stale_report =
      [
        %{
          id: :stale_locked,
          type: :contact,
          locked: true,
          metadata: %{timeline_id: "timeline:stale:locked"}
        },
        %{id: :stale_bad_missing_type, status: :planned}
      ]
      |> Timeline.preservation_report(source: "mission.stale.timeline")
      |> Map.put("timeline_preservation_status", "clear")
      |> Map.put("preserve_activity_count", 0)
      |> Map.put("review_change_activity_count", 0)
      |> Map.put("preservation_sensitive_activity_count", 0)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_preservation_report", stale_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    preserve_branch =
      branch(artifact, "derived_timeline_preservation_pressure_stale_locked")

    assert %{
             "timeline_preservation_status" => "preservation_required",
             "requires_preservation" => true,
             "requires_operator_review" => false,
             "protection_decision" => "preserve",
             "required_operator_action" => "record_timeline_preservation",
             "feedback_source" => "mission_state.source_timeline_preservation_report.rows[0]"
           } = List.first(preserve_branch["events"])

    review_branch =
      branch(artifact, "derived_timeline_preservation_pressure_stale_bad_missing_type")

    assert %{
             "timeline_preservation_status" => "review_required",
             "requires_preservation" => false,
             "requires_operator_review" => true,
             "protection_decision" => "review_change",
             "invalid_activity_input" => true,
             "required_operator_action" => "review_invalid_activity_input",
             "feedback_source" => "mission_state.source_timeline_preservation_report.rows[1]"
           } = List.first(review_branch["events"])

    assert_timeline_preservation_pressure_score_terms(preserve_branch, artifact)
    assert_timeline_preservation_pressure_score_terms(review_branch, artifact)

    preserve_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_timeline_preservation_pressure_stale_locked"))

    assert preserve_row["branch_timeline_preservation_statuses"] == ["preservation_required"]
    assert preserve_row["branch_timeline_preservation_protection_decisions"] == ["preserve"]

    review_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_preservation_pressure_stale_bad_missing_type")
      )

    assert review_row["branch_timeline_preservation_statuses"] == ["review_required"]
    assert review_row["branch_timeline_preservation_protection_decisions"] == ["review_change"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_preservation_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    timeline_preservation_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "timeline_preservation_review")
      )

    assert timeline_preservation_pressure_count == 1

    assert branch["score_terms"]["timeline_preservation_pressure_penalty"] ==
             -timeline_preservation_pressure_count * risk_weight

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_preservation_pressure_count) *
               risk_weight

    assert "timeline_preservation_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "timeline_preservation_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
