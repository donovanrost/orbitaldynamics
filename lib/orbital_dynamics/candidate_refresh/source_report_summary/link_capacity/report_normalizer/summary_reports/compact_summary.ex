defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ReportNormalizer.SummaryReports.CompactSummary do
  @moduledoc false

  @link_capacity_summary_contract "link_capacity_summary.v1"
  @relay_data_path_summary_contract "relay_data_path_summary.v1"

  def link_capacity?(%{} = report) do
    matches_contract?(report, @link_capacity_summary_contract)
  end

  def relay_data_path?(%{} = report) do
    matches_contract?(report, @relay_data_path_summary_contract)
  end

  def metadata(summary) do
    Map.take(summary, [
      "provenance",
      "source",
      "source_summary_model",
      "source_summary_schema_contract",
      "source_artifact_type"
    ])
  end

  defp matches_contract?(report, contract) do
    Map.get(report, "schema_contract") == contract or
      Map.get(report, "source_summary_schema_contract") == contract
  end
end
