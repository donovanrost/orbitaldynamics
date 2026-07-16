defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.MapCounts do
  @moduledoc false

  alias __MODULE__.ValueCount

  def count(summary) do
    [
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "input_contract_counts"
    ]
    |> Enum.find_value(:error, fn field ->
      case Map.get(summary, field) do
        %{} = map -> {:ok, ValueCount.from_map(field, map)}
        _map -> false
      end
    end)
  end
end
