export interface Tournament {
  id: string;
  name: string;
  location: string;
  venueAddress: string;
  date: string;
  externalUrl: string;
  image: string;
  games: string;
}

export interface SearchParams {
  query: string;
  radius: number;
  gameIds?: number[];
}

export interface UnifiedSearchResponse {
  tournaments: Tournament[];
  center: {
    lat: number;
    lng: number;
  };
  displayName: string;
}

export interface GameOption {
  id: number;
  name: string;
  imageUrl: string;
}

export const POPULAR_GAMES: GameOption[] = [
  { 
    id: 43868, 
    name: "Street Fighter 6", 
    imageUrl: "https://www.streetfighter.com/6/assets/images/common/logo_sf6.png" 
  },
  { 
    id: 49783, 
    name: "Tekken 8", 
    imageUrl: "https://tk8.tekken.com/assets/images/common/logo.png" 
  },
  { 
    id: 33945, 
    name: "Guilty Gear -Strive-", 
    imageUrl: "https://www.guiltygear.com/ggst/en/wordpress/wp-content/themes/ggst/img/common/logo.png" 
  },
  { 
    id: 1386, 
    name: "Smash Ultimate", 
    imageUrl: "https://www.smashbros.com/assets_v2/img/top/logo.png" 
  },
  { 
    id: 1, 
    name: "Melee", 
    imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/4/4e/Super_Smash_Bros._Melee_box_art.png/220px-Super_Smash_Bros._Melee_box_art.png" 
  },
  { 
    id: 49830, 
    name: "Mortal Kombat 1", 
    imageUrl: "https://www.mortalkombat.com/static/mk1-logo.png" 
  },
  { 
    id: 48999, 
    name: "Granblue Fantasy Versus: Rising", 
    imageUrl: "https://rising.granbluefantasy.jp/assets/img/common/logo_en.png" 
  },
  { 
    id: 50926, 
    name: "Under Night In-Birth II", 
    imageUrl: "https://www.arcsystemworks.jp/uni2sys/img/common/logo.png" 
  },
  { 
    id: 287, 
    name: "Dragon Ball FighterZ", 
    imageUrl: "https://en.bandainamcoent.eu/sites/default/files/dbfz_logo.png" 
  },
  { 
    id: 10, 
    name: "Killer Instinct", 
    imageUrl: "https://www.ultra-combo.com/wp-content/themes/killer-instinct/assets/images/ki-logo.png" 
  },
  { 
    id: 12, 
    name: "Skullgirls", 
    imageUrl: "https://skullgirls.com/wp-content/themes/skullgirls/images/logo.png" 
  },
  { 
    id: 35061, 
    name: "Melty Blood: Type Lumina", 
    imageUrl: "https://meltyblood.typelumina.com/common/img/common/logo_en.png" 
  }
];