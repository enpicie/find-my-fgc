export interface StartGGTournament {
    id: string;
    name: string;
    city: string;
    startAt: number;
    url: string;
    images: { url: string; urlType: string }[];
}

// Cleaned version sent to Frontend
export interface CleanTournament {
    id: string;
    name: string;
    location: string;
    date: string;
    externalUrl: string;
    image: string;
}
