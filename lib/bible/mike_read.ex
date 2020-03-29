defmodule Bible.Mike do
  def next do
    {{year, _month, _day} = dt, _} = :calendar.local_time()
    dt = Date.from_erl!(dt)
    dt_first = Date.from_erl!({year, 1, 1})
    {dt, dt_first}
    day_in_year = Date.diff(dt, dt_first) + 1
    # day_in_year = 365

    # Run through state machine to find first chapter to read today.
    # today (state, book_number, )
    info = Bible.Info.get_bible_info(Bible.Versions.ESV)
    chapter_acc = (day_in_year - 1) * 4 + 1
    today(:next, 0, chapter_acc, info)
  end

  def today(:next, book_number, chapter_acc, info) do
    book = Bible.Info.get_book_name(info, book_number + 1)
    {:ok, chapters} = Bible.Info.get_chapter_count(info, book)
    IO.inspect({book, chapters, chapter_acc}, label: :state)

    case chapter_acc > chapters do
      true -> today(:next, book_number + 1, chapter_acc - chapters, info)
      false -> {book, chapter_acc}
    end
  end
end
