defmodule Bible.Server do
  use GenServer
  @moduledoc """
  This is a genserver that loads bible layout information. This information can be queried for books, chapters in a book and verses in a chapter.

  The information about the books in the bible are held in a map. Each book has it's own entry with the key being the name of the book. The value of each entry is the info about the book in a binary as follows:

    byte 1 : "N" or "O" for new or old testament.
    byte 2 : Order of book in their respective testaments.
    byte 3 : Order of book in the Bible.
    byte 4 : Number of chapters in the book.
    byte 5..n : Number of verses starting with chapter 1. Each is a byte.

  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: BibleServer])
  end

  @doc """
  State for the BibleServer consists of the following:

    %{ "Metadata" => bible_metadata,
       "Verse Count" => verse_counter }

  bible_metadata : This is the map described above.
  verse_counter : Used to count all verses in the bible. Each book gets starting and ending verses set in the metadata.
  """
  def init (:ok) do
    metadata = new_load_metadata
#    metadata = load_bible_metadata

    book_number_map = gen_book_number_map(metadata)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    verse_count_map = gen_verse_count_map(metadata)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    verse_count_map = add_starting_verse(1,book_number_map,verse_count_map,[],1)
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)

    state = %{ "Metadata" => metadata,
               "Book Number Map" => book_number_map,
               "Verse Count Map" => verse_count_map}
    {:ok, state}
  end

  @doc """
  Returns the number of chapters in the book specified.
  """
  def get_chapter_count(book) do
    GenServer.call(BibleServer, {:chapter_count, book})
  end

  @doc """
  Returns the bible metadata map. Format is described above.
  """
  def get_metadata do
    GenServer.call(BibleServer, :metadata)
  end

  @doc """
  Returns the number of verses in the book and chapter specified.
  """
  def get_verse_count(book, chapter) do
    GenServer.call(BibleServer, {:verse_count, book, chapter})
  end

  @doc """
  Returns a list of all the books in the bible. These are not ordered in any particular way.
  """
  def get_books do
    GenServer.call(BibleServer, :books)
  end

  @doc """
  Returns true of false based on whether specified string is a book in the
  Bible.
  """
  def is_book?(book) do
    GenServer.call(BibleServer, {:is_book, book})
  end

  def get_book_number(book_name, option) do
    GenServer.call(BibleServer, {:book_number, book_name, option})
  end

  def get_book_name(book_number) do
    GenServer.call(BibleServer, {:book_name, book_number})
  end

  def get_ref_verse_range(reference) do
    GenServer.call(BibleServer, {:verse_range, reference})
  end

  # Retrieves the chapter count for the specified book.
  def handle_call({:chapter_count, book}, _from, state) do
    with true <- Map.has_key?(state["Metadata"],book),
         chapters <- get_chapter_count(state["Metadata"],book)
            do
          {:reply, {:ok, chapters}, state}
    else
      _ -> {:reply, :error, state}
    end
  end

  # Retrieves the Bible metadata table.
  def handle_call(:metadata, _from, state) do
    {:reply, state["Metadata"], state}
  end

  # Retrieves the verse count for specified book and chapter.
  def handle_call({:verse_count, book, chapter}, _from, state) do
    with true <- Map.has_key?(state["Metadata"],book),
         chapters <- get_chapter_count(state["Metadata"],book),
         true <- chapter >= 1 && chapter <= chapters,
         verses <- get_verse_count(state["Metadata"], book, chapter)
          do
      {:reply, {:ok, verses}, state}
    else
      _ -> {:reply, :error, state}
    end
  end

  # Returns an unordered list of all the books in the Bible.
  def handle_call(:books, _from, state) do
    {:reply, get_books(state["Metadata"]), state}
  end

  # Returns true or false based on valid Bible book.
  def handle_call({:is_book, book}, _from, state) do
    {:reply, Map.has_key?(state["Metadata"],book), state}
  end

  def handle_call({:book_number, book_name, option}, _from, state) do
    metadata = state["Metadata"]
    number = get_book_num(metadata, book_name, option)
    {:reply, number, state}
  end

  def handle_call({:book_name, book_number}, _from, state) do
    num_map = state["Book Number Map"]
    {:reply, num_map[book_number], state}
  end

  def handle_call({:verse_range, {a,b,c,d,e,f}}, _from, state) do
    book_number_map = state["Book Number Map"]
    book = book_number_map[a]
    start_verse = get_verse_index(state, book, b, c)
    book = book_number_map[d]
    end_verse = get_verse_index(state, book, e, f)
    {:reply, {start_verse,end_verse}, state}
  end

  def handle_call({:verse_range, ref}, _from, state) do
    book = ref["Start Book"]
    chapter = ref["Start Chapter"]
    verse = ref["Start Verse"]
    start_verse = get_verse_index(state, book, chapter, verse)
    book = ref["End Book"]
    chapter = ref["End Chapter"]
    verse = ref["End Verse"]
    end_verse = get_verse_index(state, book, chapter, verse)
    {:reply, {start_verse,end_verse}, state}
  end


  #--------------------------

  defp get_book_num(bible_db, book, option) do
    <<
      testament :: binary-size(1),
      number :: unsigned-integer-size(8),
      num_in_bible :: unsigned-integer-size(8),
      _ :: binary
    >> = bible_db[book]
    case option do
      :in_bible -> num_in_bible
      :in_testament -> number
      _ -> number
    end
  end

  defp get_verse_count(bible_db, book, chapter) do
    pos = 4 + chapter - 1
    <<
      _ :: binary-size(pos),
      verse_count :: unsigned-integer-size(8),
      _ :: binary
    >> = bible_db[book]
    verse_count
  end

  defp get_chapter_count(bible_db, book) do
    <<
      _ :: binary-size(3),
      count :: unsigned-integer-size(8),
      _ :: binary
    >> = bible_db[book]
    count
  end

  defp get_books(bible_db) do
    bible_db
    |> Map.keys
  end

  defp new_load_metadata do
    Bible.Versions.ESV.get_version
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
#      |> IO.inspect
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

  defp set_atom (pair) do
    case pair do
      [a, b] ->
        %{String.strip a => String.strip b}
      _ ->
        %{:delim => 0}
    end
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
    << header :: binary-size(4),
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

  defp get_verse_index(state, book, chapter, verse) do
    verse_count_map = state["Verse Count Map"]
    metadata = state["Metadata"]
    chaps = chapter-1
    << header :: binary-size(4),
       verse_list :: binary-size(chaps),
       _ :: binary >> = metadata[book]

    verse_start = verse_count_map[book]["Start Verse"]

    verses_in_prior_chapters = for(<<byte::8 <- verse_list >>, do: byte)
      |> Enum.sum
    verse_sum = verse_start + verses_in_prior_chapters + verse - 1
  end

end
