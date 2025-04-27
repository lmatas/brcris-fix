#!/bin/bash

# Check if .env file exists, if not, copy the example file
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Creando archivo .env a partir de .env.example..."
        cp .env.example .env
        echo "Archivo .env creado. Por favor, edítalo con los detalles de conexión a tu base de datos."
    else
        echo "Advertencia: No se encontró .env.example. Creando .env vacío."
        touch .env
        echo "Archivo .env creado. Por favor, edítalo con los detalles de conexión a tu base de datos."
        # Opcionalmente, añadir contenido por defecto como antes
        # echo "DB_HOST=localhost" > .env
        # echo "DB_PORT=5432" >> .env
        # echo "DB_NAME=your_db_name" >> .env
        # echo "DB_USER=your_db_user" >> .env
        # echo "DB_PASSWORD=your_db_password" >> .env
    fi
else
    echo "El archivo .env ya existe."
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creando entorno virtual..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo crear el entorno virtual. Asegúrate de que python3 y venv estén instalados."
        exit 1
    fi
else
    echo "El entorno virtual ya existe."
fi

# Activate virtual environment
echo "Activando entorno virtual..."
source venv/bin/activate

# Install requirements
echo "Instalando dependencias desde requirements.txt..."
pip install -r requirements.txt

echo ""
echo "Configuración completada."
echo "Entorno virtual 'venv' activado y dependencias instaladas."
echo "Asegúrate de que el archivo .env contenga la configuración correcta de la base de datos."
