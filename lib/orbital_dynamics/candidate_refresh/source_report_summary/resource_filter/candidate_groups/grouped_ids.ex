defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds do
  @moduledoc false

  alias __MODULE__.ReportValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds.RouteSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    Map.new(RouteSpecs.specs(), fn {field, pairs_fun, fallback_fields} ->
      {
        field,
        reports
        |> Enum.map(&ReportValues.by_pairs_or_fallback(&1, pairs_fun, fallback_fields))
        |> merge_string_list_maps()
      }
    end)
  end
end
