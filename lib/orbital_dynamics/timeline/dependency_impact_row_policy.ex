defmodule OrbitalDynamics.Timeline.DependencyImpactRowPolicy do
  @moduledoc false

  def build(scope, rows, impacted, sorted_uniq) do
    rows
    |> Enum.flat_map(fn row ->
      activity_impacts =
        intersection(
          list_value(row, "dependency_activity_ids"),
          impacted.activity_ids,
          sorted_uniq
        )

      timeline_impacts =
        intersection(
          list_value(row, "dependency_timeline_ids"),
          impacted.timeline_ids,
          sorted_uniq
        )

      exclusive_activity_impacts =
        intersection(
          list_value(row, "exclusive_with_activity_ids"),
          impacted.activity_ids,
          sorted_uniq
        )

      exclusive_timeline_impacts =
        intersection(
          list_value(row, "exclusive_with_timeline_ids"),
          impacted.timeline_ids,
          sorted_uniq
        )

      if dependency_impact_row?(
           row,
           activity_impacts,
           timeline_impacts,
           exclusive_activity_impacts,
           exclusive_timeline_impacts,
           impacted
         ) do
        [
          %{
            "id" => dependency_impact_row_id(scope, row),
            "scope" => scope,
            "dependency_impact_status" => "review_required",
            "required_operator_action" => "review_timeline_integrity",
            "operator_action_reason" =>
              dependency_impact_operator_action_reason(
                activity_impacts,
                timeline_impacts,
                exclusive_activity_impacts,
                exclusive_timeline_impacts
              ),
            "activity_id" => row["activity_id"],
            "timeline_id" => row["timeline_id"],
            "activity_type" => row["activity_type"],
            "status" => row["status"],
            "approval_status" => row["approval_status"],
            "dependency_activity_ids" => list_value(row, "dependency_activity_ids"),
            "dependency_timeline_ids" => list_value(row, "dependency_timeline_ids"),
            "exclusive_with_activity_ids" => list_value(row, "exclusive_with_activity_ids"),
            "exclusive_with_timeline_ids" => list_value(row, "exclusive_with_timeline_ids"),
            "impacted_dependency_activity_ids" => activity_impacts,
            "impacted_dependency_timeline_ids" => timeline_impacts,
            "impacted_exclusive_with_activity_ids" => exclusive_activity_impacts,
            "impacted_exclusive_with_timeline_ids" => exclusive_timeline_impacts
          }
          |> compact_map()
        ]
      else
        []
      end
    end)
  end

  defp dependency_impact_row?(
         row,
         activity_impacts,
         timeline_impacts,
         exclusive_activity_impacts,
         exclusive_timeline_impacts,
         impacted
       ) do
    (activity_impacts != [] or timeline_impacts != [] or exclusive_activity_impacts != [] or
       exclusive_timeline_impacts != []) and
      row["activity_id"] not in impacted.activity_ids and
      row["timeline_id"] not in impacted.timeline_ids
  end

  defp dependency_impact_operator_action_reason(
         activity_impacts,
         timeline_impacts,
         exclusive_activity_impacts,
         exclusive_timeline_impacts
       ) do
    dependency? = activity_impacts != [] or timeline_impacts != []
    exclusivity? = exclusive_activity_impacts != [] or exclusive_timeline_impacts != []

    case {dependency?, exclusivity?} do
      {true, true} -> "dependency_and_exclusivity_changed_or_removed_source_activity"
      {true, false} -> "dependency_changed_or_removed_source_activity"
      {false, true} -> "exclusivity_changed_or_removed_source_activity"
      {false, false} -> "dependency_changed_or_removed_source_activity"
    end
  end

  defp dependency_impact_row_id(scope, row) do
    row_id = row["timeline_id"] || row["activity_id"] || "unknown"
    "dependency_impact:#{scope}:#{row_id}"
  end

  defp intersection(left, right, sorted_uniq) do
    right = MapSet.new(right)

    left
    |> Enum.filter(&MapSet.member?(right, &1))
    |> sorted_uniq.()
  end

  defp list_value(value, key) do
    OrbitalDynamics.Timeline.CollectionValuePolicy.list_value(value, key)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
