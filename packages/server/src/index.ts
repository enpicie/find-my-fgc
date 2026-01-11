import express from 'express';
import axios from 'axios';
import cors from 'cors';
import dotenv from 'dotenv';
import { StartGGTournament, CleanTournament } from './types';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const STARTGG_URL = 'https://api.start.gg/gql/alpha';

app.post('/api/search', async (req, res) => {
    const { lat, lng, radius } = req.body;

    const query = `
    query TournamentsByLocation($coordinates: String!, $radius: String!) {
      tournaments(query: {
        filter: {
          location: { distanceFrom: $coordinates, distance: $radius },
          upcoming: true
        }
      }) {
        nodes {
          id name city startAt url
          images { url urlType }
        }
      }
    }
  `;

    try {
        const response = await axios.post(
            STARTGG_URL,
            {
                query,
                variables: { coordinates: `${lat},${lng}`, radius: `${radius}mi` }
            },
            { headers: { Authorization: `Bearer ${process.env.STARTGG_API_KEY}` } }
        );

        const nodes: StartGGTournament[] = response.data.data.tournaments.nodes;

        // Data Cleaning/Simplification
        const cleaned: CleanTournament[] = nodes.map(t => ({
            id: t.id,
            name: t.name,
            location: t.city || 'Online',
            date: new Date(t.startAt * 1000).toLocaleDateString(),
            externalUrl: `https://start.gg${t.url}`,
            image: t.images.find(i => i.urlType === 'profile')?.url || ''
        }));

        res.json(cleaned);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Start.gg API failure' });
    }
});

app.listen(5000, () => console.log('Backend running on port 5000'));
