defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields do
  @moduledoc false

  alias __MODULE__.ConflictGroups
  alias __MODULE__.CountMaps
  alias __MODULE__.InvalidInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "conflict_group_count" => sum_report_count(reports, &conflict_group_count/1),
      "invalid_contact_input_count" => sum_report_count(reports, &InvalidInputs.count/1),
      "invalid_contact_input_ids" => InvalidInputs.ids(reports)
    }
    |> Map.merge(CountMaps.fields(reports))
  end

  defp row_count(report) do
    ConflictGroups.count(report) + InvalidInputs.count(report)
  end

  defp conflict_group_count(report), do: ConflictGroups.count(report)
end
