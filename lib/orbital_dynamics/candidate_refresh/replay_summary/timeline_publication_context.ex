defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext do
  @moduledoc false

  alias __MODULE__.Fields

  def fields(summary, allow_source_artifact_type_fallback?) do
    Fields.fields(summary, allow_source_artifact_type_fallback?)
  end
end
