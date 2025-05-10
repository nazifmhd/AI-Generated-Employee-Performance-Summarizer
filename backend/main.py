from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from openai import OpenAI
import os
import asyncio
from dotenv import load_dotenv

# Load environment variables from .env file if present
load_dotenv()

# Get API key with better error handling
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    print("WARNING: OPENAI_API_KEY environment variable not found!")
    print("Using a placeholder API key for development. OpenAI calls will fail.")

# Setup OpenAI client
client = OpenAI(api_key=api_key)

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class EmployeeData(BaseModel):
    name: str
    id: str
    department: str
    month: str
    tasksCompleted: int
    goalsMet: float
    peerFeedback: str | None = None
    managerComments: str | None = None

class RequestBody(BaseModel):
    employees: List[EmployeeData]

async def generate_employee_summary(emp: EmployeeData):
    """Generate summary for a single employee"""
    prompt = (
        f"Generate a professional performance summary for {emp.name}, who worked in {emp.department} "
        f"during {emp.month}. They completed {emp.tasksCompleted} tasks and achieved {emp.goalsMet}% of their goals. "
    )

    if emp.peerFeedback:
        prompt += f"Peer feedback: {emp.peerFeedback}. "
    if emp.managerComments:
        prompt += f"Manager comments: {emp.managerComments}. "

    prompt += "Make the summary concise and well-structured."

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a professional HR assistant."},
                {"role": "user", "content": prompt}
            ]
        )

        summary = response.choices[0].message.content
        return {
            "name": emp.name,
            "id": emp.id,
            "department": emp.department,
            "month": emp.month,
            "tasksCompleted": str(emp.tasksCompleted),  # Convert to string to match expectations
            "goalsMet": f"{emp.goalsMet}%",  # Add % sign to match expected format
            "peerFeedback": emp.peerFeedback or "",
            "managerComments": emp.managerComments or "",
            "summary": summary
        }
    except Exception as e:
        print(f"Error generating summary for {emp.name}: {str(e)}")
        raise e

@app.post("/generate-summaries")
async def generate_summaries(data: RequestBody):
    if not api_key:
        raise HTTPException(
            status_code=500, 
            detail="OpenAI API key not configured. Set OPENAI_API_KEY environment variable."
        )
        
    summaries = []

    # Process employees one by one to avoid overwhelming the API
    for emp in data.employees:
        try:
            summary = await generate_employee_summary(emp)
            summaries.append(summary)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"OpenAI API error: {str(e)}")

    return {"summaries": summaries}

@app.get("/health")
async def health_check():
    return {"status": "ok", "api_key_configured": bool(api_key)}