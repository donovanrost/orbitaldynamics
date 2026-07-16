defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.FreshnessFields.FieldValues do
  @moduledoc false

  alias __MODULE__.ReasonFields

  def fields(reports) do
    %{
      "status_counts" => status_counts(reports)
    }
    |> Map.merge(reason_fields(reports))
  end

  defp status_counts(reports) do
    reports
    |> Enum.map(&freshness_report_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp reason_fields(reports) do
    ReasonFields.fields(reports)
  end

  defp freshness_report_status(report) do
    Map.get(report, "status") || Map.get(report, "freshness_status")
  end
end
