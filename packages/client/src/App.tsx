import React, { useState, useRef } from 'react';
import { GoogleMap, useJsApiLoader, Marker, Autocomplete } from '@react-google-maps/api';
import axios from 'axios';

interface Tournament {
  id: string;
  name: string;
  location: string;
  date: string;
  externalUrl: string;
  image: string;
}

const libraries: ("places")[] = ["places"];

export default function App() {
  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string,
    libraries,
  });

  const [coords, setCoords] = useState({ lat: 34.0522, lng: -118.2437 });
  const [radius, setRadius] = useState(50);
  const [results, setResults] = useState<Tournament[]>([]);
  const [loading, setLoading] = useState(false);
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null);

  const onSearch = async () => {
    setLoading(true);
    try {
      const { data } = await axios.post('http://localhost:5000/api/search', {
        ...coords,
        radius
      });
      setResults(data);
    } catch (err) {
      alert("Error fetching tournaments");
    } finally {
      setLoading(false);
    }
  };

  if (!isLoaded) return <div>Loading...</div>;

  return (
    <div style={{ padding: '20px', maxWidth: '1000px', margin: 'auto', fontFamily: 'sans-serif' }}>
      <h1>FindMyFGC</h1>

      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', alignItems: 'flex-end' }}>
        <div style={{ flex: 1 }}>
          <label>Location:</label>
          <Autocomplete
            onLoad={ref => (autocompleteRef.current = ref)}
            onPlaceChanged={() => {
              const place = autocompleteRef.current?.getPlace();
              if (place?.geometry?.location) {
                setCoords({ lat: place.geometry.location.lat(), lng: place.geometry.location.lng() });
              }
            }}
          >
            <input type="text" style={{ width: '100%', padding: '8px' }} placeholder="Zip, City, or Venue" />
          </Autocomplete>
        </div>

        <div>
          <label>Radius: {radius}mi</label><br/>
          <input type="range" min="5" max="500" value={radius} onChange={e => setRadius(Number(e.target.value))} />
        </div>

        <button onClick={onSearch} disabled={loading} style={{ padding: '8px 20px' }}>
          {loading ? '...' : 'Search'}
        </button>
      </div>

      <GoogleMap
        mapContainerStyle={{ width: '100%', height: '400px', borderRadius: '10px' }}
        center={coords}
        zoom={10}
        onClick={(e) => e.latLng && setCoords({ lat: e.latLng.lat(), lng: e.latLng.lng() })}
      >
        <Marker position={coords} />
      </GoogleMap>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginTop: '20px' }}>
        {results.map(t => (
          <div key={t.id} style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
            {t.image && <img src={t.image} style={{ width: '50px', height: '50px', float: 'right' }} alt="profile" />}
            <h3>{t.name}</h3>
            <p>{t.location} • {t.date}</p>
            <a href={t.externalUrl} target="_blank" rel="noreferrer">Register on start.gg</a>
          </div>
        ))}
      </div>
    </div>
  );
}
