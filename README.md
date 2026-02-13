# FindMyFGC Local Setup Guide

Follow these steps to run the application on your local machine for development and debugging.

## 1. Backend Setup (Swift + Docker)
The backend acts as a proxy to keep your API keys secure.

1.  Navigate to the `backend` folder: `cd backend`
2.  Build the Docker image:
    ```bash
    docker build -t fgc-backend .
    ```
3.  Run the container (Replace `YOUR_TOKEN` with your start.gg API key):
    ```bash
    docker run -p 8080:8080 -e STARTGG_API_KEY=YOUR_TOKEN fgc-backend
    ```
    The backend is now running at `http://localhost:8080`.

## 2. Frontend Setup (React + Vite)
The frontend handles the UI and uses Gemini for geocoding.

1.  In the project root, install dependencies:
    ```bash
    npm install
    ```
2.  Run the dev server with your Gemini API Key:
    ```bash
    # For Unix-like systems (macOS/Linux):
    VITE_API_KEY=your_gemini_key npm run dev

    # For Windows (Command Prompt):
    set VITE_API_KEY=your_gemini_key && npm run dev
    ```
3.  Open your browser to the URL displayed (usually `http://localhost:5173`).

## 🛠 Project Structure
- `/backend`: Swift Vapor application (Logic + Proxy).
- `/services`: Frontend API wrappers.
- `/components`: Reusable React UI elements.
- `App.tsx`: Main application state and layout.