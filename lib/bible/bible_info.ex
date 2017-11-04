defmodule Bible.Info do

  @doc """
  Returns a map that has information about the specific version requested.
  Note that the information is meant to be used by the functions in the
  Bible.Info module.
  """
  def get_bible_info version_module do
    { _version_name, metadata } = new_load_metadata(version_module)

    book_number_map = gen_book_number_map(metadata)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    verse_count_map = gen_verse_count_map(metadata)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    verse_count_map = add_starting_verse(1,book_number_map,verse_count_map,[],1)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    %{ "Start Verse" => start_verse, "Verse Count" => verse_count} = verse_count_map["Revelation"]

    %{ "Metadata" => metadata,
       "Book Number Map" => book_number_map,
       "Verse Count Map" => verse_count_map,
       "Total Verses" => start_verse + verse_count - 1}
  end

  def get_books(info) do
    info["Metadata"]
    |> Map.keys
  end

  def get_book_count info do
    get_books(info)
    |> Enum.count
  end

  def is_book?(book, info) do
    Map.has_key?(info["Metadata"],book)
  end

  def get_reference_range(info, {a,b,c,d,e,f}) do
    book_number_map = info["Book Number Map"]
    book = book_number_map[a]
    start_verse = get_verse_index(info, book, b, c)
    book = book_number_map[d]
    end_verse = get_verse_index(info, book, e, f)
    {start_verse,end_verse}
  end

  def get_reference_range(info,ref) do
    book = ref["Start Book"]
    chapter = ref["Start Chapter"]
    verse = ref["Start Verse"]
    start_verse = get_verse_index(info, book, chapter, verse)
    book = ref["End Book"]
    chapter = ref["End Chapter"]
    verse = ref["End Verse"]
    end_verse = get_verse_index(info, book, chapter, verse)
    {start_verse,end_verse}
  end

  def get_book_name info, book_number do
    info["Book Number Map"][book_number]
  end

  def get_total_verse_count(info) do
    info["Total Verses"]
  end

  def get_chapter_count(info, book) do
    with metadata = info["Metadata"],
         true <- Map.has_key?(metadata,book)
    do
      <<
        _ :: binary-size(3),
        count :: unsigned-integer-size(8),
        _ :: binary
      >> = info["Metadata"][book]
      {:ok, count}
    else
      _ -> {:error, "Could not find #{book}"}
    end

  end

  def get_verse_count(info, book, chapter) do
    with metadata = info["Metadata"],
         true <- Map.has_key?(metadata,book),
         {:ok, chapters} <- get_chapter_count(info,book),
         true <- chapter >= 1 && chapter <= chapters
    do
      pos = 4 + chapter - 1
      <<
        _ :: binary-size(pos),
        verse_count :: unsigned-integer-size(8),
        _ :: binary
      >> = info["Metadata"][book]
      {:ok, verse_count}
  else
      _ ->
        {:error, "Could not find #{book} chapter #{Chapter}"}
    end

  end

  defp new_load_metadata version_module do
    version = version_module.get_version
    metadata = version_module.get_version_data
      |> String.split("\n")
      |> Enum.map(&(String.trim(&1)))
      |> Enum.drop_while(&(&1 == ""))             # Remove leading empty lines.
      |> Enum.reverse
      |> Enum.drop_while(&(&1 == ""))             # Remove trailing empty lines.
      |> Enum.reverse
      |> Enum.chunk_by(&(String.at(&1,1) == " "))
      |> Enum.chunk(2)
      |> Enum.map(&(gen_book_metadata(&1)))
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
    { version, metadata }
  end

  defp gen_book_metadata(book_entry) do
    [ head | tail ] = book_entry
    [ book_info | _ ] = head
    [ verse_counts | _ ] = tail
    {book_name, info_bin} = get_book_info_binary(book_info)
    verses_bin = get_book_verses_binary(verse_counts)
    bin = info_bin <> verses_bin
    map = %{ book_name => bin }
#    IO.inspect map
#    [ book_info | [ verse_counts | tail ]] = book_entry
#    IO.inpsect book_info
#    IO.inspect verse_counts
    map
  end

  defp gen_book_number_map(metadata) do
    metadata
      |> Enum.map(&(get_book_num_entry(&1)))
  end

  defp get_book_num_entry(book_map) do
    { book, book_binary } = book_map
    << _ :: binary-size(2),
       book_number :: unsigned-integer-size(8),
       _ :: binary >> = book_binary
    %{ book_number => book }
  end

  defp gen_verse_count_map(metadata) do
    metadata
      |> Enum.map(&(get_verses_in_book(&1)))
  end

  defp get_verses_in_book(book_map) do
    { book, book_binary } = book_map
    << _header :: binary-size(4),
       verse_list :: binary >> = book_binary
    %{ book => for(<<byte::8 <- verse_list >>, do: byte) |> Enum.sum }
  end

  defp add_starting_verse(67, _, _, list,_) do
    list
  end

  defp add_starting_verse(book_number, book_number_map, verse_count_map, list, acc) do
    book = book_number_map[book_number]
    verses = verse_count_map[book]
    list = [%{ book => %{ "Verse Count" => verses,
                      "Start Verse" => acc}}] ++ list
    add_starting_verse(book_number+1,book_number_map,verse_count_map,list,acc+verses)
  end

  defp get_book_verses_binary(verse_counts) do
    verse_counts
      |> Enum.reduce(fn(x,acc) -> acc <> " " <> x end)
      |> String.split
      |> Enum.map(fn(x) -> { num, _ } = Integer.parse(x); num end)
      |> Enum.reduce(<<>>, fn(x,acc) -> acc <> << x :: unsigned-integer-size(8) >> end)
  end

  defp get_book_info_binary(book_info_string) do
    { metrics, book_name } = String.split_at(book_info_string,11)
    book_name = String.trim(book_name)
    info_parts = String.split(metrics)
    [ new_old, num_in_testament, num_in_bible, chapters ] = info_parts
    { num_t, _ } = Integer.parse(num_in_testament)
    { num_b, _ } = Integer.parse(num_in_bible)
    { chaps, _ } = Integer.parse(chapters)
     info_binary = <<
      new_old :: binary-size(1),
      num_t :: unsigned-integer-size(8),
      num_b :: unsigned-integer-size(8),
      chaps :: unsigned-integer-size(8)
    >>
#    { :ok, num_in_testament } = Integer.parse()
    {book_name, info_binary}
  end

  def get_book_number(info, book, option) do
    <<
      _testament :: binary-size(1),
      number :: unsigned-integer-size(8),
      num_in_bible :: unsigned-integer-size(8),
      _ :: binary
    >> = info["Metadata"][book]
    case option do
      :in_bible -> num_in_bible
      :in_testament -> number
      _ -> number
    end
  end

  defp get_verse_index(info, book, chapter, verse) do
#    IO.inspect {:index, info, book, chapter, verse}
    verse_count_map = info["Verse Count Map"]
    metadata = info["Metadata"]
    chaps = chapter-1
    << _header :: binary-size(4),
       verse_list :: binary-size(chaps),
       _ :: binary >> = metadata[book]

    verse_start = verse_count_map[book]["Start Verse"]

    verses_in_prior_chapters = for(<<byte::8 <- verse_list >>, do: byte)
      |> Enum.sum
    verse_start + verses_in_prior_chapters + verse - 1
  end




end
