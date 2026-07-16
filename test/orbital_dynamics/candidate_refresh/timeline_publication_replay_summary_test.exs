defmodule OrbitalDynamics.CandidateRefresh.TimelinePublicationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Timeline}

  test "timeline publication replay summary preserves publication provenance without publishing" do
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

    publication_summary =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v2"
      }
      |> Timeline.publication_summary(
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: timeline_diff_summary
      )
      |> Map.put("provenance", %{"trust_boundary" => "publication_boundary"})

    refresh = %{"source_timeline_publication_summary" => publication_summary}

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_timeline_publication_contract" => "timeline_publication_summary.v1",
             "source_report_timeline_publication_count" => 1,
             "source_report_timeline_publication_row_count" => 1,
             "source_report_timeline_publication_paths" => [
               "source_timeline_publication_summary"
             ],
             "source_report_timeline_publication_status_counts" => %{
               "published_with_downstream_invalidations" => 1
             },
             "source_report_timeline_publication_downstream_invalidation_status_counts" => %{
               "invalidated" => 1
             },
             "source_report_timeline_publication_dependency_impact_status_counts" => %{
               "review_required" => 1
             },
             "source_report_timeline_publication_ids" => [
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1"
             ],
             "source_report_timeline_publication_source_artifact_ids" => [
               "timeline:published_plan:v2"
             ],
             "source_report_timeline_publication_invalidated_downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "source_report_timeline_publication_dependency_impact_row_count" => 2,
             "source_report_timeline_publication_impacted_source_activity_ids" => ["health_gate"],
             "source_report_timeline_publication_impacted_source_timeline_ids" => [
               "timeline:health_check:0.0"
             ],
             "source_report_timeline_publication_dependent_activity_ids" => ["cmd_main"],
             "source_report_timeline_publication_dependent_timeline_ids" => [
               "timeline:command:20.0"
             ],
             "source_report_timeline_publication_downstream_invalidation_reason_counts" => %{
               "dependency_impact_review_required" => 2
             },
             "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason" =>
               %{
                 "dependency_impact_review_required" => [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ]
               },
             "source_report_timeline_publication_source_dependent_activity_ids" => ["cmd_main"],
             "source_report_timeline_publication_source_dependent_timeline_ids" => [
               "timeline:command:20.0"
             ],
             "source_report_timeline_publication_replacement_dependent_activity_ids" => [
               "cmd_main"
             ],
             "source_report_timeline_publication_replacement_dependent_timeline_ids" => [
               "timeline:command:20.0"
             ],
             "source_report_timeline_publication_diff_row_count" => 3,
             "source_report_timeline_publication_diff_review_required_count" => 2,
             "source_report_timeline_publication_changed_field_counts" => %{
               "timeline_presence" => 2
             },
             "source_report_timeline_publication_branch_local_timeline_publication_pressure" =>
               true,
             "source_report_timeline_publication_branch_local_dependency_pressure" => true,
             "source_report_timeline_publication_branch_local_changed_field_pressure" => true,
             "source_report_timeline_publication_branch_local_invalidation_pressure" => true,
             "source_report_timeline_publication_branch_local_review_pressure" => true,
             "source_reports" => %{
               "timeline_publication_summary" => %{
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["publication_boundary"]
               }
             }
           } = source_report_summary

    assert %{
             "model" => "artifact_only_candidate_refresh_timeline_publication_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_publication_summary",
             "contract" => "timeline_publication_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["source_timeline_publication_summary"],
             "publication_status_counts" => %{
               "published_with_downstream_invalidations" => 1
             },
             "downstream_invalidation_status_counts" => %{"invalidated" => 1},
             "downstream_invalidation_reason_counts" => %{
               "dependency_impact_review_required" => 2
             },
             "dependency_impact_status_counts" => %{"review_required" => 1},
             "publication_authority_counts" => %{"mission_operations" => 1},
             "source_artifact_type_counts" => %{"operational_timeline_report.v1" => 1},
             "publication_ids" => [
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1"
             ],
             "source_artifact_ids" => ["timeline:published_plan:v2"],
             "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
             "downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "invalidated_downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "invalidated_downstream_product_ids_by_reason" => %{
               "dependency_impact_review_required" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ]
             },
             "dependency_impact_row_count" => 2,
             "impacted_source_activity_ids" => ["health_gate"],
             "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
             "dependent_activity_ids" => ["cmd_main"],
             "dependent_timeline_ids" => ["timeline:command:20.0"],
             "source_dependent_activity_ids" => ["cmd_main"],
             "source_dependent_timeline_ids" => ["timeline:command:20.0"],
             "replacement_dependent_activity_ids" => ["cmd_main"],
             "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
             "impacted_dependency_activity_ids" => ["health_gate"],
             "timeline_diff_row_count" => 3,
             "timeline_diff_changed_count" => 0,
             "timeline_diff_review_required_count" => 2,
             "changed_field_counts" => %{"timeline_presence" => 2},
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["publication_boundary"],
             "branch_local_timeline_publication_pressure" => true,
             "branch_local_timeline_publication_dependency_pressure" => true,
             "branch_local_timeline_publication_changed_field_pressure" => true,
             "branch_local_timeline_publication_invalidation_pressure" => true,
             "branch_local_timeline_publication_review_pressure" => true,
             "assumptions" => %{
               "publication_execution" => "not_performed_by_summary",
               "notification_delivery" => "not_performed_by_summary",
               "operator_authority" => "not_granted_by_timeline_publication_replay_summary",
               "import_approval" => "not_granted_by_timeline_publication_replay_summary"
             }
           } = replay_summary = CandidateRefresh.timeline_publication_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_timeline_publication_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_publication_branch_local_timeline_publication_pressure" =>
               true,
             "source_report_timeline_publication_branch_local_dependency_pressure" => true,
             "source_report_timeline_publication_branch_local_changed_field_pressure" => true,
             "source_report_timeline_publication_branch_local_invalidation_pressure" => true,
             "source_report_timeline_publication_branch_local_review_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_publication_replay_summary(artifact) == replay_summary
  end

  test "timeline publication replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_publication_replay_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_publication_pressure"]
    refute summary["branch_local_timeline_publication_dependency_pressure"]
    refute summary["branch_local_timeline_publication_changed_field_pressure"]
    refute summary["branch_local_timeline_publication_invalidation_pressure"]
    refute summary["branch_local_timeline_publication_review_pressure"]
  end

  test "timeline publication replay derives dependency IDs from row-only review and import handoffs" do
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

    publication_summary =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v2"
      }
      |> Timeline.publication_summary(
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: Timeline.dependency_impact_summary(source, replacement),
        timeline_diff_summary: Timeline.diff_summary(source, replacement)
      )

    strip_embedded_publication_summary = fn artifact ->
      Map.update!(artifact, "rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.delete("source_timeline_publication_summary")
          |> Map.update("source_review_row", nil, fn
            %{} = source_review_row ->
              Map.delete(source_review_row, "source_timeline_publication_summary")

            source_review_row ->
              source_review_row
          end)
        end)
      end)
    end

    refresh = %{
      "source_operator_review_package" =>
        publication_summary
        |> OperatorReview.from_timeline_publication_summary()
        |> strip_embedded_publication_summary.(),
      "source_cadence_import_manifest" =>
        publication_summary
        |> CadenceImport.from_timeline_publication_summary()
        |> strip_embedded_publication_summary.()
    }

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_timeline_publication_count" => 2,
             "source_report_timeline_publication_row_count" => 2,
             "source_report_timeline_publication_impacted_source_activity_ids" => ["health_gate"],
             "source_report_timeline_publication_impacted_source_timeline_ids" => [
               "timeline:health_check:0.0"
             ],
             "source_report_timeline_publication_dependent_activity_ids" => ["cmd_main"],
             "source_report_timeline_publication_dependent_timeline_ids" => [
               "timeline:command:20.0"
             ],
             "source_report_timeline_publication_downstream_invalidation_reason_counts" => %{
               "dependency_impact_review_required" => 4
             },
             "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason" =>
               %{
                 "dependency_impact_review_required" => [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ]
               },
             "source_report_timeline_publication_source_dependent_activity_ids" => ["cmd_main"],
             "source_report_timeline_publication_replacement_dependent_activity_ids" => [
               "cmd_main"
             ],
             "source_report_timeline_publication_impacted_dependency_activity_ids" => [
               "health_gate"
             ]
           } = source_report_summary

    assert %{
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "impacted_source_activity_ids" => ["health_gate"],
             "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
             "dependent_activity_ids" => ["cmd_main"],
             "dependent_timeline_ids" => ["timeline:command:20.0"],
             "downstream_invalidation_reason_counts" => %{
               "dependency_impact_review_required" => 4
             },
             "invalidated_downstream_product_ids_by_reason" => %{
               "dependency_impact_review_required" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ]
             },
             "source_dependent_activity_ids" => ["cmd_main"],
             "replacement_dependent_activity_ids" => ["cmd_main"],
             "impacted_dependency_activity_ids" => ["health_gate"],
             "branch_local_timeline_publication_dependency_pressure" => true
           } = CandidateRefresh.timeline_publication_replay_summary(refresh)

    strip_invalidation_reasons = fn artifact ->
      Map.update!(artifact, "rows", fn rows ->
        Enum.map(rows, fn row ->
          row =
            row
            |> Map.delete("downstream_invalidation_reason_counts")
            |> Map.delete("invalidated_downstream_product_ids_by_reason")

          Map.update(row, "source_review_row", nil, fn
            %{} = source_review_row ->
              source_review_row
              |> Map.delete("downstream_invalidation_reason_counts")
              |> Map.delete("invalidated_downstream_product_ids_by_reason")

            source_review_row ->
              source_review_row
          end)
        end)
      end)
    end

    legacy_refresh = %{
      "source_operator_review_package" =>
        refresh["source_operator_review_package"]
        |> strip_invalidation_reasons.(),
      "source_cadence_import_manifest" =>
        refresh["source_cadence_import_manifest"]
        |> strip_invalidation_reasons.()
    }

    assert %{
             "downstream_invalidation_reason_counts" => %{},
             "invalidated_downstream_product_ids_by_reason" => %{},
             "branch_local_timeline_publication_invalidation_pressure" => true
           } = CandidateRefresh.timeline_publication_replay_summary(legacy_refresh)
  end

  test "timeline publication replay lifts review and import handoff rows" do
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

    summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:handoff_plan:v1"
        },
        publication_sequence: 3,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:handoff_plan:v0"],
        downstream_product_ids: [
          "operator_review:handoff_plan:v1",
          "cadence_import:handoff_plan:v1"
        ],
        dependency_impact_summary: Timeline.dependency_impact_summary(source, replacement),
        timeline_diff_summary: Timeline.diff_summary(source, replacement)
      )

    package = OperatorReview.from_timeline_publication_summary(summary)
    manifest = CadenceImport.from_timeline_publication_summary(summary)

    stale_embedded_summary = %{
      "schema_contract" => "timeline_publication_summary.v1",
      "model" => "artifact_only_timeline_publication_summary",
      "publication_id" => "timeline_publication:stale_embedded",
      "publication_status" => "review_required",
      "source_artifact_id" => "timeline:stale_embedded",
      "invalidated_downstream_product_ids" => ["stale_import:handoff_plan:v0"],
      "dependency_impact_row_count" => 99,
      "timeline_diff_row_count" => 99,
      "timeline_diff_review_required_count" => 99,
      "review_timeline_ids" => ["timeline:stale_embedded_review"],
      "provenance" => %{"trust_boundary" => "stale_embedded_publication_boundary"}
    }

    stale_embedded_handoff = fn artifact ->
      Map.update!(artifact, "rows", fn rows ->
        Enum.map(
          rows,
          &Map.put(&1, "source_timeline_publication_summary", stale_embedded_summary)
        )
      end)
    end

    sparse_embedded_handoff = fn artifact ->
      Map.update!(artifact, "rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.take(["id", "review_type", "import_type", "row_type", "action", "import_action"])
          |> Map.merge(%{
            "publication_id" => "timeline_publication:sparse_row",
            "source_artifact_id" => "timeline:sparse_row",
            "source_artifact_type" => "operational_timeline_report.v1",
            "source_timeline_publication_summary" => summary
          })
        end)
      end)
    end

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => [
               "source_operator_review_package.rows.source_timeline_publication_summary"
             ],
             "publication_ids" => [publication_id],
             "invalidated_downstream_product_ids" => [
               "cadence_import:handoff_plan:v1",
               "operator_review:handoff_plan:v1"
             ],
             "dependency_impact_row_count" => 2,
             "impacted_dependency_activity_ids" => ["health_gate"],
             "timeline_diff_row_count" => 3,
             "timeline_diff_review_required_count" => 2,
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "branch_local_timeline_publication_dependency_pressure" => true,
             "branch_local_timeline_publication_changed_field_pressure" => true,
             "branch_local_timeline_publication_invalidation_pressure" => true
           } =
             CandidateRefresh.timeline_publication_replay_summary(%{
               "source_operator_review_package" => package
             })

    assert publication_id == summary["publication_id"]

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => [
               "source_cadence_import_manifest.rows.source_timeline_publication_summary"
             ],
             "publication_ids" => [^publication_id],
             "invalidated_downstream_product_ids" => [
               "cadence_import:handoff_plan:v1",
               "operator_review:handoff_plan:v1"
             ],
             "dependency_impact_row_count" => 2,
             "impacted_dependency_activity_ids" => ["health_gate"],
             "timeline_diff_row_count" => 3,
             "timeline_diff_review_required_count" => 2,
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "branch_local_timeline_publication_dependency_pressure" => true,
             "branch_local_timeline_publication_changed_field_pressure" => true,
             "branch_local_timeline_publication_invalidation_pressure" => true
           } =
             CandidateRefresh.timeline_publication_replay_summary(%{
               "source_cadence_import_manifest" => manifest
             })

    for {source_key, artifact, source_path} <- [
          {
            "source_operator_review_package",
            stale_embedded_handoff.(package),
            "source_operator_review_package.rows.source_timeline_publication_summary"
          },
          {
            "source_cadence_import_manifest",
            stale_embedded_handoff.(manifest),
            "source_cadence_import_manifest.rows.source_timeline_publication_summary"
          }
        ] do
      assert %{
               "source_report_count" => 1,
               "source_report_row_count" => 1,
               "source_report_paths" => [^source_path],
               "publication_ids" => [^publication_id],
               "source_artifact_ids" => ["timeline:handoff_plan:v1"],
               "invalidated_downstream_product_ids" => [
                 "cadence_import:handoff_plan:v1",
                 "operator_review:handoff_plan:v1"
               ],
               "dependency_impact_row_count" => 2,
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "review_timeline_ids" => [
                 "timeline:health_check:0.0",
                 "timeline:health_check:5.0"
               ],
               "branch_local_timeline_publication_dependency_pressure" => true,
               "branch_local_timeline_publication_changed_field_pressure" => true,
               "branch_local_timeline_publication_invalidation_pressure" => true
             } =
               CandidateRefresh.timeline_publication_replay_summary(%{
                 source_key => artifact
               })
    end

    for {source_key, artifact, source_path} <- [
          {
            "source_operator_review_package",
            sparse_embedded_handoff.(package),
            "source_operator_review_package.rows.source_timeline_publication_summary"
          },
          {
            "source_cadence_import_manifest",
            sparse_embedded_handoff.(manifest),
            "source_cadence_import_manifest.rows.source_timeline_publication_summary"
          }
        ] do
      assert %{
               "source_report_paths" => [^source_path],
               "publication_ids" => [^publication_id],
               "source_artifact_ids" => ["timeline:handoff_plan:v1"],
               "invalidated_downstream_product_ids" => [
                 "cadence_import:handoff_plan:v1",
                 "operator_review:handoff_plan:v1"
               ],
               "dependency_impact_row_count" => 2,
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "review_timeline_ids" => [
                 "timeline:health_check:0.0",
                 "timeline:health_check:5.0"
               ]
             } =
               CandidateRefresh.timeline_publication_replay_summary(%{
                 source_key => artifact
               })
    end
  end
end
