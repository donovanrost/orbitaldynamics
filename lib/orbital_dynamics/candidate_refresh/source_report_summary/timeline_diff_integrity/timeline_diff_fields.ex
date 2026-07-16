defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields do
  @moduledoc false

  alias __MODULE__.ActivityIds.AggregateFields, as: ActivityIdFields
  alias __MODULE__.ChangeCounts.AggregateFields, as: ChangeCountFields
  alias __MODULE__.DuplicateIdentities.AggregateFields, as: DuplicateIdentityFields
  alias __MODULE__.SourceMetadata.TrustBoundaryFields
  alias __MODULE__.StatusFields.RowCounts, as: StatusRowCounts

  def fields(reports) do
    status_fields(reports)
    |> Map.merge(trust_boundary_fields(reports))
    |> Map.merge(ActivityIdFields.fields(reports))
    |> Map.merge(DuplicateIdentityFields.fields(reports))
    |> Map.merge(ChangeCountFields.fields(reports))
  end

  defp status_fields(reports) do
    %{
      "diff_status_counts" => StatusRowCounts.merge(reports, "diff_status"),
      "required_operator_action_counts" =>
        StatusRowCounts.merge(reports, "required_operator_action")
    }
  end

  defp trust_boundary_fields(reports) do
    %{
      "trust_boundary_status" => TrustBoundaryFields.status(reports),
      "trust_boundaries" => TrustBoundaryFields.values(reports)
    }
  end
end
