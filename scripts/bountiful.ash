/******************************************************************************
* Bountiful by RESPRiT
* Version 0.1
* https://github.com/RESPRiT
*
* Adapted from AutoBHH:
* -Originally by izchak
* -Major revisions by Raorn and Zarqon
******************************************************************************/
script "Bountiful";
notify tamedtheturtle;
since r18000;

/****************************
Custom Properties Used:
 - bountiful.useBanisher
 - bountiful.useCopier
 - bountiful.useFax
 - bountiful.useRunaway
 - bountiful.maxBanishCost
 - bountiful.maxSpecialCost
*****************************/

//----------------------------------------
// Global Variables
string current;
int count;

// Property Shorthands:
//   Simply assigns property values to short variable names
boolean useBan = get_property("bountiful.useBanisher").to_boolean();
boolean useCopier = get_property("bountiful.useCopier").to_boolean();
boolean useFax = get_property("bountiful.useFax").to_boolean();
boolean useRun = get_property("bountiful.useRunaway").to_boolean();
int maxBanish = get_property("bountiful.maxBanishCost").to_int();
int maxSpecial = get_property("bountiful.maxSpecialCost").to_int();

// Constants
string EASY = "easy";
string HARD = "hard";
string SPECIAL = "special";

// Banishers
int[item] BAN_ITEMS = {
  $item[Louder Than Bomb] : 20,
  $item[crystal skull] : 20,
  $item[tennis ball] : 20,
  $item[divine champagne popper] : 5
};

boolean[skill] BAN_SKILLS = {
  $skill[Snokebomb] : true
};

//----------------------------------------
// Private Functions

bounty _bounty(string type) {
  bounty ret;
  switch(type) {
    case EASY:
      ret = to_bounty(get_property("currentEasyBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenEasyBountyItem"));
      } else {
        return ret;
      }
    case HARD:
      ret = to_bounty(get_property("currentHardBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenHardBountyItem"));
      } else {
        return ret;
      }
    case SPECIAL:
      ret = to_bounty(get_property("currentSpecialBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenSpecialBountyItem"));
      } else {
        return ret;
      }
    default:
      abort("_bounty: Invalid bounty type");
  }
  return $bounty[none];
}

boolean _accepted(string type) {
  switch(type) {
    case EASY:
      return get_property("currentEasyBountyItem") != "";
    case HARD:
      return get_property("currentHardBountyItem") != "";
    case SPECIAL:
      return get_property("currentSpecialBountyItem") != "";
    default:
      abort("_accepted: Invalid bounty type");
  }
  return false;
}

// TODO: Only items, needs skills
monster[item] get_used_banishers() {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[item] list;
  for(int i = 0; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i]);
    int[monster] invert;
    foreach id, em in get_monsters(_bounty(current).location) {
      invert[em] = id;
    }
    item it = to_item(banish_data[i + 1]);
    if(invert contains m) list[it] = m;
  }

  return list;
}

item get_unused_banisher() {
  monster[item] used = get_used_banishers();

  foreach banisher in BAN_ITEMS {
    if(!(used contains banisher)) {
      return banisher;
    }
  }

  return $item[none];
}

/**
* Visits the BHH and possibly performs an action based on the query
* @param {string} query - the query to do BHH actions
* @returns {string} - the page text
*/
string visit_bhh(string query) {
  string page = visit_url("bounty.php?pwd"+query);
  return page;
}

// @Overload
string visit_bhh() {
  return visit_bhh("");
}

boolean accept_bounty(string type) {
  if(_accepted(type)) {
    return false;
  }

  string query = "&action=take"+_bounty(type).kol_internal_type;
  visit_bhh(query);
  visit_bhh();
  return true;
}

// TODO
void print_current() {

}

// TODO
void print_available() {

}

/**
* Checks if the given monster is currently being hunted
* @param {monster} opp - the string representation of the monster to check
* @returns {boolean} - if the given monster is being hunted
*/
boolean is_hunted(monster opp) {
  // Checks if opp equals any of the current bounty monsters
  return opp == to_bounty(get_property("currentEasyBountyItem")).monster ||
         opp == to_bounty(get_property("currentHardBountyItem")).monster ||
         opp == to_bounty(get_property("currentSpecialBountyItem")).monster;
}

// @Overload
boolean is_hunted(string opp) {
  return is_hunted(to_monster(opp));
}

/**
* Custom action filter, see here:
*   http://wiki.kolmafia.us/index.php?title=Adventure
* @param {int} round   - the current combat round
* @param {monster} opp - the current enemy monster
* @param {string} text - the current page text
* @returns {boolean} - if the given monster is being hunted
*/
string combat(int round, monster opp, string text) {
  // Check if the current monster is worth hunting
  if(is_hunted(opp)) {
    if(useCopier && (round == 0) && _accepted(current)) {
      if((item_amount($item[Rain-Doh black box]) > 0) &&
          $item[Rain-Doh black box].dailyusesleft > 0) {
        return "item Rain-Doh black box";
      } else if(item_amount($item[Spooky Putty sheet]) > 0 &&
          $item[Spooky Putty sheet].dailyusesleft > 0) {
        return "item Spooky Putty sheet";
      }
    }
  } else if(useBan) {
    item banisher = get_unused_banisher();
    if(item_amount(banisher) > 0) {
      return "item " + to_string(banisher);
    }
  }

  // Default to CCS if custom actions can't happen
  return get_ccs_action(round);
}

bounty optimal_bounty() {
  bounty[int] bounty_counts;
  bounty_counts[_bounty(EASY).number] = _bounty(EASY);
  bounty_counts[_bounty(HARD).number] = _bounty(HARD);
  bounty_counts[_bounty(SPECIAL).number] = _bounty(SPECIAL);

  int min = 696969;
  foreach count in bounty_counts {
    if(count < min && count != 0) {
      min = count;
    }
  }

  return bounty_counts[min];
}

boolean hunt_bounty(bounty b) {
  if(useFax && !to_boolean(get_property("_photocopyUsed"))) {
    faxbot(_bounty(b.type).monster);
    use(1, $item[photocopied monster]);
  } else if(item_amount($item[Rain-Doh box full of monster]) > 0 ||
            $item[Rain-Doh black box].dailyusesleft > 0) {
    use(1, $item[Rain-Doh box full of monster]);
  } else if(item_amount($item[Spooky Putty monster]) > 0) {
    use(1, $item[Spooky Putty monster]);
  } else {
    current = b.type;
    adventure(1, b.location, "combat");
  }
  visit_bhh();
  return false;
}

// Main function execution
void main(string params) {
  if(!_accepted(optimal_bounty().type)) {
    accept_bounty(optimal_bounty().type);
  }
  while(optimal_bounty() != $bounty[none]) {
    current = optimal_bounty().type;
    hunt_bounty(optimal_bounty());
  }
}
