defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.Lookup

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.NestedSourceValues.FieldSets

  def station_id(row) do
    Lookup.nested_value(row, FieldSets.station_sources())
  end

  def spacecraft_id(row) do
    Lookup.nested_value(row, FieldSets.spacecraft_sources())
  end

  def source_activity_ids(row) do
    [
      Lookup.nested_value(row, "first_resource_pressure", FieldSets.activity_id_fields()),
      Lookup.nested_value(row, "source_activity", FieldSets.activity_id_fields())
    ]
  end
end
