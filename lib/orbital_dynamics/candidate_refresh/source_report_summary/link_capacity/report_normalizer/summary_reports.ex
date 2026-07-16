defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ReportNormalizer.SummaryReports do
  @moduledoc false

  alias __MODULE__.CompactSummary
  alias OrbitalDynamics.Communications.LinkCapacity, as: CommunicationsLinkCapacity

  def normalize(summary, rows) do
    cond do
      CompactSummary.link_capacity?(summary) and rows != [] ->
        %{
          "schema_contract" => "link_capacity_report.v1",
          "rows" => rows,
          "source" => summary["source"]
        }
        |> CommunicationsLinkCapacity.summary()
        |> Map.put("rows", rows)
        |> Map.merge(CompactSummary.metadata(summary))

      CompactSummary.relay_data_path?(summary) and rows != [] ->
        rows
        |> CommunicationsLinkCapacity.relay_data_path_summary(source: summary["source"])
        |> Map.merge(CompactSummary.metadata(summary))

      true ->
        summary
    end
  end
end
