defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewIssueRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewIssueDetails

  def errors(rows) do
    rows
    |> Enum.filter(&SchemaValidationReviewIssueDetails.error_row?/1)
    |> Enum.map(&SchemaValidationReviewIssueDetails.issue_from_row/1)
    |> Enum.reject(&(&1 == %{}))
  end

  def warnings(rows) do
    rows
    |> Enum.filter(&SchemaValidationReviewIssueDetails.warning_row?/1)
    |> Enum.map(&SchemaValidationReviewIssueDetails.issue_from_row/1)
    |> Enum.reject(&(&1 == %{}))
  end

  def remediation(rows) do
    rows
    |> Enum.map(&SchemaValidationReviewIssueDetails.remediation_from_row/1)
    |> Enum.reject(&(&1 == %{}))
  end

  def status_from_rows(rows) do
    cond do
      Enum.any?(rows, &SchemaValidationReviewIssueDetails.error_row?/1) ->
        "fail"

      status = row_value(rows, ["validation_status", "schema_validation_gate_status"]) ->
        status

      true ->
        "fail"
    end
  end

  def row_value(rows, fields) do
    Enum.find_value(rows, fn row ->
      Enum.find_value(fields, fn field ->
        case Map.get(row, field) do
          value when value in [nil, ""] -> nil
          value -> value
        end
      end)
    end)
  end
end
