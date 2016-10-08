defmodule Server.Test do
  use ExUnit.Case
  use Timex
  doctest Bible.Server

  setup_all do
    metadata = Bible.Server.get_metadata
    {:ok, metadata: metadata}
  end

  test "verse count" do
    { :ok, verse_count } = Bible.Server.get_verse_count("Mark",12)
    assert verse_count == 44
  end

  test "chapter count" do
    { :ok, chapter_count } = Bible.Server.get_chapter_count("Psalms")
    assert chapter_count == 150
  end

  test "total chapter count" do
    books = Bible.Server.get_metadata
    |> Map.keys
    |> Enum.count
    assert books == 66
  end

  test "bible book list" do
    books = Bible.Server.get_books
    assert 66 == books |> Enum.count
  end

  test "Reference Verse Range" do
    ref = Bible.References.exp_bible_reference("Matthew 1:1 - Mark 1:1")
    range = Bible.Server.get_ref_verse_range(ref)
    assert {23208, 24279} = range
  end

end
