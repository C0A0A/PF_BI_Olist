import sys
import os

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

DB_CONNECTION_STRING = os.getenv("DB_CONNECTION_STRING")
API_TOKEN = os.getenv("API_TOKEN")