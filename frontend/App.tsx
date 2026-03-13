import React, { useEffect, useState } from 'react';
import SearchPanel from './components/SearchPanel';
import TournamentCard from './components/TournamentCard';
import Map from './components/Map';
import FAQ from './pages/FAQ';
import { useTournaments } from './hooks/useTournaments';
import logo from '@/assets/findmyfgclogo.png';

function useHash(): [string, (hash: string) => void] {
  const [hash, setHash] = useState(() => window.location.hash.slice(1));

  useEffect(() => {
    const onHashChange = () => setHash(window.location.hash.slice(1));
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  const navigate = (newHash: string) => {
    window.location.hash = newHash;
  };

  return [hash, navigate];
}

const App: React.FC = () => {
  const [page, navigate] = useHash();
  const [faqScrollTarget, setFaqScrollTarget] = useState<string | undefined>(undefined);

  const goToFAQ = (section?: string) => {
    setFaqScrollTarget(section);
    navigate('faq');
  };

  useEffect(() => {
    if (page !== 'faq') setFaqScrollTarget(undefined);
  }, [page]);

  const {
    query, setQuery,
    radius, setRadius,
    selectedGameIds, toggleGameId,
    loading, tournaments,
    center, locationName,
    error, handleSearch
  } = useTournaments();

  const header = (
    <header className="bg-slate-900 border-b border-slate-800 p-4 shrink-0 flex items-center justify-between z-40 sticky top-0 md:relative">
      <div className="flex items-center gap-3">
        <img src={logo} alt="FindMyFGC" className="p-1.5 rounded-lg" style={{ height: '3.25rem', width: '3.25rem' }} />
        <div>
          <h1 className="text-lg md:text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-indigo-400 to-purple-400 tracking-tight">
            FindMyFGC
          </h1>
          <div className="text-[10px] text-slate-500 font-mono flex items-center gap-1 uppercase">
            This site does not collect your data.
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <a
          href="https://x.com/enpicie"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 hover:text-white text-xs font-medium transition-colors"
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.737-8.835L1.254 2.25H8.08l4.253 5.622 5.911-5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
          </svg>
        </a>
        <a
          href="https://ko-fi.com/enpicie"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#FF5E5B]/10 hover:bg-[#FF5E5B]/20 border border-[#FF5E5B]/30 text-[#FF5E5B] hover:text-[#ff7a78] text-xs font-medium transition-colors"
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M23.881 8.948c-.773-4.085-4.859-4.593-4.859-4.593H.723c-.604 0-.679.798-.679.798s-.082 7.324-.022 11.822c.164 4.641 3.568 4.535 3.568 4.535s14.678.102 15.522 0c.513-.058 4.948-.12 5.244-4.815.234-3.641.009-6.959-.475-7.747zm-9.392 5.65c-.628.578-1.395.868-2.302.868H9.14v2.127H6.947V8.507h3.14c.907 0 1.674.29 2.302.868.628.578.942 1.289.942 2.134 0 .844-.314 1.555-.942 2.089zm6.418.686c-.628.578-1.395.868-2.302.868h-3.14v2.127h-2.193V8.507h3.14c.907 0 1.674.29 2.302.868.628.578.942 1.289.942 2.134 0 .844-.314 1.555-.942 2.089zm-9.574-3.044H9.14v2.127h1.193c.296 0 .536-.093.72-.278.184-.185.276-.43.276-.735 0-.306-.092-.551-.276-.736-.184-.185-.424-.278-.72-.278zm6.418 0h-1.193v2.127h1.193c.296 0 .536-.093.72-.278.184-.185.276-.43.276-.735 0-.306-.092-.551-.276-.736-.184-.185-.424-.278-.72-.278z" />
          </svg>
          Support
        </a>
      </div>
    </header>
  );

  if (page === 'faq') {
    return (
      <div className="flex flex-col min-h-screen bg-slate-950 font-sans">
        {header}
        <FAQ onBack={() => navigate('')} scrollTo={faqScrollTarget} />
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen md:h-screen md:overflow-hidden bg-slate-950 font-sans">
      {header}

      <main className="flex flex-col md:flex-row flex-grow min-h-0 relative">
        <aside className="w-full md:w-96 flex flex-col border-r border-slate-800 bg-slate-900 md:overflow-y-auto p-4 md:p-6 gap-6 shrink-0 z-20 shadow-2xl order-2 md:order-1">
          <SearchPanel
            location={query}
            setLocation={setQuery}
            radius={radius}
            setRadius={setRadius}
            selectedGameIds={selectedGameIds}
            toggleGameId={toggleGameId}
            onSearch={handleSearch}
            loading={loading}
          />

          {error && (
            <div className="bg-red-900/20 border border-red-500/50 p-3 rounded-lg text-red-400 text-xs">
              {error}
            </div>
          )}

          <section className="flex flex-col gap-4 pb-24 md:pb-4">
            <div id="results-heading" className="flex justify-between items-center scroll-mt-20">
              <h2 className="text-lg font-bold text-slate-300">Events ({tournaments.length})</h2>
            </div>

            {tournaments.length === 0 && !loading && (
              <div className="bg-slate-800/50 border border-dashed border-slate-700 rounded-lg p-8 text-center flex flex-col items-center gap-3">
                <div className="text-3xl opacity-30">📍</div>
                <p className="text-slate-400 text-sm">Search for a location.</p>
                {query && (
                  <button
                    onClick={() => goToFAQ('there-are-events-around-me-but-not-for-the-game-that-i-play')}
                    className="text-[11px] text-slate-600 hover:text-slate-400 transition-colors"
                  >
                    Not finding events for your game? →
                  </button>
                )}
              </div>
            )}

            {loading && (
              <div className="space-y-4 animate-pulse">
                {[1, 2, 3].map(i => <div key={i} className="bg-slate-800 h-32 rounded-lg border border-slate-700" />)}
              </div>
            )}

            <div className="space-y-4">
              {tournaments.map((t) => <TournamentCard key={t.id} tournament={t} />)}
            </div>
          </section>
        </aside>

        <section className="h-[300px] md:h-full w-full md:flex-grow relative z-10 order-1 md:order-2 border-b md:border-b-0 border-slate-800 shrink-0 md:p-4">
          <div className="absolute top-3 left-3 z-[1000] bg-slate-900/90 border border-slate-700 px-3 py-1.5 rounded-full shadow-lg text-[10px] md:text-xs font-bold text-indigo-300 flex items-center gap-2 pointer-events-none">
            <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-pulse"></span>
            {locationName}
          </div>
          <Map center={center} zoom={11} tournaments={tournaments} />
        </section>
      </main>
    </div>
  );
};

export default App;
