import React, { useState } from "react";
import Navbar from "../components/Navbar";
import { Line, Bar } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Tooltip, Legend, Filler);

const Manager = () => {
  const [poolId, setPoolId] = useState("");
  const [swapFee, setSwapFee] = useState("");
  const [rentPerBlock, setRentPerBlock] = useState("");
  const [graphOption, setGraphOption] = useState("supply");
  const [rightBoxOption, setRightBoxOption] = useState("swap");

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
  
  const graphData = {
    supply: {
      labels: ["June 29, 2025", "July", "Aug", "Sep 27, 2025"],
      datasets: [
        {
          label: "Total Supplied",
          data: [62, 64, 61, 60],
          borderColor: "rgba(34,197,94,1)", 
          backgroundColor: "rgba(34,197,94,0.4)",
          fill: true,
          tension: 0.3,
        },
        {
          label: "Liquidity",
          data: [6, 6.2, 5.9, 5.97],
          borderColor: "rgba(59,130,246,1)",
          backgroundColor: "rgba(59,130,246,0.3)",
          fill: true,
          tension: 0.3,
        },
      ],
    },
    borrow: {
      labels: ["June 29, 2025", "July", "Aug", "Sep 27, 2025"],
      datasets: [
        {
          label: "Total Borrowed",
          data: [40, 45, 42, 50],
          borderColor: "rgba(245,158,11,1)", 
          backgroundColor: "rgba(245,158,11,0.3)",
          fill: true,
          tension: 0.3,
        },
        {
          label: "Liquidity",
          data: [6, 6.3, 5.8, 6.1],
          borderColor: "rgba(59,130,246,1)", 
          backgroundColor: "rgba(59,130,246,0.3)",
          fill: true,
          tension: 0.3,
        },
      ],
    },
    withdraw: {
      labels: ["June 29, 2025", "July", "Aug", "Sep 27, 2025"],
      datasets: [
        {
          label: "Total Withdrawn",
          data: [10, 15, 12, 18],
          borderColor: "rgba(220,38,38,1)",
          backgroundColor: "rgba(220,38,38,0.3)",
          fill: true,
          tension: 0.3,
        },
        {
          label: "Liquidity",
          data: [6, 6.1, 6.0, 6.05],
          borderColor: "rgba(59,130,246,1)", 
          backgroundColor: "rgba(59,130,246,0.3)",
          fill: true,
          tension: 0.3,
        },
      ],
    },
    repay: {
      labels: ["June 29, 2025", "July", "Aug", "Sep 27, 2025"],
      datasets: [
        {
          label: "Total Repaid",
          data: [20, 25, 22, 30],
          borderColor: "rgba(139,92,246,1)", 
          backgroundColor: "rgba(139,92,246,0.3)",
          fill: true,
          tension: 0.3,
        },
        {
          label: "Liquidity",
          data: [6, 6.15, 5.95, 6.02],
          borderColor: "rgba(59,130,246,1)",
          backgroundColor: "rgba(59,130,246,0.3)",
          fill: true,
          tension: 0.3,
        },
      ],
    },
    manager: {
      labels: ["Epoch1", "Epoch2", "Epoch3", "Epoch4"],
      datasets: [
        {
          label: "Manager Bids",
          data: [5, 6, 3, 10],
          backgroundColor: [
            "rgba(236,72,153,0.8)",
            "rgba(168,85,247,0.8)", 
            "rgba(59,130,246,0.8)",
            "rgba(34,197,94,0.8)"
          ],
          borderColor: [
            "rgba(236,72,153,1)",
            "rgba(168,85,247,1)",
            "rgba(59,130,246,1)", 
            "rgba(34,197,94,1)"
          ],
          borderWidth: 2,
          borderRadius: 4,
          borderSkipped: false,
        },
      ],
    },
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: "top",
        labels: { color: "white" },
      },
      tooltip: { mode: "index", intersect: false },
    },
    scales: {
      x: { ticks: { color: "white" }, grid: { color: "rgba(255,255,255,0.1)" } },
      y: { ticks: { color: "white" }, grid: { color: "rgba(255,255,255,0.1)" } },
    },
  };

  const histogramOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: "top",
        labels: { color: "white" },
      },
      tooltip: { 
        mode: "index", 
        intersect: false,
        callbacks: {
          title: function(tooltipItems) {
            return tooltipItems[0].label;
          },
          label: function(context) {
            return `${context.dataset.label}: ${context.parsed.y} bids`;
          }
        }
      },
    },
    scales: {
      x: { 
        ticks: { color: "white" }, 
        grid: { color: "rgba(255,255,255,0.1)" },
        title: {
          display: true,
          text: 'Epochs',
          color: 'white'
        }
      },
      y: { 
        ticks: { color: "white" }, 
        grid: { color: "rgba(255,255,255,0.1)" },
        title: {
          display: true,
          text: 'Number of Bids',
          color: 'white'
        },
        beginAtZero: true
      },
    },
  };

  const SwapBox = () => (
    <div className="w-full max-w-3xl rounded-3xl bg-violet-900/20 border border-purple-600  backdrop-blur-2xl shadow-[0_8px_32px_rgba(0,0,0,0.5)] pt-10 pb-28 pl-10 pr-10 relative z-10">
      <h2 className="text-4xl font-bold mb-8 text-white">Swap</h2>

      <div className="rounded-xl bg-violet-900/20 border border-purple-600 backdrop-blur-xl p-4 mb-8">
        <div className="flex justify-between items-center">
          <span className="text-gray-300 text-sm">Sell</span>
        </div>
        <div className="flex justify-between items-end mt-2">
          <input
            type="number"
            className="bg-transparent text-3xl font-semibold text-white focus:outline-none w-2/3 placeholder:text-gray-500"
            placeholder="0"
          />
          <p className="text-xs text-gray-400">Token</p>
        </div>
      </div>

      <div className="rounded-xl bg-violet-900/20 border border-purple-600 backdrop-blur-xl p-4 mb-8">
        <div className="flex justify-between items-center">
          <span className="text-gray-300 text-sm">Buy</span>
        </div>
        <div className="flex justify-between items-end mt-2">
          <input
            type="number"
            className="bg-transparent text-3xl font-semibold text-white focus:outline-none w-2/3 placeholder:text-gray-500"
            placeholder="0"
          />
          <p className="text-xs text-gray-400">Token</p>
        </div>
      </div>
  
      <button className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-500 to-indigo-500 text-white font-semibold hover:opacity-90 transition">
        Enter an amount
      </button>
    </div>
  );
  

  const SellBox = () => (
    <div className="bg-zinc-900/70 border border-purple-400 rounded-xl pt-8 pb-44 pl-8 pr-8 w-full flex flex-col gap-6">
      <h2 className="text-3xl mb-8 font-bold">Sell</h2>
      <div className="flex flex-col items-center gap-4">
        <div className="text-4xl mb-8">$0</div>
        <div className="flex mb-8 gap-3">
          {["25%", "50%", "75%", "Max"].map((pct) => (
            <button key={pct} className="bg-zinc-800 px-4 py-2 rounded-md hover:bg-zinc-700">
              {pct}
            </button>
          ))}
        </div>
        <input className="bg-zinc-800 px-3 py-2 border border-purple-400 rounded-md w-full" placeholder="Enter an amount" />
      </div>
    </div>
  );

  const ManagerForm = () => (
    <form
      onSubmit={handleSubmit}
      className="bg-purple-900/30 border border-purple-400 rounded-xl p-12 shadow w-full flex flex-col gap-6"
    >
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
  );

  const renderRightBox = () => {
    if (rightBoxOption === "swap") return <SwapBox />;
    if (rightBoxOption === "sell") return <SellBox />;
    if (rightBoxOption === "manager") return <ManagerForm />;
    return null;
  };

  const handleGraphClick = (option) => {
    setGraphOption(option);
    if (option === "supply" || option === "borrow") setRightBoxOption("swap");
    if (option === "withdraw" || option === "repay") setRightBoxOption("sell");
    if (option === "manager") setRightBoxOption("manager");
  };

  const renderChart = () => {
    if (graphOption === "manager") {
      return <Bar data={graphData[graphOption]} options={histogramOptions} />;
    }
    return <Line data={graphData[graphOption]} options={options} />;
  };

  return (
    <div className="relative min-h-screen flex flex-col bg-black text-white">
      
      <div className="absolute inset-0 z-0" />
      <iframe
        src="https://sincere-polygon-333639.framer.app/404-2"
        className="absolute top-0 left-40 w-[150vw] h-[150vh] scale-[1.2] z-[0]"
        frameBorder="0"
        allowFullScreen
      />
      <Navbar />
      <div className="relative z-10 px-8 pt-36 pb-10">
        <h1 className="text-6xl font-bold mb-8 text-center">Manager Contest</h1>
        <p className="text-zinc-300 mb-10 max-w-2xl text-center mx-auto">
          Submit your details to contest for becoming the pool manager.
        </p>

        <div className="flex flex-col lg:flex-row gap-8 justify-center items-start">
          <div className="bg-zinc-900/50 border border-purple-400 rounded-xl p-6 shadow w-full lg:w-1/2 flex flex-col">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold">
                $
              </div>
              <div>
                <h2 className="text-xl font-bold">USD Coin</h2>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-zinc-400">USDC</span>
                  <span className="bg-blue-100 text-blue-700 px-2 py-0.5 rounded-md text-xs font-medium">Base</span>
                  <span className="bg-green-100 text-green-700 px-2 py-0.5 rounded-md text-xs font-medium">Core</span>
                </div>
              </div>
            </div>
            {renderChart()}
            <div className="flex gap-4 mt-6 justify-center">
              {["supply", "borrow", "withdraw", "repay", "manager"].map((option) => (
                <button
                  key={option}
                  onClick={() => handleGraphClick(option)}
                  className={`px-4 py-2 rounded ${graphOption === option ? "bg-purple-600" : "bg-zinc-700 hover:bg-zinc-600"
                    }`}
                >
                  {option.charAt(0).toUpperCase() + option.slice(1)}
                </button>
              ))}
            </div>
          </div>

          <div className="w-full lg:w-1/2">{renderRightBox()}</div>
        </div>
      </div>
    </div>
  );
};

export default Manager;