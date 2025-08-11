# Spray Map App (Shiny + Leaflet)

This Shiny application allows you to **draw points on an interactive Leaflet map** using a *spray effect*.  
Points are added **randomly distributed inside a circle** centered at the cursor position while holding **Shift + Left Click**.

## ✨ Features
- **Spray effect**: Distribute multiple points randomly within a configurable radius.
- **Shift + Left Click drawing**: Hold Shift to draw; release to return to normal pan/zoom.
- **Configurable parameters**:
  - Spray radius (meters)
  - Spray intensity (points per step)
- **Live counters**:
  - Total points
  - Per-class points
- **Multiple classes**: Points can belong to one of 4 classes (`A`, `B`, `C`, `D`), each with a distinct color.
- **Export**: Download all generated points as a CSV file (`point_id, class_id, lon, lat, class`).
- **Clear**: Reset all points on the map.

## 🖥 Usage
1. Launch the app in RStudio:
   ```r
   library(shiny)
   runApp("path/to/SprayMapApp")
