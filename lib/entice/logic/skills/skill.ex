defmodule Entice.Logic.Skill do
  import Inflex

  defmacro __using__(_) do
    quote do
      import Entice.Logic.Skill
      import Entice.Logic.Skill.Effect

      @skills %{}
      @before_compile Entice.Logic.Skill
    end
  end


  defmacro defskill(skillname, opts, do_block \\ []) do
    skillid = Keyword.get(opts, :id)
    name = skillname |> elem(2) |> hd |> to_string
    uname = underscore(name)

    quote do
      # add the module
      defmodule unquote(skillname) do
        @behaviour Entice.Logic.Skill.Behaviour
        def id, do: unquote(skillid)
        def name, do: unquote(name)
        def underscore_name, do: unquote(uname)
        def apply_effect(target, caster), do: {:ok, caster}
        defoverridable [apply_effect: 2]
        unquote(do_block)
      end
      # then update the stats
      @skills Map.put(@skills, unquote(skillid), unquote(skillname))
    end
  end


  defmacro __before_compile__(_) do
    quote do

      @doc """
      Simplistic skill getter.
      Either uses skill ID or tries to convert a skill name to the module atom.
      The skill should be a GW skill name in PascalCase.
      """
      def get_skill(id) when is_integer(id), do: Map.get(@skills, id)
      def get_skill(name) do
        try do
          ((__MODULE__ |> Atom.to_string) <> "." <> name) |> String.to_existing_atom
        rescue
          ArgumentError -> nil
        end
      end

      @doc "Get all skills that are known"
      def get_skills,
      do: @skills |> Map.values

      def max_unlocked_skills,
      do: get_skills |> Enum.reduce(0, fn (skill, acc) -> Entice.Utils.BitOps.set_bit(acc, skill.id) end)
    end
  end
end


defmodule Entice.Logic.Skill.Behaviour do
  use Behaviour
  alias Entice.Entity

  @doc "Unique skill identitfier, resembles roughly GW"
  defcallback id() :: integer

  @doc "Unique skill name"
  defcallback name() :: String.t

  @doc "Unique skill name (snake case)"
  defcallback underscore_name() :: String.t

  @doc "General skill description"
  defcallback description() :: String.t

  @doc "Cast time of the skill in MS"
  defcallback cast_time() :: integer

  @doc "Recharge time of the skill in MS"
  defcallback recharge_time() :: integer

  @doc "Energy cost of the skill in mana"
  defcallback energy_cost() :: integer

  @doc "Is called after the casting finished."
  defcallback apply_effect(target_entity_id :: term, caster_entity :: %Entity{}) ::
    {:ok, new_caster_entity :: %Entity{}} |
    {:error, reason :: term}
end


defmodule Entice.Logic.Skill.Effect do
  @moduledoc """
  Helpers that can be used when implementing skill effect scripts
  """
  use Entice.Logic.Attributes
  alias Entice.Entity


  def damage(target, amount) do
    target |> Entity.update_attribute(Health,
      fn %Health{health: health} = h when (health - amount) <= 0 -> %Health{h | health: 0}
         %Health{health: health} = h                             -> %Health{h | health: (health - amount)}
      end)
  end


  def heal(target, amount) do
    target |> Entity.update_attribute(Health,
      fn %Health{health: health, max_health: max} = h when (health + amount) >= max -> %Health{h | health: max}
         %Health{health: health} = h                                                -> %Health{h | health: (health + amount)}
      end)
  end
end
