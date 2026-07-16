defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.Aggregation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Normalization
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceTrustBoundaries

  def data_keys(feedback) when is_map(feedback) do
    feedback
    |> Map.drop(["provenance", "trust_boundary", "source", "metadata"])
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  def merge(derived, explicit) do
    Map.merge(derived, explicit, fn _key, derived_value, explicit_value ->
      if is_map(derived_value) and is_map(explicit_value) do
        Map.merge(derived_value, explicit_value)
      else
        explicit_value
      end
    end)
  end

  def compact(feedback) do
    feedback
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  def source_result_artifact_feedback(sources) when is_list(sources) do
    sources
    |> Enum.reduce(%{}, fn {_path, feedback, _trust_boundary}, merged ->
      feedback =
        feedback
        |> Normalization.normalize_explicit()
        |> Map.drop(["provenance", "trust_boundary"])

      merge(merged, feedback)
    end)
    |> put_source_result_artifact_trust_boundary(sources)
    |> compact()
  end

  def source_result_artifact_feedback(_sources), do: %{}

  def source_report_feedback(reports, feedback_fun)
      when is_list(reports) and is_function(feedback_fun, 1) do
    reports
    |> Enum.reduce(%{}, fn {_path, report}, feedback ->
      derived_feedback =
        report
        |> feedback_fun.()
        |> Normalization.normalize_explicit()

      merge(feedback, derived_feedback)
    end)
    |> compact()
  end

  def source_report_feedback(_reports, _feedback_fun), do: %{}

  def source_result_artifact_input_keys(sources) do
    sources
    |> source_result_artifact_feedback()
    |> data_keys()
  end

  defp put_source_result_artifact_trust_boundary(feedback, sources) do
    SourceTrustBoundaries.put_source_result_artifact_trust_boundary(feedback, sources)
  end
end
