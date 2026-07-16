defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.RefGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def refs_by(report, field, []) do
    Map.get(report, refs_field(field))
  end

  def refs_by(_report, field, rows) do
    rows
    |> Enum.reduce(%{}, fn row, refs_by_field ->
      value = Rows.ref_group_value(row, field)
      evidence_ref = Rows.evidence_ref(row)

      if value in [nil, ""] or evidence_ref in [nil, ""] do
        refs_by_field
      else
        Map.update(refs_by_field, to_string(value), [to_string(evidence_ref)], fn refs ->
          [to_string(evidence_ref) | refs]
        end)
      end
    end)
    |> Map.new(fn {value, refs} -> {value, refs |> Enum.uniq() |> Enum.sort()} end)
    |> compact_map()
  end

  defp refs_field("schema_contract"), do: "evidence_refs_by_contract"
  defp refs_field(field), do: "evidence_refs_by_#{field}"
end
