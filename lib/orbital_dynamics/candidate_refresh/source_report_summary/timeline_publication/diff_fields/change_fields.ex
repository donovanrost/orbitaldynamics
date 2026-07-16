defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DiffFields.ChangeFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def fields(summaries) do
    %{
      "changed_field_counts" =>
        summaries
        |> Enum.map(&Map.get(&1, "changed_field_counts", %{}))
        |> merge_count_maps(),
      "changed_timeline_ids" => list_values(summaries, "changed_timeline_ids"),
      "review_timeline_ids" => list_values(summaries, "review_timeline_ids"),
      "timeline_ids_by_changed_field" =>
        summaries
        |> Enum.map(&Map.get(&1, "timeline_ids_by_changed_field", %{}))
        |> merge_string_list_maps()
    }
  end

  defp list_values(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end
end
