defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPrecondition do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      summary = stringify_keys(entry_value)

      if summary?(summary) do
        {entry_path, summary}
      end
    end)
  end

  def operator_review_entries(path, value) do
    TimelineActivityPreconditionReviewImportReports.operator_review_entries(
      path,
      value,
      &summary?/1
    )
  end

  def cadence_import_entries(path, value) do
    TimelineActivityPreconditionReviewImportReports.cadence_import_entries(
      path,
      value,
      &summary?/1
    )
  end

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    preconditions = Map.get(summary, "preconditions") || Map.get(summary, :preconditions)

    is_list(preconditions) and
      (model == "artifact_only_timeline_activity_precondition_summary" or
         schema_contract in [nil, "timeline_activity_precondition_summary.v1"])
  end

  def summary?(_summary), do: false

  defp stringify_keys(value), do: TimelineActivityPreconditionEncoding.stringify_keys(value)
end
