defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "operator review and import lift contact allocation summaries from candidate refresh artifacts" do
    summary_with_contact = fn source, contact_id ->
      contact_allocation_summary_fixture()
      |> Map.put("source", source)
      |> Map.update!("review_rows", fn rows ->
        Enum.map(rows, &Map.merge(&1, %{"contact_id" => contact_id, "source" => source}))
      end)
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          if row["contact_id"] == "dl_deferred" do
            Map.merge(row, %{"contact_id" => contact_id, "source" => source})
          else
            row
          end
        end)
      end)
    end

    direct_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.direct",
        "dl_summary_direct_review"
      )

    canonical_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.canonical",
        "dl_summary_canonical_review"
      )

    wrapped_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.wrapped",
        "dl_summary_wrapped_review"
      )

    nested_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.nested",
        "dl_summary_nested_review"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_allocation_summary_handoff",
      "source_contact_allocation_summary" => [direct_summary],
      "contact_allocation_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    allocation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert length(allocation_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_summary_handoff",
             "contact_allocation_review_count" => 4,
             "review_type_counts" => %{"contact_allocation_review" => 4}
           } = review

    assert Enum.sort(Enum.map(allocation_rows, & &1["source"])) == [
             "candidate_refresh.contact_allocation_summary.review_rows",
             "candidate_refresh.source_contact_allocation_summary[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_summary.review_rows"
           ]

    assert Enum.all?(
             allocation_rows,
             &(&1["allocation_status"] == "deferred" and
                 &1["effective_allocation_status"] == "deferred" and
                 &1["allocation_reason"] == "same_station_contention" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["direction"] == "downlink" and
                 &1["required_operator_action"] == "review_contact_allocation" and
                 &1["source_contact_allocation"]["schema_contract"] ==
                   "contact_allocation_summary.v1")
           )

    assert Enum.any?(
             allocation_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.contact_allocation_summary.review_rows",
                 "contact_id" => "dl_summary_canonical_review",
                 "source_contact_allocation" => %{
                   "source" => "unit_test.contact_allocation_summary.canonical"
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "contact_allocation_review"))

    assert length(import_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_summary_handoff",
             "import_action_counts" => %{"review_contact_allocation" => 4},
             "source_review_type_counts" => %{"contact_allocation_review" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_row"]["source_contact_allocation"]["schema_contract"] ==
                   "contact_allocation_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
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
