defmodule ReferencesTest do
  use ExUnit.Case
  use Timex
  doctest Bible.References

  setup_all do
    metadata = Bible.Server.get_metadata
    {:ok, metadata: metadata}
  end

  test "part type colon" do
    assert { :colon, nil, [] } == Bible.References.parts_type([":"])
  end

  test "part type comma" do
    assert { :comma, nil, [] } == Bible.References.parts_type([","])
  end

  test "part type hyphen" do
    assert { :hyphen, nil, [] } == Bible.References.parts_type(["-"])
  end

  test "part type book" do
    assert { :book, "Acts", [] } == Bible.References.parts_type(["Acts"])
  end

  test "part type book two part" do
    assert { :book, "1 Kings", [] } == Bible.References.parts_type(["1", "Kings"])
  end

  test "part type book three part" do
    assert { :book, "Song of Solomon", ["Extra"] } == Bible.References.parts_type(["Song", "of", "Solomon", "Extra"])
  end

  test "part type book no match" do
    assert { :other, "Song", ["of", "Michael", "Extra"] } == Bible.References.parts_type(["Song", "of", "Michael", "Extra"])
  end

  test "part type number" do
    assert { :number, 23, ["hello"] } == Bible.References.parts_type(["23", "hello"])
  end

  test "part type chapter number" do
    assert { :chapter, 23, ["hello"] } == Bible.References.parts_type(["23", ":", "hello"])
  end

  test "Check Problem Ref" do
    r = Bible.References.cycle_reference("John 1-3")
    assert r == "John 1-3"
  end

  test "Check List of References" do
    refs = "John 1-3,Genesis 22"
    r = Bible.References.exp_bible_references(refs)
    s = Bible.References.reduce_references(r)
    assert refs == s
  end

  # John 19-21 was returning John 19 - John. Reordered variant 13 in case
  # statement.
  test "Check John 19-21" do
    r = "John 19-21"
    assert r == Bible.References.cycle_reference(r)
  end

  test "Check Variants and Reductions" do
    assert [] == Bible.References.references_test
  end

end
