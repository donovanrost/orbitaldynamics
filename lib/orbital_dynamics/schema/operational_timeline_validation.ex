defmodule OrbitalDynamics.Schema.OperationalTimelineValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate_optional_report(issues, nil, _validate_contract), do: issues

  def validate_optional_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_report(issues, _report, _validate_contract),
    do: [error("$.operational_timeline_report", "must be an object") | issues]

  def validate_row(issues, path, row, callbacks) do
    OrbitalDynamics.Schema.OperationalTimelineRowContracts.validate(
      issues,
      path,
      row,
      Keyword.fetch!(callbacks, :validate_optional_timeline_preconditions),
      Keyword.fetch!(callbacks, :validate_optional_activity_context),
      &OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts.validate/3,
      Keyword.fetch!(callbacks, :validate_timeline_identity)
    )
  end
end
