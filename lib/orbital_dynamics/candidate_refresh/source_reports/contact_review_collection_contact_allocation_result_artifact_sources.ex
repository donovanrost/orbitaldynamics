defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationResultArtifactSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationReportFields

  def sources(path, artifact) do
    [{"#{path}", artifact}] ++
      Enum.map(ContactReviewCollectionContactAllocationReportFields.fields(), fn field ->
        {"#{path}.#{field}", Map.get(artifact, field)}
      end)
  end
end
