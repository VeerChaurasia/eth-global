import { BrowserRouter, Routes, Route } from "react-router-dom";
import Pool from "./pages/Pool.jsx";
import Manager from "./pages/Manager.jsx";
import Help from "./pages/Help.jsx";
import App from "./App.jsx";
import Swap from "./pages/Swap.jsx";
import Layout from "./Layout.jsx";

import ReactDOM from "react-dom/client";
import React from "react";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<App />} />
          <Route path="/pools" element={<Pool />} />
          <Route path="/swap" element={<Swap />} />
          <Route path="/manager" element={<Manager />} />
          <Route path="/help" element={<Help />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);
