#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    # Create .env file with default values or prompt user for input
    echo "DB_HOST=localhost" > .env
    echo "DB_PORT=5432" >> .env
    echo "DB_NAME=your_db_name" >> .env
    echo "DB_USER=your_db_user" >> .env
    echo "DB_PASSWORD=your_db_password" >> .env
    echo ".env file created. Please edit it with your database connection details."
else
    echo ".env file already exists."
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
source venv/bin/activate

# Install requirements
echo "Installing requirements..."
pip install -r requirements.txt

echo "Setup complete. Virtual environment activated and requirements installed."
echo "Remember to edit the .env file with your database connection details."
