defmodule OrbitalDynamics.Schema.CandidateRefreshObjectiveGapContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      validate_non_negative_integer_count_map: 3
    ]

  def validate(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "gap_row_count",
          "downlink_gap_row_count",
          "target_gap_row_count",
          "collection_latency_gap_row_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "status_counts",
        "objective_type_counts",
        "term_key_counts",
        "ground_station_counts",
        "target_counts",
        "collection_counts",
        "source_activity_id_counts"
      ],
      issues,
      fn field, acc ->
        validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end
end
