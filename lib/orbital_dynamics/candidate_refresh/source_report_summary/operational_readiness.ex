defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.Evidence
  alias __MODULE__.GateStatus
  alias __MODULE__.ResourceAvailability
  alias __MODULE__.TimelinePublication

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    BaseFields.fields(sources, reports)
    |> Map.merge(Evidence.fields(reports))
    |> Map.merge(GateStatus.fields(reports))
    |> Map.merge(ResourceAvailability.fields(reports))
    |> Map.merge(TimelinePublication.fields(reports))
    |> compact_map()
  end
end
