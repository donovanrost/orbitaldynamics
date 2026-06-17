defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, summary) do
    source_reports
    |> Flattened.source_report_fields()
    |> Map.merge(%{
      "source_report_contact_contention_branch_local_contact_contention_pressure" =>
        Map.get(summary, "branch_local_contact_contention_pressure"),
      "source_report_contact_contention_branch_local_conflict_pressure" =>
        Map.get(summary, "branch_local_contact_contention_conflict_pressure"),
      "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
        Map.get(summary, "branch_local_invalid_contact_input_pressure"),
      "source_report_contact_contention_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_contact_contention_review_pressure")
    })
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
