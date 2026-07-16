defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessStatusCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_values: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues,
    as: RowValues

  def import_readiness_status_counts(summary, []) do
    count_values([Map.get(summary, "import_readiness_status")])
  end

  def import_readiness_status_counts(_summary, rows) do
    RowValues.import_readiness_status_counts_from_rows(rows)
  end

  def import_classification_counts(summary, []) do
    count_values([Map.get(summary, "import_classification")])
  end

  def import_classification_counts(_summary, rows) do
    RowValues.import_classification_counts_from_rows(rows)
  end
end
