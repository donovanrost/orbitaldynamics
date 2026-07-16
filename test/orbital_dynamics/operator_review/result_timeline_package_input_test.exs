defmodule OrbitalDynamics.OperatorReview.ResultTimelinePackageInputTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.OperatorReview

  test "result artifact source id and metadata use mapper package input" do
    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "source_artifact_id" => "result_artifact:study:run",
             "provenance" => %{"source" => "result_test"}
           } =
             OperatorReview.from_result_artifact(%{
               study_id: :study,
               run: %{id: :run},
               metadata: %{source: :result_test}
             })
  end

  test "operational timeline report source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "operational_timeline_report.v1",
             "source_artifact_id" => "timeline:atom",
             "provenance" => %{"source" => "timeline_test"}
           } =
             OperatorReview.from_operational_timeline_report(%{
               id: :"timeline:atom",
               provenance: %{source: :timeline_test}
             })

    assert %{"source_artifact_id" => "operational_timeline_report"} =
             OperatorReview.from_operational_timeline_report(%{})
  end

  test "planned activity source id and provenance use mapper package input" do
    assert %{
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "planned:atom",
             "provenance" => %{"source" => "planned_test"}
           } =
             OperatorReview.from_planned_activity(%{
               id: :"planned:atom",
               type: :observe,
               provenance: %{source: :planned_test}
             })

    assert %{"source_artifact_id" => "planned_activity"} =
             OperatorReview.from_planned_activity(%{})
  end
end
