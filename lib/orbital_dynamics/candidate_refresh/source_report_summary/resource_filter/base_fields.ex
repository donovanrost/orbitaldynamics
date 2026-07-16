defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields do
  @moduledoc false

  alias __MODULE__.Contract
  alias __MODULE__.CountFields
  alias __MODULE__.InvalidInputs

  def fields(sources, reports, trust_boundaries) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => Contract.value(reports),
      "count" => length(sources),
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
    |> Map.merge(CountFields.fields(reports))
    |> Map.merge(invalid_input_fields(reports))
  end

  def invalid_resource_summary_input_count(report) do
    InvalidInputs.invalid_resource_summary_input_count(report)
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"

  defp invalid_input_fields(reports) do
    InvalidInputs.fields(reports)
  end
end
