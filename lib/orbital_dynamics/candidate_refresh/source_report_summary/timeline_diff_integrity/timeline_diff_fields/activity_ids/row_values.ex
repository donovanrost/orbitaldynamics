defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def counts(rows, paths) do
    rows
    |> Enum.flat_map(&activity_ids(&1, paths))
    |> count_source_report_values()
  end

  defp activity_ids(row, paths) do
    paths
    |> Enum.flat_map(fn
      path when is_list(path) -> List.wrap(get_in(row, path))
      path -> List.wrap(Map.get(row, path))
    end)
    |> List.flatten()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end
end
