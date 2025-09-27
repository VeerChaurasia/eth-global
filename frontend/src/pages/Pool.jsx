import { useState } from "react";
import { Search } from "lucide-react";
import Navbar from "../components/Navbar";
import { Link } from "react-router-dom";

function PoolPage() {
  const [search, setSearch] = useState("");

  const stats = [
    { label: "1D volume", value: "$6.96B", change: "+45.88% today" },
    { label: "Total Uniswap TVL", value: "$4.29B", change: "+3.42% today" },
    { label: "v2 TVL", value: "$1.86B", change: "+3.88% today" },
    { label: "v3 TVL", value: "$1.75B", change: "+2.86% today" },
    { label: "v4 TVL", value: "$678.68M", change: "+3.66% today" },
  ];

  const pools = [
    { pool: "ETH/USDT", protocol: "v3", fee: "0.3%", tvl: "$144.1M", apr: "69.52%", reward: "-", vol1d: "$91.5M", vol30d: "$1.6B", ratio: "0.63" },
    { pool: "WBTC/USDC", protocol: "v3", fee: "0.3%", tvl: "$130.8M", apr: "33.88%", reward: "-", vol1d: "$40.5M", vol30d: "$814.5M", ratio: "0.31" },
    { pool: "WBTC/ETH", protocol: "v3", fee: "0.3%", tvl: "$97.3M", apr: "7.23%", reward: "-", vol1d: "$6.4M", vol30d: "$351.4M", ratio: "0.07" },
    { pool: "ETH/USDC", protocol: "v4", fee: "0.05%", tvl: "$91.1M", apr: "20.67%", reward: "+7.23%", vol1d: "$103.2M", vol30d: "$3.0B", ratio: "1.13" },
    { pool: "ETH/USDC", protocol: "v3", fee: "0.05%", tvl: "$86.1M", apr: "62%", reward: "-", vol1d: "$292.6M", vol30d: "$6.2B", ratio: "3.40" },
  ];
  const filteredPools = pools.filter((p) =>
    p.pool.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="relative min-h-screen flex flex-col bg-black text-white">

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

        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8 w-full max-w-6xl">
          {stats.map((s, i) => (
            <div key={i} className="bg-purple-900/30 border border-purple-400 rounded-2xl p-4 shadow">
              <p className="text-sm text-zinc-400">{s.label}</p>
              <p className="text-xl font-bold">{s.value}</p>
              <p className="text-green-400 text-sm">{s.change}</p>
            </div>
          ))}
        </div>

        <div className="flex items-center justify-between mb-6 w-full max-w-6xl">
          <div className="relative w-1/3">
            <Search className="absolute left-3 top-2.5 h-5 w-5 text-zinc-400" />
            <input
              type="text"
              placeholder="Search tokens and pools"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 rounded-xl bg-zinc-900 text-white placeholder-zinc-500 focus:outline-none"
            />
          </div>
          <div className="flex gap-3">
            <button className="bg-purple-600 px-4 py-2 rounded-xl font-medium">
              Add liquidity
            </button>
            <button className="bg-zinc-800 px-4 py-2 rounded-xl">
              Protocol
            </button>
          </div>
        </div>

        <div className="overflow-x-auto w-full max-w-6xl">
          <table className="w-full text-left border-separate border-spacing-y-2">
            <thead>
              <tr className="text-zinc-400 text-sm">
                <th className="px-4 py-2">Pool</th>
                <th>Protocol</th>
                <th>Fee tier</th>
                <th>TVL</th>
                <th>Pool APR</th>
                <th>Reward APR</th>
                <th>1D vol</th>
                <th>30D vol</th>
                <th>1D vol/TVL</th>
              </tr>
            </thead>
            <tbody>
              {filteredPools.map((p, i) => (
                <tr key={i} className="bg-purple-800/20 rounded-xl">
                  <td className="px-4 py-5 font-medium">
                    <Link
                      to="/manager"
                      className="text-white-400 hover:underline"
                    >
                      {p.pool}
                    </Link>
                  </td>
                  <td>{p.protocol}</td>
                  <td>{p.fee}</td>
                  <td>{p.tvl}</td>
                  <td>{p.apr}</td>
                  <td className={p.reward.includes("+") ? "text-pink-400" : ""}>
                    {p.reward}
                  </td>
                  <td>{p.vol1d}</td>
                  <td>{p.vol30d}</td>
                  <td>{p.ratio}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default PoolPage;
