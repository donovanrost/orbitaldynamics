defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness do
  @moduledoc false

  alias __MODULE__.CounterofferIds
  alias __MODULE__.CountFields
  alias __MODULE__.Summaries

  def fields(reports) do
    summaries = Summaries.import_readiness(reports)

    summaries
    |> CountFields.fields()
    |> Map.merge(CounterofferIds.fields(summaries))
    |> reject_empty_fields()
  end

  defp reject_empty_fields(fields) do
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
