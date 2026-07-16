defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.{
    CompactSummary,
    RawInputSummary
  }

  def report_input_summary(sources) do
    {compact_summary_sources, contact_intent_sources} =
      Enum.split_with(sources, fn {_path, source} -> contact_intent_summary?(source) end)

    [
      RawInputSummary.input_summary(contact_intent_sources),
      CompactSummary.input_summary(compact_summary_sources)
    ]
    |> CompactSummary.merge_input_summaries()
  end

  defp contact_intent_summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    schema_contract == "contact_intent_summary.v1"
  end

  defp contact_intent_summary?(_summary), do: false
end
