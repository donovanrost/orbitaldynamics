defmodule OrbitalDynamics.Schema.OperatorReviewValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate_optional_package(issues, nil, _validate_contract), do: issues

  def validate_optional_package(issues, %{} = package, validate_contract),
    do: validate_contract.(package) ++ issues

  def validate_optional_package(issues, _package, _validate_contract),
    do: [error("$.operator_review_package", "must be an object") | issues]

  def validate_package(
        issues,
        path,
        package,
        source_artifact_types,
        model_limits,
        callbacks
      ) do
    OrbitalDynamics.Schema.OperatorReviewPackageContracts.validate(
      issues,
      path,
      package,
      source_artifact_types,
      model_limits,
      callbacks
    )
  end

  def validate_row(issues, path, row, review_types, counteroffer_states, callbacks) do
    OrbitalDynamics.Schema.OperatorReviewRowContracts.validate(
      issues,
      path,
      row,
      review_types,
      counteroffer_states,
      callbacks
    )
  end

  def validate_row_links(issues, path, row) do
    OrbitalDynamics.Schema.ReviewRowLinkContracts.validate(issues, path, row)
  end
end
