import React from "react";
import { Outlet, Link } from "react-router-dom";

const Layout = () => {
  return (
    <div>
      <main style={{}}>
        <Outlet />
      </main>
    </div>
  );
};

export default Layout;
