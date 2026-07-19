defmodule OrbitalDynamics.CadenceImport.CampaignReviewPackageImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_candidate_refresh_artifact(artifact, opts, import) do
    artifact = JsonNormalization.stringify_keys(artifact)

    review_package =
      artifact["operator_review_package"] ||
        OperatorReview.from_candidate_refresh_artifact(artifact)

    source_id = Keyword.get(opts, :source_artifact_id, artifact["refresh_id"])

    import.(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "candidate_refresh.v1",
        source_artifact_id: source_id
      )
    )
  end

  def from_repair_artifact(artifact, opts, import) do
    artifact = JsonNormalization.stringify_keys(artifact)

    review_package =
      artifact["operator_review_package"] ||
        OperatorReview.from_repair_artifact(artifact)

    source_id =
      get_in(artifact, ["repair_metadata", "repair_id"]) ||
        Map.get(artifact, "source_plan_id", "campaign_repair")

    import.(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: "campaign_repair.v2",
        source_artifact_id: source_id,
        source_repair_id: source_id,
        source_plan_id: artifact["source_plan_id"]
      )
    )
  end
end
