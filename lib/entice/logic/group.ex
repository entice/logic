defmodule Entice.Logic.Group do
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Group.LeaderBehaviour
  alias Entice.Logic.Group.MemberBehaviour
  import Map


  def init(entity_id),
  do: Entity.put_behaviour(entity_id, LeaderBehaviour, [])


  @doc """
  Members cannot invite.
  Leaders will only invite other leaders.
  If you invite someone, that someone will get the event and not you.
  """
  def invite(sender_id, target_id),
  do: Entity.notify(target_id, {:group_invite, sender_id})


  @doc """
  Confirm that you got the invite, and that its valid (not that your taking it).
  """
  def invite_ack(sender_id, target_id),
  do: Entity.notify(target_id, {:group_invite_ack, sender_id})


  @doc """
  Enforce a new leader entity for the receiver.
  Members will simply reassign.
  Leader will propagate to their members and become a member.
  (Used internally if invite was successful)
  """
  def new_leader(entity_id, leader_id, invs \\ []),
  do: Entity.notify(entity_id, {:group_new_leader, leader_id, invs})


  @doc """
  Assigns the given entity to the receiver's party.
  Leaders will simply add, members will do nothing.
  (Used internally if invite was successful)
  """
  def self_assign(sender_id, leader_id),
  do: Entity.notify(leader_id, {:group_assign, sender_id})


  @doc """
  Kick the target from your group.
  If target not in group, but in invites, will be removed from invites.
  Only usable by a leader.
  """
  def kick(sender_id, target_id) do
    Entity.notify(sender_id, {:group_kick, target_id})
    Entity.notify(target_id, {:group_kick, sender_id})
  end


  @doc """
  Leave a group, only works as a member.
  """
  def leave(member_id, leader_id),
  do: Entity.notify(leader_id, {:group_leave, member_id})


  @doc """
  Removes any kind of grouping behaviour from this entity.
  Works reasonably: If you're in a group (member or leader),
  you will leave the group.
  """
  def remove(entity_id) do
    Entity.remove_behaviour(entity_id, LeaderBehaviour)
    Entity.remove_behaviour(entity_id, MemberBehaviour)
  end


  # Server-internal API


  defmodule LeaderBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Group


    def init(id, attributes, %{invited: invs}),
    do: {:ok, attributes |> put(Leader, %Leader{invited: invs}), %{entity_id: id}}

    def init(id, attributes, _args),
    do: {:ok, attributes |> put(Leader, %Leader{}), %{entity_id: id}}


    # merging...


    def handle_event({:group_invite, sender_id}, %{Leader => %Leader{invited: invs}} = attributes, %{entity_id: id} = state) do
      if sender_id in invs do
        case Entity.fetch_attribute(sender_id, Leader) do
          {:ok, %Leader{}} -> sender_id |> Group.new_leader(id, invs)
          _                -> nil
        end
      else
        id |> Group.invite_ack(sender_id)
      end
      {:ok, attributes, state}
    end


    def handle_event({:group_invite_ack, sender_id}, %{Leader => %Leader{invited: invs} = l} = attributes, state) do
      leader = %Leader{l | invited: [sender_id | invs]}
      {:ok, Map.put(attributes, Leader, leader), state}
    end


    def handle_event({:group_new_leader, leader_id, _invs}, %{Leader => %Leader{members: mems, invited: invs}} = attributes, %{entity_id: id} = state) do
      for m <- mems, do: m |> Group.new_leader(leader_id, invs)
      id |> Group.self_assign(leader_id)
      {:become, MemberBehaviour, %{leader_id: leader_id}, Map.put(attributes, Leader, %Leader{}), state}
    end


    def handle_event({:group_assign, sender_id}, %{Leader => %Leader{members: mems, invited: invs}} = attributes, state) do
      leader = %Leader{members: mems ++ [sender_id], invited: invs -- [sender_id]}
      {:ok, Map.put(attributes, Leader, leader), state}
    end


    # kicking/leaving...


    def handle_event({:group_kick, id}, %{Leader => %Leader{members: [hd | _] = mems, invited: invs}} = attributes, %{entity_id: id}) do
      for m <- mems, do: m |> Group.new_leader(hd, invs)
      init(id, attributes, [])
    end


    def handle_event({:group_kick, sender_id}, %{Leader => %Leader{invited: invs} = l} = attributes, state) do
      leader = %Leader{l | invited: invs -- [sender_id]}
      {:ok, Map.put(attributes, Leader, leader), state}
    end


    def handle_event({:group_leave, sender_id}, %{Leader => %Leader{members: mems} = l} = attributes, state) do
      leader = %Leader{l | members: mems -- [sender_id]}
      {:ok, Map.put(attributes, Leader, leader), state}
    end


    def terminate(:remove_handler, %{Leader => %Leader{members: [], invited: invs}} = attributes, %{entity_id: id}) do
      for i <- invs, do: id |> Group.kick(i)
      {:ok, Map.delete(attributes, Leader)}
    end


    def terminate(:remove_handler, %{Leader => %Leader{members: [hd | _] = mems, invited: invs}} = attributes, _state) do
      for m <- mems, do: m |> Group.new_leader(hd, invs)
      {:ok, Map.delete(attributes, Leader)}
    end
  end


  defmodule MemberBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Group


    def init(id, attributes, %{leader_id: lead}) do
      {:ok, attributes |> put(Member, %Member{leader: lead}), %{entity_id: id}}
    end


    # merging...


    def handle_event({:group_invite, sender_id}, %{Member => %Member{leader: leader_id}} = attributes, state) do
      Entity.notify(leader_id, {:group_invite, sender_id}) # forward to actual group leader
      {:ok, attributes, state}
    end


    # if leader id and my id are the same, make me leader
    def handle_event({:group_new_leader, id, invs}, %{Member => %Member{}} = attributes, %{entity_id: id} = state),
    do: {:become, LeaderBehaviour, %{invited: invs}, attributes, state}


    # if someone else is the leader, then just reassign to that entity
    def handle_event({:group_new_leader, leader_id, _invs}, %{Member => %Member{}} = attributes, %{entity_id: id} = state) do
      id |> Group.self_assign(leader_id)
      {:ok, Map.put(attributes, Member, %Member{leader: leader_id}), state}
    end


    # kicking...


    def handle_event({:group_kick, sender_id}, %{Member => %Member{leader: leader_id}} = attributes, %{entity_id: id} = state)
    when sender_id == leader_id or sender_id == id do
      id |> Group.new_leader(id)
      {:ok, attributes, state}
    end


    def terminate(:remove_handler, %{Member => %Member{leader: leader_id}} = attributes, %{entity_id: id}) do
      #leave
      id |> Group.leave(leader_id)
      {:ok, Map.delete(attributes, Member)}
    end
  end
end
