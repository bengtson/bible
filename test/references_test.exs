defmodule ReferencesTest do
  use ExUnit.Case
  use Timex
  doctest Bible.References

  setup_all do
    info = Bible.Info.get_bible_info("Z")
    {:ok, info: info}
  end

  test "part type colon", state do
    assert { :colon, nil, [] } == Bible.References.parts_type([":"], state.info)
  end

  test "part type comma", state do
    assert { :comma, nil, [] } == Bible.References.parts_type([","], state.info)
  end

  test "part type hyphen", state do
    assert { :hyphen, nil, [] } == Bible.References.parts_type(["-"], state.info)
  end

  test "part type book", state do
    assert { :book, "Acts", [] } == Bible.References.parts_type(["Acts"], state.info)
  end

  test "part type book two part", state do
    assert { :book, "1 Kings", [] } == Bible.References.parts_type(["1", "Kings"], state.info)
  end

  test "part type book three part", state do
    assert { :book, "Song of Solomon", ["Extra"] } == Bible.References.parts_type(["Song", "of", "Solomon", "Extra"], state.info)
  end

  test "part type book no match", state do
    assert { :other, "Song", ["of", "Michael", "Extra"] } == Bible.References.parts_type(["Song", "of", "Michael", "Extra"], state.info)
  end

  test "part type number", state do
    assert { :number, 23, ["hello"] } == Bible.References.parts_type(["23", "hello"], state.info)
  end

  test "part type chapter number", state do
    assert { :chapter, 23, ["hello"] } == Bible.References.parts_type(["23", ":", "hello"], state.info)
  end

  test "Check Problem Ref", state do
    r = Bible.References.cycle_reference("John 1-3", state.info)
    assert r == "John 1-3"
  end

  test "Check List of References", state do
    refs = "John 1-3; Genesis 22"
    r = Bible.References.exp_bible_references(refs, state.info)
    s = Bible.References.reduce_references(r, state.info)
    assert refs == s
  end

  # John 19-21 was returning John 19 - John. Reordered variant 13 in case
  # statement.
  test "Check John 19-21", state do
    r = "John 19-21"
    assert r == Bible.References.cycle_reference(r,state.info)
  end

  test "Check Variants and Reductions", state do
    assert [] == Bible.References.references_test state.info
  end

end
