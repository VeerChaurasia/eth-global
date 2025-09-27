import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";

const Navbar = () => {


  const openHelp = () => {
    alert("Help box not implemented yet!");
  };

  // Wallet connect function
  const [walletAddress, setWalletAddress] = useState("");

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        setWalletAddress(accounts[0]);
      } catch (error) {
        alert("Wallet connection failed!");
      }
    } else {
      alert("MetaMask not detected. Please install MetaMask.");
    }
  };

  return (
    <div className="flex justify-between items-center px-2 md:px-16 py-4 absolute top-0 left-0 w-full z-20 bg-white/10 backdrop-blur-2xl border-b border-white/20">

      <div className="flex items-center gap-2">
        <p className="text-white font-bold text-lg">LOGO</p>
      </div>

      <div className="hidden md:flex gap-8 text-white text-sm md:text-base">
      <Link to="/swap" className="hover:text-purple-300 transition">
          Swap
        </Link>
      <Link to="/pools" className="hover:text-purple-300 transition">
          Pool
        </Link>
        <Link to="/manager" className="hover:text-purple-300 transition">
          Manager
        </Link>
        <button
          onClick={openHelp}
          className="hover:text-purple-300 transition focus:outline-none"
        >
          Help
        </button>
      </div>

      <div className="flex items-center gap-4">
        <button
          onClick={connectWallet}
          className="bg-gradient-to-r from-purple-500 to-indigo-600 text-white px-4 py-2 rounded-md font-medium hover:bg-gray-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {walletAddress ? `${walletAddress.slice(0, 6)}...${walletAddress.slice(-4)}` : "Connect Wallet"}
        </button>
      </div>
    </div>
  );
};

export default Navbar;
