defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.ModelIdFields.GroupedIds.RowGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.RowModelIds

  def by(report, fallback_field, group_fun) do
    rows = rows(report)

    if rows == [] do
      compact_model_id_map(report, fallback_field)
    else
      RowModelIds.grouped_ids(rows, &group_fun.(report, &1))
    end
  end

  defp compact_model_id_map(summary, field) do
    case Map.get(summary, field) do
      %{} = model_id_map -> model_id_map
      _model_id_map -> %{}
    end
  end

  defp rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
