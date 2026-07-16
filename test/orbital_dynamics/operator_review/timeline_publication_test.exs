defmodule OrbitalDynamics.OperatorReview.TimelinePublicationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "timeline publication summaries become operator review rows" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    dependency_impact = Timeline.dependency_impact_summary(source, replacement)
    timeline_diff_summary = Timeline.diff_summary(source, replacement)

    summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: timeline_diff_summary
      )

    package = OperatorReview.from_timeline_publication_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_publication_summary.v1",
             "source_artifact_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "review_count" => 1,
             "timeline_publication_review_count" => 1,
             "required_operator_action_counts" => %{"review_timeline_publication" => 1},
             "review_type_counts" => %{"timeline_publication_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_publication_review",
               "source" => "timeline_publication_summary",
               "subject_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_sequence" => 7,
               "publication_status" => "published_with_downstream_invalidations",
               "downstream_invalidation_status" => "invalidated",
               "publication_authority" => "mission_operations",
               "source_artifact_id" => "timeline:published_plan:v2",
               "source_artifact_type" => "operational_timeline_report.v1",
               "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
               "downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "invalidated_downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "downstream_invalidation_reason_counts" => %{
                 "dependency_impact_review_required" => 2
               },
               "invalidated_downstream_product_ids_by_reason" => %{
                 "dependency_impact_review_required" => [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ]
               },
               "dependency_impact_status" => "review_required",
               "dependency_impact_row_count" => 2,
               "impacted_source_activity_ids" => ["health_gate"],
               "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
               "dependent_activity_ids" => ["cmd_main"],
               "dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependent_activity_ids" => ["cmd_main"],
               "source_dependent_timeline_ids" => ["timeline:command:20.0"],
               "replacement_dependent_activity_ids" => ["cmd_main"],
               "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "changed_field_counts" => %{"timeline_presence" => 2},
               "changed_timeline_ids" => [],
               "review_timeline_ids" => ["timeline:health_check:0.0", "timeline:health_check:5.0"],
               "timeline_ids_by_changed_field" => %{
                 "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
               },
               "required_operator_action" => "review_timeline_publication",
               "operator_action_reason" => "publication_invalidates_downstream_products",
               "source_timeline_publication_summary" => ^summary
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_publication_status =
      put_in(package, ["rows", Access.at(0), "publication_status"], "published")

    assert {:error, stale_publication_status_report} =
             Schema.validate_artifact(stale_publication_status)

    assert Enum.any?(
             stale_publication_status_report["errors"],
             &(&1["path"] == "$.rows[0].publication_status" and
                 &1["message"] ==
                   "must equal source_timeline_publication_summary.publication_status")
           )

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package
  end

  test "timeline publication source id falls back through source artifact and default" do
    assert %{"source_artifact_id" => "timeline_publication:001"} =
             OperatorReview.from_timeline_publication_summary(%{
               publication_id: :"timeline_publication:001"
             })

    assert %{"source_artifact_id" => "timeline:source"} =
             OperatorReview.from_timeline_publication_summary(%{
               source_artifact_id: :"timeline:source"
             })

    assert %{"source_artifact_id" => "timeline_publication_summary"} =
             OperatorReview.from_timeline_publication_summary(%{})
  end

  test "CandidateRefresh lifts publication summaries from direct and result artifacts" do
    summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"]
      )

    artifact = %{
      "refresh_id" => "refresh:publication_summary_result_handoff",
      "timeline_publication_summary" => summary,
      "source_result_artifact" => [summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_publication_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    publication_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_publication_summary"]["schema_contract"] ==
            "timeline_publication_summary.v1")
      )

    assert length(publication_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:publication_summary_result_handoff",
             "review_count" => 3,
             "timeline_publication_review_count" => 3,
             "required_operator_action_counts" => %{"review_timeline_publication" => 3}
           } = review

    assert Enum.sort(Enum.map(publication_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_publication_summary",
             "candidate_refresh.source_result_artifact[0]",
             "candidate_refresh.timeline_publication_summary"
           ]

    assert Enum.all?(
             publication_rows,
             &(&1["publication_id"] == summary["publication_id"] and
                 &1["publication_status"] == "published_with_downstream_invalidations" and
                 &1["invalidated_downstream_product_ids"] == [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ])
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_publication_summary",
            "schema_contract"
          ]) == "timeline_publication_summary.v1")
      )

    assert length(import_rows) == 3

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_publication_summary",
                 "publication_id"
               ]) == summary["publication_id"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
