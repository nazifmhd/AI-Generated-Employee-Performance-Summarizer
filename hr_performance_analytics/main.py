from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import openai
import os

# Setup OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")  # or hardcode for local testing

app = FastAPI()

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

@app.post("/generate-summaries")
async def generate_summaries(data: RequestBody):
    summaries = []

    for emp in data.employees:
        prompt = (
            f"Generate a professional performance summary for {emp.name}, who worked in {emp.department} "
            f"during {emp.month}. They completed {emp.tasksCompleted} tasks and achieved {emp.goalsMet}% of their goals. "
        )

        if emp.peerFeedback:
            prompt += f"Peer feedback: {emp.peerFeedback}. "
        if emp.managerComments:
            prompt += f"Manager comments: {emp.managerComments}. "

        prompt += "Make the summary concise and well-structured."

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # or gpt-4 if available
            messages=[
                {"role": "system", "content": "You are a professional HR assistant."},
                {"role": "user", "content": prompt}
            ]
        )

        summary = response['choices'][0]['message']['content']
        summaries.append({
            "name": emp.name,
            "department": emp.department,
            "summary": summary
        })

    return {"summaries": summaries}
