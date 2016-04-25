defmodule Entice.Logic.Skills do
  use Entice.Logic.Skill
  use Entice.Logic.Attributes

  defskill NoSkill, id: 0 do
    def description,   do: "Non-existing skill as a placeholder for empty skillbar slots."
    def cast_time,     do: 0
    def recharge_time, do: 0
    def energy_cost,   do: 0
  end

  defskill HealingSignet, id: 1 do
    def description,   do: "You gain 82...154...172 Health. You have -40 armor while using this skill."
    def cast_time,     do: 2000
    def recharge_time, do: 4000
    def energy_cost,   do: 0

    def apply_effect(_target, caster),
    do: heal(caster, 10)
  end

  defskill ResurrectionSignet, id: 2 do
    def description,   do: "Resurrects target party member (100% Health, 25% Energy). This signet only recharges when you gain a morale boost."
    def cast_time,     do: 3000
    def recharge_time, do: 0
    def energy_cost,   do: 0

    def apply_effect(target, _caster),
    do: resurrect(target, 100, 25)

    def check_requirements(target, _caster),
    do: require_dead(target)
  end

  defskill SignetOfCapture, id: 3 do
    def description,   do: "Choose one skill from a nearby dead Boss of your profession. Signet of Capture is permanently replaced by that skill. If that skill was elite, gain 250 XP for every level you have earned."
    def cast_time,     do: 2000
    def recharge_time, do: 2000
    def energy_cost,   do: 0
  end

  defskill Bamph, id: 4 do
    def description,   do: "BAMPH!"
    def cast_time,     do: 0
    def recharge_time, do: 0
    def energy_cost,   do: 0

    def apply_effect(target, _caster),
    do: damage(target, 10)
  end

  defskill PowerBlock, id: 5 do
    def description,   do: "If target foe is casting a spell or chant, that skill and all skills of the same attribute are disabled (1...10...12 seconds) and that skill is interrupted."
    def cast_time,     do: 250
    def recharge_time, do: 20000
    def energy_cost,   do: 15
  end

  defskill MantraOfEarth, id: 6 do
    def description,   do: "(30...78...90 seconds.) Reduces earth damage you take by 26...45...50%. You gain 2 Energy when you take earth damage."
    def cast_time,     do: 0
    def recharge_time, do: 20000
    def energy_cost,   do: 10
  end

  defskill MantraOfFlame, id: 7 do
    def description,   do: "(30...78...90 seconds.) Reduces fire damage you take by 26...45...50%. You gain 2 Energy when you take fire damage."
    def cast_time,     do: 0
    def recharge_time, do: 20000
    def energy_cost,   do: 10
  end

  defskill MantraOfFrost, id: 8 do
    def description,   do: "(30...78...90 seconds.) Reduces cold damage you take by 26...45...50%. You gain 2 Energy when you take cold damage."
    def cast_time,     do: 0
    def recharge_time, do: 20000
    def energy_cost,   do: 10
  end

  defskill MantraOfLightning, id: 9 do
    def description,   do: "(30...78...90 seconds.) Reduces lightning damage you take by 26...45...50%. You gain 2 Energy when you take lightning damage."
    def cast_time,     do: 0
    def recharge_time, do: 20000
    def energy_cost,   do: 10
  end

  defskill HexBreaker, id: 10 do
    def description,   do: "(5...65...80 seconds.) The next hex against you fails and the caster takes 10...39...46 damage."
    def cast_time,     do: 0
    def recharge_time, do: 15000
    def energy_cost,   do: 5
  end

  defskill Distortion, id: 11 do
    def description,   do: "(1...4...5 seconds.) You have 75% chance to block. Block cost: you lose 2 Energy or Distortion ends."
    def cast_time,     do: 0
    def recharge_time, do: 8000
    def energy_cost,   do: 5
  end
end
