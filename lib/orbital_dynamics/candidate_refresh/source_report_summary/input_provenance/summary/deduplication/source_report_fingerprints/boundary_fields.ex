defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportFingerprints.BoundaryFields do
  @moduledoc false

  alias __MODULE__.BranchLocal
  alias __MODULE__.FieldSpecs

  def drop(%{} = value) do
    value
    |> Map.drop(FieldSpecs.boundary_fields())
    |> Map.new(fn {key, nested_value} ->
      {key, drop(nested_value)}
    end)
  end

  def drop(values) when is_list(values) do
    Enum.map(values, &drop/1)
  end

  def drop(value), do: value

  def branch_local?(report) do
    BranchLocal.boundary?(report)
  end
end
