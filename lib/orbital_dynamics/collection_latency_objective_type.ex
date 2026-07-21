defmodule OrbitalDynamics.CollectionLatencyObjectiveType do
  @moduledoc false

  @aliases [
    "collection_latency",
    "collection_downlink_latency",
    "data_latency",
    "downlink_latency",
    "max_collection_latency",
    "collection_latency_limit"
  ]

  def aliases, do: @aliases

  defguard is_supported(type) when type in @aliases

  def supported?(type), do: type in @aliases

  def canonical(type) when type in @aliases, do: "collection_latency"
  def canonical(_type), do: nil
end
