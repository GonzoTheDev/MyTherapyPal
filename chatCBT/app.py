from langchain_community.vectorstores import Epsilla
from pyepsilla import vectordb
from sentence_transformers import SentenceTransformer
import streamlit as st
import os

import subprocess
from typing import List

# Local embedding model for embedding the question.
model = SentenceTransformer('all-MiniLM-L6-v2')

class LocalEmbeddings():
  def embed_query(self, text: str) -> List[float]:
    return model.encode(text).tolist()

embeddings = LocalEmbeddings()

# Connect to Epsilla as knowledge base.
client = vectordb.Client()
vector_store = Epsilla(
  client,
  embeddings,
  db_path="/tmp/localchatdb",
  db_name="LocalChatDB"
)
vector_store.use_collection("LocalChatCollection")

# The 1st welcome message
st.title("💬 Chatbot")
if "messages" not in st.session_state:
  st.session_state["messages"] = [{"role": "mental health assistant", "content": "Hi, I'm your mental health assistant. How can I help you today?"}]

# A fixture of chat history
for msg in st.session_state.messages:
  st.chat_message(msg["role"]).write(msg["content"])

# Answer user question upon receiving
if question := st.chat_input():
  st.session_state.messages.append({"role": "user", "content": question})

  context = '\n'.join(map(lambda doc: doc.page_content, vector_store.similarity_search(question, k = 5)))

  st.chat_message("user").write(question)

  # Here we use prompt engineering to ingest the most relevant pieces of chunks from knowledge into the prompt.
  prompt = f'''
    You are a mental health assistant that is included with the MyTherapyPal application. You should be an expert in CBT (cognitive behavioural therapy) try to answer the Question based on your CBT expertise and the given Context. Try to understand the Context and rephrase them.
    Please don't make things up. Ask for more information when needed. If you cannot answer the question, try to redirect the user to a human expert or professional.

    Context:
    {context}

    Question:
    {question}

    Answer:
    '''
  print(prompt)

  # Call the local LLM and wait for the generation to finish. This is just a quick demo and we can improve it
  # with better ways in the future.
  command = ['llm', '-m', 'llama2:latest', prompt]
  try:
      process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=-1, cwd=os.getcwd(), env=os.environ)
      output, errors = process.communicate()
      if process.returncode == 0:
          content = output
      else:
          print(f"Error: {errors}")
          content = "Sorry, I'm unable to process your request right now."
  except Exception as e:
      print(f"Error occurred during subprocess call: {e}")
      content = "Sorry, I'm unable to process your request right now."

  # Append the response
  msg = { 'role': 'assistant', 'content': content }
  st.session_state.messages.append(msg)
  st.chat_message("assistant").write(msg['content'])