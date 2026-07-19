defmodule OrbitalDynamics.CadenceImport.ActivityResultImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{JsonNormalization, SourceIdentifierPolicy}
  alias OrbitalDynamics.OperatorReview

  def from_planned_activity(activity, opts, import) do
    from_review_report(
      activity,
      opts,
      import,
      &OperatorReview.from_planned_activity/1,
      "planned_activity.v1",
      &(&1["id"] || &1["activity_id"]),
      "planned_activity"
    )
  end

  def from_realized_activity(activity, opts, import) do
    from_review_report(
      activity,
      opts,
      import,
      &OperatorReview.from_realized_activity/1,
      "realized_activity.v1",
      &(&1["id"] || &1["realized_activity_id"]),
      "realized_activity"
    )
  end

  def from_realized_state_snapshot(snapshot, opts, import) do
    from_review_report(
      snapshot,
      opts,
      import,
      &OperatorReview.from_realized_state_snapshot/1,
      "realized_state_snapshot.v1",
      &(&1["snapshot_id"] || get_in(&1, ["metadata", "snapshot_id"])),
      "realized_state_snapshot"
    )
  end

  def from_result_artifact(artifact, opts, import) do
    from_review_report(
      artifact,
      opts,
      import,
      &OperatorReview.from_result_artifact/1,
      "result_artifact.v1",
      &SourceIdentifierPolicy.result_artifact/1,
      "result_artifact"
    )
  end

  defp from_review_report(
         artifact,
         opts,
         import,
         review,
         source_type,
         source_id,
         fallback
       ) do
    artifact = JsonNormalization.stringify_keys(artifact)
    selected_source_id = Keyword.get(opts, :source_artifact_id, source_id.(artifact))

    import.(review.(artifact), opts, source_type, selected_source_id || fallback)
  end
end
