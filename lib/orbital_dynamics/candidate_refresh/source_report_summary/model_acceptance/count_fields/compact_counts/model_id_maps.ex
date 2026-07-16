defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.ModelIdMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.MapCounts

  def count(summary) do
    Enum.find_value(FieldSpecs.compact_model_id_count_fields(), :error, fn field ->
      case Map.get(summary, field) do
        %{} = model_id_map -> {:ok, MapCounts.count(model_id_map)}
        _model_id_map -> false
      end
    end)
  end

  def group_count(summary, field, group) do
    case Map.get(summary, field) do
      %{} = model_id_map ->
        {:ok, MapCounts.group_count(model_id_map, group)}

      _model_id_map ->
        :error
    end
  end

  def count_map(summary, field) do
    case Map.get(summary, field) do
      %{} = model_id_map -> {:ok, MapCounts.group_count_map(model_id_map)}
      _model_id_map -> :error
    end
  end
end
