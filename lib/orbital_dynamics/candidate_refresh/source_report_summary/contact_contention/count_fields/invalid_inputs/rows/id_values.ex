defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs.Rows.IdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def ids(report) do
    explicit_ids =
      report
      |> Map.get("invalid_contact_input_ids")
      |> List.wrap()

    row_ids =
      report
      |> Map.get("invalid_contact_inputs", [])
      |> Enum.map(&EncodedValue.stringify_keys/1)
      |> Enum.map(&StableIds.stable_id_or_nil(&1["contact_id"] || &1["id"] || &1["subject_id"]))

    (explicit_ids ++ row_ids)
    |> sorted_string_values()
  end
end
