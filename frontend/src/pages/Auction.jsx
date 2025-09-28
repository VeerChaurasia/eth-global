import { useState } from "react";
import { Search } from "lucide-react";
import Navbar from "../components/Navbar";
import { Link } from "react-router-dom";

function Auction() {
  const [search, setSearch] = useState("");


  // Example participants in auction
  const managers = [
    {
      address: "0x12aB...34Ef",
      pool: "ETH/USDT",
      swapFee: "0.3%",
      rent: "$500/mo",
      status: "Pending",
    },
    {
      address: "0x98fC...77Aa",
      pool: "WBTC/USDC",
      swapFee: "0.05%",
      rent: "$650/mo",
      status: "Approved",
    },
    {
      address: "0x45dE...19Bc",
      pool: "ETH/USDC",
      swapFee: "0.15%",
      rent: "$450/mo",
      status: "Pending",
    },
    {
      address: "0x88aF...92Cd",
      pool: "WBTC/ETH",
      swapFee: "0.25%",
      rent: "$700/mo",
      status: "Rejected",
    },
  ];

  const filteredManagers = managers.filter(
    (m) =>
      m.address.toLowerCase().includes(search.toLowerCase()) ||
      m.pool.toLowerCase().includes(search.toLowerCase())
  );


  return (
    <div className="relative min-h-screen flex flex-col bg-black text-white">
      {/* Background iframe (optional aesthetic) */}
      <iframe
        src="https://sincere-polygon-333639.framer.app/404-2"
        className="absolute top-0 left-40 w-[150vw] h-[150vh] scale-[1.2] z-[0]"
        frameBorder="0"
        allowFullScreen
      />
      <div className="absolute inset-0 z-0" />

      <div className="relative z-10 flex flex-col items-center px-6 pt-20 pb-10">
        <Navbar />
        <div className="h-20" />

        {/* Search bar */}
        <div className="flex items-center justify-between mb-6 w-full max-w-6xl">
          <div className="relative w-1/3">
            <Search className="absolute left-3 top-2.5 h-5 w-5 text-zinc-400" />
            <input
              type="text"
              placeholder="Search addresses or pools"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 rounded-xl bg-zinc-900 text-white placeholder-zinc-500 focus:outline-none"
            />
          </div>
          <Link to="/manager">
        <button className="bg-purple-600 px-4 py-2 rounded-xl font-medium">
          Join Auction
        </button>
      </Link>
        </div>

        {/* Auction participants table */}
        <div className="overflow-x-auto w-full max-w-6xl">
          <table className="w-full text-left border-separate border-spacing-y-2">
            <thead>
              <tr className="text-zinc-400 text-sm">
                <th className="px-4 py-2">Address</th>
                <th>Pool</th>
                <th>Swap Fee</th>
                <th>Rent</th>
                <th>Status</th>
                <th className="text-center">Action</th>
              </tr>
            </thead>
            <tbody>
              {filteredManagers.map((m, i) => (
                <tr key={i} className="bg-purple-800/20 rounded-xl">
                  <td className="px-4 py-5 font-medium">
                    <Link to={`/manager/${m.address}`} className="hover:underline">
                      {m.address}
                    </Link>
                  </td>
                  <td>{m.pool}</td>
                  <td>{m.swapFee}</td>
                  <td>{m.rent}</td>
                  <td
                    className={
                      m.status === "Approved"
                        ? "text-green-400"
                        : m.status === "Rejected"
                        ? "text-red-400"
                        : "text-yellow-400"
                    }
                  >
                    {m.status}
                  </td>
                  
                  
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default Auction;
