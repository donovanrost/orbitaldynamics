defmodule OrbitalDynamics.Schema.OperatorReviewCapabilityContext do
  @moduledoc false

  def operator_review_capabilities do
    OrbitalDynamics.OperatorReview.capabilities()
  end

  def operator_review_package_model_limits do
    operator_review_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def operator_review_source_artifact_types do
    operator_review_capabilities().source_artifact_types
  end

  def operator_review_types do
    operator_review_capabilities().review_types
  end
end
