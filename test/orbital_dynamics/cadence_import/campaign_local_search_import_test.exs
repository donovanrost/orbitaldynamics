Code.require_file("../campaign_planner/local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.CadenceImport.CampaignLocalSearchImportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: Support
  alias OrbitalDynamics.Schema

  test "imports exactly one review_local_search action with the entire exact trace handoff" do
    plan = local_search_plan()
    trace = plan["optimizer_search_trace"]

    review_rows =
      Enum.filter(plan["operator_review_package"]["rows"], fn row ->
        row["review_type"] == "local_search_review"
      end)

    cadence_rows =
      Enum.filter(plan["cadence_import_manifest"]["rows"], fn row ->
        row["import_action"] == "review_local_search"
      end)

    assert [review_row] = review_rows
    assert [cadence_row] = cadence_rows
    assert review_row["source_optimizer_search_trace"] == trace
    assert review_row["plan_id"] == plan["plan_id"]
    assert review_row["selected_alternative_id"] == trace["selected_alternative_id"]
    assert review_row["selected_timeline_scenario_id"] == trace["selected_timeline_scenario_id"]
    assert review_row["selected_activity_ids"] == trace["selected_activity_ids"]
    assert review_row["selected_activity_count"] == trace["selected_activity_count"]

    assert cadence_row["source_review_row_id"] == review_row["id"]
    assert cadence_row["source_review_type"] == "local_search_review"
    assert cadence_row["source_review_row"] == review_row
    assert plan["cadence_import_manifest"]["source_artifact_id"] == plan["plan_id"]

    assert get_in(plan, ["cadence_import_manifest", "provenance", "source_plan_id"]) ==
             plan["plan_id"]

    assert plan["operational_readiness_report"]["source_artifact_id"] == plan["plan_id"]
    assert {:ok, _report} = Schema.validate_artifact(plan["cadence_import_manifest"])
  end

  test "default campaign import remains byte-shape compatible without a local-search action" do
    plan =
      CampaignPlanner.build(
        Support.result_set(),
        campaign: Support.campaign(),
        generated_at: Support.generated_at()
      )

    refute Map.has_key?(plan, "optimizer_search_trace")

    refute Enum.any?(plan["operator_review_package"]["rows"], fn row ->
             row["review_type"] == "local_search_review"
           end)

    refute Enum.any?(plan["cadence_import_manifest"]["rows"], fn row ->
             row["import_action"] == "review_local_search" or
               row["source_review_type"] == "local_search_review"
           end)
  end

  defp local_search_plan do
    CampaignPlanner.build_with_local_search(
      Support.result_set(),
      campaign: Support.campaign(),
      generated_at: Support.generated_at(),
      local_search: Support.local_search()
    )
  end
end
