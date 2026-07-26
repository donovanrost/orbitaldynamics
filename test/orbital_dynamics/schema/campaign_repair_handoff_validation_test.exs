defmodule OrbitalDynamics.Schema.CampaignRepairHandoffValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema.CampaignRepairHandoffValidation

  test "indexes matching map rows without losing source positions" do
    rows = [%{"kind" => "keep"}, "invalid", %{"kind" => "drop"}, %{"kind" => "keep"}]

    assert CampaignRepairHandoffValidation.indexed_rows(
             rows,
             &(Map.get(&1, "kind") == "keep")
           ) == [
             {%{"kind" => "keep"}, 0},
             {%{"kind" => "keep"}, 3}
           ]

    assert CampaignRepairHandoffValidation.indexed_rows(nil, fn _row -> true end) == []
  end

  test "resolves direct sources before embedded review-row sources" do
    assert CampaignRepairHandoffValidation.row_source(%{
             "source" => "direct",
             "source_review_row" => %{"source" => "embedded"}
           }) == "direct"

    assert CampaignRepairHandoffValidation.row_source(%{
             "source_review_row" => %{"source" => "embedded"}
           }) == "embedded"
  end

  test "validates present direct and embedded source copies at their original row paths" do
    source_rows = [%{"id" => "source-1"}]

    indexed_rows = [
      {%{
         "source_copy" => %{"id" => "drifted"},
         "source_review_row" => %{"source_copy" => %{"id" => "drifted"}}
       }, 4}
    ]

    issues =
      CampaignRepairHandoffValidation.validate_source_copies(
        [],
        "$.rows",
        indexed_rows,
        source_rows,
        [["source_copy"], ["source_review_row", "source_copy"]],
        "must match source"
      )

    assert Enum.map(issues, &{&1["path"], &1["message"]}) == [
             {"$.rows[4].source_review_row.source_copy", "must match source"},
             {"$.rows[4].source_copy", "must match source"}
           ]

    assert CampaignRepairHandoffValidation.validate_source_copies(
             [],
             "$.rows",
             [{%{}, 4}],
             source_rows,
             [["source_copy"]],
             "must match source"
           ) == []
  end
end
