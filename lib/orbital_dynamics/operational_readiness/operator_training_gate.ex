defmodule OrbitalDynamics.OperationalReadiness.OperatorTrainingGate do
  @moduledoc false

  def build(evidence) do
    case evidence["operator_training_requirement_count"] do
      count when is_integer(count) and count > 0 ->
        %{
          "id" => "operator_training",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" =>
            "operator training or qualification evidence requires role-qualified review before import"
        }
        |> Map.merge(context(evidence))

      _count ->
        nil
    end
  end

  def context(evidence) do
    %{
      "operator_training_requirement_count" => evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" => evidence["operator_training_requirement_counts"],
      "required_operator_roles" => evidence["required_operator_roles"],
      "required_training_ids" => evidence["required_training_ids"],
      "required_certification_ids" => evidence["required_certification_ids"],
      "required_qualification_ids" => evidence["required_qualification_ids"]
    }
  end
end
