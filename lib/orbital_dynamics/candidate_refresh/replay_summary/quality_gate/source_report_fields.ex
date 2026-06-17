defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Core
  alias __MODULE__.ResourceAvailability
  import __MODULE__.Aggregation, only: [compact_map: 1]

  def source_report_fields(source_reports) do
    source_reports
    |> Core.fields()
    |> Map.merge(ResourceAvailability.fields(source_reports))
    |> compact_map()
  end
end
