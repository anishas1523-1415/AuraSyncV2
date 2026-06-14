import os
import json
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import List
import yt_dlp
import numpy as np

app = FastAPI(title="AuraSynq AI & Proxy Service")

# ==========================================
# 1. AI Recommendation Engine: Aura Blend
# ==========================================
class UserProfile(BaseModel):
    user_id: str
    top_genres: dict  # e.g., {"pop": 0.8, "electronic": 0.5, "chill": 0.9}

class BlendRequest(BaseModel):
    user_a: UserProfile
    user_b: UserProfile

def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    dot_product = np.dot(vec_a, vec_b)
    norm_a = np.linalg.norm(vec_a)
    norm_b = np.linalg.norm(vec_b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(dot_product / (norm_a * norm_b))

@app.post("/api/blend")
async def generate_aura_blend(request: BlendRequest):
    """
    Calculates genre cosine similarity between two users to generate a shared mood vibe.
    In a full production scenario, this queries Supabase directly.
    """
    # Create unified genre vector space
    all_genres = list(set(request.user_a.top_genres.keys()).union(set(request.user_b.top_genres.keys())))
    
    vec_a = np.array([request.user_a.top_genres.get(g, 0.0) for g in all_genres])
    vec_b = np.array([request.user_b.top_genres.get(g, 0.0) for g in all_genres])
    
    similarity_score = cosine_similarity(vec_a, vec_b)
    
    # Generate the blended vibe
    shared_genres = [g for g in all_genres if request.user_a.top_genres.get(g, 0) > 0.4 and request.user_b.top_genres.get(g, 0) > 0.4]
    
    return {
        "similarity_score": round(similarity_score, 2),
        "blend_vibe": "Energetic Sync" if similarity_score > 0.7 else "Chill Discovery",
        "shared_genres": shared_genres[:3],
        "message": "Query Supabase tracks filtering by 'shared_genres' to return playlist array."
    }

# ==========================================
# 2. Stealth Audio Proxy (yt-dlp)
# Bypasses the V1 IP-bans & Cipher issues
# ==========================================
@app.get("/api/stream/{video_id}")
async def get_audio_stream(video_id: str):
    """
    Uses yt-dlp to dynamically extract the direct HLS/Audio URL.
    Returns a RedirectResponse to the raw Google CDN, preventing our server from being IP-banned.
    """
    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        # Emulate iOS client to bypass strict web cipher algorithms
        'extractor_args': {'youtube': {'player_client': ['ios']}}
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"https://www.youtube.com/watch?v={video_id}", download=False)
            stream_url = info.get('url', None)
            
            if not stream_url:
                raise HTTPException(status_code=404, detail="Audio stream extraction failed")
                
            # Redirect the client directly to the media server. 
            # This offloads bandwidth and prevents our FastAPI server from getting rate-limited.
            return RedirectResponse(url=stream_url)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stealth extraction failed: {str(e)}")

# ==========================================
# 3. Synchronized Lyrics Engine (lrclib)
# ==========================================
@app.get("/api/lyrics")
async def get_synced_lyrics(track_name: str, artist_name: str):
    """
    Fetches timestamped LRC lyrics from the free open-source lrclib API.
    """
    url = "https://lrclib.net/api/get"
    params = {
        "track_name": track_name,
        "artist_name": artist_name
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        
        if response.status_code == 200:
            data = response.json()
            return {
                "synced_lyrics": data.get("syncedLyrics", None),
                "plain_lyrics": data.get("plainLyrics", None)
            }
        else:
            raise HTTPException(status_code=404, detail="Lyrics not found in lrclib database")
