import React, { useState } from "react";
import { ChevronDown, ArrowUpDown } from "lucide-react";
import Navbar from "../components/Navbar";

function SwapPage() {
    const tokens = ["USDT", "ETH", "BTC", "SONIC"];
    const [giveToken, setGiveToken] = useState("USDT");
    const [getToken, setGetToken] = useState("SONIC");
    const [giveAmount, setGiveAmount] = useState("");
    const [getAmount, setGetAmount] = useState("");
    const handleSwap = () => {
        setGiveAmount(getAmount);
        setGetAmount(giveAmount);
    };



    return (
        <div className="flex flex-col min-h-screen bg-[#000000] overflow-hidden items-center justify-center relative">
            <Navbar />
            <iframe
                src="https://sincere-polygon-333639.framer.app/404-2"
                className="absolute top-0 left-40 w-[150vw] h-[150vh] scale-[1.2] z-[0]"
                frameBorder="0"
                allowFullScreen
            />

            <h1 className="text-3xl md:text-7xl font-bold text-white mb-6 text-center drop-shadow-lg">
                Swap Anytime,
                <br/> 
                Anywhere
            </h1>

            <div className="w-full max-w-md rounded-3xl bg-white/10 backdrop-blur-2xl border border-white/20 shadow-[0_8px_32px_rgba(0,0,0,0.5)] p-6 relative z-10">

                <div className="rounded-xl bg-violet-900/20 border border-purple-600 backdrop-blur-xl p-4 mb-4">
                    <div className="flex justify-between items-center">
                        <span className="text-gray-300 text-sm">You Give</span>
                        <select
                            value={giveToken}
                            onChange={(e) => setGiveToken(e.target.value)}
                            className="bg-white/10 text-white text-sm rounded-lg px-3 py-1 focus:outline-none"
                        >
                            {tokens.map((token) => (
                                <option key={token} value={token} className="bg-black">
                                    {token}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className="flex justify-between items-end mt-2">
                        <input
                            type="number"
                            value={giveAmount}
                            onChange={(e) => setGiveAmount(e.target.value)}
                            className="bg-transparent text-3xl font-semibold text-white focus:outline-none w-2/3 placeholder:text-gray-500"
                        />
                        <p className="text-xs text-gray-400">{giveAmount} {giveToken}</p>
                    </div>
                </div>

                <div className="flex justify-center -my-6 relative">
                    <button
                        onClick={handleSwap}
                        className="bg-purple-600 relative rounded-full p-3 shadow-lg border border-purple-400 z-10"
                    >
                        <ArrowUpDown size={22} className="text-white" />
                    </button>
                </div>

                <div className="rounded-xl backdrop-blur-xl bg-violet-900/20 border border-purple-600 p-4 mt-2 mb-4">
                    <div className="flex justify-between items-center">
                        <span className="text-gray-300 text-sm">You Get</span>
                        <select
                            value={getToken}
                            onChange={(e) => setGetToken(e.target.value)}
                            className="bg-white/10 text-white text-sm rounded-lg px-3 py-1 focus:outline-none"
                        >
                            {tokens.map((token) => (
                                <option key={token} value={token} className="bg-black">
                                    {token}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className="flex justify-between items-end mt-2">
                        <input
                            type="number"
                            value={getAmount}
                            onChange={(e) => setGetAmount(e.target.value)}
                            className="bg-transparent text-3xl font-semibold text-white focus:outline-none w-2/3 placeholder:text-gray-500"
                        />
                        <p className="text-xs text-gray-400">{getAmount} {getToken}</p>
                    </div>
                </div>

                <div className="flex justify-between items-center text-xs text-gray-400 mb-4">
                    <p>1 ETH = 3200.98 USDT ($3208.38)</p>
                    <p className="bg-white/10 px-3 py-1 rounded-lg">$346.43</p>
                </div>

                <button className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-500 to-indigo-500 text-white font-semibold hover:opacity-90 transition">
                    Swap
                </button>
            </div>
        </div>
    );
}

export default SwapPage;