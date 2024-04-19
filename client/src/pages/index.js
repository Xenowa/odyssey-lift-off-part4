import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
/** importing our pages */
import Tracks from './tracks';
import Track from './track';
import Module from './module';
import BallerinaIndex from './BallerinaIndex';

export default function Pages() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<BallerinaIndex />} />
        {/* <Route element={<Tracks />} path="/" /> */}
        {/* <Route element={<Track />} path="/track/:trackId" /> */}
        {/* <Route element={<Module />} path="/track/:trackId/module/:moduleId" /> */}
      </Routes>
    </BrowserRouter>
  );
}
