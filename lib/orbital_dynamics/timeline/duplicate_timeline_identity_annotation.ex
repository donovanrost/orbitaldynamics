defmodule OrbitalDynamics.Timeline.DuplicateTimelineIdentityAnnotation do
  @moduledoc false

  def annotate(rows) do
    duplicate_by_timeline =
      rows
      |> rows_by_timeline_id()
      |> Map.filter(fn {_timeline_id, matches} -> length(matches) > 1 end)

    Enum.map(rows, fn row ->
      case Map.get(duplicate_by_timeline, row["timeline_id"]) do
        nil ->
          row

        matches ->
          annotate_duplicate_timeline_identity_row(row, matches)
      end
    end)
  end

  defp annotate_duplicate_timeline_identity_row(row, matches) do
    activity_ids = Enum.map(matches, & &1["activity_id"])

    row
    |> Map.merge(%{
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_activity_count" => length(matches),
      "duplicate_timeline_identity_activity_ids" => activity_ids,
      "duplicate_timeline_identity_activities" => matches,
      "superseded_required_operator_action" => row["required_operator_action"],
      "superseded_operator_action_reason" => row["operator_action_reason"],
      "required_operator_action" => "review_duplicate_timeline_identity",
      "operator_action_reason" => "duplicate_timeline_identity_collision"
    })
    |> compact_map()
  end

  defp rows_by_timeline_id(rows) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.rows_by_timeline_id(rows)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
