defmodule OrbitalDynamics.Timeline.DependencyImpactSummaryPolicy do
  @moduledoc false

  def build(
        diff_report,
        source_rows,
        replacement_rows,
        schema_contract,
        model_limits,
        sorted_uniq
      ) do
    impacted = source_identities(diff_report, sorted_uniq)

    impact_rows =
      OrbitalDynamics.Timeline.DependencyImpactRowPolicy.build(
        "source",
        source_rows,
        impacted,
        sorted_uniq
      ) ++
        OrbitalDynamics.Timeline.DependencyImpactRowPolicy.build(
          "replacement",
          replacement_rows,
          impacted,
          sorted_uniq
        )

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_timeline_dependency_impact_summary",
      "validation_level" => "artifact_contract",
      "source" => "timeline_diff_report.v1",
      "source_activity_count" => diff_report["source_activity_count"],
      "replacement_activity_count" => diff_report["replacement_activity_count"],
      "changed_source_activity_count" => length(impacted.activity_ids),
      "changed_source_timeline_count" => length(impacted.timeline_ids),
      "dependency_impact_status" => if(impact_rows == [], do: "clear", else: "review_required"),
      "dependent_activity_count" => length(impact_rows),
      "source_dependent_activity_count" => Enum.count(impact_rows, &(&1["scope"] == "source")),
      "replacement_dependent_activity_count" =>
        Enum.count(impact_rows, &(&1["scope"] == "replacement")),
      "impacted_source_activity_ids" => impacted.activity_ids,
      "impacted_source_timeline_ids" => impacted.timeline_ids,
      "dependent_activity_ids" => impact_rows |> Enum.map(& &1["activity_id"]) |> sorted_uniq.(),
      "dependent_timeline_ids" => impact_rows |> Enum.map(& &1["timeline_id"]) |> sorted_uniq.(),
      "source_dependent_activity_ids" =>
        scope_ids(impact_rows, "source", "activity_id", sorted_uniq),
      "source_dependent_timeline_ids" =>
        scope_ids(impact_rows, "source", "timeline_id", sorted_uniq),
      "replacement_dependent_activity_ids" =>
        scope_ids(impact_rows, "replacement", "activity_id", sorted_uniq),
      "replacement_dependent_timeline_ids" =>
        scope_ids(impact_rows, "replacement", "timeline_id", sorted_uniq),
      "impacted_dependency_activity_ids" =>
        row_ids(impact_rows, "impacted_dependency_activity_ids", sorted_uniq),
      "impacted_dependency_timeline_ids" =>
        row_ids(impact_rows, "impacted_dependency_timeline_ids", sorted_uniq),
      "impacted_exclusive_with_activity_ids" =>
        row_ids(impact_rows, "impacted_exclusive_with_activity_ids", sorted_uniq),
      "impacted_exclusive_with_timeline_ids" =>
        row_ids(impact_rows, "impacted_exclusive_with_timeline_ids", sorted_uniq),
      "dependency_impact_rows" => impact_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "source" => "timeline_diff_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => model_limits
    }
  end

  defp source_identities(diff_report, sorted_uniq) do
    rows =
      diff_report
      |> Map.get("rows", [])
      |> Enum.filter(&(&1["diff_status"] in ["changed", "removed"]))

    %{
      activity_ids:
        rows
        |> Enum.flat_map(fn row ->
          [row["source_activity_id"] | list_value(row, "source_duplicate_activity_ids")]
        end)
        |> sorted_uniq.(),
      timeline_ids:
        rows
        |> Enum.map(& &1["timeline_id"])
        |> sorted_uniq.()
    }
  end

  defp scope_ids(rows, scope, field, sorted_uniq) do
    rows
    |> Enum.filter(&(&1["scope"] == scope))
    |> Enum.map(& &1[field])
    |> sorted_uniq.()
  end

  defp row_ids(rows, field, sorted_uniq) do
    rows
    |> Enum.flat_map(&list_value(&1, field))
    |> sorted_uniq.()
  end

  defp list_value(value, key) do
    OrbitalDynamics.Timeline.CollectionValuePolicy.list_value(value, key)
  end
end
