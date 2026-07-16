defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.CapacityFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def input_summary([]), do: nil

  def input_summary(sources) do
    intents = Enum.map(sources, fn {_path, intent} -> intent end)

    %{
      "paths" => Enum.map(sources, fn {path, _intent} -> path end),
      "contract" => "contact_intent.v1",
      "count" => length(sources),
      "row_count" => length(sources)
    }
    |> Map.merge(CapacityFields.fields(intents))
    |> Map.merge(SourceMetrics.fields(intents))
    |> compact_map()
  end
end
