defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation do
  @moduledoc false

  alias __MODULE__.SourceFields
  alias __MODULE__.ValidationFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(ValidationFields.fields(reports))
    |> compact_map()
  end
end
