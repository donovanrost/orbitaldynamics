defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.PlanImpactFields.SummaryValues do
  @moduledoc false

  alias __MODULE__.DirectValues

  @source_summary_model "artifact_only_provider_counteroffer_plan_impact_summary"

  def reports(reports) do
    Enum.filter(reports, fn report ->
      Map.get(report, "source_summary_model") == @source_summary_model
    end)
  end

  def single_value_counts(summaries, value_field) do
    DirectValues.single_value_counts(summaries, value_field)
  end

  def sorted_string_list(summaries, field) do
    DirectValues.sorted_string_list(summaries, field)
  end

  def reject_empty_fields(fields) do
    fields
    |> Enum.reject(fn
      {_key, nil} -> true
      {_key, 0} -> true
      {_key, []} -> true
      {_key, map} when map == %{} -> true
      _entry -> false
    end)
    |> Map.new()
  end
end
