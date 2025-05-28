#!/bin/bash

echo "🎵 Starting Synther Local Server"
echo "==============================="
echo ""
echo "Your app will be available at:"
echo "  http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd build/web
python3 -m http.server 8000 || python -m SimpleHTTPServer 8000