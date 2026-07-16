defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.FieldSets do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.MapFields

  def count_fields, do: CountFields.fields()
  def map_fields, do: MapFields.fields()
end
