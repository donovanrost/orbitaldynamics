defmodule OrbitalDynamics.OperatorReview.TimelineDependencyImpactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema, Timeline}

  test "timeline dependency impact summaries become operator review rows" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    summary = Timeline.dependency_impact_summary(source, replacement)
    package = OperatorReview.from_timeline_dependency_impact_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_dependency_impact_summary.v1",
             "source_artifact_id" => "timeline_diff_report.v1",
             "review_count" => 2,
             "timeline_dependency_impact_review_count" => 2,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2}
           } = package

    assert [
             %{
               "review_type" => "timeline_dependency_impact_review",
               "source" => "timeline_dependency_impact_summary.rows",
               "subject_id" => "timeline:command:20.0",
               "timeline_id" => "timeline:command:20.0",
               "activity_id" => "cmd_combo",
               "dependency_impact_scope" => "source",
               "dependency_impact_status" => "review_required",
               "required_operator_action" => "review_timeline_integrity",
               "operator_action_reason" =>
                 "dependency_and_exclusivity_changed_or_removed_source_activity",
               "impacted_source_activity_ids" => ["health_gate"],
               "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
               "dependent_activity_ids" => ["cmd_combo"],
               "dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependent_activity_ids" => ["cmd_combo"],
               "source_dependent_timeline_ids" => ["timeline:command:20.0"],
               "replacement_dependent_activity_ids" => ["cmd_combo"],
               "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependency_impact_impacted_dependency_activity_ids" => [],
               "source_dependency_impact_impacted_dependency_timeline_ids" => [
                 "timeline:health_check:0.0"
               ],
               "source_dependency_impact_impacted_exclusive_with_activity_ids" => [
                 "health_gate"
               ],
               "source_dependency_impact_impacted_exclusive_with_timeline_ids" => [],
               "dependency_timeline_ids" => ["timeline:health_check:0.0"],
               "exclusive_with_activity_ids" => ["health_gate"],
               "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
               "impacted_exclusive_with_activity_ids" => ["health_gate"],
               "source_timeline_dependency_impact" => %{
                 "scope" => "source",
                 "activity_id" => "cmd_combo"
               }
             },
             %{
               "review_type" => "timeline_dependency_impact_review",
               "dependency_impact_scope" => "replacement",
               "source_timeline_dependency_impact" => %{
                 "scope" => "replacement",
                 "activity_id" => "cmd_combo"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package
  end

  test "timeline dependency impact source id uses id before source and default" do
    assert %{"source_artifact_id" => "dependency_impact:001"} =
             OperatorReview.from_timeline_dependency_impact_summary(%{
               id: :"dependency_impact:001",
               source: :dependency_impact_source,
               dependency_impact_rows: []
             })

    assert %{"source_artifact_id" => "timeline_dependency_impact_summary"} =
             OperatorReview.from_timeline_dependency_impact_summary(%{dependency_impact_rows: []})
  end
end
