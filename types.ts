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
  emoji: string;
}

export const POPULAR_GAMES: GameOption[] = [
  { id: 43868, name: "Street Fighter 6", emoji: "👊" },
  { id: 49783, name: "Tekken 8", emoji: "🤜" },
  { id: 33945, name: "Guilty Gear -Strive-", emoji: "🎸" },
  { id: 1386, name: "Smash Ultimate", emoji: "⭐" },
  { id: 1, name: "Melee", emoji: "🦊" },
  { id: 49830, name: "Mortal Kombat 1", emoji: "🐉" },
  { id: 48999, name: "Granblue Fantasy Versus: Rising", emoji: "⚔️" },
  { id: 50926, name: "Under Night In-Birth II", emoji: "🌙" },
  { id: 287, name: "Dragon Ball FighterZ", emoji: "☄️" },
];
