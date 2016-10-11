defmodule Bible.ReadServer do
  use GenServer
  use Timex
  @moduledoc """
  This server provides services related to what parts of the Bible
  have been read over periods of time. for example; the following information can be obtained:

  1 - Percent of Bible read during a specific period.
  2 - List of readings during a specific time period.
  3 - List of what has not been read during a period of time.
  4 - On-track indiciator for reading entire bible over a specified period of time.
  5 - ...

  Information is read from a MapTable file where entries are a date and a citation. These are all then put into a binary that has the following format:

    <<days since 1/1/2000>><<book>><<chap>><<verse>><<book>><<chap>><<verse>>
    ...
    ...

  Requires that the BibleServer is running.
  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: BibleReadServer])
  end

  @doc """
  State for the BibleServer consists of the following:

    %{ "Metadata" => bible_metadata }

  bible_metadata : This is the map described above.
  """
  def init (:ok) do
    readings = load_bible_readings
    total_verses = get_total_verses
    state = %{ "Readings" => readings,
               "Total Verses" => total_verses }
    {:ok, state}
  end

  @doc """
  Returns the bible metadata map. Format is described above.
  """
  def get_readings do
    GenServer.call(BibleReadServer, :readings)
  end

  def clear do
    GenServer.call(BibleReadServer, :clear)
  end

  @doc """
  Loads the specified readings file into the reading server. The format of the
  reading file is provided in the module documentation.
  """
  def load_readings_file(filepath) do
    GenServer.call(BibleReadServer, {:load_file, filepath})
  end

  def load_readings(reading_string) do
    GenServer.call(BibleReadServer, {:load_string, reading_string})
  end

  @doc """
  Given a start and end date (inclusive) this returns all the readings that fall in the provided range.
  """
  def get_readings({start_date, end_date}) do
    get_readings(start_date, end_date)
  end
  def get_readings(start_date, end_date) do
    GenServer.call(BibleReadServer, {:readings, start_date, end_date})
  end

  def reading_metrics(readings, reference) do
    GenServer.call(BibleReadServer, {:metrics, readings, reference})
  end

  def handle_call(:clear, _from, _state) do
    state = %{ "Readings" => <<>>,
               "Total Verses" => get_total_verses }
    {:reply, :ok, state}
  end

  # Retrieves the Bible metadata table.
  def handle_call(:readings, _from, state) do
    {:reply, state["Readings"], state}
  end

  # Loads the specified readings file into the read server.
  def handle_call({:load_file, filepath}, _from, _state) do
    readings = load_file(filepath)
    total_verses = get_total_verses
    state = %{ "Readings" => readings,
               "Total Verses" => total_verses }
    {:reply, :ok, state}
  end

  # Loads the specified readings string into the read server.
  def handle_call({:load_string, reading_string}, _from, _state) do
    readings = load(reading_string)
    total_verses = get_total_verses
    state = %{ "Readings" => readings,
               "Total Verses" => total_verses }
    {:reply, :ok, state}
  end



  def handle_call({:readings, start_date, end_date}, _from, state) do
    readings = get_readings_between(state["Readings"], start_date, end_date, state)
    {:reply, readings, state}
  end

  def handle_call({:metrics, readings, reference}, _from, state) do
    ref = Bible.References.exp_bible_reference(reference)
    {start,stop} = Bible.Server.get_ref_verse_range(ref)
    length = stop-start+1
    s1 = start-1
    << <<_::bitstring-size(s1)>>,
       <<bin::bitstring-size(length)>>,
       <<_::bitstring>> >> = readings
    total = bit_size(bin)
    read = for(<< bit::size(1) <- bin >>, do: bit) |> Enum.sum

#    IO.inspect bin
    {:reply, {total, read}, state}
  end

  @doc """
  Returns a binary list of readings between the dates specified. Requires that a readings binary be provided.
  """
  def filter_readings(readings, start_date, end_date) do
    epoch_date = Timex.to_date {2000,1,1}
    start_days = Timex.diff(start_date,epoch_date,:days)
    end_days = Timex.diff(end_date,epoch_date,:days)

    for(<<  days :: unsigned-integer-size(16),
        start_book :: unsigned-integer-size(8),
        start_chap :: unsigned-integer-size(8),
        start_vers :: unsigned-integer-size(8),
        end_book :: unsigned-integer-size(8),
        end_chap :: unsigned-integer-size(8),
        end_vers :: unsigned-integer-size(8) <- readings >>, do:
          { days, start_book, start_chap, start_vers,
            end_book, end_chap, end_vers })
        |> Enum.filter(&(filter_readings_test(elem(&1,0),start_days,end_days)))
  end

  def get_readings_between(readings, start_date, end_date, state) do
    total_verses = state["Total Verses"]
    filter_readings(readings, start_date, end_date)
      |> Enum.reduce(<<0::size(total_verses)>>, fn (reading, acc) -> add_reading(acc, reading) end)
  end

  defp add_reading(readings, reading) do
    { _, a, b, c, d, e, f } = reading
    { first_v, last_v } = Bible.Server.get_ref_verse_range({a,b,c,d,e,f})
    p1 = first_v - 1
    p2 = last_v - first_v + 1
    p3 = bit_size(readings) - last_v
    << s1 :: size(p1),
       _ :: size(p2),
       s3 :: size(p3) >> = readings
    << <<s1::size(p1)>>::bitstring,
       <<-1::size(p2)>>::bitstring,
       <<s3::size(p3)>>::bitstring >>
  end

  defp filter_readings_test(days, start_days, end_days) do
    days >= start_days && days <= end_days
  end

  def load_bible_readings do
    File.read!(Application.fetch_env!(:bible, :bible_readings_file))
      |> load
  end

  def load_file(filepath) do
    File.read!(filepath)
      |> load
  end

  def load(reads) do
    reads
      |> String.split("\n")               # Get list of lines.
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.split(&1," : ", parts: 2)))    # Have date and ref.
      |> Enum.map(&(add_ref_days(&1)))            # Add reference into entry.
      |> Enum.sort(&(&1["Days"] <= &2["Days"]))
      |> Enum.map( fn map -> map["Readings"] end)
      |> Enum.join
  end


  # Change to accept a multi-reference line after date.
  # Need an entry in the map called Refs that is a list of maps for each
  # individual ref.
  defp add_ref_days ([string_date,reading]) do
    string_date = String.trim(string_date)
    { :ok, date } = Timex.parse(string_date, "{D}-{Mshort}-{YYYY}")
    epoch_date = Timex.to_date {2000,1,1}
    days = Timex.diff(date,epoch_date,:days)
    refs = Bible.References.exp_bible_references(reading)
    newrefs = refs
      |> Enum.map(&(add_book_number(&1,days)))
      |> Enum.join
    %{"Days" => days, "Readings" => newrefs}
  end

  defp add_book_number(ref,days) do
    start_book_number = Bible.Server.get_book_number(ref["Start Book"],:in_bible)
    end_book_number = Bible.Server.get_book_number(ref["End Book"],:in_bible)

    <<
      days :: unsigned-integer-size(16),
      start_book_number :: unsigned-integer-size(8),
      ref["Start Chapter"] :: unsigned-integer-size(8),
      ref["Start Verse"] :: unsigned-integer-size(8),
      end_book_number :: unsigned-integer-size(8),
      ref["End Chapter"] :: unsigned-integer-size(8),
      ref["End Verse"] :: unsigned-integer-size(8)
    >>
  end

  defp get_total_verses do
    ref = Bible.References.exp_bible_reference("Revelation")
    { _, total } = Bible.Server.get_ref_verse_range(ref)
    total
  end

end
