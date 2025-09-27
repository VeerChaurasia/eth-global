import './App.css'
import { useNavigate } from 'react-router-dom'
import Navbar from './components/Navbar'

function App() {
  const navigate = useNavigate();

  return (
    <div className="relative min-h-screen flex flex-col bg-black text-white">

      <iframe
        src="https://sincere-polygon-333639.framer.app/404-2"
        className="absolute top-0 left-40 w-[150vw] h-[150vh] scale-[1.2] z-[0]"
        frameBorder="0"
        allowFullScreen
      />

      <div className="absolute inset-0 z-0" />

      <div className="relative z-10 flex flex-col items-center px-6 pt-40 pb-10">
        <Navbar />
        <div className="h-20" />

        <h1 className="text-6xl font-bold mb-8">
          SWAP
        </h1>

        <p className="text-zinc-300 mb-10 max-w-2xl text-center">
          Experience seamless token trading with lightning-fast execution, secure transactions, and an intuitive interface.
        </p>

        <button
          onClick={() => navigate('/swap')}
          className="px-6 py-3 rounded-xl bg-gradient-to-r from-purple-500 to-indigo-500 text-white font-semibold hover:opacity-90 transition"
        >
          Enter App
        </button>
      </div>
    </div>
  );
}

export default App
