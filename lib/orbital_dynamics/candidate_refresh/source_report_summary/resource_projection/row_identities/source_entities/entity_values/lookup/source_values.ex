defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup.FieldValues

  def value(row, direct_fields, nested_sources, nested_value) do
    FieldValues.direct_value(row, direct_fields) || nested_value.(row, nested_sources)
  end
end
