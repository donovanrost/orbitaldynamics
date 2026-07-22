defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.BaseFields.DirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.DirectionRouting

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    report_fields = Enum.map(reports, &report_fields/1)

    direction_counts =
      report_fields
      |> Enum.map(&elem(&1, 0))
      |> merge_count_maps()

    contact_ids_by_direction =
      report_fields
      |> Enum.map(&elem(&1, 1))
      |> merge_string_list_maps()

    %{
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" =>
        DirectionRouting.field(positive_counts(direction_counts), contact_ids_by_direction)
    }
  end

  defp report_fields(report) do
    direction_counts = Recommendation.direction_counts(report)

    allowed_contact_ids =
      List.wrap(Recommendation.selected_contact_ids(report)) ++
        List.wrap(Recommendation.deferred_contact_ids(report))

    contact_ids_by_direction =
      report
      |> Recommendation.contact_ids_by_direction()
      |> filter_contact_ids(direction_counts, allowed_contact_ids)

    {direction_counts, contact_ids_by_direction}
  end

  defp filter_contact_ids(%{} = values_by_direction, %{} = counts, allowed_contact_ids) do
    allowed_contact_ids = MapSet.new(allowed_contact_ids)

    counts
    |> positive_counts()
    |> Map.keys()
    |> Enum.reduce(%{}, fn direction, filtered ->
      contact_ids =
        values_by_direction
        |> Map.get(direction, [])
        |> List.wrap()
        |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, direction, contact_ids)
      end
    end)
  end

  defp filter_contact_ids(_values_by_direction, _counts, _allowed_contact_ids), do: %{}

  defp positive_counts(%{} = counts),
    do: Map.filter(counts, fn {_direction, count} -> is_integer(count) and count > 0 end)

  defp positive_counts(_counts), do: %{}
end
