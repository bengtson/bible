defmodule Info.Test do
  use ExUnit.Case
  use Timex

  setup_all do
    info = Bible.Info.get_bible_info "Z"
    {:ok, info: info}
  end

  test "verse count", state do
    { :ok, verse_count } = Bible.Info.get_verse_count(state.info,"Mark",12)
    assert verse_count == 44
  end

  test "chapter count", state do
    {:ok, chapter_count} = Bible.Info.get_chapter_count(state.info,"Psalms")
    assert chapter_count == 150
  end

  test "total chapter count", state do
    books = state.info["Metadata"]
    |> Map.keys
    |> Enum.count
    assert books == 66
  end

  test "bible book list", state do
    books = Bible.Info.get_books(state.info)
    assert 66 == books |> Enum.count
  end

  test "Reference Verse Range", state do
    ref = Bible.References.exp_bible_reference("Matthew 1:1 - Mark 1:1", state.info)
    range = Bible.Info.get_reference_range(state.info,ref)
    assert {23208, 24279} = range
  end

end
