defmodule Modbus.Rtu do
  @moduledoc false
  require Logger
  alias Modbus.Helper
  alias Modbus.Request
  alias Modbus.Response

  def pack_req(cmd) do
    cmd |> Request.pack() |> wrap
  end

  def parse_req(wraped) do
    wraped |> unwrap |> Request.parse()
  end

  def pack_res(cmd, values) do
    cmd |> Response.pack(values) |> wrap
  end

  def parse_res(cmd, wraped) do
    res = unwrap(wraped)

    if res do
      Response.parse(cmd, res)
    else
      :error
    end
  end

  def res_len(cmd) do
    Response.length(cmd) + 2
  end

  def req_len(cmd) do
    Request.length(cmd) + 2
  end

  # CRC is little endian
  # http://modbus.org/docs/Modbus_over_serial_line_V1_02.pdf page 13
  def wrap(payload) do
    <<crc_hi, crc_lo>> = Helper.crc(payload)
    <<payload::binary, crc_lo, crc_hi>>
  end

  # CRC is little endian
  # http://modbus.org/docs/Modbus_over_serial_line_V1_02.pdf page 13
  def unwrap(data) do
    size = :erlang.byte_size(data) - 2
    <<payload::binary-size(size), crc_lo, crc_hi>> = data

    case Helper.crc(payload) do
      <<^crc_hi, ^crc_lo>> ->
        payload

      _ ->
        Logger.error("[Modbus.Rtu] -> wrong response")
        nil
    end
  end
end
