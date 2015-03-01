defmodule Entice.Logic.GroupTest do
  use ExUnit.Case
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Group
  alias Entice.Test.Spy


  setup do
    {:ok, e1, _pid} = Entity.start
    {:ok, e2, _pid} = Entity.start
    {:ok, e3, _pid} = Entity.start
    {:ok, e4, _pid} = Entity.start

    Group.init(e1)
    Spy.inject_into(e1, self)

    Group.init(e2)
    Spy.inject_into(e2, self)

    Group.init(e3)
    Group.new_leader(e3, e1)
    Spy.inject_into(e3, self)
    assert_receive %{sender: ^e1, event: {:group_assign, ^e3}}

    Group.init(e4)
    Group.new_leader(e4, e2)
    Spy.inject_into(e4, self)
    assert_receive %{sender: ^e2, event: {:group_assign, ^e4}}

    {:ok, [e1: e1, e2: e2, e3: e3, e4: e4]}
  end


  test "setup", %{e1: e1, e2: e2, e3: e3, e4: e4} do
    assert {:ok, %Leader{members: [^e3], invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{members: [^e4], invited: []}} = Entity.fetch_attribute(e2, Leader)
    assert {:ok, %Member{leader: ^e1}}                 = Entity.fetch_attribute(e3, Member)
    assert {:ok, %Member{leader: ^e2}}                 = Entity.fetch_attribute(e4, Member)
  end


  test "inviting", %{e1: e1, e2: e2} do
    e1 |> Group.invite(e2)

    assert_receive %{sender: ^e2, event: {:group_invite, ^e1}}

    assert {:ok, %Leader{invited: [^e2]}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}}    = Entity.fetch_attribute(e2, Leader)
  end


  test "inviting a member of another group", %{e1: e1, e2: e2, e4: e4} do
    e1 |> Group.invite(e4)

    assert_receive %{sender: ^e4, event: {:group_invite, ^e1}}
    assert_receive %{sender: ^e2, event: {:group_invite, ^e1}}

    assert {:ok, %Leader{invited: [^e2]}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}}    = Entity.fetch_attribute(e2, Leader)
  end


  test "merging", %{e1: e1, e2: e2, e3: e3, e4: e4} do
    e1 |> Group.invite(e2)
    assert_receive %{sender: ^e2, event: {:group_invite, ^e1}}

    e2 |> Group.invite(e1)
    assert_receive %{sender: ^e1, event: {:group_invite, ^e2}}

    # leader should receive new members...
    assert_receive %{sender: ^e1, event: {:group_assign, ^e2}}
    assert_receive %{sender: ^e1, event: {:group_assign, ^e4}}

    assert {:ok, %Leader{members: [^e3 | new_mems], invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Member{leader: ^e1}}                            = Entity.fetch_attribute(e2, Member)
    assert e2 in new_mems and e4 in new_mems
    assert Entity.has_attribute?(e2, Leader) == false
  end


  test "kicking a member", %{e1: e1, e3: e3} do
    e1 |> Group.kick(e3)

    assert_receive %{sender: ^e3, event: {:group_kick, ^e1}}
    assert_receive %{sender: ^e1, event: {:group_leave, ^e3}}

    assert {:ok, %Leader{members: [], invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{members: [], invited: []}} = Entity.fetch_attribute(e3, Leader)
    assert Entity.has_attribute?(e3, Member) == false
  end


  test "kicking an invite - another", %{e1: e1, e2: e2} do
    e1 |> Group.invite(e2)

    assert_receive %{sender: ^e2, event: {:group_invite, ^e1}}

    assert {:ok, %Leader{invited: [e2]}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e2, Leader)

    e2 |> Group.kick(e1)

    assert_receive %{sender: ^e2, event: {:group_kick, ^e1}}
    assert_receive %{sender: ^e1, event: {:group_kick, ^e2}}

    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e2, Leader)
  end


  test "kicking an invite - my own", %{e1: e1, e2: e2} do
    e1 |> Group.invite(e2)

    assert_receive %{sender: ^e2, event: {:group_invite, ^e1}}

    assert {:ok, %Leader{invited: [e2]}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e2, Leader)

    e1 |> Group.kick(e2)

    assert_receive %{sender: ^e1, event: {:group_kick, ^e2}}
    assert_receive %{sender: ^e2, event: {:group_kick, ^e1}}

    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert {:ok, %Leader{invited: []}} = Entity.fetch_attribute(e2, Leader)
  end


  test "remove behaviour as leader", %{e1: e1, e3: e3} do
    e1 |> Group.remove()

    assert_receive %{sender: ^e3, event: {:group_new_leader, ^e3}}

    assert {:ok, %Leader{members: [], invited: []}} = Entity.fetch_attribute(e3, Leader)
    assert :error                                   = Entity.fetch_attribute(e1, Leader)
  end


  test "remove behaviour as member", %{e1: e1, e3: e3} do
    e3 |> Group.remove()

    assert_receive %{sender: ^e1, event: {:group_leave, ^e3}}

    assert {:ok, %Leader{members: [], invited: []}} = Entity.fetch_attribute(e1, Leader)
    assert :error                                   = Entity.fetch_attribute(e3, Member)
  end
end
