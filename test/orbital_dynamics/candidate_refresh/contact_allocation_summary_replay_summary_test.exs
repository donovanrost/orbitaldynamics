defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationSummaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays contact allocation summaries" do
    refresh = %{
      "source_contact_allocation_summary" => contact_allocation_summary_fixture()
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_counts_by_family" => %{"contact_allocation_report" => 1},
             "source_report_contact_allocation_allocated_contact_count" => 1,
             "source_report_contact_allocation_returned_allocated_contact_count" => 1,
             "source_report_contact_allocation_deferred_contact_count" => 1,
             "source_report_contact_allocation_allocation_status_counts" => %{
               "allocated" => 1,
               "deferred" => 1
             },
             "source_report_contact_allocation_branch_local_contact_allocation_pressure" => true,
             "source_report_contact_allocation_branch_local_deferred_allocation_pressure" => true,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_contact_allocation_summary"],
                 "source_summary_model_counts" => %{
                   "artifact_only_contact_allocation_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "contact_allocation_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{"contact_allocation_report.v1" => 1},
                 "contact_allocation_summary_schema_contract" => "contact_allocation_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary[
             "source_report_contact_allocation_source_summary_model_counts"
           ] == %{"artifact_only_contact_allocation_summary" => 1}

    assert source_summary[
             "source_report_contact_allocation_source_summary_schema_contract_counts"
           ] == %{"contact_allocation_summary.v1" => 1}

    assert source_summary[
             "source_report_contact_allocation_source_artifact_type_counts"
           ] == %{"contact_allocation_report.v1" => 1}

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
             "source_summary_model_counts" => %{
               "artifact_only_contact_allocation_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "contact_allocation_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"contact_allocation_report.v1" => 1},
             "contact_allocation_summary_schema_contract" => "contact_allocation_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "operator_authority" => "not_granted_by_contact_allocation_replay_summary",
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary replays contact allocation summaries from result artifact wrappers" do
    refresh = %{
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_contact_allocation_summary" =>
          contact_allocation_summary_fixture()
          |> Map.delete("provenance"),
        "provenance" => %{"trust_boundary" => "ground_partner_api"}
      }
    }

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_result_artifact.source_contact_allocation_summary"],
                 "source_summary_model_counts" => %{
                   "artifact_only_contact_allocation_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "contact_allocation_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{"contact_allocation_report.v1" => 1},
                 "contact_allocation_summary_schema_contract" => "contact_allocation_summary.v1",
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ground_partner_api"]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => ["source_result_artifact.source_contact_allocation_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_contact_allocation_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "contact_allocation_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"contact_allocation_report.v1" => 1},
             "contact_allocation_summary_schema_contract" => "contact_allocation_summary.v1",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ground_partner_api"],
             "branch_local_contact_allocation_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  defp contact_allocation_summary_fixture do
    allocated_row = %{
      "contact_id" => "dl_allocated",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    deferred_row = %{
      "contact_id" => "dl_deferred",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    %{
      "schema_contract" => "contact_allocation_summary.v1",
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_summary",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "returned_allocated_contact_count" => 1,
      "policy_blocked_allocated_contact_count" => 0,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "invalid_contact_input_count" => 0,
      "status_blocked_contact_count" => 0,
      "resource_blocked_contact_count" => 0,
      "duplicate_contact_id_count" => 0,
      "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "allocation_reason_counts" => %{
        "same_station_contention" => 1,
        "selected_by_contention_resolution" => 1
      },
      "contact_ids_by_allocation_reason" => %{
        "same_station_contention" => ["dl_deferred"],
        "selected_by_contention_resolution" => ["dl_allocated"]
      },
      "allocated_contact_ids" => ["dl_allocated"],
      "returned_allocated_contact_ids" => ["dl_allocated"],
      "deferred_contact_ids" => ["dl_deferred"],
      "blocked_contact_ids" => [],
      "review_contact_ids" => ["dl_deferred"],
      "rows" => [allocated_row, deferred_row],
      "review_rows" => [deferred_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      },
      "provenance" => %{"trust_boundary" => "allocation_fixture"}
    }
  end
end
