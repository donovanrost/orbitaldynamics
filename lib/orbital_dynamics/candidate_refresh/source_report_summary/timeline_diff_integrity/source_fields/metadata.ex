defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.SourceFields.Metadata do
  @moduledoc false

  alias __MODULE__.Contract

  def timeline_diff_fields(sources, reports) do
    %{
      "paths" => paths(sources),
      "contract" => Contract.timeline_diff(reports),
      "count" => length(sources)
    }
  end

  def integrity_fields(sources) do
    %{
      "paths" => paths(sources),
      "contract" => "timeline_integrity_report.v1",
      "count" => length(sources)
    }
  end

  defp paths(sources) do
    Enum.map(sources, fn {path, _report} -> path end)
  end
end
