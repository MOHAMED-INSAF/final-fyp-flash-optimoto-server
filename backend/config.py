import os

# Database configuration
SQLALCHEMY_DATABASE_URI = 'sqlite:///optimoto.db'  # Using SQLite for simplicity
SQLALCHEMY_TRACK_MODIFICATIONS = False

# JWT configuration
JWT_SECRET_KEY = 'your-secret-key-here'  # Change this to a secure secret key 