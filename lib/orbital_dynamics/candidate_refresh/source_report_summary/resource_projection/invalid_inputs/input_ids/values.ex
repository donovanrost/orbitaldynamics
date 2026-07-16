defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.Values do
  @moduledoc false

  alias __MODULE__.RowIds

  def invalid_values(report, explicit_ids_field, input_rows_field, id_fields) do
    explicit_ids =
      report
      |> Map.get(explicit_ids_field)
      |> List.wrap()

    input_ids =
      report
      |> Map.get(input_rows_field, [])
      |> RowIds.from_rows(id_fields)

    explicit_ids ++ input_ids
  end
end
