defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups.ValueCounts do
  @moduledoc false

  alias __MODULE__.Frequencies

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups.Rows

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def token_counts(report, field) do
    report
    |> Rows.values()
    |> Enum.map(&NormalizedToken.value(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Frequencies.from_values()
  end

  def stable_id_counts(report, field) do
    report
    |> Rows.values()
    |> Enum.map(&StableIds.stable_id_or_nil(Map.get(&1, field)))
    |> Enum.reject(&is_nil/1)
    |> Frequencies.from_values()
  end

  def contact_id_counts(report) do
    report
    |> Rows.values()
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("contact_ids", [])
      |> List.wrap()
    end)
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Frequencies.from_values()
  end
end
