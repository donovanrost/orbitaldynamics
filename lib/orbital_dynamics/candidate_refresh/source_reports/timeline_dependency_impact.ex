defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpact do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRows

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      summary = stringify_keys(entry_value)

      if summary?(summary) do
        {entry_path, summary}
      end
    end)
  end

  def operator_review_entries(path, value) do
    TimelineDependencyImpactReviewReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    TimelineDependencyImpactReviewReports.cadence_import_entries(path, value)
  end

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    rows =
      Map.get(summary, "dependency_impact_rows") || Map.get(summary, :dependency_impact_rows)

    is_list(rows) and
      (model == "artifact_only_timeline_dependency_impact_summary" or
         schema_contract in [nil, "timeline_dependency_impact_summary.v1"])
  end

  def summary?(_summary), do: false

  defp stringify_keys(value), do: TimelineDependencyImpactRows.stringify_keys(value)
end
