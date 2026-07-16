defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation.ValidationFields.RemediationFields.CountFields do
  @moduledoc false

  alias __MODULE__.ReportCounts

  def fields(reports) do
    %{
      "error_count" => error_count(reports),
      "warning_count" => warning_count(reports),
      "remediation_count" => remediation_count(reports)
    }
  end

  defp error_count(reports), do: ReportCounts.sum(reports, "error_count", "errors")

  defp warning_count(reports), do: ReportCounts.sum(reports, "warning_count", "warnings")

  defp remediation_count(reports),
    do: ReportCounts.sum(reports, "remediation_count", "remediation")
end
