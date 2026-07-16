defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields.FieldSpecs.Review do
  @moduledoc false

  def all do
    [
      {"review_activity_id_counts", ["review_activity_ids", "activity_id"]},
      {"review_timeline_id_counts", ["review_timeline_ids", "timeline_id"]}
    ]
  end
end
