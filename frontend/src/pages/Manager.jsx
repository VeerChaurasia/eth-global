import React, { useState } from "react";
import Navbar from "../components/Navbar";

const Manager = () => {
  const [poolId, setPoolId] = useState("");
  const [swapFee, setSwapFee] = useState("");
  const [rentPerBlock, setRentPerBlock] = useState("");
  const deposit = rentPerBlock ? (parseFloat(rentPerBlock) * 7200).toFixed(4) : "0";

  const handleSubmit = (e) => {
    e.preventDefault();
    alert(`
      Pool ID: ${poolId}
      Swap Fee: ${swapFee}
      Rent Per Block: ${rentPerBlock}
      Deposit: ${deposit}
    `);
  };

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

        <h1 className="text-6xl font-bold mb-8">Manager Contest</h1>
        <p className="text-zinc-300 mb-10 max-w-2xl text-center">
          Submit your details to contest for becoming the pool manager.
        </p>

        <form
          onSubmit={handleSubmit}
          className="bg-purple-900/30 border border-purple-400 rounded-xl p-8 shadow w-full max-w-2xl flex flex-col gap-6"
        >
          {/* Pool ID */}
          <div className="flex flex-col">
            <label className="text-sm mb-2">Pool ID</label>
            <input
              type="text"
              value={poolId}
              onChange={(e) => setPoolId(e.target.value)}
              className="px-4 py-2 rounded-md bg-zinc-800 border border-zinc-700 focus:outline-none focus:border-purple-500"
              placeholder="Enter Pool ID"
              required
            />
          </div>

          {/* Swap Fee */}
          <div className="flex flex-col">
            <label className="text-sm mb-2">Swap Fee (%)</label>
            <input
              type="number"
              step="0.01"
              value={swapFee}
              onChange={(e) => setSwapFee(e.target.value)}
              className="px-4 py-2 rounded-md bg-zinc-800 border border-zinc-700 focus:outline-none focus:border-purple-500"
              placeholder="Enter Swap Fee"
              required
            />
          </div>

          {/* Rent Per Block */}
          <div className="flex flex-col">
            <label className="text-sm mb-2">Rent Per Block</label>
            <input
              type="number"
              step="0.0001"
              value={rentPerBlock}
              onChange={(e) => setRentPerBlock(e.target.value)}
              className="px-4 py-2 rounded-md bg-zinc-800 border border-zinc-700 focus:outline-none focus:border-purple-500"
              placeholder="Enter Rent Per Block"
              required
            />
          </div>

          {/* Deposit (calculated) */}
          <div className="flex flex-col">
            <label className="text-sm mb-2">Deposit (Rent Per Block × 7200)</label>
            <input
              type="text"
              value={deposit}
              readOnly
              className="px-4 py-2 rounded-md bg-zinc-900 border border-zinc-700 text-zinc-400 cursor-not-allowed"
            />
          </div>

          <button
            type="submit"
            className="mt-4 bg-purple-600 px-6 py-3 rounded-lg font-medium hover:bg-purple-700"
          >
            Submit Contest
          </button>
        </form>
      </div>
    </div>
  );
};

export default Manager;
