defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities do
  @moduledoc false

  alias __MODULE__.EntityValues.NestedSourceValues
  alias __MODULE__.EntityValues.StableSourceValues

  def nested_station_id(row) do
    NestedSourceValues.station_id(row)
  end

  def nested_spacecraft_id(row) do
    NestedSourceValues.spacecraft_id(row)
  end

  def nested_source_activity_ids(row) do
    NestedSourceValues.source_activity_ids(row)
  end

  def source_entity_station_id(row) do
    StableSourceValues.station_id(row)
  end

  def source_entity_spacecraft_id(row) do
    StableSourceValues.spacecraft_id(row)
  end
end
