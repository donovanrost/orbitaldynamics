defmodule OrbitalDynamics.Schema.CampaignRepairStationReservationReviewSummaryHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.StationReservation

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_station_reservation_review_summary"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_reservations = Enum.map(expected_rows, &Map.get(&1, "source_station_reservation"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_reservations)
    |> validate_cadence_handoff(artifact, expected_sources, source_reservations)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_reservations
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain the exact source station-reservation review-summary rows"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source station-reservation review-summary identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_reservations,
      [["source_station_reservation"]],
      "must match the corresponding enclosing source station-reservation review-summary row"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reservations
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_reservations
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain the exact source station-reservation review-summary import rows"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source station-reservation review-summary identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_reservations,
      [["source_station_reservation"], ["source_review_row", "source_station_reservation"]],
      "must match the corresponding enclosing source station-reservation review-summary row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reservations
       ),
       do: issues

  defp source_rows(%{
         "source_station_reservation_review_summary" =>
           %{"schema_contract" => "station_reservation_review_summary.v1"} = summary
       }) do
    StationReservation.source_report_rows(summary, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_summary_row?(row) do
    Map.get(row, "review_type") == "station_reservation_review" and
      review_summary_source?(row_source(row))
  end

  defp cadence_summary_row?(row) do
    (Map.get(row, "source_review_type") == "station_reservation_review" or
       Map.get(row, "import_action") == "review_station_reservation") and
      review_summary_source?(row_source(row))
  end

  defp review_summary_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp review_summary_source?(_source), do: false
end
