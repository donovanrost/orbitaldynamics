defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.ModelIdFields
  alias __MODULE__.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(model_fields(reports))
    |> compact_map()
  end

  defp model_fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(ModelIdFields.fields(reports))
  end
end
