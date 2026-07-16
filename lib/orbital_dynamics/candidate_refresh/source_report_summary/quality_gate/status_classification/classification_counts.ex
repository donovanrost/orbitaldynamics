defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.ClassificationCounts do
  @moduledoc false

  alias __MODULE__.Classifications

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def fields(reports) do
    %{
      "readiness_level_counts" => readiness_level_counts(reports),
      "import_classification_counts" => import_classification_counts(reports),
      "status_counts" => status_counts(reports)
    }
  end

  defp readiness_level_counts(reports) do
    reports
    |> Enum.map(&Classifications.readiness_level/1)
    |> count_source_report_values()
  end

  defp import_classification_counts(reports) do
    reports
    |> Enum.map(&Classifications.import_classification/1)
    |> count_source_report_values()
  end

  defp status_counts(reports) do
    reports
    |> Enum.map(&Classifications.status/1)
    |> count_source_report_values()
  end
end
