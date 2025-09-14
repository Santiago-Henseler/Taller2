defmodule VoiceChatTest do
  use ExUnit.Case
  doctest VoiceChat

  test "greets the world" do
    assert VoiceChat.hello() == :world
  end
end
