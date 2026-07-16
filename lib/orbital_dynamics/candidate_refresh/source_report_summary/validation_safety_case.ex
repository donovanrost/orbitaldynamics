defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase do
  @moduledoc false

  alias __MODULE__.SummaryFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def summary_input_summary([]), do: nil

  def summary_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "validation_safety_case_summary.v1",
      "count" => length(sources)
    }
    |> Map.merge(SummaryFields.fields(reports))
    |> compact_map()
  end
end
