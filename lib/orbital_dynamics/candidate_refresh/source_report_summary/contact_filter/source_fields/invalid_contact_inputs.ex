defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.InvalidContactInputs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1, sum_report_count: 2]

  def fields(reports) do
    %{
      "invalid_contact_input_count" =>
        sum_report_count(reports, &Report.invalid_contact_input_count/1),
      "invalid_contact_input_ids" => ids(reports)
    }
  end

  defp ids(reports) do
    reports
    |> Enum.flat_map(&Report.invalid_contact_input_ids/1)
    |> sorted_string_values()
    |> case do
      [] -> nil
      invalid_contact_input_ids -> invalid_contact_input_ids
    end
  end
end
