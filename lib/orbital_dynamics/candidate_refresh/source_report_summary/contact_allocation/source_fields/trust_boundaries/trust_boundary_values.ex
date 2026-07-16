defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.SourceFields.TrustBoundaries.TrustBoundaryValues do
  @moduledoc false

  def from_row(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
