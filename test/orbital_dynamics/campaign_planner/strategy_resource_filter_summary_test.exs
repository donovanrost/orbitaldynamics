Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceFilterSummaryTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state resource-filter summaries into branch refresh requests" do
    resource_filter_summary = fn prefix, trust_boundary ->
      %{
        "schema_contract" => "resource_filter_report.v1",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "#{prefix}_obs_payload_block",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload",
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared"
          }
        ],
        "invalid_resource_summary_inputs" => [
          %{"resource_summary_id" => "#{prefix}_bad_resource_summary"}
        ]
      }
      |> OrbitalDynamics.ResourceFilter.summary()
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_source_summary =
      resource_filter_summary.("direct_source", "direct_source_resource_filter_summary_boundary")

    direct_canonical_summary =
      resource_filter_summary.(
        "direct_canonical",
        "direct_canonical_resource_filter_summary_boundary"
      )

    source_wrapped_summary =
      resource_filter_summary.("source_wrapped", "source_wrapped_resource_filter_summary_fixture")

    result_wrapped_summary =
      resource_filter_summary.("result_wrapped", "result_wrapped_resource_filter_summary_fixture")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_resource_filter_summary", direct_source_summary)
      |> Map.put("resource_filter_summary", direct_canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "resource_filter_summary" => Map.delete(source_wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "source_wrapped_resource_filter_summary_boundary"
        }
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "resource_filter_summary" => Map.delete(result_wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "result_wrapped_resource_filter_summary_boundary"
        }
      })

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

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_resource_filter_summary",
          "mission_state.resource_filter_summary",
          "mission_state.source_result_artifact.resource_filter_summary",
          "mission_state.result_artifact.resource_filter_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_resource_filter_suppressed_candidate_count" => 4,
             "source_report_resource_filter_invalid_resource_summary_input_count" => 4,
             "source_report_resource_filter_invalid_resource_summary_input_ids" => [
               "direct_canonical_bad_resource_summary",
               "direct_source_bad_resource_summary",
               "result_wrapped_bad_resource_summary",
               "source_wrapped_bad_resource_summary"
             ],
             "source_report_resource_filter_suppressed_reason_counts" => %{
               "payload_unavailable" => 4
             },
             "source_report_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "payload_unavailable" => [
                 "direct_source_obs_payload_block",
                 "direct_canonical_obs_payload_block",
                 "source_wrapped_obs_payload_block",
                 "result_wrapped_obs_payload_block"
               ]
             },
             "source_report_resource_filter_spacecraft_counts" => %{"leo_1" => 4},
             "source_report_resource_filter_resource_counts" => %{"payload_1" => 4},
             "source_report_resource_filter_blocking_dimension_counts" => %{"payload" => 4}
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "resource_filter_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "suppressed_candidate_count" => 4,
             "invalid_resource_summary_input_count" => 4,
             "invalid_resource_summary_input_ids" => [
               "direct_canonical_bad_resource_summary",
               "direct_source_bad_resource_summary",
               "result_wrapped_bad_resource_summary",
               "source_wrapped_bad_resource_summary"
             ],
             "suppressed_reason_counts" => %{"payload_unavailable" => 4},
             "candidate_ids_by_suppressed_reason" => %{
               "payload_unavailable" => [
                 "direct_source_obs_payload_block",
                 "direct_canonical_obs_payload_block",
                 "source_wrapped_obs_payload_block",
                 "result_wrapped_obs_payload_block"
               ]
             },
             "resource_filter_spacecraft_counts" => %{"leo_1" => 4},
             "resource_filter_resource_counts" => %{"payload_1" => 4},
             "resource_filter_blocking_dimension_counts" => %{"payload" => 4},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "direct_canonical_resource_filter_summary_boundary",
               "direct_source_resource_filter_summary_boundary",
               "result_wrapped_resource_filter_summary_boundary",
               "source_wrapped_resource_filter_summary_boundary"
             ],
             "branch_local_resource_filter_pressure" => true,
             "branch_local_candidate_suppression_pressure" => true,
             "branch_local_invalid_resource_summary_pressure" => true,
             "branch_local_resource_blocking_pressure" => true
           } = CandidateRefresh.resource_filter_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_resource_filter_summary",
          "mission_state.resource_filter_summary",
          "mission_state.source_result_artifact.resource_filter_summary",
          "mission_state.result_artifact.resource_filter_summary"
        ] do
      assert source_path in replay_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
