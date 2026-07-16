defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalTimelineFeedbackTrustBoundaries,
    RealizedFeedbackTrustBoundaries,
    RealizedFeedbackWeights
  }

  def metadata(rows_with_sources, source_report_contract, opts \\ default_callbacks()) do
    callbacks = callbacks!(opts)
    {rows, source_paths} = rows_and_source_paths(rows_with_sources)

    weighted_feedback_row_count = callbacks.weighted_feedback_row_count.(rows)
    feedback_weight_sources = callbacks.feedback_weight_sources.(rows)
    trust_boundaries = trust_boundaries(rows)
    feedback_trust_boundaries = callbacks.feedback_trust_boundaries.(rows)

    %{
      "source_report_contract" => source_report_contract,
      "source_report_count" => length(rows),
      "source_report_paths" => if(source_paths == [], do: nil, else: source_paths),
      "source_report_row_count" => length(rows),
      "source_activity_type_counts" => count_present_values(rows, ["type", "activity_type"]),
      "source_direction_counts" => count_present_values(rows, "direction"),
      "source_cadence_import_status_counts" =>
        count_present_values(rows, "cadence_import_status"),
      "source_planned_protection_decision_counts" =>
        count_present_values(rows, ["planned_protection_decision", "protection_decision"]),
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources),
      "trust_boundary_status" => trust_boundary_status(rows),
      "trust_boundaries" => trust_boundaries,
      "feedback_trust_boundaries" => feedback_trust_boundaries
    }
    |> compact_map()
  end

  def realized_metadata(rows_with_sources, opts \\ realized_default_callbacks()) do
    callbacks = realized_callbacks!(opts)
    {rows, source_paths} = rows_and_source_paths(rows_with_sources)

    weighted_feedback_row_count = callbacks.weighted_feedback_row_count.(rows)
    feedback_weight_sources = callbacks.feedback_weight_sources.(rows)
    trust_boundaries = callbacks.trust_boundaries.(rows)

    %{
      "source_report_contract" => "realized_activity.v1",
      "source_report_count" => length(rows),
      "source_report_paths" => if(source_paths == [], do: nil, else: source_paths),
      "source_report_row_count" => length(rows),
      "source_activity_type_counts" => count_present_values(rows, ["type", "activity_type"]),
      "source_direction_counts" => count_present_values(rows, "direction"),
      "source_cadence_import_status_counts" =>
        count_present_values(rows, "cadence_import_status"),
      "source_realized_status_counts" =>
        count_present_values(rows, ["status", "realized_status"]),
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources),
      "trust_boundary_status" => if(trust_boundaries == [], do: nil, else: "declared"),
      "trust_boundaries" => if(trust_boundaries == [], do: nil, else: trust_boundaries),
      "feedback_trust_boundaries" => callbacks.feedback_trust_boundaries.(rows)
    }
    |> compact_map()
  end

  defp rows_and_source_paths(rows_with_sources) do
    rows = Enum.map(rows_with_sources, fn {row, _source_path} -> row end)

    source_paths =
      rows_with_sources
      |> Enum.map(fn {_row, source_path} -> source_path end)
      |> Enum.uniq()

    {rows, source_paths}
  end

  defp callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp realized_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      trust_boundaries: Keyword.fetch!(opts, :trust_boundaries),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp realized_default_callbacks do
    [
      weighted_feedback_row_count: &RealizedFeedbackWeights.weighted_row_count/1,
      feedback_weight_sources: &RealizedFeedbackWeights.sources/1,
      trust_boundaries: &realized_activity_source_trust_boundaries/1,
      feedback_trust_boundaries: &RealizedFeedbackTrustBoundaries.feedback_boundaries/1
    ]
  end

  defp default_callbacks do
    [
      weighted_feedback_row_count: &RealizedFeedbackWeights.weighted_row_count/1,
      feedback_weight_sources: &RealizedFeedbackWeights.sources/1,
      feedback_trust_boundaries: &OperationalTimelineFeedbackTrustBoundaries.feedback_boundaries/1
    ]
  end

  defp realized_activity_source_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(&RealizedFeedbackTrustBoundaries.activity_boundaries/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_present_values(rows, fields) when is_list(fields) do
    rows
    |> Enum.map(fn row ->
      Enum.find_value(fields, fn field ->
        case Map.get(row, field) do
          value when value in [nil, ""] -> nil
          value -> value
        end
      end)
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp count_present_values(rows, field), do: count_present_values(rows, [field])

  defp trust_boundary_status(rows) do
    case trust_boundaries(rows) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["trust_boundary"],
        get_in(row, ["provenance", "trust_boundary"]),
        row["_source_report_trust_boundary"]
      ]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp compact_map(map) do
    Map.reject(map, fn {_key, value} -> is_nil(value) end)
  end
end
