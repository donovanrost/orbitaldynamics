Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceDecisionEvidenceTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy score-term evidence drift", %{strategy: strategy} do
    row = hd(strategy["score_term_report"]["rows"])

    coherent_identity_drift =
      strategy
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "id"],
        "score_term:stale_branch:1:stale_term"
      )
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "scenario_id"],
        "stale_branch"
      )
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "branch_id"],
        "stale_branch"
      )

    coherent_term_key_drift =
      strategy
      |> put_in(
        ["score_term_report", "rows", Access.at(0), "term_key"],
        "stale_term"
      )
      |> update_in(["score_term_report", "score_term_keys"], fn keys ->
        ["stale_term" | keys] |> Enum.uniq() |> Enum.sort()
      end)

    reordered =
      update_in(strategy, ["score_term_report", "rows"], fn [first, second | rest] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.score_term_report.model",
       put_in(strategy, ["score_term_report", "model"], "ranked_timeline_score_terms")},
      {"$.score_term_report.source",
       put_in(strategy, ["score_term_report", "source"], "schema_valid_drift")},
      {"$.score_term_report.assumptions.policy",
       update_in(
         strategy,
         ["score_term_report", "assumptions", "policy", "risk_weight"],
         &(&1 + 1)
       )},
      {"$.score_term_report.assumptions.scenario_id_represents",
       put_in(
         strategy,
         ["score_term_report", "assumptions", "scenario_id_represents"],
         "stale_identity"
       )},
      {"$.score_term_report.assumptions.score_term_source",
       put_in(
         strategy,
         ["score_term_report", "assumptions", "score_term_source"],
         "stale_source"
       )},
      {"$.score_term_report.rows[0].id", coherent_identity_drift},
      {"$.score_term_report.rows[0].rank",
       update_in(strategy, ["score_term_report", "rows", Access.at(0), "rank"], &(&1 + 1))},
      {"$.score_term_report.rows[0].term_key", coherent_term_key_drift},
      {"$.score_term_report.rows[0].value",
       update_in(strategy, ["score_term_report", "rows", Access.at(0), "value"], &(&1 + 1))},
      {"$.score_term_report.rows[0].timeline_score",
       update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "timeline_score"],
         &(&1 + 1)
       )},
      {"$.score_term_report.rows[0].selected",
       update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "selected"],
         &(!&1)
       )},
      {"$.score_term_report.rows[0].id", reordered}
    ]

    assert row["selected"]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy objective-tradeoff evidence drift", %{strategy: strategy} do
    row = hd(strategy["objective_tradeoff_report"]["tradeoffs"])
    score_term_key = row["score_terms"] |> Map.keys() |> hd()

    coherent_identity_drift =
      strategy
      |> put_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "scenario_id"],
        "stale_branch"
      )
      |> put_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "branch_id"],
        "stale_branch"
      )

    coherent_activity_drift =
      strategy
      |> update_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_ids"],
        &(&1 ++ ["stale_activity"])
      )
      |> update_in(
        ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_count"],
        &(&1 + 1)
      )

    reordered =
      update_in(strategy, ["objective_tradeoff_report", "tradeoffs"], fn [
                                                                           first,
                                                                           second
                                                                           | rest
                                                                         ] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.objective_tradeoff_report.model",
       put_in(
         strategy,
         ["objective_tradeoff_report", "model"],
         "ranked_timeline_score_term_tradeoffs"
       )},
      {"$.objective_tradeoff_report.objective",
       put_in(strategy, ["objective_tradeoff_report", "objective"], "schema valid drift")},
      {"$.objective_tradeoff_report.policy",
       update_in(
         strategy,
         ["objective_tradeoff_report", "policy", "risk_weight"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.assumptions.source",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "source"],
         "schema_valid_drift"
       )},
      {"$.objective_tradeoff_report.assumptions.scenario_id_represents",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "scenario_id_represents"],
         "stale_identity"
       )},
      {"$.objective_tradeoff_report.assumptions.score_delta_from_selected",
       put_in(
         strategy,
         ["objective_tradeoff_report", "assumptions", "score_delta_from_selected"],
         "stale_formula"
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].scenario_id", coherent_identity_drift},
      {"$.objective_tradeoff_report.tradeoffs[0].rank",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "rank"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_delta_from_selected",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_delta_from_selected"
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].activity_count", coherent_activity_drift},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_observation_count",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "selected_observation_count"
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_contact_count",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "selected_contact_count"],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_terms",
       update_in(
         strategy,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_terms",
           score_term_key
         ],
         &(&1 + 1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected",
       update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "selected"],
         &(!&1)
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].rank", reordered}
    ]

    assert row["selected"]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end
end
