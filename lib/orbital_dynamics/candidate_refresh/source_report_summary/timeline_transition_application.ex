defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication do
  @moduledoc false

  alias __MODULE__.DuplicateIdentity
  alias __MODULE__.Outcome
  alias __MODULE__.SelectedActivity
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(metric_fields(reports))
    |> compact_map()
  end

  defp metric_fields(reports) do
    SelectedActivity.fields(reports)
    |> Map.merge(Outcome.fields(reports))
    |> Map.merge(DuplicateIdentity.fields(reports))
  end
end
