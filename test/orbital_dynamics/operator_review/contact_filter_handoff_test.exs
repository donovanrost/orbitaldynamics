defmodule OrbitalDynamics.OperatorReview.ContactFilterHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "schema validation rejects stale duplicate suppression handoff rows" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:duplicate_handoff",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 2,
      "duplicate_suppressed_candidate_row_count" => 2,
      "duplicate_suppressed_candidate_id_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "dup_contact:1",
          "base_candidate_id" => "dup_contact",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "suppressed_reason" => "ground_station_unavailable",
          "duplicate_suppressed_candidate_id_collision" => true,
          "duplicate_suppressed_candidate_index" => 1,
          "duplicate_suppressed_candidate_count" => 2
        },
        %{
          "id" => "dup_contact:2",
          "base_candidate_id" => "dup_contact",
          "type" => "downlink",
          "scenario_id" => "leo_2",
          "suppressed_reason" => "ground_station_unavailable",
          "duplicate_suppressed_candidate_id_collision" => true,
          "duplicate_suppressed_candidate_index" => 2,
          "duplicate_suppressed_candidate_count" => 2
        }
      ]
    }

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    package = OperatorReview.from_contact_filter_report(report)
    manifest = CadenceImport.from_contact_filter_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_package_count =
      update_in(package, ["rows", Access.at(0)], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_count", 1)
      end)

    assert {:error, count_report} = Schema.validate_artifact(invalid_package_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    invalid_package_index =
      update_in(package, ["rows", Access.at(1)], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_index", 1)
      end)

    assert {:error, index_report} = Schema.validate_artifact(invalid_package_index)

    assert Enum.any?(
             index_report["errors"],
             &(&1["path"] == "$.rows" and
                 String.starts_with?(
                   &1["message"],
                   "duplicate_suppressed_candidate_index values must cover 1..2"
                 ))
           )

    invalid_manifest =
      update_in(manifest, ["rows", Access.at(0)], fn row ->
        row
        |> Map.put("duplicate_suppressed_candidate_count", 1)
        |> put_in(["source_review_row", "duplicate_suppressed_candidate_count"], 1)
      end)

    assert {:error, manifest_report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             manifest_report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    mismatched_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_count", 1)
      end)

    assert {:error, mismatch_report} = Schema.validate_artifact(mismatched_source_review)

    assert Enum.any?(
             mismatch_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.duplicate_suppressed_candidate_count" and
                 &1["message"] ==
                   "must match duplicate_suppressed_candidate_count on Cadence import row")
           )
  end
end
