defmodule OrbitalDynamics.Schema.CampaignRepairCommandWindowHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_command_window_source "command_window_report.rows"
  @repair_source_command_window_source "campaign_repair.source_command_window_report.rows"
  @no_review_actions ~w(monitor_activity none_locked_activity none_terminal_activity)

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_report_handoffs(
      artifact,
      Map.get(artifact, "command_window_report"),
      @repair_command_window_source,
      "generated Repair"
    )
    |> validate_report_handoffs(
      artifact,
      Map.get(artifact, "source_command_window_report"),
      @repair_source_command_window_source,
      "Repair source"
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_report_handoffs(
         issues,
         artifact,
         %{"rows" => command_window_rows},
         source,
         source_description
       )
       when is_list(command_window_rows) do
    source_rows = Enum.filter(command_window_rows, &reviewable_command_window?/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows, source, source_description)
    |> validate_cadence_handoff(artifact, source_rows, source, source_description)
  end

  defp validate_report_handoffs(
         issues,
         _artifact,
         _report,
         _source,
         _source_description
       ),
       do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         command_window_rows,
         source,
         source_description
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_command_window_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(command_window_rows),
      "must contain one #{source_description} command-window review row per enclosing reviewable report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      command_window_rows,
      [["source_command_window"]],
      "must match the corresponding enclosing #{source_description} command-window report row"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _command_window_rows,
         _source,
         _source_description
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         command_window_rows,
         source,
         source_description
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_command_window_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(command_window_rows),
      "must contain one #{source_description} command-window import row per enclosing reviewable report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      command_window_rows,
      [
        ["source_command_window"],
        ["source_review_row", "source_command_window"]
      ],
      "must match the corresponding enclosing #{source_description} command-window report row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _command_window_rows,
         _source,
         _source_description
       ),
       do: issues

  defp reviewable_command_window?(%{} = row),
    do: Map.get(row, "required_operator_action") not in @no_review_actions

  defp reviewable_command_window?(_row), do: false

  defp operator_command_window_row?(row, source) do
    Map.get(row, "review_type") == "command_window_review" and
      row_source(row) == source
  end

  defp cadence_command_window_row?(row, source) do
    (Map.get(row, "source_review_type") == "command_window_review" or
       Map.get(row, "import_action") == "review_command_window") and
      row_source(row) == source
  end
end
