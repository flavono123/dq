require 'benchmark'
require 'fileutils'
require 'nokogiri'
require 'yaml'

class YAMLGenerator
  NON_DIALOG_TEXT_PATTERN = /{|}|\||%|\[|\]/
  # RULE: Distinquished minimum prefixes end with `_'(except for full id name)
  NON_DIALOG_ID_PATTERN = %r{^(\[pc\]menu_|\[pc\]str_|
                            action_|activity_|actor_|already_used_camping_|
                            buff_|building_|
                            camping_|cant_|character_|confirm_|corrupt_|curio_|
                            dlc_|dungeon_|
                            effect_|enemy_|estate_|
                            fe_|front_|
                            game_|
                            item_|
                            mailing_|menu_base_|menu_controls_|menu_options_|menu_transfer_|monster_|
                            no_|not_|
                            obstacle_|on_|options_category_|options_value|
                            pass_|
                            raid_quest_|raid_results|realm_|resistance_|retreat_combat_|retreat_confirm_|retreat_fail_|retreat_raid_|
                            skill_|sort_roster_|sort_trinket_|stagecoach_|stall_|start_|
                            str_abbey_|
                            str_affliction_description_nothing|str_affliction_name_|
                            str_ambush_|
                            str_ancestor_obstacle|
                            str_and|
                            str_bar_add_|
                            str_blacksmith_summary|
                            str_brothel_add_|
                            str_camping_|
                            str_cant_place|str_cant_use_firewood_|str_cant_use_torch_during_|
                            str_caretaker_goal_plot_|
                            str_caretaker_goals_|
                            str_centre_|
                            str_confirm_dlc_|
                            str_could_not_|
                            str_darkest_|
                            str_darkness_|
                            str_deadhero_|
                            str_death_|
                            str_debug_|
                            str_delete_|
                            str_demo_|
                            str_difficulty_|
                            str_discard_|
                            str_disease_cured|str_disease_new|
                            str_diseases|
                            str_district_|str_districts_|
                            str_dlc_|
                            str_drinking_|
                            str_embarked_|
                            str_empty_|
                            str_flagellation_add_|
                            str_full|
                            str_game_mode_|
                            str_glossary_term_|
                            str_gold|
                            str_graveyard_|
                            str_guild_|
                            str_help_|
                            str_hero_|
                            str_in_the|
                            str_inventory_description_heirloomurn|
                            str_inventory_description_provision|
                            str_inventory_description_supplyfirewood|
                            str_inventory_description_supplyholy_water|
                            str_inventory_description_supplymedicinal_herbs|
                            str_inventory_description_supplyrope|
                            str_inventory_description_supplyshovel|
                            str_inventory_description_supplyskeleton_key|
                            str_inventory_description_supplytorch|
                            str_inventory_title_|str_inventory_type_|
                            str_its_a_trap|
                            str_language_|
                            str_level|
                            str_map_ac_|
                            str_meal_|
                            str_media_|
                            str_monster_skill_|str_monstername_|
                            str_move_|
                            str_navigate_|
                            str_new_|
                            str_no_|
                            str_obstacle_|
                            str_overlay_|
                            str_part|
                            str_plot_|
                            str_prayer_add_|
                            str_preamble_|
                            str_quest_complete_|
                            str_quest_info_|
                            str_quirk_is_singleton|
                            str_quirk_name_|
                            str_quirk_new|
                            str_quirk_removed|
                            str_quirks|
                            str_resolve_|
                            str_return_|
                            str_roster_list_full|
                            str_sanitarium_|
                            str_save_|
                            str_scouting|
                            str_select_|
                            str_skill_|
                            str_sort_|
                            str_stragecoach_prisoner_|str_stagecoach_roster_|
                            str_stage_coach_|
                            str_start_|
                            str_stat_|
                            str_statue_summary|
                            str_tavern_summary|
                            str_torch_|
                            str_town_tip|
                            str_town_title|
                            str_trinket_found|
                            str_type_in_|
                            str_ugc_|
                            str_ui_|
                            str_unequip_|
                            str_upper_|
                            str_user_|
                            str_virtue_|
                            str_warning_|
                            str_warrens_tip|
                            str_weal_tip|
                            surprise_|
                            town_activity_name_|
                            town_confirm_|
                            town_district_|
                            town_event_info_|
                            town_event_title_|
                            town_free|
                            town_name_|
                            town_progression_|
                            town_provision_|
                            town_quest_difficulty_|
                            town_quest_dungeon_|
                            town_quest_goal_|
                            town_quest_goals|
                            town_quest_length_|
                            town_quest_locked|
                            town_quest_name_|
                            town_quest_number_|
                            town_quest_progress_|
                            town_quest_quest_|
                            town_quest_rewards|
                            town_quest_select_|
                            tray_icon_|
                            trinket_hero_|
                            trinket_rarity_|
                            tutorial_popup_|
                            upgrade_|
                            variable_
                            )}x

  HEROES = %w[
    abomination
    antiquarian
    arbalest
    bounty_hunter
    crusader
    grave_robber
    hellion
    highwayman
    houdmaster
    houndmaster
    jester
    leper
    man_at_arms
    musketeer
    occultist
    plague_doctor
    vestal
  ].freeze

  SPEAKER_ID_PATTERN_MAP = {
    ancestor: //
  }.freeze


  def initialize
    @total_entries = []
    @xmls = xml_paths.map { |f| File.read(f) }
  end

  def check_duration(method, *args)
    ret = nil
    time = Benchmark.measure {
      ret = send(method, *args)
    }

    formatted_args = args.join(', ')
    formatted_args = formatted_args[0..30] + ' <...eliding...>' if formatted_args.size > 30

    left = "Duration for call `#{ method }#{ "(#{formatted_args})'" unless args.empty? }"
    right = "- #{ format('%.6f', time.real) }"

    puts format('%-100s %s', left, right)

    ret
  end

  def gen_yaml(filename)
    # Parse and filter
    xmls.each do |xml|
      entries = check_duration(:parse, xml)
      check_duration(:filter!, entries)

      # Dedup
      check_duration(:distinguish_by_dup_id!, entries)
      check_duration(:dedup_by_text!, entries)

      total_entries.concat(entries)
    end

    check_duration(:sort!, total_entries)

    # Output as a file
    check_duration(:rotate_yaml, filename)
    check_duration(:create_yaml, filename)
    check_duration(:chmod_yaml_as_readonly!, filename)
  end

  def xml_paths
    @xml_paths ||= Dir['org/*.xml']
  end

  private

  attr_reader :total_entries, :xmls

  def parse(xml, language='english') # TODO: multi-lang support, only English for now
    english = Nokogiri.XML(xml).xpath("/root/language[@id='#{language}']")
    english.xpath('entry').to_a
  end

  def filter!(entries)
    filter_by_id!(entries)
    filter_by_text!(entries)
  end

  # filter non-dialogs
  def filter_by_id!(entries)
    entries.filter! {|e| e['id'] !~ NON_DIALOG_ID_PATTERN}
  end

  # filter the text with template or in-game statement(TAVERN: xxx...)
  def filter_by_text!(entries)
    entries.filter! {|e| e.text !~ NON_DIALOG_TEXT_PATTERN}
  end

  def sort!(entries)
    entries.sort_by! {|e| e['id']}
  end

  def distinguish_by_dup_id!(entries)
    tally = entries.group_by {|e| e['id']}.to_h { |id, es| [id, es.size] }
    dup_ids = tally.filter { |_id, size| size > 1 }.keys
    dup_ids.each do |id|
      dup_id_es = entries.filter { |e| e['id'] == id }
      dup_id_es.each_with_index do |e, i|
        e['id'] = "#{id}_#{i}"
      end
    end
  end

  def dedup_by_text!(entries)
    entries.uniq! { |e| e.text }
  end

  def rotate_yaml(filename)
    FileUtils.mv(filename, "#{filename}.old") if File.exists?(filename)
  end

  def create_yaml(filename)
    hash = {}

    HEROES.each do |hero|
      hero_es = []
      delete_indices = []
      total_entries.each do |e|
        hero_es << e if e['id'].start_with?(hero)
      end

      hero_es.each { |e| total_entries.delete(e) }

      hash.merge!({ hero => to_h(hero_es) })
    end


    hash.merge!({ 'rest' => to_h(total_entries) })

    yaml = hash.to_yaml

    File.open(filename, 'w+') {|f| f.write(yaml)}
  end

  def to_h(entries)
    entries.to_h {|e| [e['id'], e.text]}
  end

  def chmod_yaml_as_readonly!(filename)
    File.chmod(0444, filename)
  end
end


def bq(str)
  "`#{str}'"
end

filename = 'dialog.yaml'
yml_gen = YAMLGenerator.new
puts "Create the #{bq(filename)} from #{yml_gen.xml_paths.map {|x| bq(x)}.join(', ')}"
yml_gen.gen_yaml('dialog.yaml')
