Code.require_file("strategy_recommendation_pressure_events_fixture.ex", __DIR__)

Code.require_file(
  "strategy_recommendation_pressure_expected_handoff_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, async: true

      alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffSupport
      alias OrbitalDynamics.Schema

      import StrategyRecommendationPressureHandoffSupport

      setup_all do
        {:ok, StrategyRecommendationPressureHandoffSupport.setup_context(unquote(opts))}
      end
    end
  end
end

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffSupport do
  import ExUnit.Assertions

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsFixture
  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureExpectedHandoffFixture
  alias OrbitalDynamics.Schema

  def setup_context(opts) do
    artifact = StrategyRecommendationPressureEventsFixture.artifact()

    context = %{
      artifact: artifact,
      handoff: handoff(artifact)
    }

    context =
      if Keyword.get(opts, :expected_handoff, false) do
        Map.put(
          context,
          :expected_handoff,
          StrategyRecommendationPressureExpectedHandoffFixture.expected_handoff()
        )
      else
        context
      end

    if Keyword.get(opts, :invalid_contact_intent, false) do
      invalid_artifact =
        StrategyRecommendationPressureEventsFixture.invalid_contact_intent_artifact()

      Map.put(context, :invalid_contact_intent_handoff, handoff(invalid_artifact))
    else
      context
    end
  end

  def handoff(artifact) do
    recommendation_review_row =
      Enum.find(
        artifact["operator_review_package"]["rows"],
        &(&1["review_type"] == "strategy_recommendation")
      )

    selected_import_row =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "import_strategy_recommendation" and &1["selected"] == true)
      )

    review_import = OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    review_import_row =
      Enum.find(
        review_import["rows"],
        &(&1["source_review_type"] == "strategy_recommendation")
      )

    Map.merge(artifact, %{
      artifact: artifact,
      recommendation_review_index:
        Enum.find_index(
          artifact["operator_review_package"]["rows"],
          &(&1["id"] == recommendation_review_row["id"])
        ),
      recommendation_review_row: recommendation_review_row,
      review_import: review_import,
      review_import_index:
        Enum.find_index(review_import["rows"], &(&1["id"] == review_import_row["id"])),
      review_import_row: review_import_row,
      selected_import_index:
        Enum.find_index(
          artifact["cadence_import_manifest"]["rows"],
          &(&1["id"] == selected_import_row["id"])
        ),
      selected_import_row: selected_import_row
    })
  end

  def assert_risk_expiration_context_contract(
        handoff,
        field,
        {identity_field, identity_value},
        expected_status
      ) do
    stale_status = if expected_status == "active", do: "expired", else: "active"

    assert_risk_context_contract(
      handoff,
      field,
      {identity_field, identity_value},
      "station_reservation_expiration_status",
      [expected_status],
      [stale_status]
    )
  end

  def assert_risk_context_contract(
        handoff,
        field,
        {identity_field, identity_value},
        source_field,
        expected_value,
        stale_value
      ) do
    assert_risk_context_contract(
      handoff,
      field,
      {identity_field, identity_value},
      source_field,
      expected_value,
      stale_value,
      :drop_field
    )
  end

  def assert_risk_context_contract(
        handoff,
        field,
        {identity_field, identity_value},
        source_field,
        expected_value,
        stale_value,
        legacy_mode
      ) do
    %{
      artifact: artifact,
      recommendation_review_index: recommendation_review_index,
      recommendation_review_row: recommendation_review_row,
      review_import: review_import,
      review_import_index: review_import_index,
      review_import_row: review_import_row,
      selected_import_index: selected_import_index,
      selected_import_row: selected_import_row
    } = handoff

    assert recommendation_review_row[field] == expected_value
    assert selected_import_row[field] == expected_value
    assert review_import_row[field] == expected_value
    assert review_import_row["source_review_row"][field] == expected_value

    missing_review_context =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &Map.delete(&1, field)
      )

    assert {:error, missing_review_context_report} =
             Schema.validate_artifact(missing_review_context)

    assert Enum.any?(
             missing_review_context_report["errors"],
             &(&1["path"] == "$.rows[#{recommendation_review_index}].#{field}")
           )

    legacy_review_context =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &legacy_risk_context_row(
          &1,
          field,
          identity_field,
          identity_value,
          source_field,
          legacy_mode
        )
      )

    assert {:ok, _legacy_review_context} = Schema.validate_artifact(legacy_review_context)

    stale_selected_context =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(selected_import_index)],
        &Map.put(&1, field, stale_value)
      )

    assert {:error, stale_selected_context_report} =
             Schema.validate_artifact(stale_selected_context)

    assert Enum.any?(
             stale_selected_context_report["errors"],
             &(&1["path"] == "$.rows[#{selected_import_index}].#{field}")
           )

    missing_review_import_context =
      update_in(
        review_import,
        ["rows", Access.at(review_import_index)],
        &Map.delete(&1, field)
      )

    assert {:error, missing_review_import_context_report} =
             Schema.validate_artifact(missing_review_import_context)

    assert Enum.any?(
             missing_review_import_context_report["errors"],
             &(&1["path"] == "$.rows[#{review_import_index}].#{field}")
           )
  end

  def stale_context_value([_, _ | _] = values), do: Enum.reverse(values)
  def stale_context_value([value]) when is_boolean(value), do: [not value]
  def stale_context_value([value]) when is_integer(value), do: [value + 1]
  def stale_context_value([value]) when is_float(value), do: [value + 1.0]
  def stale_context_value([value]) when is_binary(value), do: ["stale_" <> value]
  def stale_context_value([values]) when is_list(values), do: [Enum.reverse(values)]

  def stale_context_value([%{} = value]) do
    {key, current_value} = Enum.at(value, 0)
    [Map.put(value, key, stale_context_scalar(current_value))]
  end

  defp legacy_risk_context_row(
         row,
         field,
         identity_field,
         identity_value,
         source_fields,
         :drop_field
       ) do
    row
    |> Map.delete(field)
    |> update_in(["source_recommendation", "risks_remaining"], fn risks ->
      Enum.map(risks, fn risk ->
        if risk_identity_matches?(risk, identity_field, identity_value) do
          Enum.reduce(List.wrap(source_fields), risk, &Map.delete(&2, &1))
        else
          risk
        end
      end)
    end)
    |> update_in(["source_recommendation", "explanation"], fn explanation ->
      Enum.map(explanation, fn explanation_row ->
        if risk_identity_matches?(explanation_row, identity_field, identity_value) do
          Enum.reduce(List.wrap(source_fields), explanation_row, &Map.delete(&2, &1))
        else
          explanation_row
        end
      end)
    end)
    |> sync_mutated_risk_contexts()
  end

  defp legacy_risk_context_row(
         row,
         field,
         identity_field,
         identity_value,
         _source_field,
         :drop_risk
       ) do
    risks =
      row
      |> get_in(["source_recommendation", "risks_remaining"])
      |> Enum.reject(&risk_identity_matches?(&1, identity_field, identity_value))

    row
    |> Map.delete(field)
    |> put_in(["source_recommendation", "risks_remaining"], risks)
    |> Map.put("risk_count", length(risks))
    |> sync_mutated_risk_contexts()
  end

  defp stale_context_scalar(value) when is_boolean(value), do: not value
  defp stale_context_scalar(value) when is_integer(value), do: value + 1
  defp stale_context_scalar(value) when is_float(value), do: value + 1.0
  defp stale_context_scalar(value) when is_binary(value), do: "stale_" <> value
  defp stale_context_scalar([value | rest]), do: [stale_context_scalar(value) | rest]

  defp sync_mutated_risk_contexts(row) do
    risks = get_in(row, ["source_recommendation", "risks_remaining"])

    context_keys =
      OrbitalDynamics.RecommendationRiskContext.ResourceFilter.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ResourceMargin.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ResourceProjection.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.RelayDataPath.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ValidationRefresh.context_keys()

    context =
      risks
      |> OrbitalDynamics.RecommendationRiskContext.ResourceFilter.context()
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ResourceMargin.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ResourceProjection.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.RelayDataPath.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ValidationRefresh.context(risks))

    row
    |> Map.drop(context_keys)
    |> Map.merge(context)
  end

  defp risk_identity_matches?(risk, identity_field, identity_values)
       when is_list(identity_values) do
    risk[identity_field] in identity_values
  end

  defp risk_identity_matches?(risk, identity_field, identity_value) do
    risk[identity_field] == identity_value
  end
end
