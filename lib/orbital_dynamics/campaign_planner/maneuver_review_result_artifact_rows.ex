defmodule OrbitalDynamics.CampaignPlanner.ManeuverReviewResultArtifactRows do
  @moduledoc false

  def rows_with_source(artifact, source_path, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)

    artifact = stringify_keys.(artifact)

    review_rows =
      [
        "source_maneuver_review_report",
        "maneuver_review_report"
      ]
      |> Enum.flat_map(fn report_key ->
        report = Map.get(artifact, report_key)

        report
        |> report_rows(artifact, opts)
        |> Enum.map(fn row -> {row, "#{source_path}.#{report_key}.rows"} end)
      end)

    review_keys =
      review_rows
      |> Enum.map(fn {row, _row_source_path} -> row end)
      |> MapSet.new(&replay_identity(&1, opts))

    recommendation_rows =
      artifact
      |> recommendation_review_rows(opts)
      |> Enum.map(fn row ->
        row =
          row
          |> stringify_keys.()
          |> put_inherited_trust_boundary(artifact, opts)
          |> Map.put_new(
            "_source_report_trust_boundary",
            Map.get(row, "trust_boundary") || get_in(row, ["provenance", "trust_boundary"])
          )

        {row, "#{source_path}.maneuver_recommendations"}
      end)

    review_rows ++
      Enum.reject(recommendation_rows, fn {row, _row_source_path} ->
        MapSet.member?(review_keys, replay_identity(row, opts))
      end)
  end

  def replay_identity(row, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    encode_value = Keyword.fetch!(opts, :encode_value)

    row = stringify_keys.(row)

    [
      row["maneuver_id"] || row["activity_id"],
      row["scenario_id"],
      row["epoch_s"],
      row["delta_v_km_s"],
      row["required_operator_action"] || row["action"]
    ]
    |> encode_value.()
  end

  defp report_rows(%{} = report, artifact, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)

    report = stringify_keys.(report)

    report_trust_boundary =
      Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(fn row ->
      row
      |> stringify_keys.()
      |> put_inherited_trust_boundary(report, opts)
      |> put_inherited_trust_boundary(artifact, opts)
      |> Map.put_new("_source_report_trust_boundary", report_trust_boundary)
    end)
  end

  defp report_rows(_report, _artifact, _opts), do: []

  defp recommendation_review_rows(artifact, opts) do
    case Map.get(artifact, "maneuver_recommendations", []) do
      [] ->
        []

      recommendations ->
        recommendations
        |> OrbitalDynamics.ManeuverReview.report(
          source: "result_artifact.maneuver_recommendations",
          source_artifact_id: source_id(artifact, opts)
        )
        |> Map.get("rows", [])
        |> List.wrap()
    end
  end

  defp source_id(artifact, opts) do
    encode_value = Keyword.fetch!(opts, :encode_value)

    Enum.find_value(
      [
        Map.get(artifact, "id"),
        Map.get(artifact, "study_id"),
        get_in(artifact, ["run", "id"]),
        get_in(artifact, ["execution_report", "run_id"])
      ],
      &encode_value.(&1)
    )
  end

  defp put_inherited_trust_boundary(report, artifact, opts) do
    opts
    |> Keyword.fetch!(:put_inherited_result_artifact_trust_boundary)
    |> then(& &1.(report, artifact))
  end
end
