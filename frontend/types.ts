export interface Tournament {
  id: string;
  name: string;
  location: string;
  venueAddress: string;
  lat: number | null;
  lng: number | null;
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
