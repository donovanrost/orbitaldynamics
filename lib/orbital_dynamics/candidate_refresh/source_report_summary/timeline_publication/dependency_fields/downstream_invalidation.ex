defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DependencyFields.DownstreamInvalidation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(summaries) do
    %{
      "downstream_invalidation_reason_counts" =>
        summaries
        |> Enum.map(&Map.get(&1, "downstream_invalidation_reason_counts"))
        |> merge_count_maps(),
      "invalidated_downstream_product_ids_by_reason" =>
        summaries
        |> Enum.map(&Map.get(&1, "invalidated_downstream_product_ids_by_reason"))
        |> merge_string_list_maps()
    }
  end
end
