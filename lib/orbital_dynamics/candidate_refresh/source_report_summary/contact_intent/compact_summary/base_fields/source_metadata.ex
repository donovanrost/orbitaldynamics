defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.SourceMetadata do
  @moduledoc false

  alias __MODULE__.ContractValue
  alias __MODULE__.TrustBoundaryFields

  defdelegate contract(summaries), to: ContractValue
  defdelegate trust_boundary_fields(summaries), to: TrustBoundaryFields
end
