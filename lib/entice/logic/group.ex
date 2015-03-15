defmodule Entice.Logic.Group do
  @moduledoc """
  Implements a distributed grouping behaviour for entities.
  This has two different kinds of implementations, one for leaders of a group,
  and one for members. These different behaviours react to the same events
  according to their nature.
  """
  alias Entice.Entity
  alias Entice.Logic.Group.Leader
  alias Entice.Logic.Group.Member
  alias Entice.Logic.Group.LeaderBehaviour
  alias Entice.Logic.Group.MemberBehaviour


  defmodule Leader, do: defstruct(
    members: [],
    invited: [])

  defmodule Member, do: defstruct(
    leader: "")


  # External API


  @doc """
  Enable grouping behaviour for an entity.
  """
  def register(entity_id),
  do: Entity.put_behaviour(entity_id, LeaderBehaviour, [])


  @doc """
  Removes any kind of grouping behaviour from this entity.
  Works reasonably: If you're in a group (member or leader),
  you will leave the group.
  """
  def unregister(entity_id) do
    Entity.remove_behaviour(entity_id, LeaderBehaviour)
    Entity.remove_behaviour(entity_id, MemberBehaviour)
  end


  @doc """
  Check if a given entity is the leader of my group.
  If this is called by the leader with its own id, then the result is true.
  """
  def is_my_leader?(entity_id, leader_id) do
    my_leader = cond do
      Entity.has_attribute?(entity_id, Leader) -> entity_id
      Entity.has_attribute?(entity_id, Member) -> Entity.fetch_attribute!(entity_id, Member) |> Map.get(:leader)
    end
    my_leader == leader_id
  end


  @doc """
  Members cannot invite.
  Leaders will only invite other leaders.
  If you invite someone, that someone will get the event and not you.
  """
  def invite(sender_id, target_id),
  do: Entity.notify(target_id, {:group_invite, sender_id})


  @doc """
  Kick the target from your group.
  If target not in group, but in invites, will be removed from invites.
  Only usable by a leader.
  """
  def kick(sender_id, target_id) do
    Entity.notify(sender_id, {:group_kick, target_id})
    Entity.notify(target_id, {:group_kick, sender_id})
  end


  # Internal API


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
  Leave a group, only works as a member.
  """
  def leave(member_id, leader_id),
  do: Entity.notify(leader_id, {:group_leave, member_id})


  # Actual behaviour implementation


  defmodule LeaderBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Group


    def init(entity, %{invited: invs}),
    do: {:ok, entity |> put_attribute(%Leader{invited: invs})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Leader{})}


    # merging...


    def handle_event({:group_invite, sender_id}, %Entity{id: id, attributes: %{Leader => %Leader{invited: invs}}} = entity)
    when sender_id != id do
      if sender_id in invs and Entity.has_attribute?(sender_id, Leader) do
        sender_id |> Group.new_leader(id, invs)
      else
        id |> Group.invite_ack(sender_id)
      end
      {:ok, entity}
    end


    def handle_event({:group_invite_ack, sender_id}, %Entity{attributes: %{Leader => %Leader{invited: invs}}} = entity),
    do: {:ok, entity |> update_attribute(Leader, fn l -> %Leader{l | invited: [sender_id | invs]} end)}


    def handle_event({:group_new_leader, leader_id, _invs}, %Entity{attributes: %{Leader => %Leader{members: mems, invited: invs}}} = entity) do
      for m <- mems, do: m |> Group.new_leader(leader_id, invs)
      entity.id |> Group.self_assign(leader_id)
      {:become, MemberBehaviour, %{leader_id: leader_id}, entity |> put_attribute(%Leader{})}
    end


    def handle_event({:group_assign, sender_id}, %Entity{attributes: %{Leader => %Leader{members: mems, invited: invs}}} = entity),
    do: {:ok, entity |> put_attribute(%Leader{members: mems ++ [sender_id], invited: invs -- [sender_id]})}


    # kicking/leaving...


    def handle_event({:group_kick, id}, %Entity{id: id, attributes: %{Leader => %Leader{members: [hd | _] = mems, invited: invs}}} = entity) do
      for m <- mems, do: m |> Group.new_leader(hd, invs)
      {:ok, entity |> put_attribute(%Leader{})}
    end


    def handle_event({:group_kick, sender_id}, %Entity{attributes: %{Leader => %Leader{invited: invs}}} = entity),
    do: {:ok, entity |> update_attribute(Leader, fn l -> %Leader{l | invited: invs -- [sender_id]} end)}


    def handle_event({:group_leave, sender_id}, %Entity{attributes: %{Leader => %Leader{members: mems}}} = entity),
    do: {:ok, entity |> update_attribute(Leader, fn l -> %Leader{l | members: mems -- [sender_id]} end)}


    def terminate(:remove_handler, %Entity{attributes: %{Leader => %Leader{members: [], invited: invs}}} = entity) do
      for i <- invs, do: entity.id |> Group.kick(i)
      {:ok, entity |> remove_attribute(Leader)}
    end


    def terminate(:remove_handler, %Entity{attributes: %{Leader => %Leader{members: [hd | _] = mems, invited: invs}}} = entity) do
      for m <- mems, do: m |> Group.new_leader(hd, invs)
      {:ok, entity |> remove_attribute(Leader)}
    end
  end


  defmodule MemberBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Group


    def init(entity, %{leader_id: lead}),
    do: {:ok, entity |> put_attribute(%Member{leader: lead})}


    # merging...


    def handle_event({:group_invite, sender_id}, %Entity{attributes: %{Member => %Member{leader: leader_id}}} = entity) do
      Entity.notify(leader_id, {:group_invite, sender_id}) # forward to actual group leader
      {:ok, entity}
    end


    # if leader id and my id are the same, make me leader
    def handle_event({:group_new_leader, id, invs}, %Entity{id: id} = entity),
    do: {:become, LeaderBehaviour, %{invited: invs}, entity}


    # if someone else is the leader, then just reassign to that entity
    def handle_event({:group_new_leader, leader_id, _invs}, entity) do
      entity.id |> Group.self_assign(leader_id)
      {:ok, entity |> put_attribute(%Member{leader: leader_id})}
    end


    # kicking...


    def handle_event({:group_kick, sender_id}, %Entity{id: id, attributes: %{Member => %Member{leader: leader_id}}} = entity)
    when sender_id == leader_id or sender_id == id do
      id |> Group.new_leader(id)
      {:ok, entity}
    end


    def terminate(:remove_handler, %Entity{attributes: %{Member => %Member{leader: leader_id}}} = entity) do
      entity.id |> Group.leave(leader_id)
      {:ok, entity |> remove_attribute(Member)}
    end
  end
end
