defmodule OrbitalDynamics.Validation.ActivityTimelineFixtureCoverageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  @artifact_model_prefix "artifact."
  @family_contract_prefix "timeline_"
  @explicit_family_contracts ~w(
    activity_template.v1
    approval_requirement.v1
    candidate_activity.v1
    candidate_rejection_report.v1
    command_window_report.v1
    invalidated_candidate.v1
    operational_timeline_report.v1
    plan_delta.v1
    planned_activity.v1
    realized_activity.v1
    source_window_lineage.v1
  )

  test "every registered activity/timeline artifact contract has a curated reference fixture" do
    family_contracts =
      Schema.contracts()
      |> Map.keys()
      |> Enum.filter(&family_contract?/1)
      |> Enum.sort()

    fixture_contracts =
      Validation.reference_fixtures()
      |> Map.values()
      |> Enum.map(&Map.fetch!(&1, "model_id"))
      |> Enum.filter(&String.starts_with?(&1, @artifact_model_prefix))
      |> Enum.map(&String.replace_prefix(&1, @artifact_model_prefix, ""))
      |> MapSet.new()

    missing_contracts =
      Enum.reject(family_contracts, &MapSet.member?(fixture_contracts, &1))

    assert family_contracts != []

    assert missing_contracts == [],
           "registered activity/timeline contracts missing curated artifact fixtures: #{inspect(missing_contracts)}"
  end

  test "family scope includes typed handoffs without absorbing adjacent planner contracts" do
    assert family_contract?("timeline_future_contract.v1")
    assert family_contract?("planned_activity.v1")
    assert family_contract?("command_window_report.v1")
    refute family_contract?("campaign_plan.v1")
    refute family_contract?("maneuver_recommendation.v1")
  end

  defp family_contract?(contract) do
    String.starts_with?(contract, @family_contract_prefix) or
      contract in @explicit_family_contracts
  end
end
