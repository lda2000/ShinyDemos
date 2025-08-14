# Spray Map App (Shiny + Leaflet)

This Shiny application allows you to **draw points on an interactive Leaflet map** using a *spray effect*.  
Points are added **randomly distributed inside a circle** centered at the cursor position while holding **Shift + Left Click**.

- **Author for the geodetical features**: [Luca Dell'Anna](https://www.linkedin.com/in/lucadellanna/)
- **Inspired by the LinkedIn post by**: [Joachim Schork](https://www.linkedin.com/in/joachim-schork)

---

## 📸 Preview
![Spray Map App Screenshot](screenshot.png)

---

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

---

## 📦 Requirements
- R (≥ 4.0.0)
- Packages:
  ```r
  install.packages(c("shiny", "leaflet", "htmlwidgets"))
  ```

---

## 👨‍💻 **Authors & Credits**
- **Author**: [Luca Dell'Anna](https://www.linkedin.com/in/lucadellanna/) — Main developer of this Shiny application.
- **First Author of Original Spray Logic**: [Joachim Schork](https://www.linkedin.com/in/joachim-schork) — Inspiration for the spray drawing method.

---

**License**: MIT (feel free to use and modify with attribution)
