defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.FieldMap do
  @moduledoc false

  alias __MODULE__.CountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.IdLists

  def fields(reports) do
    Map.merge(
      CountFields.fields(reports),
      %{
        "invalid_activity_input_ids" => IdLists.invalid_activity_input_ids(reports),
        "invalid_resource_summary_input_ids" =>
          IdLists.invalid_resource_summary_input_ids(reports)
      }
    )
  end
end
