defmodule OrbitalDynamics.OperatorReview.CompositeArtifactPackageInputTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.OperatorReview

  test "campaign artifact source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign:atom",
             "provenance" => %{"source" => "campaign_test"}
           } =
             OperatorReview.from_campaign_artifact(%{
               plan_id: :"campaign:atom",
               provenance: %{source: :campaign_test}
             })
  end

  test "candidate refresh artifact source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:atom",
             "provenance" => %{"source" => "refresh_test"}
           } =
             OperatorReview.from_candidate_refresh_artifact(%{
               refresh_id: :"refresh:atom",
               provenance: %{source: :refresh_test}
             })
  end

  test "repair artifact source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => "repair:atom",
             "provenance" => %{"source" => "repair_test"}
           } =
             OperatorReview.from_repair_artifact(%{
               repair_metadata: %{repair_id: :"repair:atom"},
               provenance: %{source: :repair_test}
             })
  end

  test "strategy artifact source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "campaign_strategy.v3",
             "source_artifact_id" => "strategy:atom",
             "provenance" => %{"source" => "strategy_test"}
           } =
             OperatorReview.from_strategy_artifact(%{
               strategy_metadata: %{strategy_id: :"strategy:atom"},
               provenance: %{source: :strategy_test}
             })
  end
end
