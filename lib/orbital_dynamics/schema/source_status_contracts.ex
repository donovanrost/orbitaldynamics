defmodule OrbitalDynamics.Schema.SourceStatusContracts do
  @moduledoc false

  def validate_freshness_matches(
        issues,
        path,
        %{"source_freshness_report" => %{} = source_report} = row,
        statuses
      ) do
    validate_status_matches(
      issues,
      path,
      row,
      source_report,
      "source_freshness_report",
      "freshness_status",
      statuses,
      "must be one of current, stale, unknown"
    )
  end

  def validate_freshness_matches(issues, _path, _row, _statuses), do: issues

  def validate_schema_validation_matches(
        issues,
        path,
        %{"source_schema_validation_report" => %{} = source_report} = row,
        statuses
      ) do
    validate_status_matches(
      issues,
      path,
      row,
      source_report,
      "source_schema_validation_report",
      "validation_status",
      statuses,
      "must be one of pass, fail"
    )
  end

  def validate_schema_validation_matches(issues, _path, _row, _statuses), do: issues

  def validate_execution_matches(
        issues,
        path,
        %{"source_execution_report" => %{} = source_report} = row,
        statuses
      ) do
    validate_status_matches(
      issues,
      path,
      row,
      source_report,
      "source_execution_report",
      "execution_status",
      statuses,
      "must be one of completed, completed_with_errors, failed, running, created"
    )
  end

  def validate_execution_matches(issues, _path, _row, _statuses), do: issues

  defp validate_status_matches(
         issues,
         path,
         row,
         source_report,
         source_field,
         row_status_field,
         statuses,
         invalid_message
       ) do
    row_status = Map.get(row, row_status_field)
    source_status = Map.get(source_report, "status")

    issues =
      if is_binary(source_status) and source_status not in statuses do
        [
          error(
            "#{path}.#{source_field}.status",
            invalid_message
          )
          | issues
        ]
      else
        issues
      end

    if is_binary(row_status) and is_binary(source_status) and row_status != source_status,
      do: [
        error("#{path}.#{source_field}.status", "must match #{row_status_field}")
        | issues
      ],
      else: issues
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
